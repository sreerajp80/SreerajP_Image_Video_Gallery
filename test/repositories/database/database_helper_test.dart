import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('turns on WAL mode for a database file on disk', () async {
    final tempDir = Directory.systemTemp.createTempSync('db_wal_test');
    final helper = DatabaseHelper(
      customPath: p.join(tempDir.path, 'wal.db'),
      customFactory: databaseFactoryFfi,
    );
    addTearDown(() async {
      await helper.close();
      tempDir.deleteSync(recursive: true);
    });

    final db = await helper.database;
    final rows = await db.rawQuery('PRAGMA journal_mode;');

    expect(rows.single.values.single, 'wal');
  });

  group('DatabaseHelper Lifecycle & Schema', () {
    late DatabaseHelper dbHelper;

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
    });

    tearDown(() async {
      await dbHelper.close();
    });

    test(
      'initializes all required tables, indexes, and FTS virtual table',
      () async {
        final db = await dbHelper.database;
        expect(db.isOpen, isTrue);

        final tables = await db.rawQuery('''
        SELECT name FROM sqlite_master WHERE type='table';
      ''');
        final tableNames = tables.map((t) => t['name'] as String).toSet();

        expect(tableNames, contains(DatabaseConstants.tableMedia));
        expect(tableNames, contains(DatabaseConstants.tableAlbums));
        expect(tableNames, contains(DatabaseConstants.tableAlbumMedia));
        expect(tableNames, contains(DatabaseConstants.tableTags));
        expect(tableNames, contains(DatabaseConstants.tableMediaTags));
        expect(tableNames, contains(DatabaseConstants.tableVault));
        expect(tableNames, contains(DatabaseConstants.tableMediaSearchFts));
      },
    );

    test('enforces foreign key constraints', () async {
      final db = await dbHelper.database;
      final fkStatus = await db.rawQuery('PRAGMA foreign_keys;');
      expect(fkStatus.first.values.first, 1);
    });
  });
}
