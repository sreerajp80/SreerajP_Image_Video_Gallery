import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/fts_support.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A module no SQLite build has, standing in for FTS5 on Android.
const FtsModule _missingModule = FtsModule(
  label: 'missing',
  moduleName: 'fts_missing_for_test',
  idColumnSuffix: '',
  options: <String>[],
);

/// What SQLite 3.22 leaves after a failed FTS5 create inside a transaction:
/// the table's row with no storage (rootpage 0) and a module it lacks.
/// Written out by hand so the test does not depend on the code it checks.
const String _brokenTableSql =
    'CREATE VIRTUAL TABLE media_search_fts USING fts_missing_for_test('
    'media_id, display_name, user_notes, tags_content, exif_search_text, '
    'address)';

const List<String> _searchTriggers = <String>[
  '''CREATE TRIGGER trg_media_insert AFTER INSERT ON media_items BEGIN
       INSERT INTO media_search_fts (media_id, display_name, user_notes,
         tags_content, exif_search_text, address)
       VALUES (new.id, new.display_name, '', '', '', '');
     END;''',
  '''CREATE TRIGGER trg_media_update AFTER UPDATE ON media_items BEGIN
       UPDATE media_search_fts SET display_name = new.display_name
       WHERE media_id = new.id;
     END;''',
  '''CREATE TRIGGER trg_media_delete AFTER DELETE ON media_items BEGIN
       DELETE FROM media_search_fts WHERE media_id = old.id;
     END;''',
];

Map<String, Object?> _media(String id, String name) => <String, Object?>{
  'id': id,
  'path': '/storage/emulated/0/DCIM/$name',
  'display_name': name,
  'media_type': 'image',
  'mime_type': 'image/jpeg',
  'size_bytes': 10,
  'date_added': 1,
  'date_modified': 1,
};

