import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:sqflite/sqflite.dart';

/// One way to build the full-text search table: an SQLite module plus the
/// options it takes.
///
/// Which modules exist depends on the SQLite build. Android's own SQLite has
/// FTS4 but no FTS5; the SQLite used by the desktop tests has FTS5 but no FTS4.
class FtsModule {
  /// Creates a module description. `{id}` in [options] stands for the id
  /// column's name.
  const FtsModule({
    required this.label,
    required this.moduleName,
    required this.idColumnSuffix,
    required this.options,
  });

  /// Short name for logs.
  final String label;

  /// The name after `USING`, for example `fts5`.
  final String moduleName;

  /// Added after the id column, for example ` UNINDEXED` for FTS5.
  final String idColumnSuffix;

  /// Extra arguments after the columns.
  final List<String> options;

  /// FTS5 with the `unicode61` tokenizer.
  static const FtsModule fts5 = FtsModule(
    label: 'FTS5',
    moduleName: 'fts5',
    idColumnSuffix: ' UNINDEXED',
    options: <String>["tokenize = 'unicode61'"],
  );

  /// FTS4 with the `unicode61` tokenizer, the usual choice on Android.
  static const FtsModule fts4Unicode = FtsModule(
    label: 'FTS4 unicode61',
    moduleName: 'fts4',
    idColumnSuffix: '',
    options: <String>['notindexed={id}', 'tokenize=unicode61'],
  );

  /// FTS4 with its default tokenizer.
  static const FtsModule fts4 = FtsModule(
    label: 'FTS4',
    moduleName: 'fts4',
    idColumnSuffix: '',
    options: <String>['notindexed={id}'],
  );

  /// The order in which modules are tried. The first one that works wins.
  static const List<FtsModule> preferred = <FtsModule>[fts5, fts4Unicode, fts4];

  /// The `CREATE VIRTUAL TABLE` statement for [table]. The first of
  /// [columns] is the id column, which is stored but not searched.
  String createTableSql(String table, List<String> columns) {
    final idColumn = columns.first;
    final parts = <String>[
      '$idColumn$idColumnSuffix',
      ...columns.skip(1),
      for (final option in options) option.replaceAll('{id}', idColumn),
    ];
    return 'CREATE VIRTUAL TABLE $table USING $moduleName(${parts.join(', ')});';
  }
}

/// Finds out which [FtsModule] this device's SQLite supports.
class FtsSupport {
  FtsSupport._();

  /// Tries each of [candidates] on a separate, throw-away in-memory database
  /// and returns the first that works, or null when none does.
  ///
  /// This must not happen inside the main database's transaction. Old SQLite
  /// (3.22, Android 10) keeps the table's row in the schema when
  /// `CREATE VIRTUAL TABLE` fails for a missing module inside a transaction,
  /// and that row then breaks every write. Here each try runs on its own
  /// connection, outside any transaction, with its own table name.
  static Future<FtsModule?> probe(
    DatabaseFactory factory, {
    List<FtsModule> candidates = FtsModule.preferred,
  }) async {
    final db = await factory.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      for (var i = 0; i < candidates.length; i++) {
        final candidate = candidates[i];
        final table = 'fts_probe_$i';
        try {
          await db.execute(
            candidate.createTableSql(table, const <String>['a', 'b']),
          );
          await db.execute('DROP TABLE $table;');
          AppLogger.info('Search index uses ${candidate.label}');
          return candidate;
        } catch (_) {
          AppLogger.info('${candidate.label} is not available');
        }
      }
      return null;
    } finally {
      await db.close();
    }
  }

  /// True when [error] says an SQLite module is missing.
  static bool isMissingModuleError(Object error) =>
      error.toString().contains('no such module');
}
