import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_type_resolver.dart';
import 'package:in_sreerajp_imgvidgal/services/media/stale_cleanup_store.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

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

  /// Whether the scan walked the whole device list, not only new rows.
  ///
  /// A full pass may hide or show rows without counting them, so it always
  /// counts as a change. Defaults to true, the safe side.
  final bool fullPass;

  const ScanResult({
    required this.indexed,
    required this.skipped,
    required this.removed,
    required this.permissionStatus,
    this.fullPass = true,
    this.changed,
  });

  /// Rows that were new or really changed, or null when not known.
  ///
  /// [indexed] counts every row read, and a quick pass always re-reads the
  /// newest row, so [indexed] alone can never say "nothing changed".
  final int? changed;

  /// Whether the visible library may differ from before the scan.
  ///
  /// False only for a quick pass that wrote and removed nothing, which is
  /// what most app opens and resumes are. Lists need no reload then.
  bool get libraryChanged =>
      fullPass || (changed ?? indexed) > 0 || removed > 0;
}

/// Scans the Android MediaStore and indexes what it finds into SQLite.
///
/// All device access goes through the injected [MediaStoreChannel], so this
/// class is fully testable with a fake channel.
class MediaScannerService {
  final MediaStoreChannel _channel;
  final MediaDao _mediaDao;
  final int _batchSize;
  final StaleCleanupStore? _staleStore;
  final DateTime Function() _now;

  final StreamController<ScanProgress> _progressController =
      StreamController<ScanProgress>.broadcast();

  ScanProgress _progress = const ScanProgress(phase: ScanPhase.idle);
  bool _isScanning = false;

  /// Above this many ghost rows the safety stop in [_indexPass] may apply.
  @visibleForTesting
  static const int ghostSafetyMin = 20;

  /// Unreadable rows seen by the last full pass. They are on the device but
  /// never in the index, so the quick-scan count check allows for them.
  int _lastFullPassSkipped = 0;

  MediaScannerService({
    required MediaStoreChannel channel,
    required MediaDao mediaDao,
    int batchSize = AppConstants.scanBatchSize,
    StaleCleanupStore? staleStore,
    DateTime Function()? now,
  }) : _channel = channel,
       _mediaDao = mediaDao,
       _batchSize = batchSize,
       _staleStore = staleStore,
       _now = now ?? DateTime.now;

