import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TagDao Database Access Object', () {
    late DatabaseHelper dbHelper;
    late TagDao tagDao;
    late MediaDao mediaDao;

    final now = DateTime(2026, 8, 29, 10);

    final testTag = Tag(
      id: 'tag_nature',
      name: 'Nature',
      colorValue: 0xFF4CAF50,
      description: 'Flora, fauna, landscapes',
      dateCreated: now,
    );

    final testMedia = MediaItem(
      id: 'media_tag_test',
      path: '/storage/DCIM/landscape.jpg',
      displayName: 'landscape.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 120000,
      dateAdded: now,
      dateModified: now,
    );

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      tagDao = TagDao(dbHelper: dbHelper);
      mediaDao = MediaDao(dbHelper: dbHelper);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test('inserts, updates, and fetches tags by ID and Name', () async {
      await tagDao.insertTag(testTag);

      var retrieved = await tagDao.getTagById(testTag.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Nature');

      final retrievedByName = await tagDao.getTagByName('nature');
      expect(retrievedByName, isNotNull);
      expect(retrievedByName!.id, testTag.id);

      await tagDao.updateTag(retrieved.copyWith(name: 'Wild Nature'));
      retrieved = await tagDao.getTagById(testTag.id);
      expect(retrieved!.name, 'Wild Nature');
    });

    test('attaches tags to media and tracks tag counts', () async {
      await mediaDao.insertMediaItem(testMedia);
      await tagDao.insertTag(testTag);

      await tagDao.addTagToMedia(testMedia.id, testTag.id);

      final updatedTag = await tagDao.getTagById(testTag.id);
      expect(updatedTag!.itemCount, 1);

      final mediaTags = await tagDao.getTagsForMedia(testMedia.id);
      expect(mediaTags.length, 1);
      expect(mediaTags.first.name, 'Nature');

      await tagDao.removeTagFromMedia(testMedia.id, testTag.id);
      final emptyTag = await tagDao.getTagById(testTag.id);
      expect(emptyTag!.itemCount, 0);
    });

    test('item count counts only tagged items the user can see', () async {
      MediaItem item(String id) => testMedia.copyWith(
        id: id,
        path: '/storage/DCIM/$id.jpg',
        displayName: '$id.jpg',
      );
      await tagDao.insertTag(testTag);
      await mediaDao.insertMediaItem(item('visible'));
      await mediaDao.insertMediaItem(item('trashed').copyWith(isTrash: true));
      await mediaDao.insertMediaItem(item('vaulted').copyWith(isVaulted: true));
      await mediaDao.insertMediaItem(
        item('hidden').copyWith(isOutOfReach: true),
      );
      for (final id in ['visible', 'trashed', 'vaulted', 'hidden']) {
        await tagDao.addTagToMedia(id, testTag.id);
      }

      expect((await tagDao.getTagById(testTag.id))!.itemCount, 1);
      expect((await tagDao.getTagByName('nature'))!.itemCount, 1);
      expect((await tagDao.getAllTags()).single.itemCount, 1);
      expect((await tagDao.getTagsForMedia('visible')).single.itemCount, 1);
    });

    test('item count drops when a tagged item is hidden later', () async {
      await mediaDao.insertMediaItem(testMedia);
      await tagDao.insertTag(testTag);
      await tagDao.addTagToMedia(testMedia.id, testTag.id);
      expect((await tagDao.getAllTags()).single.itemCount, 1);

      // A scan with limited access hides the photo; nothing recounts.
      await mediaDao.markOutOfReachExcept(<String>{});

      expect((await tagDao.getAllTags()).single.itemCount, 0);
    });

    group('saved item_count (schema 8 triggers)', () {
      /// Reads the raw column. The DAO read swaps in a live count, which
      /// would hide a wrong saved number.
      Future<int> savedCount() async {
        final db = await dbHelper.database;
        final rows = await db.query(
          DatabaseConstants.tableTags,
          columns: [DatabaseConstants.colTagItemCount],
          where: '${DatabaseConstants.colId} = ?',
          whereArgs: [testTag.id],
        );
        return rows.single[DatabaseConstants.colTagItemCount]! as int;
      }

      MediaItem item(String id) => testMedia.copyWith(
        id: id,
        path: '/storage/DCIM/$id.jpg',
        displayName: '$id.jpg',
      );

      setUp(() async {
        await tagDao.insertTag(testTag);
        for (final id in ['a', 'b']) {
          await mediaDao.insertMediaItem(item(id));
          await tagDao.addTagToMedia(id, testTag.id);
        }
      });

      test('follows adding and removing tags', () async {
        expect(await savedCount(), 2);
        await tagDao.removeTagFromMedia('a', testTag.id);
        expect(await savedCount(), 1);
        await tagDao.setTagsForMedia('a', {testTag.id});
        expect(await savedCount(), 2);
        await tagDao.setTagsForMedia('b', <String>{});
        expect(await savedCount(), 1);
      });

      test('follows trash, vault and limited media access', () async {
        await mediaDao.updateTrash('a', true);
        expect(await savedCount(), 1);
        await mediaDao.updateVaulted('b', true);
        expect(await savedCount(), 0);
        await mediaDao.updateTrash('a', false);
        await mediaDao.updateVaulted('b', false);
        expect(await savedCount(), 2);
        await mediaDao.markAllOutOfReach();
        expect(await savedCount(), 0);
        await mediaDao.clearOutOfReach();
        expect(await savedCount(), 2);
      });

      test('follows a deleted photo through the cascade', () async {
        await mediaDao.deleteMediaItem('b');
        expect(await savedCount(), 1);
      });

      test('a whole-row write with a wrong count is corrected', () async {
        await tagDao.updateTag(testTag.copyWith(itemCount: 99));
        expect(await savedCount(), 2);
      });
    });
  });
}
