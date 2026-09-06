import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/smart_album.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/album_name_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/folder_path_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/smart_album_service.dart';

/// Thrown when an album name breaks one of the rules.
///
/// Carries the reason so the UI can show the right message rather than
/// guessing from the text. Mirrors `TagValidationException`.
class AlbumValidationException implements Exception {
  final AlbumNameError reason;
  final String message;

  const AlbumValidationException(this.reason, this.message);

  @override
  String toString() => 'AlbumValidationException: $message';
}

/// The only way the app reads or changes albums.
///
/// Three quite different things arrive here as one kind of answer. A virtual
/// album is a stored row with stored membership; a device folder is worked out
/// from file paths at read time; a smart album is only a rule. Turning all
/// three into [AlbumSummary] here is what lets the albums screen draw them side
/// by side without knowing any of that.
///
/// Nothing in this class touches the file system. Adding a photo to an album
/// writes one row and moves no bytes, which is what makes a virtual album safe
/// by construction.
class AlbumRepository {
  final AlbumDao _albumDao;
  final MediaDao _mediaDao;

  AlbumRepository({AlbumDao? albumDao, MediaDao? mediaDao})
    : _albumDao = albumDao ?? AlbumDao(),
      _mediaDao = mediaDao ?? MediaDao();

  // ---------------------------------------------------------------- virtual

  /// Every user-made album, pinned ones first.
  Future<List<Album>> getVirtualAlbums() {
    return _albumDao.getAlbumsByType(AlbumType.virtualAlbum);
  }

  /// Every user-made album as a grid row, with its cover resolved.
  Future<List<AlbumSummary>> getVirtualAlbumSummaries() async {
    final albums = await getVirtualAlbums();
    final summaries = <AlbumSummary>[];
    for (final album in albums) {
      summaries.add(
        AlbumSummary(
          id: album.id,
          name: album.name,
          albumType: AlbumType.virtualAlbum,
          itemCount: album.itemCount,
          coverItem: await _resolveCover(album),
        ),
      );
    }
    return summaries;
  }

  /// One album as a grid row, or null when it is no longer there.
  Future<AlbumSummary?> getVirtualAlbumSummary(String albumId) async {
    final album = await _albumDao.getAlbumById(albumId);
    if (album == null) return null;
    return AlbumSummary(
      id: album.id,
      name: album.name,
      albumType: album.albumType,
      itemCount: album.itemCount,
      coverItem: await _resolveCover(album),
    );
  }

  /// The items in one album, in album order.
  Future<List<MediaItem>> getAlbumMedia(String albumId) async {
    final ids = await _albumDao.getMediaIdsForAlbum(albumId);
    return _mediaDao.getMediaItemsByIds(ids);
  }

  /// Makes a new album and returns it.
  ///
  /// Throws [AlbumValidationException] when the name is not allowed.
  Future<Album> createAlbum(String name, {DateTime? now}) async {
    final existing = await getVirtualAlbums();
    final check = AlbumNameRules.check(
      name,
      existingNames: existing.map((a) => a.name),
    );
    _throwIfInvalid(check);

    final stamp = now ?? DateTime.now();
    final album = Album(
      id: _newId(check.normalized),
      name: check.normalized,
      albumType: AlbumType.virtualAlbum,
      dateCreated: stamp,
      dateModified: stamp,
    );
    await _albumDao.insertAlbum(album);
    return album;
  }

  /// Renames an album.
  ///
  /// Throws [AlbumValidationException] when the new name is empty, too long, or
  /// already taken by a different album.
  Future<Album> renameAlbum(String albumId, String name) async {
    final album = await _requireAlbum(albumId);
    final existing = await getVirtualAlbums();
    final check = AlbumNameRules.check(
      name,
      existingNames: existing.map((a) => a.name),
      ignoreName: album.name,
    );
    _throwIfInvalid(check);

    final updated = album.copyWith(
      name: check.normalized,
      dateModified: DateTime.now(),
    );
    await _albumDao.updateAlbum(updated);
    return updated;
  }

  /// Deletes an album.
  ///
  /// Only the album row and its membership rows go. Every photo stays exactly
  /// where it was on the device: a virtual album never owned the files.
  Future<void> deleteAlbum(String albumId) {
    return _albumDao.deleteAlbum(albumId);
  }

