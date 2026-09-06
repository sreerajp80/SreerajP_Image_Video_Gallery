import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_type_resolver.dart';

/// Stage the scanner is currently in.
enum ScanPhase {
  idle,
  checkingPermission,
  counting,
  indexing,
  cleaningUp,
  completed,
  failed,
}

/// Progress snapshot emitted while a scan runs.
@immutable
class ScanProgress {
  final ScanPhase phase;

  /// Number of MediaStore rows handled so far.
  final int scanned;

  /// Total rows expected, or 0 when the total is not yet known.
  final int total;

  /// Rows that could not be read and were skipped.
  final int skipped;

  const ScanProgress({
    required this.phase,
    this.scanned = 0,
    this.total = 0,
    this.skipped = 0,
  });

  /// Completion fraction from 0.0 to 1.0, or null when the total is unknown.
  double? get fraction {
    if (total <= 0) return null;
    return (scanned / total).clamp(0.0, 1.0);
  }

  ScanProgress copyWith({
    ScanPhase? phase,
    int? scanned,
    int? total,
    int? skipped,
  }) {
    return ScanProgress(
      phase: phase ?? this.phase,
      scanned: scanned ?? this.scanned,
      total: total ?? this.total,
      skipped: skipped ?? this.skipped,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanProgress &&
          runtimeType == other.runtimeType &&
          phase == other.phase &&
          scanned == other.scanned &&
          total == other.total &&
          skipped == other.skipped;

  @override
  int get hashCode => Object.hash(phase, scanned, total, skipped);
}

/// Outcome of a completed scan.
@immutable
class ScanResult {
  /// Items written into the database.
  final int indexed;

  /// Rows that could not be read and were skipped.
  final int skipped;

  /// Database rows removed because the file no longer exists.
  final int removed;

  /// Permission state at the time of the scan.
  final MediaPermissionStatus permissionStatus;

  const ScanResult({
    required this.indexed,
    required this.skipped,
    required this.removed,
    required this.permissionStatus,
  });
}

/// Scans the Android MediaStore and indexes what it finds into SQLite.
///
/// All device access goes through the injected [MediaStoreChannel], so this
/// class is fully testable with a fake channel.
class MediaScannerService {
  final MediaStoreChannel _channel;
  final MediaDao _mediaDao;
  final int _batchSize;

  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();

  ScanProgress _progress = const ScanProgress(phase: ScanPhase.idle);
  bool _isScanning = false;

  MediaScannerService({
    required MediaStoreChannel channel,
    required MediaDao mediaDao,
    int batchSize = AppConstants.scanBatchSize,
  }) : _channel = channel,
       _mediaDao = mediaDao,
       _batchSize = batchSize;

  /// Live scan progress. Broadcast, so several listeners are allowed.
  Stream<ScanProgress> get progressStream => _progressController.stream;

  /// The most recent progress snapshot.
  ScanProgress get progress => _progress;

  /// Whether a scan is currently running.
  bool get isScanning => _isScanning;

  /// Scans the device and writes every readable item into the database.
  ///
  /// When [incremental] is true only rows modified since the newest indexed
  /// item are read, which makes repeat scans cheap. Stale database rows are
  /// removed only after a full scan with full permission, because with partial
  /// ("selected photos") access the missing rows may simply be hidden.
  Future<ScanResult> scan({bool incremental = false}) async {
    if (_isScanning) {
      throw const MediaScanException('A media scan is already running');
    }
    _isScanning = true;

    try {
      _emit(const ScanProgress(phase: ScanPhase.checkingPermission));
      final permission = await _channel.checkPermissions();
      if (!permission.canRead) {
        _emit(_progress.copyWith(phase: ScanPhase.failed));
        throw PermissionDeniedException(
          'Media permission is required before scanning',
          isPermanent: permission == MediaPermissionStatus.permanentlyDenied,
        );
      }

      _emit(_progress.copyWith(phase: ScanPhase.counting));
      final total = await _channel.getMediaCount();
      _emit(_progress.copyWith(phase: ScanPhase.indexing, total: total));

      final int? since = incremental
          ? await _mediaDao.getNewestDateModifiedMs()
          : null;

      final seenIds = <String>{};
      var scanned = 0;
      var skipped = 0;
      var indexed = 0;
      var offset = 0;

      while (true) {
        final entries = await _channel.queryMedia(
          offset: offset,
          limit: _batchSize,
          sinceDateModifiedMs: since,
        );
        if (entries.isEmpty) break;

        final items = <MediaItem>[];
        for (final entry in entries) {
          scanned++;
          try {
            final item = mapEntryToMediaItem(entry);
            items.add(item);
            seenIds.add(item.id);
          } catch (_) {
            // A single bad row is counted and skipped, never fatal.
            skipped++;
          }
        }

        if (items.isNotEmpty) {
          await _mediaDao.batchUpsertMediaItems(items);
          indexed += items.length;
        }

        _emit(
          _progress.copyWith(
            phase: ScanPhase.indexing,
            scanned: scanned,
            skipped: skipped,
          ),
        );

        if (entries.length < _batchSize) break;
        offset += entries.length;
      }

      var removed = 0;
      if (!incremental && permission == MediaPermissionStatus.granted) {
        _emit(_progress.copyWith(phase: ScanPhase.cleaningUp));
        removed = await _mediaDao.deleteMediaItemsMissingFrom(seenIds);
      }

      _emit(
        _progress.copyWith(
          phase: ScanPhase.completed,
          scanned: scanned,
          skipped: skipped,
        ),
      );

      return ScanResult(
        indexed: indexed,
        skipped: skipped,
        removed: removed,
        permissionStatus: permission,
      );
    } on AppException {
      _emit(_progress.copyWith(phase: ScanPhase.failed));
      rethrow;
    } catch (e, st) {
      _emit(_progress.copyWith(phase: ScanPhase.failed));
      throw MediaScanException('Media scan failed', cause: e, stackTrace: st);
    } finally {
      _isScanning = false;
    }
  }

  /// Converts a raw MediaStore row into the immutable domain model.
  ///
  /// Visible for testing. Throws [MediaScanException] for a row that cannot be
  /// turned into a usable item, so the caller can skip it.
  @visibleForTesting
  static MediaItem mapEntryToMediaItem(MediaStoreEntry entry) {
    if (entry.id.isEmpty) {
      throw const MediaScanException('MediaStore row has no id');
    }

    final mediaType = MediaTypeResolver.resolve(
      mimeType: entry.mimeType,
      fileName: entry.displayName,
    );

    final dateModified = DateTime.fromMillisecondsSinceEpoch(
      entry.dateModifiedMs,
    );
    final dateAdded = entry.dateAddedMs > 0
        ? DateTime.fromMillisecondsSinceEpoch(entry.dateAddedMs)
        : dateModified;
    final dateTaken = (entry.dateTakenMs != null && entry.dateTakenMs! > 0)
        ? DateTime.fromMillisecondsSinceEpoch(entry.dateTakenMs!)
        : null;

    return MediaItem(
      id: entry.id,
      path: entry.path,
      uri: entry.uri,
      displayName: entry.displayName,
      mediaType: mediaType,
      mimeType: entry.mimeType,
      size: entry.size,
      dateAdded: dateAdded,
      dateModified: dateModified,
      dateTaken: dateTaken,
      durationMs: mediaType == MediaType.video ? entry.durationMs : null,
      width: entry.width,
      height: entry.height,
      orientation: entry.orientation,
    );
  }

  void _emit(ScanProgress next) {
    _progress = next;
    if (!_progressController.isClosed) {
      _progressController.add(next);
    }
  }

  /// Releases the progress stream.
  Future<void> dispose() async {
    await _progressController.close();
  }
}
