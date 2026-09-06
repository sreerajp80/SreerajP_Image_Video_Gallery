import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_scan_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/best_photo_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/content_hash_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/duplicate_group_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/duplicate_scan_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/hash_tools_channel.dart';

/// Platform bridge for streamed digests and downsampled grayscale decoding.
final hashToolsChannelProvider = Provider<HashToolsChannel>((ref) {
  return PlatformHashToolsChannel();
});

/// Picks which copy of a picture to keep.
final bestPhotoServiceProvider = Provider<BestPhotoService>((ref) {
  return const BestPhotoService();
});

/// Sorts fingerprints into groups of copies.
final duplicateGroupServiceProvider = Provider<DuplicateGroupService>((ref) {
  return DuplicateGroupService(
    bestPhotoService: ref.watch(bestPhotoServiceProvider),
  );
});

/// Computes and stores the fingerprints of one item.
final contentHashServiceProvider = Provider<ContentHashService>((ref) {
  return ContentHashService(
    channel: ref.watch(hashToolsChannelProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    // Falls back to the cached thumbnail when the platform cannot decode the
    // original, which keeps the scan working on a host or an odd device.
    thumbnailLoader: (item) async {
      final service = await ref.read(thumbnailServiceProvider.future);
      return service.getThumbnail(item);
    },
  );
});

/// Drives a whole duplicate scan.
final duplicateScanServiceProvider = Provider<DuplicateScanService>((ref) {
  return DuplicateScanService(
    mediaDao: ref.watch(mediaDaoProvider),
    hashService: ref.watch(contentHashServiceProvider),
    groupService: ref.watch(duplicateGroupServiceProvider),
  );
});

/// Runs the scan and exposes its live state to the cleaner screen.
class DuplicateScanController extends StateNotifier<DuplicateScanState> {
  final DuplicateScanService _service;

  DuplicateScanController({required DuplicateScanService service})
    : _service = service,
      super(const DuplicateScanState());

  /// Starts a scan, ignoring the request when one is already running.
  Future<void> start() async {
    if (state.isRunning) return;
    state = const DuplicateScanState(stage: DuplicateScanStage.hashing);
    await _service.run(
      onProgress: (next) {
        if (mounted) state = next;
      },
    );
  }

  /// Asks the running scan to stop.
  void cancel() => _service.cancel();

  /// Drops a group from the list once its copies have been dealt with.
  ///
  /// The group has just been acted on, so leaving it on screen would invite
  /// the user to act on it twice.
  void dismissGroup(String groupId) {
    state = state.copyWith(
      groups: state.groups.where((g) => g.id != groupId).toList(),
    );
  }
}

/// The duplicate scan, shared by the cleaner and the compare screen.
final duplicateScanControllerProvider =
    StateNotifierProvider<DuplicateScanController, DuplicateScanState>((ref) {
      return DuplicateScanController(
        service: ref.watch(duplicateScanServiceProvider),
      );
    });

/// One group by id, or null once it has been dealt with or never existed.
final duplicateGroupProvider = Provider.family<DuplicateGroup?, String>((
  ref,
  groupId,
) {
  final groups = ref.watch(duplicateScanControllerProvider).groups;
  for (final group in groups) {
    if (group.id == groupId) return group;
  }
  return null;
});

/// Which copy the user has chosen to keep in each group.
///
/// Keyed by group id and holding the id of the keeper. A group with no entry
/// falls back to whatever the scan suggested, so the screen always has an
/// answer without having to seed this map up front.
class DuplicateKeeperNotifier extends StateNotifier<Map<String, String>> {
  DuplicateKeeperNotifier() : super(const <String, String>{});

  /// Chooses the copy to keep in one group.
  void choose(String groupId, String mediaId) {
    state = <String, String>{...state, groupId: mediaId};
  }

  /// The chosen keeper, or the suggestion when the user has not chosen.
  String keeperFor(DuplicateGroup group) =>
      state[group.id] ?? group.suggestedKeeperId;

  /// Forgets the choice for one group.
  void forget(String groupId) {
    final next = <String, String>{...state}..remove(groupId);
    state = next;
  }
}

/// The user's keep choices across the cleaner.
final duplicateKeeperProvider =
    StateNotifierProvider<DuplicateKeeperNotifier, Map<String, String>>((ref) {
      return DuplicateKeeperNotifier();
    });

/// Moves the copies the user did not keep into the trash.
///
/// Nothing is erased from the device. Every losing copy is flagged as trashed
/// in the app's own index, so it leaves the gallery and can be brought back.
/// Deleting the file itself is a separate, later decision, and is deliberately
/// not something this screen can do.
class DuplicateCleanupController extends StateNotifier<AsyncValue<int>> {
  final MediaRepository _repository;
  final Ref _ref;

  DuplicateCleanupController({
    required MediaRepository repository,
    required Ref ref,
  }) : _repository = repository,
       _ref = ref,
       super(const AsyncValue<int>.data(0));

  /// Trashes every member of [group] except [keeperId].
  ///
  /// Returns how many copies were moved, or null when something went wrong.
  Future<int?> keepOnly(DuplicateGroup group, String keeperId) async {
    state = const AsyncValue<int>.loading();
    try {
      var moved = 0;
      for (final item in group.items) {
        if (item.id == keeperId) continue;
        await _repository.setTrash(item.id, true);
        moved++;
      }
      state = AsyncValue<int>.data(moved);
      _ref
          .read(duplicateScanControllerProvider.notifier)
          .dismissGroup(group.id);
      _ref.read(duplicateKeeperProvider.notifier).forget(group.id);
      return moved;
    } catch (e, st) {
      state = AsyncValue<int>.error(e, st);
      return null;
    }
  }
}

/// The "keep this one" action, used by the compare screen.
final duplicateCleanupControllerProvider =
    StateNotifierProvider<DuplicateCleanupController, AsyncValue<int>>((ref) {
      return DuplicateCleanupController(
        repository: ref.watch(mediaRepositoryProvider),
        ref: ref,
      );
    });
