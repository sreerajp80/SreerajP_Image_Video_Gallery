import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
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

    final now = DateTime(2026, 8, 29, 10, 0, 0);

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
  });
}
