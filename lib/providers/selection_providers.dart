import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

/// Which media items are ticked, across every grid in the app.
///
/// One selection, not one per screen. Long-pressing on the timeline and then
/// opening an album keeps the ticks, which is what makes "select a few here,
/// a few there, then act on all of them" work at all.
///
/// It holds ids rather than whole items. A [MediaItem] carries EXIF and tag
/// lists, and keeping five hundred of them alive so a checkbox can be ticked
/// would be a real cost for no benefit; the items are resolved from the
/// database only when an action actually needs them.
class SelectionNotifier extends StateNotifier<Set<String>> {
  SelectionNotifier() : super(const <String>{});

  /// Whether anything is ticked.
  ///
  /// This is also what puts the grids into selection mode: there is no
  /// separate flag that could get out of step with the set itself.
  bool get isActive => state.isNotEmpty;

  /// Whether one item is ticked.
  bool contains(String id) => state.contains(id);

  /// Ticks or unticks one item.
  ///
  /// Refuses to grow past the cap rather than accepting a selection the batch
  /// runner would then have to refuse. Better to stop at the boundary than to
  /// let someone select six hundred photos and only then be told.
  void toggle(String id) {
    if (state.contains(id)) {
      state = <String>{...state}..remove(id);
      return;
    }
    if (state.length >= AppConstants.batchMaxSelectionSize) return;
    state = <String>{...state, id};
  }

  /// Ticks everything given, up to the cap.
  void selectAll(Iterable<String> ids) {
    state = <String>{
      ...state,
      ...ids,
    }.take(AppConstants.batchMaxSelectionSize).toSet();
  }

  /// Unticks everything.
  void clear() => state = const <String>{};

  /// Unticks anything not in [ids].
  ///
  /// Called after a batch that removed items from the library, so the
  /// selection cannot keep pointing at photos that are gone.
  void retainOnly(Set<String> ids) {
    final kept = state.intersection(ids);
    if (kept.length != state.length) state = kept;
  }

  /// Whether one more item can be ticked.
  bool get isFull => state.length >= AppConstants.batchMaxSelectionSize;
}

/// The ticked media ids.
final selectionProvider = StateNotifierProvider<SelectionNotifier, Set<String>>(
  (ref) => SelectionNotifier(),
);

/// Whether the grids should be drawing tick boxes.
final selectionModeProvider = Provider<bool>((ref) {
  return ref.watch(selectionProvider).isNotEmpty;
});

/// How many items are ticked.
final selectionCountProvider = Provider<int>((ref) {
  return ref.watch(selectionProvider).length;
});

/// The ticked items themselves, read from the database.
///
/// A future rather than a value, because the ids are what is held and the
/// rows have to be fetched. Watched only by the things that genuinely need
/// whole items — the action bar's rules and the batch runner — so ticking a
/// box does not re-read five hundred rows.
final selectedMediaProvider = FutureProvider<List<MediaItem>>((ref) async {
  final ids = ref.watch(selectionProvider);
  if (ids.isEmpty) return const <MediaItem>[];

  final items = await ref
      .watch(mediaRepositoryProvider)
      .getMediaItemsByIds(ids.toList(growable: false));

  return items;
});