  /// Adds one item to an album, at the end.
  Future<void> addMedia(String albumId, String mediaId) {
    return _albumDao.addMediaToAlbum(albumId, mediaId);
  }

  /// Adds one item to several albums at once.
  Future<void> addMediaToAlbums(String mediaId, Iterable<String> albumIds) {
    return _albumDao.addMediaToAlbums(mediaId, albumIds);
  }

  /// Takes one item out of an album.
  Future<void> removeMedia(String albumId, String mediaId) {
    return _albumDao.removeMediaFromAlbum(albumId, mediaId);
  }

  /// Replaces the whole set of albums one item belongs to.
  ///
  /// What the "add to album" sheet needs: the user ticks and unticks, and the
  /// result is applied as a difference so nothing already correct is rewritten.
  Future<void> setAlbumsForMedia(String mediaId, Set<String> albumIds) async {
    final current = (await _albumDao.getAlbumIdsForMedia(mediaId)).toSet();

    final toAdd = albumIds.difference(current);
    if (toAdd.isNotEmpty) {
      await _albumDao.addMediaToAlbums(mediaId, toAdd);
    }
    for (final albumId in current.difference(albumIds)) {
      await _albumDao.removeMediaFromAlbum(albumId, mediaId);
    }
  }

  /// The ids of every album one item is in.
  Future<List<String>> getAlbumIdsForMedia(String mediaId) {
    return _albumDao.getAlbumIdsForMedia(mediaId);
  }

  /// The order of one album's items, as ids.
  Future<List<String>> getAlbumMediaIds(String albumId) {
    return _albumDao.getMediaIdsForAlbum(albumId);
  }

  /// Writes a whole new order for one album's items.
  Future<void> setAlbumOrder(String albumId, List<String> orderedIds) {
    return _albumDao.setMediaOrder(albumId, orderedIds);
  }

  /// Chooses the item whose thumbnail covers the album, or clears the choice.
  Future<void> setAlbumCover(String albumId, String? mediaId) async {
    if (mediaId == null) {
      await _albumDao.setCover(albumId, null);
      return;
    }
    final item = await _mediaDao.getMediaItemById(mediaId);
    await _albumDao.setCover(albumId, mediaId, coverPath: item?.path);
  }

  /// Pins an album to the top of the grid, or unpins it.
  Future<void> setAlbumPinned(String albumId, bool isPinned) {
    return _albumDao.setPinned(albumId, isPinned);
  }

  // ----------------------------------------------------------------- folders

  /// Every device folder that holds at least one indexed item.
  ///
  /// Derived from the file paths each time rather than stored, so a folder list
  /// cannot drift away from what the last scan actually found.
  Future<List<AlbumSummary>> getFolderAlbums() async {
    final rows = await _mediaDao.getFolderSummaries();

    final coverIds = <String>[
      for (final row in rows)
        if (row.coverMediaId != null) row.coverMediaId!,
    ];
    final covers = <String, MediaItem>{
      for (final item in await _mediaDao.getMediaItemsByIds(coverIds))
        item.id: item,
    };

    return <AlbumSummary>[
      for (final row in rows)
        AlbumSummary(
          id: row.directory,
          name: FolderPathRules.displayName(row.directory),
          albumType: AlbumType.physicalFolder,
          folderPath: row.directory,
          itemCount: row.itemCount,
          coverItem: covers[row.coverMediaId],
        ),
    ];
  }

  /// The items sitting directly in one device folder.
  Future<List<MediaItem>> getFolderMedia(
    String directory, {
    FilterOptions filter = const FilterOptions(),
  }) {
    return _mediaDao.getMediaItems(
      filter: filter.copyWith(folderPaths: <String>{directory}),
    );
  }

  // ------------------------------------------------------------------ smart

