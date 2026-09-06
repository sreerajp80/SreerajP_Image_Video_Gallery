import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
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
