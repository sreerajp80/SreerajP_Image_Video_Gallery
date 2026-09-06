import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';

/// Data access object over the tag tables.
final tagDaoProvider = Provider<TagDao>((ref) => TagDao());

/// The only way the app changes tags.
final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(
    tagDao: ref.watch(tagDaoProvider),
    mediaDao: ref.watch(mediaDaoProvider),
  );
});

/// Bumped whenever a tag changes, so every tag view refreshes together.
///
/// Riverpod has no way to know a database write happened, so the writes go
/// through [TagEditController] and it turns this dial. Anything that shows
/// tags watches it.
final tagRevisionProvider = StateProvider<int>((ref) => 0);

/// Every tag, ordered by name.
final allTagsProvider = FutureProvider<List<Tag>>((ref) async {
  ref.watch(tagRevisionProvider);
  return ref.watch(tagRepositoryProvider).getAllTags();
});

/// The tags on one media item.
final tagsForMediaProvider = FutureProvider.family<List<Tag>, String>((
  ref,
  mediaId,
) async {
  ref.watch(tagRevisionProvider);
  return ref.watch(tagRepositoryProvider).getTagsForMedia(mediaId);
});

/// Which tags are ticked in a filter, and how they combine.
class TagFilterSelection {
  /// Ids of the ticked tags.
  final Set<String> tagIds;

  /// Whether a photo must carry every ticked tag, or just one of them.
  final TagFilterMode mode;

  const TagFilterSelection({
    this.tagIds = const <String>{},
    this.mode = TagFilterMode.andMode,
  });

  bool get isEmpty => tagIds.isEmpty;

  TagFilterSelection copyWith({Set<String>? tagIds, TagFilterMode? mode}) {
    return TagFilterSelection(
      tagIds: tagIds ?? this.tagIds,
      mode: mode ?? this.mode,
    );
  }
}

/// Holds the tag chips the user has ticked on the search screen.
class TagFilterNotifier extends StateNotifier<TagFilterSelection> {
  TagFilterNotifier() : super(const TagFilterSelection());

  /// Ticks a tag on or off.
  void toggle(String tagId) {
    final next = <String>{...state.tagIds};
    if (!next.remove(tagId)) next.add(tagId);
    state = state.copyWith(tagIds: next);
  }

  /// Switches between "must have all of these" and "may have any of these".
  void setMode(TagFilterMode mode) => state = state.copyWith(mode: mode);

  /// Ticks exactly one tag, used when opening search from the tag list.
  void selectOnly(String tagId) {
    state = state.copyWith(tagIds: <String>{tagId});
  }

  /// Unticks everything.
  void clear() => state = state.copyWith(tagIds: const <String>{});
}

/// The ticked tag chips on the search screen.
final tagFilterProvider =
    StateNotifierProvider<TagFilterNotifier, TagFilterSelection>((ref) {
      return TagFilterNotifier();
    });

/// Makes, renames, recolours, and deletes tags on behalf of the UI.
///
/// The state is an [AsyncValue] with nothing in it: it carries whether a
/// change is in flight and whether the last one failed, which is all a dialog
/// needs to disable its button and show a message.
class TagEditController extends StateNotifier<AsyncValue<void>> {
  final TagRepository _repository;
  final Ref _ref;

  TagEditController({required TagRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(const AsyncValue<void>.data(null));

  /// Makes a tag. Returns it, or null when the name was refused.
  Future<Tag?> create(String name, {int? colorValue}) {
    return _run(() => _repository.createTag(name, colorValue: colorValue));
  }

  /// Renames a tag. Returns it, or null when the name was refused.
  Future<Tag?> rename(String tagId, String name) {
    return _run(() => _repository.renameTag(tagId, name));
  }

  /// Changes a tag's colour.
  Future<Tag?> setColor(String tagId, int colorValue) {
    return _run(() => _repository.setTagColor(tagId, colorValue));
  }

  /// Deletes a tag and takes it off every photo.
  Future<void> delete(String tagId) async {
    await _run(() async {
      await _repository.deleteTag(tagId);
      return null;
    });
  }

  /// Replaces the whole tag set of one photo.
  Future<void> setTagsForMedia(String mediaId, Set<String> tagIds) async {
    await _run(() async {
      await _repository.setTagsForMedia(mediaId, tagIds);
      return null;
    });
  }

  /// Finds a tag by name, or makes it when it is not there yet.
  ///
  /// What the "new tag" row needs: typing a name that already exists should
  /// tick the existing tag rather than fail on the unique-name rule.
  Future<Tag?> findOrCreate(String name) {
    return _run(() => _repository.findOrCreateTag(name));
  }

  /// Runs a change, records the outcome, and refreshes every tag view.
  Future<T?> _run<T>(Future<T?> Function() action) async {
    state = const AsyncValue<void>.loading();
    try {
      final result = await action();
      state = const AsyncValue<void>.data(null);
      _ref.read(tagRevisionProvider.notifier).state++;
      return result;
    } catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return null;
    }
  }
}

/// Tag changes, driven by the tag screen and the tag sheet.
final tagEditControllerProvider =
    StateNotifierProvider<TagEditController, AsyncValue<void>>((ref) {
      return TagEditController(
        repository: ref.watch(tagRepositoryProvider),
        ref: ref,
      );
    });
