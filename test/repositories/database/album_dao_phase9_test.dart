import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Covers the album ordering, cover, pinning, and membership work added in
/// Phase 9, against a real in-memory database rather than a stand-in.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late AlbumDao albumDao;
  late MediaDao mediaDao;

  final now = DateTime(2026, 8, 30, 10);

  Album album(String id, String name) => Album(
    id: id,
    name: name,
    albumType: AlbumType.virtualAlbum,
    dateCreated: now,
    dateModified: now,
  );

  MediaItem media(String id, {String? path}) => MediaItem(
    id: id,
    path: path ?? '/storage/DCIM/Camera/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 1000,
    dateAdded: now,
    dateModified: now,
  );

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    albumDao = AlbumDao(dbHelper: dbHelper);
    mediaDao = MediaDao(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('addMediaToAlbum', () {
    test('appends each item instead of tying them all at zero', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      for (final id in <String>['m1', 'm2', 'm3']) {
        await mediaDao.insertMediaItem(media(id));
        await albumDao.addMediaToAlbum('a1', id);
      }

      expect(await albumDao.getMediaIdsForAlbum('a1'), <String>[
        'm1',
        'm2',
        'm3',
      ]);
    });

    test('still honours an explicit position', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await mediaDao.insertMediaItem(media('m1'));
      await mediaDao.insertMediaItem(media('m2'));

      await albumDao.addMediaToAlbum('a1', 'm1');
      await albumDao.addMediaToAlbum('a1', 'm2', position: -1);

      expect(await albumDao.getMediaIdsForAlbum('a1'), <String>['m2', 'm1']);
    });

    test('keeps the stored item count right', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await mediaDao.insertMediaItem(media('m1'));
      await mediaDao.insertMediaItem(media('m2'));

      await albumDao.addMediaToAlbum('a1', 'm1');
      await albumDao.addMediaToAlbum('a1', 'm2');
      expect((await albumDao.getAlbumById('a1'))!.itemCount, 2);

      await albumDao.removeMediaFromAlbum('a1', 'm1');
      expect((await albumDao.getAlbumById('a1'))!.itemCount, 1);
    });

    test('adding the same item twice does not double the count', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await mediaDao.insertMediaItem(media('m1'));

      await albumDao.addMediaToAlbum('a1', 'm1');
      await albumDao.addMediaToAlbum('a1', 'm1');

      expect((await albumDao.getAlbumById('a1'))!.itemCount, 1);
    });
  });

  group('addMediaToAlbums', () {
    test('puts one item into several albums at once', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await albumDao.insertAlbum(album('a2', 'Work'));
      await mediaDao.insertMediaItem(media('m1'));

      await albumDao.addMediaToAlbums('m1', <String>['a1', 'a2']);

      expect(
        await albumDao.getAlbumIdsForMedia('m1'),
        containsAll(<String>['a1', 'a2']),
      );
      expect((await albumDao.getAlbumById('a1'))!.itemCount, 1);
      expect((await albumDao.getAlbumById('a2'))!.itemCount, 1);
    });

    test('does nothing when given no albums', () async {
      await mediaDao.insertMediaItem(media('m1'));
      await albumDao.addMediaToAlbums('m1', const <String>[]);
      expect(await albumDao.getAlbumIdsForMedia('m1'), isEmpty);
    });
  });

  group('setMediaOrder', () {
    test('writes a whole new order', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      for (final id in <String>['m1', 'm2', 'm3']) {
        await mediaDao.insertMediaItem(media(id));
        await albumDao.addMediaToAlbum('a1', id);
      }

      await albumDao.setMediaOrder('a1', <String>['m3', 'm1', 'm2']);

      expect(await albumDao.getMediaIdsForAlbum('a1'), <String>[
        'm3',
        'm1',
        'm2',
      ]);
    });

    test('the media query returns the album order too', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      for (final id in <String>['m1', 'm2', 'm3']) {
        await mediaDao.insertMediaItem(media(id));
        await albumDao.addMediaToAlbum('a1', id);
      }
      await albumDao.setMediaOrder('a1', <String>['m2', 'm3', 'm1']);

      final ids = await albumDao.getMediaIdsForAlbum('a1');
      final items = await mediaDao.getMediaItemsByIds(ids);
      expect(items.map((i) => i.id).toList(), <String>['m2', 'm3', 'm1']);
    });
  });

  group('setCover and setPinned', () {
    test('stores the chosen cover and its path', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await albumDao.setCover('a1', 'm1', coverPath: '/x/m1.jpg');

      final stored = await albumDao.getAlbumById('a1');
      expect(stored!.coverMediaId, 'm1');
      expect(stored.coverPath, '/x/m1.jpg');
    });

    test('clears the cover again', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await albumDao.setCover('a1', 'm1', coverPath: '/x/m1.jpg');
      await albumDao.setCover('a1', null);

      final stored = await albumDao.getAlbumById('a1');
      expect(stored!.coverMediaId, isNull);
      expect(stored.coverPath, isNull);
    });

    test('pins and unpins', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));

      await albumDao.setPinned('a1', true);
      expect((await albumDao.getAlbumById('a1'))!.isPinned, isTrue);

      await albumDao.setPinned('a1', false);
      expect((await albumDao.getAlbumById('a1'))!.isPinned, isFalse);
    });
  });

  group('getAlbumsByType', () {
    test('returns only albums of that kind, pinned first', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await albumDao.insertAlbum(album('a2', 'Work').copyWith(isPinned: true));
      await albumDao.insertAlbum(
        Album(
          id: 'f1',
          name: 'Camera',
          albumType: AlbumType.physicalFolder,
          dateCreated: now,
          dateModified: now,
        ),
      );

      final virtual = await albumDao.getAlbumsByType(AlbumType.virtualAlbum);
      expect(virtual.map((a) => a.id).toList(), <String>['a2', 'a1']);
    });

    test('returns nothing when no album has that kind', () async {
      expect(await albumDao.getAlbumsByType(AlbumType.smartPanoramas), isEmpty);
    });
  });

  group('getAlbumIdsForMedia', () {
    test('drops the album when the item is removed from it', () async {
      await albumDao.insertAlbum(album('a1', 'Holiday'));
      await mediaDao.insertMediaItem(media('m1'));

      await albumDao.addMediaToAlbum('a1', 'm1');
      expect(await albumDao.getAlbumIdsForMedia('m1'), <String>['a1']);

      await albumDao.removeMediaFromAlbum('a1', 'm1');
      expect(await albumDao.getAlbumIdsForMedia('m1'), isEmpty);
    });
  });
}
