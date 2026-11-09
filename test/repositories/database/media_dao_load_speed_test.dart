import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Tests for the changes that make a large timeline load fast: tags read in
/// one query, an upsert that reports real changes, and a stable list order.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late MediaDao mediaDao;
  late TagDao tagDao;

  final baseDate = DateTime(2026, 8, 29, 10);

  MediaItem photo(String id, {DateTime? taken, int size = 1000}) {
    final date = taken ?? baseDate;
    return MediaItem(
      id: id,
      path: '/storage/emulated/0/DCIM/$id.jpg',
      displayName: '$id.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: size,
      dateAdded: date,
      dateModified: date,
      dateTaken: date,
    );
  }

  Future<void> addTag(String id, String name) {
    return tagDao.insertTag(
      Tag(id: id, name: name, colorValue: 1, dateCreated: baseDate),
    );
  }

  setUp(() {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    mediaDao = MediaDao(dbHelper: dbHelper);
    tagDao = TagDao(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('tags on lists', () {
    test('each item gets its own tags: none, one or many', () async {
      await mediaDao.batchUpsertMediaItems([
        photo('a'),
        photo('b', taken: baseDate.add(const Duration(hours: 1))),
        photo('c', taken: baseDate.add(const Duration(hours: 2))),
      ]);
      await addTag('t1', 'family');
      await addTag('t2', 'trip');
      await tagDao.addTagToMedia('b', 't1');
      await tagDao.addTagToMedia('c', 't1');
      await tagDao.addTagToMedia('c', 't2');

      final items = await mediaDao.getMediaItems();
      final byId = {for (final i in items) i.id: i};

      expect(byId['a']!.tags, isEmpty);
      expect(byId['b']!.tags, ['family']);
      expect(byId['c']!.tags, unorderedEquals(['family', 'trip']));
    });

    test('a list longer than the IN limit still gets the right tags', () async {
      final many = [
        for (var i = 0; i < 650; i++)
          photo('p$i', taken: baseDate.add(Duration(minutes: i))),
      ];
      await mediaDao.batchUpsertMediaItems(many);
      await addTag('t1', 'family');
      await tagDao.addTagToMedia('p0', 't1');
      await tagDao.addTagToMedia('p649', 't1');

      final items = await mediaDao.getMediaItems();
      final byId = {for (final i in items) i.id: i};

      expect(items, hasLength(650));
      expect(byId['p0']!.tags, ['family']);
      expect(byId['p649']!.tags, ['family']);
      expect(byId['p300']!.tags, isEmpty);
    });

    test('a page with LIMIT only reads tags for its own items', () async {
      await mediaDao.batchUpsertMediaItems([
        photo('old'),
        photo('new', taken: baseDate.add(const Duration(days: 1))),
      ]);
      await addTag('t1', 'family');
      await tagDao.addTagToMedia('old', 't1');
      await tagDao.addTagToMedia('new', 't1');

      final page = await mediaDao.getMediaItems(limit: 1);

      expect(page.single.id, 'new');
      expect(page.single.tags, ['family']);
    });

    test('getMediaItemsByIds keeps the order and the tags', () async {
      await mediaDao.batchUpsertMediaItems([photo('a'), photo('b')]);
      await addTag('t1', 'family');
      await tagDao.addTagToMedia('a', 't1');

      final items = await mediaDao.getMediaItemsByIds(['b', 'a']);

      expect(items.map((i) => i.id), ['b', 'a']);
      expect(items[0].tags, isEmpty);
      expect(items[1].tags, ['family']);
    });
  });

  group('batchUpsertMediaItems change count', () {
    test('counts new rows, then nothing for an unchanged rescan', () async {
      final first = await mediaDao.batchUpsertMediaItems([
        photo('a'),
        photo('b'),
      ]);
      final again = await mediaDao.batchUpsertMediaItems([
        photo('a'),
        photo('b'),
      ]);

      expect(first, 2);
      expect(again, 0);
    });

    test('counts a row whose file changed, plus a new one', () async {
      await mediaDao.batchUpsertMediaItems([photo('a'), photo('b')]);

      final changed = await mediaDao.batchUpsertMediaItems([
        photo('a', size: 2000),
        photo('b'),
        photo('c'),
      ]);

      expect(changed, 2);
    });

    test('an empty list changes nothing', () async {
      expect(await mediaDao.batchUpsertMediaItems(const []), 0);
    });
  });

  group('list order', () {
    test('a first page is the exact start of the full list on ties', () async {
      // Every item has the same date, so only the id can order them.
      await mediaDao.batchUpsertMediaItems([
        for (var i = 0; i < 20; i++) photo('same$i'),
      ]);

      final full = await mediaDao.getMediaItems();
      final page = await mediaDao.getMediaItems(limit: 7);

      expect(
        page.map((i) => i.id).toList(),
        full.take(7).map((i) => i.id).toList(),
      );
    });

    test('the default filter is newest first', () async {
      await mediaDao.batchUpsertMediaItems([
        photo('old'),
        photo('new', taken: baseDate.add(const Duration(days: 1))),
      ]);

      final items = await mediaDao.getMediaItems();

      expect(items.first.id, 'new');
    });
  });
}
