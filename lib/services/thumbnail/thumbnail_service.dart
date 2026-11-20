import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:in_sreerajp_imgvidgal/services/device/device_memory_service.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_decoder_isolate.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_disk_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_memory_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_request_queue.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Signature of the background decoder, injectable so tests stay synchronous.
typedef ThumbnailDecoder =
    Future<Uint8List?> Function(ThumbnailDecodeRequest request);

/// A thumbnail request that the caller can give up on.
///
/// A grid tile cancels its request when it scrolls off screen, so the slow
/// device work is skipped for tiles nobody is looking at any more.
class ThumbnailRequest {
  /// The thumbnail bytes, or null when none can be made or the request was
  /// cancelled before it started.
  final Future<Uint8List?> future;

  final void Function() _onCancel;
  bool _cancelled = false;

  ThumbnailRequest._(this.future, this._onCancel);

  /// Says this caller no longer needs the thumbnail. Safe to call twice.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _onCancel();
  }
}

/// One thumbnail being made, shared by every caller that asked for it.
class _ThumbnailJob {
  late final Future<Uint8List?> future;

  /// Callers still waiting for this job.
  int interest = 0;

  /// True once every caller has cancelled.
  bool cancelled = false;

  /// The queued device step, once the disk cache missed.
  ThumbnailQueueTask<Uint8List>? task;
}

/// Produces and caches gallery thumbnails.
///
/// Lookup order, cheapest first:
/// 1. RAM cache
/// 2. Disk cache
/// 3. Android MediaStore hardware thumbnail
/// 4. Pure Dart decode in a background isolate
/// 5. null — the caller shows a placeholder
///
/// Requests for the same key that arrive while one is already in flight share
/// that single job, so fast scrolling cannot decode an item many times.
///
/// Steps 3 and 4 are slow, so they go through a [ThumbnailRequestQueue]: only
/// a few run at once and the newest request is served first. A new thumbnail
/// is returned as soon as it is in RAM; the disk write runs after, without
/// making the tile wait.
class ThumbnailService {
  final MediaStoreChannel _channel;
  final ThumbnailMemoryCache _memoryCache;
  final ThumbnailDiskCache _diskCache;
  final ThumbnailCacheConfig _config;
  final ThumbnailDecoder _decoder;
  final ThumbnailRequestQueue _queue;

  /// Largest original file the Dart fallback will try to decode (24 MB).
  static const int maxFallbackSourceBytes = 24 * 1024 * 1024;

  final Map<String, _ThumbnailJob> _inFlight = <String, _ThumbnailJob>{};

  /// Disk writes started but not finished yet.
  final Set<Future<void>> _pendingWrites = <Future<void>>{};

  ThumbnailService({
    required MediaStoreChannel channel,
    required ThumbnailMemoryCache memoryCache,
    required ThumbnailDiskCache diskCache,
    required ThumbnailCacheConfig config,
    ThumbnailDecoder? decoder,
    ThumbnailRequestQueue? queue,
  }) : _channel = channel,
       _memoryCache = memoryCache,
       _diskCache = diskCache,
       _config = config,
       _decoder = decoder ?? decodeThumbnailInIsolate,
       _queue =
           queue ??
           ThumbnailRequestQueue(maxConcurrent: config.maxConcurrentThumbnails);

  /// The thumbnail edge size chosen for this device.
  int get defaultSize => _config.thumbnailSize;

  /// Number of requests currently being generated.
  int get inFlightCount => _inFlight.length;

  /// Returns JPEG thumbnail bytes for [item], or null when none can be made.
  ///
  /// This request cannot be cancelled. Grid tiles use [requestThumbnail].
  Future<Uint8List?> getThumbnail(MediaItem item, {int? size}) {
    return requestThumbnail(item, size: size).future;
  }