  /// Runs the ghost-entry cleanup when it has not run in the last
  /// [AppConstants.staleCleanupInterval]. Returns how many entries went.
  ///
  /// Never throws: a failed cleanup must not stop the scan.
  Future<int> _cleanGhostsIfDue() async {
    final store = _staleStore;
    if (store == null) return 0;
    try {
      final now = _now();
      final last = await store.lastRun();
      if (last != null &&
          now.difference(last) < AppConstants.staleCleanupInterval &&
          !now.isBefore(last)) {
        return 0;
      }
      final cleaned = await _channel.cleanStaleEntries();
      await store.setLastRun(now);
      return cleaned;
    } catch (error) {
      AppLogger.warning('Ghost cleanup before the scan failed', error: error);
      return 0;
    }
  }

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
  ///
  /// Rows Android does not currently let the app see are kept but marked out
  /// of reach, so every list hides them and the user's tags, favourites and
  /// notes survive until access comes back:
  /// - limited access: always a full pass; unseen rows are marked;
  /// - full access: marked rows force a full pass, after which all are shown;
  /// - no access: every row is marked before the scan fails.
  Future<ScanResult> scan({bool incremental = false}) async {
    if (_isScanning) {
      throw const MediaScanException('A media scan is already running');
    }
    _isScanning = true;

    try {
      _emit(const ScanProgress(phase: ScanPhase.checkingPermission));
      final permission = await _channel.checkPermissions();
      if (!permission.canRead) {
        await _hideEverything();
        _emit(_progress.copyWith(phase: ScanPhase.failed));
        throw PermissionDeniedException(
          'Media permission is required before scanning',
          isPermanent: permission == MediaPermissionStatus.permanentlyDenied,
        );
      }

      _emit(_progress.copyWith(phase: ScanPhase.counting));
      final total = await _channel.getMediaCount();
      _emit(_progress.copyWith(phase: ScanPhase.indexing, total: total));

      final fullAccess = permission == MediaPermissionStatus.granted;

      // A quick pass cannot tell which rows Android hides, and with full
      // access it cannot bring hidden rows back, so either case needs a full
      // pass. With limited access the list is short, so this stays cheap.
      // Ghost entries (Android 10) are dropped from MediaStore first, so the
      // pass below no longer sees them. If any went, only a full pass lets
      // the clean-up step remove them from the index too.
      final ghostsCleaned = fullAccess ? await _cleanGhostsIfDue() : 0;

      final quickPass =
          incremental &&
          fullAccess &&
          ghostsCleaned == 0 &&
          !await _mediaDao.hasOutOfReach();

      final int? since = quickPass
          ? await _mediaDao.getNewestDateModifiedMs()
          : null;

      var pass = await _indexPass(sinceDateModifiedMs: since);
      var fullPass = !quickPass;

      // The quick pass only sees rows newer than the newest one indexed, so it
      // misses deletions and files that arrive with an old date. If the device
      // count no longer matches the index, fall back to a full pass. Skipped
      // with partial access, where hidden items make the numbers differ.
      if (quickPass) {
        final stored = await _mediaDao.getMediaStoreBackedCount();
        if (stored + _lastFullPassSkipped != total) {
          AppLogger.debug('Quick scan count mismatch; running a full pass');
          pass = await _indexPass(sinceDateModifiedMs: null);
          fullPass = true;
        }
      }
      if (fullPass) _lastFullPassSkipped = pass.skipped;

      var removed = 0;
      if (fullPass && fullAccess) {
        _emit(_progress.copyWith(phase: ScanPhase.cleaningUp));
        removed = await _mediaDao.deleteMediaItemsMissingFrom(pass.seenIds);
        await _mediaDao.clearOutOfReach();
      } else if (fullPass) {
        // Limited access: nothing is deleted, the unseen rows are hidden.
        await _mediaDao.markOutOfReachExcept(pass.seenIds);
      }

      _emit(
        _progress.copyWith(
          phase: ScanPhase.completed,
          scanned: pass.scanned,
          skipped: pass.skipped,
        ),
      );

      return ScanResult(
        indexed: pass.indexed,
        skipped: pass.skipped,
        removed: removed,
        permissionStatus: permission,
        fullPass: fullPass,
        changed: pass.changed,
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

  /// Hides every row when the app may not read media at all.
  ///
  /// Best effort: the scan is about to fail with a permission error anyway,
  /// and that error is the one the caller must see.
  Future<void> _hideEverything() async {
    try {
      await _mediaDao.markAllOutOfReach();
    } catch (error) {
      AppLogger.warning(
        'Could not hide media after access was removed',
        error: error,
      );
    }
  }

  /// Reads MediaStore page by page and upserts every readable row.
  ///
  /// With [sinceDateModifiedMs] only rows modified at or after it are read.
  ///
  /// A ghost row (file gone, Android 10) is not indexed, so the gallery does
  /// not show a photo that is not there, and a full pass then removes an
  /// older copy from the index. Safety stop: if more than half the rows (and
  /// more than [ghostSafetyMin]) look like ghosts, they are all indexed as
  /// usual; that points to a storage problem, such as a removed SD card.
  Future<_PassResult> _indexPass({required int? sinceDateModifiedMs}) async {
    final seenIds = <String>{};
    final ghosts = <MediaItem>[];
    var scanned = 0;
    var skipped = 0;
    var indexed = 0;
    var changed = 0;
    var offset = 0;

    while (true) {
      final entries = await _channel.queryMedia(
        offset: offset,
        limit: _batchSize,
        sinceDateModifiedMs: sinceDateModifiedMs,
      );
      if (entries.isEmpty) break;

      final items = <MediaItem>[];
      for (final entry in entries) {
        scanned++;
        try {
          final item = mapEntryToMediaItem(entry);
          if (entry.fileMissing) {
            ghosts.add(item);
            continue;
          }
          items.add(item);
          seenIds.add(item.id);
        } catch (error) {
          AppLogger.debug('Skipped one unreadable MediaStore row');
          // A single bad row is counted and skipped, never fatal.
          skipped++;
        }
      }

      if (items.isNotEmpty) {
        changed += await _mediaDao.batchUpsertMediaItems(items);
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

    if (ghosts.isNotEmpty) {
      if (ghosts.length > ghostSafetyMin && ghosts.length * 2 > scanned) {
        AppLogger.warning(
          'Most media looked missing; indexing it anyway as a safety stop',
        );
        changed += await _mediaDao.batchUpsertMediaItems(ghosts);
        indexed += ghosts.length;
        seenIds.addAll(ghosts.map((item) => item.id));
      } else {
        // Counted as skipped, so the quick-scan count check still matches
        // MediaStore, which keeps listing the ghost.
        skipped += ghosts.length;
      }
    }

    return _PassResult(
      seenIds: seenIds,
      scanned: scanned,
      skipped: skipped,
      indexed: indexed,
      changed: changed,
    );
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

/// What one pass over MediaStore found.
class _PassResult {
  final Set<String> seenIds;
  final int scanned;
  final int skipped;
  final int indexed;

  /// Rows that were new or had a changed Android-owned column.
  final int changed;

  const _PassResult({
    required this.seenIds,
    required this.scanned,
    required this.skipped,
    required this.indexed,
    required this.changed,
  });
}
