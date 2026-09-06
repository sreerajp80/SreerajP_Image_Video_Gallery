import 'dart:async';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/device/device_memory_service.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_decoder_isolate.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_disk_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_memory_cache.dart';

/// Signature of the background decoder, injectable so tests stay synchronous.
typedef ThumbnailDecoder =
    Future<Uint8List?> Function(ThumbnailDecodeRequest request);

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
/// that single future, so fast scrolling cannot decode an item many times.
class ThumbnailService {
  final MediaStoreChannel _channel;
  final ThumbnailMemoryCache _memoryCache;
  final ThumbnailDiskCache _diskCache;
  final ThumbnailCacheConfig _config;
  final ThumbnailDecoder _decoder;

  /// Largest original file the Dart fallback will try to decode (24 MB).
  static const int maxFallbackSourceBytes = 24 * 1024 * 1024;

  final Map<String, Future<Uint8List?>> _inFlight =
      <String, Future<Uint8List?>>{};

  ThumbnailService({
    required MediaStoreChannel channel,
    required ThumbnailMemoryCache memoryCache,
    required ThumbnailDiskCache diskCache,
    required ThumbnailCacheConfig config,
    ThumbnailDecoder? decoder,
  }) : _channel = channel,
       _memoryCache = memoryCache,
       _diskCache = diskCache,
       _config = config,
       _decoder = decoder ?? decodeThumbnailInIsolate;

  /// The thumbnail edge size chosen for this device.
  int get defaultSize => _config.thumbnailSize;

  /// Number of requests currently being generated.
  int get inFlightCount => _inFlight.length;

  /// Returns JPEG thumbnail bytes for [item], or null when none can be made.
  Future<Uint8List?> getThumbnail(MediaItem item, {int? size}) {
    final targetSize = size ?? _config.thumbnailSize;
    final key = ThumbnailDiskCache.buildKey(item, targetSize);

    final cached = _memoryCache.get(key);
    if (cached != null) return Future<Uint8List?>.value(cached);

    final pending = _inFlight[key];
    if (pending != null) return pending;

    final future = _generate(item, key, targetSize).whenComplete(() {
      _inFlight.remove(key);
    });
    _inFlight[key] = future;
    return future;
  }

  /// Drops the RAM cache. Disk thumbnails are kept.
  void clearMemoryCache() => _memoryCache.clear();

  /// Drops both RAM and disk caches.
  Future<void> clearAll() async {
    _memoryCache.clear();
    await _diskCache.clear();
  }

  Future<Uint8List?> _generate(
    MediaItem item,
    String key,
    int targetSize,
  ) async {
    final fromDisk = await _diskCache.read(key, targetSize);
    if (fromDisk != null) {
      _memoryCache.put(key, fromDisk);
      return fromDisk;
    }

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
        await _store(key, targetSize, native);
        return native;
      }
    }

    final fallback = await _decodeFallback(item, targetSize);
    if (fallback != null && fallback.isNotEmpty) {
      await _store(key, targetSize, fallback);
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

  Future<void> _store(String key, int targetSize, Uint8List bytes) async {
    _memoryCache.put(key, bytes);
    await _diskCache.write(key, targetSize, bytes);
  }

  /// Runs [action], turning any failure into null.
  ///
  /// Thumbnail generation is best effort by design: a corrupt file, a revoked
  /// permission, or a missing plugin must never throw into the widget tree.
  Future<Uint8List?> _safe(Future<Uint8List?> Function() action) async {
    try {
      return await action();
    } catch (_) {
      return null;
    }
  }
}
