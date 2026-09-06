import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AlbumDao Database Access Object', () {
    late DatabaseHelper dbHelper;
    late AlbumDao albumDao;
    late MediaDao mediaDao;

    final now = DateTime(2026, 8, 29, 10, 0, 0);

    final testMedia = MediaItem(
      id: 'media_100',
      path: '/storage/DCIM/pic.jpg',
      displayName: 'pic.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 50000,
      dateAdded: now,
      dateModified: now,
    );

    final testAlbum = Album(
      id: 'album_100',
      name: 'Favorite Vacations',
      albumType: AlbumType.virtualAlbum,
      dateCreated: now,
      dateModified: now,
      isPinned: true,
      sortOrder: 1,
    );

    setUp(() {
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

    test('inserts, updates, and retrieves album', () async {
      await albumDao.insertAlbum(testAlbum);

      var retrieved = await albumDao.getAlbumById(testAlbum.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Favorite Vacations');
      expect(retrieved.isPinned, isTrue);

      await albumDao.updateAlbum(retrieved.copyWith(name: 'Vacations 2026'));
      retrieved = await albumDao.getAlbumById(testAlbum.id);
      expect(retrieved!.name, 'Vacations 2026');
    });

    test(
      'adds media to virtual album and manages item count and membership',
      () async {
        await mediaDao.insertMediaItem(testMedia);
        await albumDao.insertAlbum(testAlbum);

        await albumDao.addMediaToAlbum(testAlbum.id, testMedia.id);

        final updatedAlbum = await albumDao.getAlbumById(testAlbum.id);
        expect(updatedAlbum!.itemCount, 1);

        final albumMedia = await albumDao.getMediaForAlbum(testAlbum.id);
        expect(albumMedia.length, 1);
        expect(albumMedia.first.id, testMedia.id);

        await albumDao.removeMediaFromAlbum(testAlbum.id, testMedia.id);
        final emptyAlbum = await albumDao.getAlbumById(testAlbum.id);
        expect(emptyAlbum!.itemCount, 0);
      },
    );

    test('deletes album and verifies cascade cleanup', () async {
      await mediaDao.insertMediaItem(testMedia);
      await albumDao.insertAlbum(testAlbum);
      await albumDao.addMediaToAlbum(testAlbum.id, testMedia.id);

      await albumDao.deleteAlbum(testAlbum.id);

      final deleted = await albumDao.getAlbumById(testAlbum.id);
      expect(deleted, isNull);

      final albums = await albumDao.getAllAlbums();
      expect(albums.isEmpty, isTrue);
    });
  });
}