void main() {
  setUpAll(sqfliteFfiInit);

  late Directory tempDir;
  late String dbPath;
  DatabaseHelper? helper;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('db_fts_repair_test');
    dbPath = p.join(tempDir.path, 'gallery.db');
  });

  tearDown(() async {
    await helper?.close();
    helper = null;
    tempDir.deleteSync(recursive: true);
  });

  Future<Database> openHelper({List<FtsModule>? candidates}) {
    final h = DatabaseHelper(
      customPath: dbPath,
      customFactory: databaseFactoryFfi,
      ftsCandidates: candidates,
    );
    helper = h;
    return h.database;
  }

  Future<void> closeHelper() async {
    await helper?.close();
    helper = null;
  }

  Future<String?> searchTableSql(DatabaseExecutor db) async {
    final rows = await db.rawQuery(
      "SELECT sql FROM sqlite_master WHERE type = 'table' "
      "AND name = 'media_search_fts';",
    );
    return rows.isEmpty ? null : rows.single['sql'] as String?;
  }

  /// Turns the healthy database at [dbPath] into what an Android 10 phone
  /// ended up with, using its own connection.
  Future<void> breakSearchTable() async {
    final db = await databaseFactoryFfi.openDatabase(dbPath);
    for (final name in [
      'trg_media_insert',
      'trg_media_update',
      'trg_media_delete',
    ]) {
      await db.execute('DROP TRIGGER $name;');
    }
    await db.execute('DROP TABLE media_search_fts;');
    for (final sql in _searchTriggers) {
      await db.execute(sql);
    }
    await db.execute('PRAGMA writable_schema = ON;');
    await db.rawInsert(
      'INSERT INTO sqlite_master (type, name, tbl_name, rootpage, sql) '
      "VALUES ('table', 'media_search_fts', 'media_search_fts', 0, ?);",
      <Object?>[_brokenTableSql],
    );
    await db.execute('PRAGMA writable_schema = OFF;');
    await db.close();
  }

  group('creating the search table', () {
    test('skips a missing module and uses the next one that works', () async {
      final db = await openHelper(
        candidates: const <FtsModule>[_missingModule, FtsModule.fts5],
      );

      expect(await searchTableSql(db), contains('USING fts5('));
      await db.insert('media_items', _media('m1', 'beach.jpg'));
      final hits = await db.rawQuery(
        "SELECT media_id FROM media_search_fts WHERE media_search_fts MATCH 'beach';",
      );
      expect(hits.single['media_id'], 'm1');
    });

    test('uses a plain table when no module works', () async {
      final db = await openHelper(
        candidates: const <FtsModule>[_missingModule],
      );

      final sql = await searchTableSql(db);
      expect(sql, startsWith('CREATE TABLE'));
      await db.insert('media_items', _media('m1', 'beach.jpg'));
      final rows = await db.query('media_search_fts');
      expect(rows.single['media_id'], 'm1');
    });
  });

  group('repairing a search table left by old SQLite', () {
    setUp(() async {
      final db = await openHelper();
      await db.insert('media_items', _media('m1', 'beach.jpg'));
      await db.insert('media_items', _media('m2', 'hill.jpg'));
      await db.insert('tags', <String, Object?>{
        'id': 't1',
        'name': 'holiday',
        'color_value': 0,
        'date_created': 1,
      });
      await db.insert('media_tag_entries', <String, Object?>{
        'media_id': 'm1',
        'tag_id': 't1',
        'date_tagged': 1,
      });
      await closeHelper();
      await breakSearchTable();
    });

    test('the broken state really stops every insert', () async {
      final db = await databaseFactoryFfi.openDatabase(dbPath);
      addTearDown(db.close);

      await expectLater(
        db.insert('media_items', _media('m3', 'sea.jpg')),
        throwsA(predicate((Object e) => FtsSupport.isMissingModuleError(e))),
      );
    });

    test('opening rebuilds a working table with every photo', () async {
      final db = await openHelper();

      expect(await searchTableSql(db), isNot(contains('fts_missing_for_test')));
      final rows = await db.query('media_search_fts', orderBy: 'media_id');
      expect(rows.map((r) => r['media_id']), <String>['m1', 'm2']);
      expect(rows.first['tags_content'], 'holiday');

      await db.insert('media_items', _media('m3', 'sea.jpg'));
      final hits = await db.rawQuery(
        "SELECT media_id FROM media_search_fts WHERE media_search_fts MATCH 'sea';",
      );
      expect(hits.single['media_id'], 'm3');

      await db.update(
        'media_items',
        <String, Object?>{'display_name': 'river.jpg'},
        where: 'id = ?',
        whereArgs: <Object?>['m2'],
      );
      await db.delete(
        'media_items',
        where: 'id = ?',
        whereArgs: <Object?>['m1'],
      );
      final after = await db.query('media_search_fts', orderBy: 'media_id');
      expect(after.map((r) => r['media_id']), <String>['m2', 'm3']);
      expect(after.first['display_name'], 'river.jpg');

      final check = await db.rawQuery('PRAGMA integrity_check;');
      expect(check.single.values.single, 'ok');
    });

    test(
      'callers opening at the same moment share one repaired database',
      () async {
        final h = DatabaseHelper(
          customPath: dbPath,
          customFactory: databaseFactoryFfi,
        );
        helper = h;

        final dbs = await Future.wait(<Future<Database>>[
          h.database,
          h.database,
          h.database,
        ]);

        expect(dbs.toSet(), hasLength(1));
        expect(dbs.first.isOpen, isTrue);
        await dbs.first.insert('media_items', _media('m3', 'sea.jpg'));
        final count = await dbs.first.rawQuery(
          'SELECT COUNT(*) AS c FROM media_search_fts;',
        );
        expect(count.single['c'], 3);
      },
    );

    test('the repair holds after closing and opening again', () async {
      await openHelper();
      await closeHelper();
      final db = await openHelper();

      final count = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM media_search_fts;',
      );
      expect(count.single['c'], 2);
    });
  });

  test('a healthy database is left exactly as it was', () async {
    var db = await openHelper();
    await db.insert('media_items', _media('m1', 'beach.jpg'));
    final schemaBefore = await db.rawQuery(
      'SELECT type, name, sql FROM sqlite_master ORDER BY name;',
    );
    final rowsBefore = await db.query('media_search_fts');
    await closeHelper();

    db = await openHelper();

    expect(
      await db.rawQuery(
        'SELECT type, name, sql FROM sqlite_master ORDER BY name;',
      ),
      schemaBefore,
    );
    expect(await db.query('media_search_fts'), rowsBefore);
  });
}
