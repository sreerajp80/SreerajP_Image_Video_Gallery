import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
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

    final now = DateTime(2026, 8, 29, 10);

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

    test('getMediaForAlbum leaves out an item the app may not see', () async {
      await albumDao.insertAlbum(testAlbum);
      await mediaDao.insertMediaItem(testMedia);
      await albumDao.addMediaToAlbum(testAlbum.id, testMedia.id);

      await mediaDao.markOutOfReachExcept(<String>{});

      expect(await albumDao.getMediaForAlbum(testAlbum.id), isEmpty);
      expect(await albumDao.getMediaIdsForAlbum(testAlbum.id), <String>[
        testMedia.id,
      ]);
    });

    test('item count counts only members the user can see', () async {
      MediaItem member(String id) => testMedia.copyWith(
        id: id,
        path: '/storage/DCIM/$id.jpg',
        displayName: '$id.jpg',
      );
      await albumDao.insertAlbum(testAlbum);
      await mediaDao.insertMediaItem(member('visible_1'));
      await mediaDao.insertMediaItem(member('visible_2'));
      await mediaDao.insertMediaItem(member('trashed').copyWith(isTrash: true));
      await mediaDao.insertMediaItem(
        member('vaulted').copyWith(isVaulted: true),
      );
      await mediaDao.insertMediaItem(
        member('hidden').copyWith(isOutOfReach: true),
      );
      for (final id in ['visible_1', 'visible_2', 'trashed', 'vaulted']) {
        await albumDao.addMediaToAlbum(testAlbum.id, id);
      }
      await albumDao.addMediaToAlbum(testAlbum.id, 'hidden');

      final byId = await albumDao.getAlbumById(testAlbum.id);
      expect(byId!.itemCount, 2);
      final all = await albumDao.getAllAlbums();
      expect(all.single.itemCount, 2);
      final byType = await albumDao.getAlbumsByType(AlbumType.virtualAlbum);
      expect(byType.single.itemCount, 2);
      expect(
        (await albumDao.getMediaForAlbum(testAlbum.id)).length,
        byId.itemCount,
      );
    });

    test('item count drops when a member is hidden later', () async {
      await albumDao.insertAlbum(testAlbum);
      await mediaDao.insertMediaItem(testMedia);
      await albumDao.addMediaToAlbum(testAlbum.id, testMedia.id);
      expect((await albumDao.getAlbumById(testAlbum.id))!.itemCount, 1);

      // A scan with limited access hides the photo; nothing recounts.
      await mediaDao.markOutOfReachExcept(<String>{});

      expect((await albumDao.getAlbumById(testAlbum.id))!.itemCount, 0);
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

    group('saved item_count (schema 8 triggers)', () {
      /// Reads the raw column. The DAO read swaps in a live count, which
      /// would hide a wrong saved number.
      Future<int> savedCount() async {
        final db = await dbHelper.database;
        final rows = await db.query(
          DatabaseConstants.tableAlbums,
          columns: [DatabaseConstants.colAlbumItemCount],
          where: '${DatabaseConstants.colId} = ?',
          whereArgs: [testAlbum.id],
        );
        return rows.single[DatabaseConstants.colAlbumItemCount]! as int;
      }

      MediaItem member(String id) => testMedia.copyWith(
        id: id,
        path: '/storage/DCIM/$id.jpg',
        displayName: '$id.jpg',
      );

      setUp(() async {
        await albumDao.insertAlbum(testAlbum);
        for (final id in ['a', 'b']) {
          await mediaDao.insertMediaItem(member(id));
          await albumDao.addMediaToAlbum(testAlbum.id, id);
        }
      });

      test('follows adding and removing members', () async {
        expect(await savedCount(), 2);
        await albumDao.removeMediaFromAlbum(testAlbum.id, 'a');
        expect(await savedCount(), 1);
      });

      test('leaves out members added while hidden', () async {
        await mediaDao.insertMediaItem(member('t').copyWith(isTrash: true));
        await albumDao.addMediaToAlbum(testAlbum.id, 't');
        expect(await savedCount(), 2);
      });

      test('follows trash and restore', () async {
        await mediaDao.updateTrash('a', true);
        expect(await savedCount(), 1);
        await mediaDao.updateTrash('a', false);
        expect(await savedCount(), 2);
      });

      test('follows the vault', () async {
        await mediaDao.updateVaulted('b', true);
        expect(await savedCount(), 1);
        await mediaDao.updateVaulted('b', false);
        expect(await savedCount(), 2);
      });

      test('follows limited media access', () async {
        await mediaDao.markOutOfReachExcept(<String>{'a'});
        expect(await savedCount(), 1);
        await mediaDao.clearOutOfReach();
        expect(await savedCount(), 2);
      });

      test('follows a deleted photo through the cascade', () async {
        await mediaDao.deleteMediaItem('a');
        expect(await savedCount(), 1);
      });

      test('a whole-row write with a wrong count is corrected', () async {
        await albumDao.updateAlbum(testAlbum.copyWith(itemCount: 99));
        expect(await savedCount(), 2);
      });
    });
  });
}
