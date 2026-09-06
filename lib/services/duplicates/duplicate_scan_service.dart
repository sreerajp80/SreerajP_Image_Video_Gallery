import 'dart:async';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_scan_state.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/media_hashes.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/content_hash_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/duplicate_group_service.dart';

/// Runs a duplicate scan across the indexed library.
///
/// The scan walks the library a page at a time, fingerprints anything that
/// does not have a fingerprint yet, and then groups the lot. Because every
/// fingerprint is written to the database as it is worked out, a second scan
/// only has to read files that are new, which turns a minutes-long job into a
/// moment.
class DuplicateScanService {
  final MediaDao _mediaDao;
  final ContentHashService _hashService;
  final DuplicateGroupService _groupService;

  /// How many rows are read and hashed per page.
  final int pageSize;

  DuplicateScanService({
    required MediaDao mediaDao,
    required ContentHashService hashService,
    DuplicateGroupService groupService = const DuplicateGroupService(),
    this.pageSize = AppConstants.duplicateScanPageSize,
  }) : _mediaDao = mediaDao,
       _hashService = hashService,
       _groupService = groupService;

  bool _cancelled = false;

  /// True while a scan is being wound down.
  bool get isCancelled => _cancelled;

  /// Asks the running scan to stop at the next page boundary.
  ///
  /// The scan does not tear anything down: every fingerprint worked out so
  /// far is already saved, so stopping early only means the next run has less
  /// left to do.
  void cancel() => _cancelled = true;

  /// Runs a scan, reporting a new state after every page.
  ///
  /// [onProgress] is called with a fresh snapshot as the scan moves, so a
  /// screen can show a live count without polling. The final state is also
  /// returned.
  Future<DuplicateScanState> run({
    void Function(DuplicateScanState state)? onProgress,
  }) async {
    _cancelled = false;

    var state = const DuplicateScanState(stage: DuplicateScanStage.hashing);
    void report(DuplicateScanState next) {
      state = next;
      onProgress?.call(next);
    }

    try {
      final total = await _mediaDao.getTotalCount();
      report(state.copyWith(total: total));

      final items = <MediaItem>[];
      final hashes = <String, MediaHashes>{};
      var processed = 0;
      var failures = 0;
      var offset = 0;

      while (true) {
        if (_cancelled) {
          report(state.copyWith(stage: DuplicateScanStage.cancelled));
          return state;
        }

        final page = await _mediaDao.getHashCandidates(
          limit: pageSize,
          offset: offset,
        );
        if (page.isEmpty) break;

        for (final item in page) {
          if (_cancelled) break;
          items.add(item);
          final hash = await _hashService.computeFor(item);
          if (hash.hasAny) {
            hashes[item.id] = hash;
          } else {
            // Unreadable or undecodable. Counted so the user can see the scan
            // did not simply ignore part of their library.
            failures++;
          }
          processed++;
        }

        report(state.copyWith(processed: processed, failures: failures));
        offset += page.length;
        if (page.length < pageSize) break;
      }

      if (_cancelled) {
        report(state.copyWith(stage: DuplicateScanStage.cancelled));
        return state;
      }

      report(state.copyWith(stage: DuplicateScanStage.grouping));
      final groups = _groupService.buildGroups(items: items, hashes: hashes);

      report(state.copyWith(stage: DuplicateScanStage.done, groups: groups));
      return state;
    } catch (e) {
      report(
        state.copyWith(
          stage: DuplicateScanStage.failed,
          errorMessage: e.toString(),
        ),
      );
      return state;
    }
  }
}