  /// Every smart album as a grid row.
  ///
  /// The name is left as the route key on purpose: only the screen can
  /// translate a smart album's name, and this layer must not reach into the UI.
  Future<List<AlbumSummary>> getSmartAlbums({DateTime? now}) async {
    final summaries = <AlbumSummary>[];
    for (final album in SmartAlbumService.all()) {
      final items = await getSmartAlbumMedia(album, now: now);
      summaries.add(
        AlbumSummary(
          id: album.key,
          name: album.key,
          albumType: album.albumType,
          itemCount: items.length,
          coverItem: items.isEmpty ? null : items.first,
        ),
      );
    }
    return summaries;
  }

  /// The items in one smart album.
  ///
  /// Two of the six rules — panoramas and recently added — are not plain column
  /// tests, so the database narrows as far as it can and the rest is decided
  /// here.
  Future<List<MediaItem>> getSmartAlbumMedia(
    SmartAlbum album, {
    FilterOptions? filter,
    DateTime? now,
  }) async {
    final items = await _mediaDao.getMediaItems(
      filter: _mergeFilters(album.filter, filter),
    );
    if (!album.needsPostFilter) return items;

    return items
        .where((item) => SmartAlbumService.matches(album, item, now: now))
        .toList(growable: false);
  }

  /// The items in the smart album a route key names, or null when the key is
  /// not one of ours.
  Future<List<MediaItem>?> getSmartAlbumMediaByKey(
    String key, {
    FilterOptions? filter,
    DateTime? now,
  }) async {
    final album = SmartAlbumService.fromKey(key);
    if (album == null) return null;
    return getSmartAlbumMedia(album, filter: filter, now: now);
  }

  // ----------------------------------------------------------------- helpers

  /// Lays the user's filter sheet over a smart album's own rule.
  ///
  /// The album's rule wins where the two overlap. Letting the sheet widen
  /// "Videos" back to every media type would leave the user in an album that
  /// no longer matches its name.
  FilterOptions _mergeFilters(FilterOptions base, FilterOptions? extra) {
    if (extra == null) return base;
    return extra.copyWith(
      mediaTypes: base.mediaTypes.isNotEmpty
          ? base.mediaTypes
          : extra.mediaTypes,
      isFavoriteOnly: base.isFavoriteOnly ?? extra.isFavoriteOnly,
      isTrash: base.isTrash || extra.isTrash,
      folderPaths: base.folderPaths.isNotEmpty
          ? base.folderPaths
          : extra.folderPaths,
      sortBy: extra.sortBy,
      sortDirection: extra.sortDirection,
    );
  }

  /// The item drawn as an album's cover.
  ///
  /// The user's chosen cover comes first; when there is none, or the chosen one
  /// has since been removed from the album, the newest member stands in. That
  /// fallback is what keeps a cover from silently going blank.
  Future<MediaItem?> _resolveCover(Album album) async {
    final chosen = album.coverMediaId;
    if (chosen != null) {
      final item = await _mediaDao.getMediaItemById(chosen);
      if (item != null) return item;
    }

    final ids = await _albumDao.getMediaIdsForAlbum(album.id);
    if (ids.isEmpty) return null;
    final items = await _mediaDao.getMediaItemsByIds(ids);
    return items.isEmpty ? null : items.first;
  }

  Future<Album> _requireAlbum(String albumId) async {
    final album = await _albumDao.getAlbumById(albumId);
    if (album == null) {
      throw StorageException('Album $albumId no longer exists');
    }
    return album;
  }

  void _throwIfInvalid(AlbumNameCheck check) {
    final error = check.error;
    if (error == null) return;
    throw AlbumValidationException(error, switch (error) {
      AlbumNameError.empty => 'An album needs a name',
      AlbumNameError.tooLong =>
        'An album name may be at most ${AlbumNameRules.maxLength} characters',
      AlbumNameError.duplicate =>
        'An album called "${check.normalized}" exists',
    });
  }

  /// A unique id for a new album.
  ///
  /// The album table takes a text primary key and the app has no UUID package,
  /// so the id is the timestamp plus the name's own hash. Both parts are
  /// needed: the timestamp keeps two albums made in the same session apart, and
  /// the name keeps two made in the same microsecond apart.
  String _newId(String normalizedName) {
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final suffix = normalizedName
        .toLowerCase()
        .hashCode
        .toUnsigned(32)
        .toRadixString(36);
    return 'album_${stamp}_$suffix';
  }
}
