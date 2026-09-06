import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';

/// Data access object over the album tables.
final albumDaoProvider = Provider<AlbumDao>((ref) => AlbumDao());

/// The only way the app reads or changes albums.
final albumRepositoryProvider = Provider<AlbumRepository>((ref) {
  return AlbumRepository(
    albumDao: ref.watch(albumDaoProvider),
    mediaDao: ref.watch(mediaDaoProvider),
  );
});

/// Bumped whenever an album changes, so every album view refreshes together.
///
/// Riverpod cannot know a database write happened, so the writes go through
/// [AlbumEditController] and it turns this dial. Anything showing albums
/// watches it. The same approach as `tagRevisionProvider`.
final albumRevisionProvider = StateProvider<int>((ref) => 0);

/// The filter the album screens apply on top of whatever album is open.
final albumFilterProvider = StateProvider<FilterOptions>((ref) {
  return const FilterOptions();
});

/// Every user-made album, as grid rows with covers resolved.
final virtualAlbumsProvider = FutureProvider<List<AlbumSummary>>((ref) async {
  ref.watch(albumRevisionProvider);
  ref.watch(mediaScanControllerProvider);
  return ref.watch(albumRepositoryProvider).getVirtualAlbumSummaries();
});

/// Every device folder holding at least one indexed item.
final deviceFolderAlbumsProvider = FutureProvider<List<AlbumSummary>>((
  ref,
) async {
  // A scan is what changes the folder list, so this refreshes with one.
  ref.watch(mediaScanControllerProvider);
  return ref.watch(albumRepositoryProvider).getFolderAlbums();
});

/// The six smart albums, with their current counts.
final smartAlbumsProvider = FutureProvider<List<AlbumSummary>>((ref) async {
  ref.watch(mediaScanControllerProvider);
  ref.watch(albumRevisionProvider);
  return ref.watch(albumRepositoryProvider).getSmartAlbums();
});

/// One user-made album as a grid row, or null when it is gone.
final albumSummaryProvider = FutureProvider.family<AlbumSummary?, String>((
  ref,
  albumId,
) async {
  ref.watch(albumRevisionProvider);
  return ref.watch(albumRepositoryProvider).getVirtualAlbumSummary(albumId);
});

/// The items in one user-made album, in album order.
final albumMediaProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  albumId,
) async {
  ref.watch(albumRevisionProvider);
  ref.watch(mediaScanControllerProvider);
  return ref.watch(albumRepositoryProvider).getAlbumMedia(albumId);
});

/// The items in one device folder, with the album filter applied.
final folderMediaProvider = FutureProvider.family<List<MediaItem>, String>((
  ref,
  directory,
) async {
  ref.watch(mediaScanControllerProvider);
  return ref
      .watch(albumRepositoryProvider)
      .getFolderMedia(directory, filter: ref.watch(albumFilterProvider));
});

/// The items in one smart album, with the album filter applied.
///
/// Returns null when the route key names no smart album, so a stale link shows
/// a "not found" state instead of crashing.
final smartAlbumMediaProvider = FutureProvider.family<List<MediaItem>?, String>(
  (ref, key) async {
    ref.watch(mediaScanControllerProvider);
    ref.watch(albumRevisionProvider);
    return ref
        .watch(albumRepositoryProvider)
        .getSmartAlbumMediaByKey(key, filter: ref.watch(albumFilterProvider));
  },
);

/// The ids of every album one item belongs to.
final albumsForMediaProvider = FutureProvider.family<List<String>, String>((
  ref,
  mediaId,
) async {
  ref.watch(albumRevisionProvider);
  return ref.watch(albumRepositoryProvider).getAlbumIdsForMedia(mediaId);
});

/// The order of one album's items, as ids, for the reorder screen.
final albumMediaIdsProvider = FutureProvider.family<List<String>, String>((
  ref,
  albumId,
) async {
  ref.watch(albumRevisionProvider);
  return ref.watch(albumRepositoryProvider).getAlbumMediaIds(albumId);
});

/// Makes, renames, deletes, and rearranges albums on behalf of the UI.
///
/// The state is an [AsyncValue] with nothing in it: it carries whether a change
/// is in flight and whether the last one failed, which is all a dialog needs to
/// disable its button and show a message.
class AlbumEditController extends StateNotifier<AsyncValue<void>> {
  final AlbumRepository _repository;
  final Ref _ref;

  AlbumEditController({required AlbumRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(const AsyncValue<void>.data(null));

  /// Makes an album. Returns it, or null when the name was refused.
  Future<Album?> create(String name) {
    return _run(() => _repository.createAlbum(name));
  }

  /// Renames an album. Returns it, or null when the name was refused.
  Future<Album?> rename(String albumId, String name) {
    return _run(() => _repository.renameAlbum(albumId, name));
  }

  /// Deletes an album. No media file is touched.
  Future<void> delete(String albumId) async {
    await _run(() async {
      await _repository.deleteAlbum(albumId);
      return null;
    });
  }

  /// Adds one item to an album, at the end.
  Future<void> addMedia(String albumId, String mediaId) async {
    await _run(() async {
      await _repository.addMedia(albumId, mediaId);
      return null;
    });
  }

  /// Takes one item out of an album.
  Future<void> removeMedia(String albumId, String mediaId) async {
    await _run(() async {
      await _repository.removeMedia(albumId, mediaId);
      return null;
    });
  }

  /// Replaces the whole set of albums one item belongs to.
  Future<void> setAlbumsForMedia(String mediaId, Set<String> albumIds) async {
    await _run(() async {
      await _repository.setAlbumsForMedia(mediaId, albumIds);
      return null;
    });
  }

  /// Writes a whole new order for one album's items.
  Future<void> setOrder(String albumId, List<String> orderedIds) async {
    await _run(() async {
      await _repository.setAlbumOrder(albumId, orderedIds);
      return null;
    });
  }

  /// Chooses the album's cover, or clears the choice.
  Future<void> setCover(String albumId, String? mediaId) async {
    await _run(() async {
      await _repository.setAlbumCover(albumId, mediaId);
      return null;
    });
  }

  /// Pins an album to the top of the grid, or unpins it.
  Future<void> setPinned(String albumId, bool isPinned) async {
    await _run(() async {
      await _repository.setAlbumPinned(albumId, isPinned);
      return null;
    });
  }

  /// Runs a change, records the outcome, and refreshes every album view.
  Future<T?> _run<T>(Future<T?> Function() action) async {
    state = const AsyncValue<void>.loading();
    try {
      final result = await action();
      state = const AsyncValue<void>.data(null);
      _ref.read(albumRevisionProvider.notifier).state++;
      return result;
    } catch (e, st) {
      state = AsyncValue<void>.error(e, st);
      return null;
    }
  }
}

/// Album changes, driven by the album screens and the picker sheet.
final albumEditControllerProvider =
    StateNotifierProvider<AlbumEditController, AsyncValue<void>>((ref) {
      return AlbumEditController(
        repository: ref.watch(albumRepositoryProvider),
        ref: ref,
      );
    });