  /// Starts (or joins) the work for [item]'s thumbnail.
  ///
  /// Call [ThumbnailRequest.cancel] when the result is no longer needed. The
  /// shared work is dropped only when every caller has cancelled, and only
  /// if the slow device step has not started yet.
  ThumbnailRequest requestThumbnail(MediaItem item, {int? size}) {
    final targetSize = size ?? _config.thumbnailSize;
    final key = ThumbnailDiskCache.buildKey(item, targetSize);

    final cached = _memoryCache.get(key);
    if (cached != null) {
      return ThumbnailRequest._(Future<Uint8List?>.value(cached), () {});
    }

    var job = _inFlight[key];
    if (job == null) {
      final newJob = _ThumbnailJob();
      newJob.future = _generate(item, key, targetSize, newJob).whenComplete(() {
        if (identical(_inFlight[key], newJob)) _inFlight.remove(key);
      });
      _inFlight[key] = newJob;
      job = newJob;
    }

    final joined = job;
    joined.interest++;
    return ThumbnailRequest._(joined.future, () {
      joined.interest--;
      if (joined.interest > 0 || joined.cancelled) return;
      joined.cancelled = true;
      joined.task?.cancel();
      // A later request for this item must start fresh work, not join the
      // cancelled job.
      if (identical(_inFlight[key], joined)) _inFlight.remove(key);
    });
  }

  /// Waits until every disk write started so far has finished.
  @visibleForTesting
  Future<void> flushDiskWrites() async {
    while (_pendingWrites.isNotEmpty) {
      await Future.wait(_pendingWrites.toList(growable: false));
    }
  }

  /// Drops the RAM cache. Disk thumbnails are kept.
  void clearMemoryCache() => _memoryCache.clear();

  /// Drops both RAM and disk caches.
  Future<void> clearAll() async {
    // Let started writes land first, so none of them refills the cleared
    // disk cache afterwards.
    await flushDiskWrites();
    _memoryCache.clear();
    await _diskCache.clear();
  }

  Future<Uint8List?> _generate(
    MediaItem item,
    String key,
    int targetSize,
    _ThumbnailJob job,
  ) async {
    final fromDisk = await _diskCache.read(key, targetSize);
    if (fromDisk != null) {
      _memoryCache.put(key, fromDisk);
      return fromDisk;
    }

    if (job.cancelled) return null;
    final task = _queue.enqueue<Uint8List>(
      () => _generateOnDevice(item, key, targetSize),
    );
    job.task = task;
    return task.future;
  }

  /// The slow steps: Android's thumbnail, then the Dart decode fallback.
  Future<Uint8List?> _generateOnDevice(
    MediaItem item,
    String key,
    int targetSize,
  ) async {
    final uri = item.uri;
    if (uri != null && uri.isNotEmpty) {
      final native = await _safe(
        () => _channel.loadThumbnail(
          uri: uri,
          width: targetSize,
          height: targetSize,
        ),
      );
      if (native != null && native.isNotEmpty) {
        _store(key, targetSize, native);
        return native;
      }
    }

    final fallback = await _decodeFallback(item, targetSize);
    if (fallback != null && fallback.isNotEmpty) {
      _store(key, targetSize, fallback);
      return fallback;
    }

    // Nothing worked: the widget layer shows a broken-media placeholder.
    return null;
  }

  Future<Uint8List?> _decodeFallback(MediaItem item, int targetSize) async {
    // Videos have no still frame to decode in pure Dart; that is a Phase 5
    // concern. Oversized originals are skipped to protect low-RAM devices.
    if (item.isVideo) return null;
    if (item.size > maxFallbackSourceBytes) return null;

    final uri = item.uri;
    if (uri == null || uri.isEmpty) return null;

    final source = await _safe(
      () => _channel.readBytes(uri, maxBytes: maxFallbackSourceBytes),
    );
    if (source == null || source.isEmpty) return null;

    return _safe(
      () => _decoder(
        ThumbnailDecodeRequest(bytes: source, targetSize: targetSize),
      ),
    );
  }

  /// Puts [bytes] in RAM now and writes them to disk in the background.
  ///
  /// The tile does not wait for the disk. A failed write is only a cache
  /// miss later, so errors are swallowed here (the disk cache logs them).
  void _store(String key, int targetSize, Uint8List bytes) {
    _memoryCache.put(key, bytes);
    late final Future<void> write;
    write = _diskCache
        .write(key, targetSize, bytes)
        .then<void>((_) {}, onError: (Object _) {})
        .whenComplete(() => _pendingWrites.remove(write));
    _pendingWrites.add(write);
  }

  /// Runs [action], turning any failure into null.
  ///
  /// Thumbnail generation is best effort by design: a corrupt file, a revoked
  /// permission, or a missing plugin must never throw into the widget tree.
  Future<Uint8List?> _safe(Future<Uint8List?> Function() action) async {
    try {
      return await action();
    } catch (error) {
      AppLogger.debug('A thumbnail step failed');
      return null;
    }
  }
}
