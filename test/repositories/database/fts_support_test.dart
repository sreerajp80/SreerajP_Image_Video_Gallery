import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/fts_support.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A module no SQLite build has, standing in for FTS5 on Android.
const FtsModule missingModule = FtsModule(
  label: 'missing',
  moduleName: 'fts_missing_for_test',
  idColumnSuffix: '',
  options: <String>[],
);

void main() {
  setUpAll(sqfliteFfiInit);

  group('FtsSupport.probe', () {
    test('skips a module SQLite does not have and picks the next', () async {
      final module = await FtsSupport.probe(
        databaseFactoryFfi,
        candidates: const <FtsModule>[missingModule, FtsModule.fts5],
      );

      expect(module, same(FtsModule.fts5));
    });

    test('returns null when no module works', () async {
      final module = await FtsSupport.probe(
        databaseFactoryFfi,
        candidates: const <FtsModule>[missingModule],
      );

      expect(module, isNull);
    });

    test('the default list finds a module on the test SQLite', () async {
      final module = await FtsSupport.probe(databaseFactoryFfi);

      expect(module, isNotNull);
    });
  });

  group('FtsModule.createTableSql', () {
    const columns = <String>['media_id', 'display_name', 'address'];

    test('FTS5 keeps the id column out of the index', () {
      expect(
        FtsModule.fts5.createTableSql('s', columns),
        'CREATE VIRTUAL TABLE s USING fts5(media_id UNINDEXED, display_name, '
        "address, tokenize = 'unicode61');",
      );
    });

    test('FTS4 names the id column in notindexed', () {
      expect(
        FtsModule.fts4Unicode.createTableSql('s', columns),
        'CREATE VIRTUAL TABLE s USING fts4(media_id, display_name, address, '
        'notindexed=media_id, tokenize=unicode61);',
      );
    });
  });

  test('isMissingModuleError spots the SQLite message', () {
    expect(
      FtsSupport.isMissingModuleError(
        Exception('DatabaseException(no such module: fts5)'),
      ),
      isTrue,
    );
    expect(
      FtsSupport.isMissingModuleError(Exception('no such table: x')),
      isFalse,
    );
  });
}
