import 'package:in_sreerajp_imgvidgal/core/domain/sync/sync_selection_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_source.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_sources.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/sync_mark_repository.dart';

// The UI reads this type from models, never from a service (G46).
export 'package:in_sreerajp_imgvidgal/models/sync/sync_sources.dart';

/// Gathers the folders and albums a sender can pick from.
///
/// Files in the trash, the vault, or out of the app's reach are never
/// offered: the album and folder reads already leave them out.
class SyncSourceService {
  final AlbumRepository _albums;
  final SyncMarkRepository _marks;

  SyncSourceService({
    required AlbumRepository albums,
    required SyncMarkRepository marks,
  }) : _albums = albums,
       _marks = marks;

  /// The sources, with how many files of each went to [peerId] already.
  ///
  /// [selection] is what the user picked before opening Transfer; it is
  /// listed first when not empty.
  ///
  /// When [selectionOnly] is true (a quick send), only [selection] is
  /// offered: the user came to send those photos, not to pick folders.
  Future<SyncSources> load({
    required String peerId,
    List<MediaItem> selection = const <MediaItem>[],
    bool selectionOnly = false,
  }) async {
    final marks = await _marks.marksForPeer(peerId);
    final sources = <SyncSource>[];

    if (selection.isNotEmpty) {
      sources.add(
        _source(
          key: 'selection',
          kind: SyncSourceKind.selection,
          name: '',
          items: selection,
          marks: marks,
        ),
      );
    }

    if (selectionOnly) {
      return SyncSources(sources: sources, marks: marks);
    }

    for (final folder in await _albums.getFolderAlbums()) {
      final path = folder.folderPath;
      if (path == null || path.isEmpty) continue;
      final items = List<MediaItem>.from(await _albums.getFolderMedia(path))
        ..sort(_oldestFirst);
      if (items.isEmpty) continue;
      sources.add(
        _source(
          key: 'folder:$path',
          kind: SyncSourceKind.folder,
          name: folder.name,
          items: items,
          marks: marks,
        ),
      );
    }

    for (final album in await _albums.getVirtualAlbums()) {
      final items = await _albums.getAlbumMedia(album.id);
      if (items.isEmpty) continue;
      sources.add(
        _source(
          key: 'album:${album.id}',
          kind: SyncSourceKind.album,
          name: album.name,
          items: items,
          marks: marks,
        ),
      );
    }

    return SyncSources(sources: sources, marks: marks);
  }

  static SyncSource _source({
    required String key,
    required SyncSourceKind kind,
    required String name,
    required List<MediaItem> items,
    required Map<String, SyncMark> marks,
  }) {
    return SyncSource(
      key: key,
      kind: kind,
      name: name,
      items: List<MediaItem>.unmodifiable(items),
      sentCount: SyncSelectionRules.countSent(items, marks),
    );
  }

  /// Oldest first, so each "send the rest" carries on in the same order.
  static int _oldestFirst(MediaItem a, MediaItem b) {
    final at = a.dateTaken ?? a.dateAdded;
    final bt = b.dateTaken ?? b.dateAdded;
    final byDate = at.compareTo(bt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }
}
