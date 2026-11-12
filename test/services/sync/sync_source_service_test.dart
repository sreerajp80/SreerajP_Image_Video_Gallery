import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_source.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/sync_mark_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/sync_source_service.dart';

/// Counts reads, and has no folders or albums worth offering.
class _CountingAlbums implements AlbumRepository {
  int reads = 0;

  @override
  Future<List<AlbumSummary>> getFolderAlbums() async {
    reads++;
    return const <AlbumSummary>[];
  }

  @override
  Future<List<Album>> getVirtualAlbums() async {
    reads++;
    return const <Album>[];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

class _NoMarks implements SyncMarkRepository {
  @override
  Future<Map<String, SyncMark>> marksForPeer(String peerId) async =>
      const <String, SyncMark>{};

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected call: ${invocation.memberName}');
}

MediaItem _item(String id) => MediaItem(
  id: id,
  path: '/pictures/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 10,
  dateAdded: DateTime(2026, 11, 2),
  dateModified: DateTime(2026, 11, 2),
);

void main() {
  group('SyncSourceService', () {
    test('a quick send offers the selection only', () async {
      final albums = _CountingAlbums();
      final service = SyncSourceService(albums: albums, marks: _NoMarks());

      final result = await service.load(
        peerId: 'peer-1',
        selection: <MediaItem>[_item('a'), _item('b')],
        selectionOnly: true,
      );

      expect(result.sources, hasLength(1));
      expect(result.sources.single.kind, SyncSourceKind.selection);
      expect(result.sources.single.itemCount, 2);
      expect(albums.reads, 0, reason: 'folders and albums are not read');
    });

    test('a phone move reads folders and albums', () async {
      final albums = _CountingAlbums();
      final service = SyncSourceService(albums: albums, marks: _NoMarks());

      final result = await service.load(peerId: 'peer-1');

      expect(result.sources, isEmpty);
      expect(albums.reads, 2);
    });
  });
}
