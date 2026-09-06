import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

MediaItem item(String id) {
  final when = DateTime(2026, 1, 1);
  return MediaItem(
    id: id,
    path: '/storage/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 100,
    dateAdded: when,
    dateModified: when,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TagRepository', () {
    late DatabaseHelper dbHelper;
    late TagDao tagDao;
    late MediaDao mediaDao;
    late TagRepository repository;

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      tagDao = TagDao(dbHelper: dbHelper);
      mediaDao = MediaDao(dbHelper: dbHelper);
      repository = TagRepository(tagDao: tagDao, mediaDao: mediaDao);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    /// The tag words the search index currently holds for one item.
    Future<String?> indexedTags(String mediaId) async {
      final db = await dbHelper.database;
      final rows = await db.query(
        DatabaseConstants.tableMediaSearchFts,
        columns: <String>[DatabaseConstants.colFtsTagsContent],
        where: '${DatabaseConstants.colFtsMediaId} = ?',
        whereArgs: <Object?>[mediaId],
      );
      if (rows.isEmpty) return null;
      return rows.first[DatabaseConstants.colFtsTagsContent] as String?;
    }

    group('creating', () {
      test('makes a tag with a cleaned-up name', () async {
        final tag = await repository.createTag('  Beach   Day  ');

        expect(tag.name, 'Beach Day');
        expect((await repository.getAllTags()).length, 1);
      });

      test('gives a new tag a palette colour drawn from its name', () async {
        final tag = await repository.createTag('beach');

        expect(TagColorPalette.contains(tag.colorValue), isTrue);
        expect(tag.colorValue, TagColorPalette.defaultColorFor('beach'));
      });

      test('honours a chosen colour', () async {
        final chosen = TagColorPalette.colors[5];
        final tag = await repository.createTag('beach', colorValue: chosen);

        expect(tag.colorValue, chosen);
      });

      test('refuses a blank name', () async {
        await expectLater(
          repository.createTag('   '),
          throwsA(
            isA<TagValidationException>().having(
              (e) => e.reason,
              'reason',
              TagNameError.empty,
            ),
          ),
        );
      });

      test('refuses a name that is already taken, whatever its case', () async {
        await repository.createTag('Beach');

        await expectLater(
          repository.createTag('beach'),
          throwsA(
            isA<TagValidationException>().having(
              (e) => e.reason,
              'reason',
              TagNameError.duplicate,
            ),
          ),
        );
      });

      test('refuses a name over the length cap', () async {
        await expectLater(
          repository.createTag('a' * (TagNameRules.maxLength + 1)),
          throwsA(isA<TagValidationException>()),
        );
      });

      test('two tags made together get different ids', () async {
        final a = await repository.createTag('one');
        final b = await repository.createTag('two');

        expect(a.id, isNot(b.id));
      });

      test(
        'findOrCreate returns the existing tag instead of failing',
        () async {
          final made = await repository.createTag('Beach');
          final found = await repository.findOrCreateTag('  beach ');

          expect(found.id, made.id);
          expect((await repository.getAllTags()).length, 1);
        },
      );

      test('findOrCreate makes the tag when it is new', () async {
        final tag = await repository.findOrCreateTag('fresh');

        expect(tag.name, 'fresh');
        expect((await repository.getAllTags()).length, 1);
      });
    });

    group('search index', () {
      test('adding a tag makes its name searchable', () async {
        await mediaDao.insertMediaItem(item('m1'));
        final tag = await repository.createTag('Beach');

        await repository.addTagToMedia('m1', tag.id);

        expect(await indexedTags('m1'), 'Beach');
      });

      test('removing the last tag clears the index cell', () async {
        // If the cell were left alone, the photo would keep turning up in
        // searches for a tag it no longer has.
        await mediaDao.insertMediaItem(item('m1'));
        final tag = await repository.createTag('Beach');
        await repository.addTagToMedia('m1', tag.id);

        await repository.removeTagFromMedia('m1', tag.id);

        expect(await indexedTags('m1'), '');
      });

      test('renaming a tag updates the index of every photo with it', () async {
        await mediaDao.insertMediaItem(item('m1'));
        await mediaDao.insertMediaItem(item('m2'));
        final tag = await repository.createTag('Beach');
        await repository.addTagToMedia('m1', tag.id);
        await repository.addTagToMedia('m2', tag.id);

        await repository.renameTag(tag.id, 'Seaside');

        expect(await indexedTags('m1'), 'Seaside');
        expect(await indexedTags('m2'), 'Seaside');
      });

      test('deleting a tag clears it from the index too', () async {
        // The junction rows go with the foreign key cascade, but the search
        // index knows nothing about cascades.
        await mediaDao.insertMediaItem(item('m1'));
        final tag = await repository.createTag('Beach');
        await repository.addTagToMedia('m1', tag.id);

        await repository.deleteTag(tag.id);

        expect(await indexedTags('m1'), '');
        expect(await repository.getTagsForMedia('m1'), isEmpty);
      });

      test('setting the whole tag set rewrites the index once', () async {
        await mediaDao.insertMediaItem(item('m1'));
        final beach = await repository.createTag('Beach');
        final family = await repository.createTag('Family');

        await repository.setTagsForMedia('m1', <String>{beach.id, family.id});
        final both = await indexedTags('m1');

        expect(both, contains('Beach'));
        expect(both, contains('Family'));

        await repository.setTagsForMedia('m1', <String>{family.id});

        expect(await indexedTags('m1'), 'Family');
      });
    });

    group('changing tags', () {
      test('renaming keeps the tag and its photos', () async {
        await mediaDao.insertMediaItem(item('m1'));
        final tag = await repository.createTag('Beach');
        await repository.addTagToMedia('m1', tag.id);

        final renamed = await repository.renameTag(tag.id, 'Seaside');

        expect(renamed.name, 'Seaside');
        final onMedia = await repository.getTagsForMedia('m1');
        expect(onMedia.single.id, tag.id);
        expect(onMedia.single.name, 'Seaside');
      });

      test(
        'a tag may be renamed to a different case of its own name',
        () async {
          final tag = await repository.createTag('beach');

          final renamed = await repository.renameTag(tag.id, 'Beach');

          expect(renamed.name, 'Beach');
        },
      );

      test('a rename onto another tag is refused', () async {
        await repository.createTag('Holiday');
        final tag = await repository.createTag('Beach');

        await expectLater(
          repository.renameTag(tag.id, 'holiday'),
          throwsA(isA<TagValidationException>()),
        );
      });

      test('changing the colour snaps it into the palette', () async {
        final tag = await repository.createTag('beach');

        final recoloured = await repository.setTagColor(tag.id, 0xFF010203);

        expect(TagColorPalette.contains(recoloured.colorValue), isTrue);
      });

      test('setting the tag set updates the stored counts', () async {
        await mediaDao.insertMediaItem(item('m1'));
        await mediaDao.insertMediaItem(item('m2'));
        final tag = await repository.createTag('Beach');

        await repository.setTagsForMedia('m1', <String>{tag.id});
        await repository.setTagsForMedia('m2', <String>{tag.id});

        expect((await tagDao.getTagById(tag.id))!.itemCount, 2);

        await repository.setTagsForMedia('m2', const <String>{});

        expect((await tagDao.getTagById(tag.id))!.itemCount, 1);
      });

      test('working on a tag that no longer exists fails clearly', () async {
        await expectLater(
          repository.renameTag('missing', 'anything'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
