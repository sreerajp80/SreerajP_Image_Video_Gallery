import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
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

    final baseDate = DateTime(2026, 8, 29, 10, 0, 0);

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
      isFavorite: false,
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

        var trashItems = await mediaDao.getMediaItems(
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
}
