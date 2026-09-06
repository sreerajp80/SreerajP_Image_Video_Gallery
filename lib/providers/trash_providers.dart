import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

/// Bumped after every trash change so watching providers refresh together.
final trashRevisionProvider = StateProvider<int>((ref) => 0);

/// All items currently in the trash, newest first.
final trashMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  ref.watch(trashRevisionProvider);
  ref.watch(mediaScanControllerProvider);
  return ref
      .watch(mediaRepositoryProvider)
      .getMediaItems(filter: const FilterOptions(isTrash: true));
});

/// Number of items sitting in the trash.
final trashCountProvider = FutureProvider<int>((ref) async {
  ref.watch(trashRevisionProvider);
  ref.watch(mediaScanControllerProvider);
  return ref.watch(mediaRepositoryProvider).getTrashCount();
});

/// Drives restore and empty-trash actions on behalf of the trash screen.
///
/// The state carries whether an action is in flight and whether the last one
/// failed, which is all the screen needs to disable its buttons and show a
/// message.
class TrashController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  TrashController({required Ref ref})
    : _ref = ref,
      super(const AsyncValue<void>.data(null));

  /// Restores one item from the trash back to the main library.
  Future<void> restoreItem(String id) async {
    state = const AsyncValue<void>.loading();
    try {
      await _ref.read(mediaRepositoryProvider).setTrash(id, false);
      state = const AsyncValue<void>.data(null);
      _ref.read(trashRevisionProvider.notifier).state++;
    } catch (e, st) {
      state = AsyncValue<void>.error(e, st);
    }
  }

  /// Restores every item in the trash back to the main library.
  Future<int> restoreAll() async {
    state = const AsyncValue<void>.loading();
    try {
      final count = await _ref
          .read(mediaRepositoryProvider)
          .restoreAllFromTrash();
      state = const AsyncValue<void>.data(null);
      _ref.read(trashRevisionProvider.notifier).state++;
      return count;
    } catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return 0;
    }
  }

  /// Permanently removes every trashed row from the gallery database.
  ///
  /// The original files stay on the device. A future scan will re-index them,
  /// so nothing is truly lost from the phone.
  Future<int> emptyTrash() async {
    state = const AsyncValue<void>.loading();
    try {
      final count = await _ref.read(mediaRepositoryProvider).emptyTrash();
      state = const AsyncValue<void>.data(null);
      _ref.read(trashRevisionProvider.notifier).state++;
      return count;
    } catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return 0;
    }
  }
}

/// Trash actions, used by the trash screen.
final trashControllerProvider =
    StateNotifierProvider<TrashController, AsyncValue<void>>((ref) {
      return TrashController(ref: ref);
    });
