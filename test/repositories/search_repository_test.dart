import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_query.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_result.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/search_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

MediaItem item(
  String id, {
  String? name,
  MediaType type = MediaType.image,
  DateTime? taken,
  String? notes,
  String? address,
  bool favorite = false,
}) {
  final when = DateTime(2026, 1, 1);
  return MediaItem(
    id: id,
    path: '/storage/DCIM/$id',
    displayName: name ?? '$id.jpg',
    mediaType: type,
    mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
    size: 100,
    dateAdded: when,
    dateModified: when,
    dateTaken: taken,
    userNotes: notes,
    address: address,
    isFavorite: favorite,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('SearchRepository', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late TagDao tagDao;
    late TagRepository tagRepository;
    late SearchRepository repository;

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      tagDao = TagDao(dbHelper: dbHelper);
      tagRepository = TagRepository(tagDao: tagDao, mediaDao: mediaDao);
      repository = SearchRepository(mediaDao: mediaDao, tagDao: tagDao);
    });

    tearDown(() async {
      await dbHelper.close();
    });

    Future<List<String>> idsFor(
      String text, {
      FilterOptions filter = const FilterOptions(),
    }) async {
      final results = await repository.searchText(text, baseFilter: filter);
      return results.map((r) => r.item.id).toList();
    }

    group('text search', () {
      test('finds a photo by its file name', () async {
        await mediaDao.insertMediaItem(item('a', name: 'sunset_beach.jpg'));
        await mediaDao.insertMediaItem(item('b', name: 'mountain.jpg'));

        expect(await idsFor('sunset'), <String>['a']);
      });

      test('matches on a prefix, the way a search box should', () async {
        await mediaDao.insertMediaItem(item('a', name: 'sunset_beach.jpg'));

        expect(await idsFor('suns'), <String>['a']);
      });

      test('finds a photo by its notes', () async {
        await mediaDao.insertMediaItem(
          item('a', name: 'x.jpg', notes: 'Grandmother birthday'),
        );

        final results = await repository.searchText('birthday');

        expect(results.single.item.id, 'a');
        expect(results.single.matchField, SearchMatchField.notes);
      });

      test('finds a photo by its place', () async {
        await mediaDao.insertMediaItem(
          item('a', name: 'x.jpg', address: 'Fort Kochi, Kerala'),
        );

        final results = await repository.searchText('place:Kochi');

        expect(results.single.item.id, 'a');
        expect(results.single.matchField, SearchMatchField.address);
      });

      test('finds a photo by its tag name', () async {
        await mediaDao.insertMediaItem(item('a', name: 'x.jpg'));
        final tag = await tagRepository.createTag('Seaside');
        await tagRepository.addTagToMedia('a', tag.id);

        // The tag words reach the index through the repository, so this also
        // proves the two stay in step.
        expect(await idsFor('Seaside'), <String>['a']);
      });

      test('several words all have to appear', () async {
        await mediaDao.insertMediaItem(item('a', name: 'sunset_beach.jpg'));
        await mediaDao.insertMediaItem(item('b', name: 'sunset_hill.jpg'));

        expect(await idsFor('sunset beach'), <String>['a']);
      });

      test('text a user types cannot break the query', () async {
        await mediaDao.insertMediaItem(item('a', name: 'sunset.jpg'));

        // Each of these would be a syntax error if it reached FTS5 unquoted.
        for (final nasty in <String>['"', 'a"b', '*', 'AND', 'NEAR(', ')']) {
          await expectLater(repository.searchText(nasty), completes);
        }
      });

      test('vaulted and trashed items never come back', () async {
        await mediaDao.insertMediaItem(item('a', name: 'sunset.jpg'));
        await mediaDao.insertMediaItem(item('b', name: 'sunset_two.jpg'));
        await mediaDao.updateTrash('b', true);

        expect(await idsFor('sunset'), <String>['a']);
      });
    });

    group('filters', () {
      test('type: narrows to one kind', () async {
        await mediaDao.insertMediaItem(item('photo', name: 'holiday.jpg'));
        await mediaDao.insertMediaItem(
          item('clip', name: 'holiday.mp4', type: MediaType.video),
        );

        expect(await idsFor('holiday type:video'), <String>['clip']);
      });

      test('a date range narrows the result', () async {
        await mediaDao.insertMediaItem(
          item('old', name: 'holiday.jpg', taken: DateTime(2024, 5, 1)),
        );
        await mediaDao.insertMediaItem(
          item('new', name: 'holiday_two.jpg', taken: DateTime(2026, 5, 1)),
        );

        expect(await idsFor('holiday after:2026-01-01'), <String>['new']);
        expect(await idsFor('holiday before:2025-01-01'), <String>['old']);
      });

      test('a filter with no text at all still returns items', () async {
        await mediaDao.insertMediaItem(item('a', favorite: true));
        await mediaDao.insertMediaItem(item('b'));

        final results = await repository.search(
          const SearchQuery(),
          baseFilter: const FilterOptions(isFavoriteOnly: true),
        );

        expect(results.single.item.id, 'a');
        // Nothing was typed, so there is no word to point at.
        expect(results.single.matchField, SearchMatchField.filter);
      });

      test('an empty search with no filters returns nothing', () async {
        await mediaDao.insertMediaItem(item('a'));

        expect(await idsFor(''), isEmpty);
      });
    });

    group('tag filtering', () {
      late String beachId;
      late String familyId;

      Future<void> seedTags() async {
        beachId = (await tagRepository.createTag('Beach')).id;
        familyId = (await tagRepository.createTag('Family')).id;

        await mediaDao.insertMediaItem(item('both', name: 'holiday_one.jpg'));
        await mediaDao.insertMediaItem(item('beach', name: 'holiday_two.jpg'));
        await mediaDao.insertMediaItem(
          item('neither', name: 'holiday_three.jpg'),
        );

        await tagRepository.setTagsForMedia('both', <String>{
          beachId,
          familyId,
        });
        await tagRepository.setTagsForMedia('beach', <String>{beachId});
      }

      test('AND mode needs every chosen tag', () async {
        await seedTags();

        final results = await repository.searchText(
          'holiday',
          baseFilter: FilterOptions(
            tagIds: <String>{beachId, familyId},
            tagFilterMode: TagFilterMode.andMode,
          ),
        );

        expect(results.map((r) => r.item.id).toList(), <String>['both']);
      });

      test('OR mode needs any one chosen tag', () async {
        await seedTags();

        final results = await repository.searchText(
          'holiday',
          baseFilter: FilterOptions(
            tagIds: <String>{beachId, familyId},
            tagFilterMode: TagFilterMode.orMode,
          ),
        );

        expect(results.map((r) => r.item.id).toSet(), <String>{
          'both',
          'beach',
        });
      });

      test('tag: in the text is resolved to a tag id', () async {
        await seedTags();

        expect((await idsFor('tag:family')).toSet(), <String>{'both'});
      });

      test('a tag that does not exist matches nothing', () async {
        await seedTags();

        // The alternative would be quietly dropping the term and showing the
        // whole library, which looks like the filter was ignored.
        expect(await idsFor('holiday tag:nosuchtag'), isEmpty);
      });

      test('resolveTagNames ignores case and unknown names', () async {
        await seedTags();

        final ids = await repository.resolveTagNames(<String>{
          'BEACH',
          'nothing',
        });

        expect(ids, <String>{beachId});
      });

      test(
        'a typed tag adds to the ticked ones rather than replacing',
        () async {
          await seedTags();

          final results = await repository.searchText(
            'tag:family',
            baseFilter: FilterOptions(
              tagIds: <String>{beachId},
              tagFilterMode: TagFilterMode.andMode,
            ),
          );

          expect(results.map((r) => r.item.id).toList(), <String>['both']);
        },
      );
    });
  });
}
