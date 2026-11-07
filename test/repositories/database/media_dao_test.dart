import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MediaDao Database Access Object', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;

    final baseDate = DateTime(2026, 8, 29, 10);

    final item1 = MediaItem(
      id: 'm1',
      path: '/storage/DCIM/Camera/IMG_001.jpg',
      displayName: 'IMG_001.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 1024000,
      dateAdded: baseDate,
      dateModified: baseDate,
      dateTaken: baseDate,
      isFavorite: true,
      exifData: const ExifData(make: 'Sony', model: 'A7IV'),
      userNotes: 'Sunset over mountain peaks',
      address: 'Munnar, Kerala',
    );

    final item2 = MediaItem(
      id: 'm2',
      path: '/storage/DCIM/Camera/VID_002.mp4',
      displayName: 'VID_002.mp4',
      mediaType: MediaType.video,
      mimeType: 'video/mp4',
      size: 5048000,
      durationMs: 15000,
      dateAdded: baseDate.add(const Duration(hours: 1)),
      dateModified: baseDate.add(const Duration(hours: 1)),
      dateTaken: baseDate.add(const Duration(hours: 1)),
      userNotes: 'Beach drone footage',
      latitude: 9.9312,
      longitude: 76.2673,
      address: 'Kochi Beach, Kerala',
    );

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('inserts and retrieves media items by ID and Path', () async {
      await mediaDao.insertMediaItem(item1);

      final retrievedById = await mediaDao.getMediaItemById(item1.id);
      expect(retrievedById, isNotNull);
      expect(retrievedById!.displayName, item1.displayName);
      expect(retrievedById.isFavorite, isTrue);
      expect(retrievedById.userNotes, 'Sunset over mountain peaks');
      expect(retrievedById.exifData?.make, 'Sony');

      final retrievedByPath = await mediaDao.getMediaItemByPath(item1.path);
      expect(retrievedByPath, isNotNull);
      expect(retrievedByPath!.id, item1.id);
    });

    test('batch upsert efficiently saves multiple items', () async {
      await mediaDao.batchUpsertMediaItems([item1, item2]);

      final totalCount = await mediaDao.getTotalCount();
      expect(totalCount, 2);
    });

    test('filters media by favorite, type, and GPS', () async {
      await mediaDao.batchUpsertMediaItems([item1, item2]);

      final favOnly = await mediaDao.getMediaItems(
        filter: const FilterOptions(isFavoriteOnly: true),
      );
      expect(favOnly.length, 1);
      expect(favOnly.first.id, 'm1');

      final videosOnly = await mediaDao.getMediaItems(
        filter: const FilterOptions(mediaTypes: {MediaType.video}),
      );
      expect(videosOnly.length, 1);
      expect(videosOnly.first.id, 'm2');

      final gpsOnly = await mediaDao.getMediaItems(
        filter: const FilterOptions(hasGpsOnly: true),
      );
      expect(gpsOnly.length, 1);
      expect(gpsOnly.first.id, 'm2');
    });

    test('updates user notes and favorite states', () async {
      await mediaDao.insertMediaItem(item1);

      await mediaDao.updateFavorite(item1.id, false);
      var updated = await mediaDao.getMediaItemById(item1.id);
      expect(updated!.isFavorite, isFalse);

      await mediaDao.updateUserNotes(item1.id, 'New updated description');
      updated = await mediaDao.getMediaItemById(item1.id);
      expect(updated!.userNotes, 'New updated description');
    });

    test(
      'FTS5 search indexes and locates media items by query keyword',
      () async {
        await mediaDao.batchUpsertMediaItems([item1, item2]);

        final searchResults1 = await mediaDao.searchMediaFts('mountain');
        expect(searchResults1.length, 1);
        expect(searchResults1.first.id, 'm1');

        final searchResults2 = await mediaDao.searchMediaFts('drone');
        expect(searchResults2.length, 1);
        expect(searchResults2.first.id, 'm2');

        final searchResults3 = await mediaDao.searchMediaFts('Kerala');
        expect(searchResults3.length, 2);
      },
    );

    test(
      'trash and vault state transitions hide items from standard queries',
      () async {
        await mediaDao.batchUpsertMediaItems([item1, item2]);

        await mediaDao.updateTrash(item1.id, true);
        var activeItems = await mediaDao.getMediaItems();
        expect(activeItems.length, 1);
        expect(activeItems.first.id, 'm2');

        final trashItems = await mediaDao.getMediaItems(
          filter: const FilterOptions(isTrash: true),
        );
        expect(trashItems.length, 1);
        expect(trashItems.first.id, 'm1');

        await mediaDao.updateVaulted(item2.id, true);
        activeItems = await mediaDao.getMediaItems();
        expect(activeItems.isEmpty, isTrue);
      },
    );

    test(
      'bulk trash operations: restoreAll, deleteAll, and getTrashCount',
      () async {
        await mediaDao.batchUpsertMediaItems([item1, item2]);

        expect(await mediaDao.getTrashCount(), 0);

        await mediaDao.updateTrash(item1.id, true);
        await mediaDao.updateTrash(item2.id, true);
        expect(await mediaDao.getTrashCount(), 2);

        // Restore all
        final restored = await mediaDao.restoreAllFromTrash();
        expect(restored, 2);
        expect(await mediaDao.getTrashCount(), 0);

        // Trash again and empty
        await mediaDao.updateTrash(item1.id, true);
        expect(await mediaDao.getTrashCount(), 1);

        final deleted = await mediaDao.deleteAllTrashed();
        expect(deleted, 1);
        expect(await mediaDao.getTrashCount(), 0);

        // Verify item2 is still in DB, item1 is removed from DB
        final remaining = await mediaDao.getMediaItems();
        expect(remaining.length, 1);
        expect(remaining.first.id, 'm2');
      },
    );
  });

  group('MediaDao.batchUpsertMediaItems on a rescan', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late Database db;

    final scanned = MediaItem(
      id: 'r1',
      path: '/storage/emulated/0/DCIM/Camera/IMG_100.jpg',
      displayName: 'IMG_100.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 2048,
      dateAdded: DateTime(2026, 11, 3),
      dateModified: DateTime(2026, 11, 3),
    );

    setUp(() async {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      db = await dbHelper.database;

      // The first scan, then everything a user and the app add later.
      await mediaDao.batchUpsertMediaItems(<MediaItem>[scanned]);
      await mediaDao.updateFavorite('r1', true);
      await mediaDao.updateUserNotes('r1', 'birthday');
      await mediaDao.updateHashes('r1', sha256: 'abc', pHash: 'def');
      await mediaDao.updateExif('r1', const ExifData(make: 'Sony'));
      await db.update(
        DatabaseConstants.tableMedia,
        <String, Object?>{
          DatabaseConstants.colMediaLatitude: 9.9,
          DatabaseConstants.colMediaLongitude: 76.2,
          DatabaseConstants.colMediaAddress: 'Kochi',
        },
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: <Object?>['r1'],
      );
      await db.insert(DatabaseConstants.tableTags, <String, Object?>{
        DatabaseConstants.colId: 't1',
        DatabaseConstants.colName: 'family',
        DatabaseConstants.colTagColorValue: 1,
        DatabaseConstants.colTagItemCount: 1,
        DatabaseConstants.colTagDateCreated: 1,
      });
      await db.insert(DatabaseConstants.tableMediaTags, <String, Object?>{
        DatabaseConstants.colMediaTagMediaId: 'r1',
        DatabaseConstants.colMediaTagTagId: 't1',
        DatabaseConstants.colMediaTagDateTagged: 1,
      });
      await db.insert(DatabaseConstants.tableAlbums, <String, Object?>{
        DatabaseConstants.colId: 'a1',
        DatabaseConstants.colName: 'Trip',
        DatabaseConstants.colAlbumType: AlbumType.values.first.name,
        DatabaseConstants.colAlbumDateCreated: 1,
        DatabaseConstants.colAlbumDateModified: 1,
      });
      await db.insert(DatabaseConstants.tableAlbumMedia, <String, Object?>{
        DatabaseConstants.colAlbumMediaAlbumId: 'a1',
        DatabaseConstants.colAlbumMediaMediaId: 'r1',
        DatabaseConstants.colAlbumMediaDateAdded: 1,
      });
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('an unchanged rescan keeps all the user data', () async {
      await mediaDao.batchUpsertMediaItems(<MediaItem>[scanned]);

      final row = (await mediaDao.getMediaItemById('r1'))!;
      expect(row.isFavorite, isTrue);
      expect(row.userNotes, 'birthday');
      expect(row.sha256Hash, 'abc');
      expect(row.pHash, 'def');
      expect(row.exifData?.make, 'Sony');
      expect(row.latitude, 9.9);
      expect(row.address, 'Kochi');
      expect(await db.query(DatabaseConstants.tableMediaTags), hasLength(1));
      expect(await db.query(DatabaseConstants.tableAlbumMedia), hasLength(1));
    });

    test('keeps the trash and vault flags', () async {
      await mediaDao.updateTrash('r1', true);
      await mediaDao.updateVaulted('r1', true);

      await mediaDao.batchUpsertMediaItems(<MediaItem>[scanned]);

      final row = (await db.query(DatabaseConstants.tableMedia)).single;
      expect(row[DatabaseConstants.colMediaIsTrash], 1);
      expect(row[DatabaseConstants.colMediaIsVaulted], 1);
    });

    test('leaves one search row, so a search finds the photo once', () async {
      await mediaDao.batchUpsertMediaItems(<MediaItem>[scanned]);
      await mediaDao.batchUpsertMediaItems(<MediaItem>[scanned]);

      expect(
        await db.query(DatabaseConstants.tableMediaSearchFts),
        hasLength(1),
      );
      expect(await mediaDao.searchMediaFts('IMG_100'), hasLength(1));
    });

    test('a rename is saved and keeps the hashes and EXIF', () async {
      await mediaDao.batchUpsertMediaItems(<MediaItem>[
        scanned.copyWith(displayName: 'renamed.jpg'),
      ]);

      final row = (await mediaDao.getMediaItemById('r1'))!;
      expect(row.displayName, 'renamed.jpg');
      expect(row.sha256Hash, 'abc');
      expect(row.exifData?.make, 'Sony');
      expect(row.isFavorite, isTrue);
      expect(await mediaDao.searchMediaFts('renamed'), hasLength(1));
    });

    test('a changed file clears the hashes and EXIF, keeps the rest', () async {
      await mediaDao.batchUpsertMediaItems(<MediaItem>[
        scanned.copyWith(size: 4096, dateModified: DateTime(2026, 11, 2)),
      ]);

      final row = (await mediaDao.getMediaItemById('r1'))!;
      expect(row.size, 4096);
      expect(row.dateModified, DateTime(2026, 11, 2));
      expect(row.sha256Hash, isNull);
      expect(row.pHash, isNull);
      expect(row.exifData, isNull);
      expect(row.isFavorite, isTrue);
      expect(row.userNotes, 'birthday');
      expect(row.address, 'Kochi');
      expect(await db.query(DatabaseConstants.tableMediaTags), hasLength(1));
    });
  });

  group('MediaDao out-of-reach rows', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;

    MediaItem photo(String id, {bool isTrash = false}) => MediaItem(
      id: id,
      path: '/storage/emulated/0/DCIM/Camera/$id.jpg',
      displayName: '$id.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 100,
      dateAdded: DateTime(2026, 11, 3),
      dateModified: DateTime(2026, 11, 3),
      isTrash: isTrash,
      sha256Hash: 'hash_$id',
    );

    setUp(() async {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      await mediaDao.batchUpsertMediaItems(<MediaItem>[
        photo('seen'),
        photo('hidden'),
        photo('seen_trash', isTrash: true),
        photo('hidden_trash', isTrash: true),
      ]);
      await mediaDao.markOutOfReachExcept(<String>{'seen', 'seen_trash'});
    });

    tearDown(() async {
      await dbHelper.close();
    });

    List<String> ids(List<MediaItem> items) =>
        items.map((item) => item.id).toList();

    test('markOutOfReachExcept hides only the unseen rows', () async {
      expect((await mediaDao.getMediaItemById('hidden'))!.isOutOfReach, isTrue);
      expect((await mediaDao.getMediaItemById('seen'))!.isOutOfReach, isFalse);
      expect(await mediaDao.hasOutOfReach(), isTrue);
    });

    test('getMediaItems leaves out a hidden row', () async {
      expect(ids(await mediaDao.getMediaItems()), <String>['seen']);
      expect(
        ids(
          await mediaDao.getMediaItems(
            filter: const FilterOptions(isTrash: true),
          ),
        ),
        <String>['seen_trash'],
      );
    });

    test('searchMediaFts leaves out a hidden row', () async {
      expect(ids(await mediaDao.searchMediaFts('hidden')), isEmpty);
      expect(ids(await mediaDao.searchMediaFts('seen')), <String>['seen']);
    });

    test('getMediaItemsByIds leaves out a hidden row', () async {
      expect(
        ids(await mediaDao.getMediaItemsByIds(<String>['hidden', 'seen'])),
        <String>['seen'],
      );
    });

    test('getFolderSummaries counts only visible rows', () async {
      final folders = await mediaDao.getFolderSummaries();
      expect(folders.single.itemCount, 1);
      expect(folders.single.coverMediaId, 'seen');
    });

    test('counts leave out hidden rows', () async {
      expect(await mediaDao.getTotalCount(), 1);
      expect(await mediaDao.getTrashCount(), 1);
    });

    test('getHashCandidates leaves out a hidden row', () async {
      expect(
        ids(await mediaDao.getHashCandidates(limit: 10, offset: 0)),
        <String>['seen'],
      );
    });

    test('restoreAllFromTrash does not touch a hidden row', () async {
      expect(await mediaDao.restoreAllFromTrash(), 1);
      expect(
        (await mediaDao.getMediaItemById('hidden_trash'))!.isTrash,
        isTrue,
      );
    });

    test('deleteAllTrashed does not delete a hidden row', () async {
      expect(await mediaDao.deleteAllTrashed(), 1);
      expect(await mediaDao.getMediaItemById('hidden_trash'), isNotNull);
    });

    test('a hidden row keeps its data and comes back with clear', () async {
      await mediaDao.updateFavorite('hidden', true);
      await mediaDao.markOutOfReachExcept(<String>{'seen'});

      await mediaDao.clearOutOfReach();

      final back = (await mediaDao.getMediaItemById('hidden'))!;
      expect(back.isOutOfReach, isFalse);
      expect(back.isFavorite, isTrue);
      expect(back.sha256Hash, 'hash_hidden');
      expect(await mediaDao.hasOutOfReach(), isFalse);
      expect(await mediaDao.getTotalCount(), 2);
    });

    test('markAllOutOfReach hides everything', () async {
      await mediaDao.markAllOutOfReach();

      expect(await mediaDao.getMediaItems(), isEmpty);
      expect(await mediaDao.getMediaItemById('seen'), isNotNull);
    });

    test('a rescan keeps the hidden flag', () async {
      await mediaDao.batchUpsertMediaItems(<MediaItem>[photo('hidden')]);

      expect((await mediaDao.getMediaItemById('hidden'))!.isOutOfReach, isTrue);
    });
  });
}
