import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';

/// The values a column may hold, enforced by the database itself
/// (engineering standard §13.4, G38).
///
/// A new database gets these as `CHECK` constraints in `CREATE TABLE`. A
/// database upgraded from schema 4 gets the same rule as triggers instead:
/// SQLite can only add a `CHECK` by rebuilding the table, and with foreign
/// keys on, dropping `media_items` would delete every album and tag link.
///
/// The allowed values come from the Dart enums. **Adding an enum value needs
/// a schema migration**, because existing databases still hold the old list.
/// `test/repositories/database/column_value_rules_test.dart` fails until
/// that is done.
class ColumnValueRule {
  final String table;
  final String column;

  /// The SQL list of allowed values, for example `'image','video'` or `0,1`.
  final String allowedSql;

  const ColumnValueRule(this.table, this.column, this.allowedSql);

  /// `col IN (...)`, for a `CHECK` or a trigger condition.
  String condition([String prefix = '']) => '$prefix$column IN ($allowedSql)';

  /// The column's `CHECK` clause, for `CREATE TABLE`.
  String get check => 'CHECK (${condition()})';

  /// Name stem for this rule's triggers.
  String get triggerStem => 'check_${table}_$column';

  static String quoted(Iterable<String> values) =>
      values.map((v) => "'${v.replaceAll("'", "''")}'").join(',');

  static const String flag = '0,1';

  static final ColumnValueRule mediaType = ColumnValueRule(
    DatabaseConstants.tableMedia,
    DatabaseConstants.colMediaType,
    quoted(MediaType.values.map((t) => t.name)),
  );

  static final ColumnValueRule albumType = ColumnValueRule(
    DatabaseConstants.tableAlbums,
    DatabaseConstants.colAlbumType,
    quoted(AlbumType.values.map((t) => t.name)),
  );

  static final ColumnValueRule vaultMediaType = ColumnValueRule(
    DatabaseConstants.tableVault,
    DatabaseConstants.colVaultMediaType,
    quoted(MediaType.values.map((t) => t.name)),
  );

  static const ColumnValueRule mediaIsFavorite = ColumnValueRule(
    DatabaseConstants.tableMedia,
    DatabaseConstants.colMediaIsFavorite,
    flag,
  );

  static const ColumnValueRule mediaIsVaulted = ColumnValueRule(
    DatabaseConstants.tableMedia,
    DatabaseConstants.colMediaIsVaulted,
    flag,
  );

  static const ColumnValueRule mediaIsTrash = ColumnValueRule(
    DatabaseConstants.tableMedia,
    DatabaseConstants.colMediaIsTrash,
    flag,
  );

  static const ColumnValueRule albumIsPinned = ColumnValueRule(
    DatabaseConstants.tableAlbums,
    DatabaseConstants.colAlbumIsPinned,
    flag,
  );

  /// Every rule, in a fixed order.
  static final List<ColumnValueRule> all = <ColumnValueRule>[
    mediaType,
    mediaIsFavorite,
    mediaIsVaulted,
    mediaIsTrash,
    albumType,
    albumIsPinned,
    vaultMediaType,
  ];

  /// The two triggers that enforce this rule on a database that has no
  /// `CHECK` for it. `RAISE(ABORT)` fails the write the same way a `CHECK`
  /// does.
  List<String> get triggerSql => <String>[
    for (final event in <String>['INSERT', 'UPDATE OF $column'])
      'CREATE TRIGGER IF NOT EXISTS '
          '${triggerStem}_${event.startsWith('INSERT') ? 'insert' : 'update'} '
          'BEFORE $event ON $table FOR EACH ROW '
          'WHEN NOT (${condition('NEW.')}) '
          "BEGIN SELECT RAISE(ABORT, 'invalid value for $table.$column'); END;",
  ];
}
