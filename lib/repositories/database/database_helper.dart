import 'dart:async';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/fts_support.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/column_value_rules.dart';

/// Manages SQLite database connection, schema setup, triggers, and migrations.
class DatabaseHelper {
  static DatabaseHelper? _instance;
  static Database? _database;

  /// Custom database path or in-memory override for testing.
  final String? _customPath;

  /// Database factory override (useful for ffi desktop/unit test support).
  final DatabaseFactory? _customFactory;

  /// The search modules to try, in order. Tests pass their own list.
  final List<FtsModule> _ftsCandidates;

  /// The search module this device supports, found once before the first
  /// open. Null means none works and search uses a plain table.
  FtsModule? _ftsModule;
  bool _ftsProbed = false;

  /// The search table's columns. The first is the id column.
  static const List<String> _ftsColumns = <String>[
    DatabaseConstants.colFtsMediaId,
    DatabaseConstants.colFtsDisplayName,
    DatabaseConstants.colFtsUserNotes,
    DatabaseConstants.colFtsTagsContent,
    DatabaseConstants.colFtsExifSearchText,
    DatabaseConstants.colFtsAddress,
  ];

  /// The triggers that copy `media_items` changes into the search table.
  static const List<String> _ftsTriggers = <String>[
    'trg_media_insert',
    'trg_media_update',
    'trg_media_delete',
  ];

  DatabaseHelper._internal({
    String? customPath,
    DatabaseFactory? customFactory,
    List<FtsModule>? ftsCandidates,
  }) : _customPath = customPath,
       _customFactory = customFactory,
       _ftsCandidates = ftsCandidates ?? FtsModule.preferred;

  /// Gets or creates the singleton instance.
  ///
  /// [ftsCandidates] is for tests: the search modules to try, in order.
  factory DatabaseHelper({
    String? customPath,
    DatabaseFactory? customFactory,
    List<FtsModule>? ftsCandidates,
  }) {
    if (customPath != null || customFactory != null || ftsCandidates != null) {
      return DatabaseHelper._internal(
        customPath: customPath,
        customFactory: customFactory,
        ftsCandidates: ftsCandidates,
      );
    }
    _instance ??= DatabaseHelper._internal();
    return _instance!;
  }

  /// Exposes the active [Database] instance, opening it if not already opened.
  Future<Database> get database async {
    final currentDb = _database;
    if (currentDb != null && currentDb.isOpen) {
      return currentDb;
    }
    // Callers at app start ask at the same moment; they share one open, so
    // the probe and the search table check run once.
    final opening = _opening ??= _initDatabase();
    try {
      final newDb = await opening;
      _database = newDb;
      return newDb;
    } finally {
      if (identical(_opening, opening)) _opening = null;
    }
  }

  /// The open in progress, shared by everyone who asks meanwhile.
  Future<Database>? _opening;

  /// Initializes the SQLite database and executes migrations if needed.
  Future<Database> _initDatabase() async {
    try {
      final dbFactory = _customFactory ?? databaseFactory;
      final String dbPath;

      final customPath = _customPath;
      if (customPath != null) {
        dbPath = customPath;
      } else {
        final databasesPath = await dbFactory.getDatabasesPath();
        dbPath = p.join(databasesPath, DatabaseConstants.databaseName);
      }

      if (!_ftsProbed) {
        _ftsModule = await FtsSupport.probe(
          dbFactory,
          candidates: _ftsCandidates,
        );
        _ftsProbed = true;
      }

      // Must run on its own connection before the real open: see the method.
      await _removeUnusableSearchTable(dbFactory, dbPath);

      return await dbFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: DatabaseConstants.schemaVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
          onOpen: _onOpen,
        ),
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to initialize SQLite database: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Configures WAL mode and enables foreign key constraints.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON;');
    // In-memory databases do not support WAL mode
    if (_customPath != inMemoryDatabasePath) {
      try {
        // journal_mode returns a row, so execute() fails on Android.
        await db.rawQuery('PRAGMA journal_mode=WAL;');
      } catch (error) {
        // The app still works without WAL, only slower under load.
        AppLogger.warning('WAL mode could not be enabled', error: error);
      }
    }
  }

  /// Removes a search table that this device's SQLite cannot use, with its
  /// triggers, so the next open can build a working one.
  ///
  /// Old SQLite (3.22, Android 10) keeps the row of a failed
  /// `CREATE VIRTUAL TABLE ... USING fts5` when it ran inside a transaction,
  /// as `onCreate` does. Every write to `media_items` then fails with
  /// `no such module: fts5`. `DROP TABLE` fails the same way, so the row is
  /// deleted from `sqlite_master` directly. That SQLite keeps the old table in
  /// the connection's memory until the connection closes, so this uses its
  /// own short connection; [_onOpen] then builds the table on a fresh one.
  ///
  /// On a healthy database this only reads.
  Future<void> _removeUnusableSearchTable(
    DatabaseFactory dbFactory,
    String dbPath,
  ) async {
    if (dbPath == inMemoryDatabasePath) return;
    if (!await dbFactory.databaseExists(dbPath)) return;

    const table = DatabaseConstants.tableMediaSearchFts;
    // Its own connection: a shared one could be the app's, and closing it
    // here would close the app's database too.
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    try {
      final rows = await db.rawQuery(
        "SELECT sql, rootpage FROM sqlite_master WHERE type = 'table' AND name = ?;",
        <Object?>[table],
      );
      if (rows.isEmpty) return;
      try {
        await db.rawQuery('SELECT 1 FROM $table LIMIT 0;');
        return;
      } catch (error) {
        if (!FtsSupport.isMissingModuleError(error)) rethrow;
      }

      // Only a virtual table has no storage of its own (rootpage 0). Never
      // touch anything else through writable_schema.
      final sql = (rows.single['sql'] as String? ?? '').trimLeft();
      final rootPage = rows.single['rootpage'] as int?;
      if (rootPage != 0 ||
          !sql.toUpperCase().startsWith('CREATE VIRTUAL TABLE')) {
        AppLogger.warning(
          'Search table is unusable but not a virtual table; left as is',
        );
        return;
      }

      AppLogger.warning(
        'Search table uses a module this SQLite lacks; rebuilding it',
      );
      await db.transaction((txn) async {
        for (final trigger in _ftsTriggers) {
          await txn.execute('DROP TRIGGER IF EXISTS $trigger;');
        }
        await txn.execute('PRAGMA writable_schema = ON;');
        try {
          await txn.rawDelete(
            "DELETE FROM sqlite_master WHERE type = 'table' AND name = ? "
            'AND rootpage = 0;',
            <Object?>[table],
          );
        } finally {
          await txn.execute('PRAGMA writable_schema = OFF;');
        }
      });
    } finally {
      await db.close();
    }
  }

  /// Builds the search table, its triggers and its rows when it is missing,
  /// for example after [_removeUnusableSearchTable] removed a broken one.
  Future<void> _onOpen(Database db) async {
    if (await _searchTableExists(db)) return;
    await db.transaction((txn) async {
      await _createFtsTableAndTriggers(txn);
      await _backfillSearchIndex(txn);
    });
    AppLogger.info('Search table rebuilt');
  }

  /// True when the search table has a row in the schema.
  Future<bool> _searchTableExists(DatabaseExecutor db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      <Object?>[DatabaseConstants.tableMediaSearchFts],
    );
    return tables.isNotEmpty;
  }

  /// Creates initial tables, indexes, triggers, and the search table.
  Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();

    // 1. Media Items Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableMedia} (
        ${DatabaseConstants.colId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colMediaPath} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.colMediaUri} TEXT,
        ${DatabaseConstants.colMediaDisplayName} TEXT NOT NULL,
        ${DatabaseConstants.colMediaType} TEXT NOT NULL ${ColumnValueRule.mediaType.check},
        ${DatabaseConstants.colMediaMimeType} TEXT NOT NULL,
        ${DatabaseConstants.colMediaSizeBytes} INTEGER NOT NULL,
        ${DatabaseConstants.colMediaDateAdded} INTEGER NOT NULL,
        ${DatabaseConstants.colMediaDateModified} INTEGER NOT NULL,
        ${DatabaseConstants.colMediaDateTaken} INTEGER,
        ${DatabaseConstants.colMediaDurationMs} INTEGER,
        ${DatabaseConstants.colMediaWidth} INTEGER,
        ${DatabaseConstants.colMediaHeight} INTEGER,
        ${DatabaseConstants.colMediaOrientation} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colMediaIsFavorite} INTEGER NOT NULL DEFAULT 0 ${ColumnValueRule.mediaIsFavorite.check},
        ${DatabaseConstants.colMediaIsVaulted} INTEGER NOT NULL DEFAULT 0 ${ColumnValueRule.mediaIsVaulted.check},
        ${DatabaseConstants.colMediaIsTrash} INTEGER NOT NULL DEFAULT 0 ${ColumnValueRule.mediaIsTrash.check},
        ${DatabaseConstants.colMediaIsOutOfReach} INTEGER NOT NULL DEFAULT 0 ${ColumnValueRule.mediaIsOutOfReach.check},
        ${DatabaseConstants.colMediaExifJson} TEXT,
        ${DatabaseConstants.colMediaUserNotes} TEXT,
        ${DatabaseConstants.colMediaSha256Hash} TEXT,
        ${DatabaseConstants.colMediaPHash} TEXT,
        ${DatabaseConstants.colMediaLatitude} REAL,
        ${DatabaseConstants.colMediaLongitude} REAL,
        ${DatabaseConstants.colMediaAddress} TEXT
      );
    ''');

    // 2. Albums Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableAlbums} (
        ${DatabaseConstants.colId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colName} TEXT NOT NULL,
        ${DatabaseConstants.colAlbumType} TEXT NOT NULL ${ColumnValueRule.albumType.check},
        ${DatabaseConstants.colAlbumRelativeFolderPath} TEXT,
        ${DatabaseConstants.colAlbumCoverMediaId} TEXT,
        ${DatabaseConstants.colAlbumCoverPath} TEXT,
        ${DatabaseConstants.colAlbumItemCount} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colAlbumDateCreated} INTEGER NOT NULL,
        ${DatabaseConstants.colAlbumDateModified} INTEGER NOT NULL,
        ${DatabaseConstants.colAlbumIsPinned} INTEGER NOT NULL DEFAULT 0 ${ColumnValueRule.albumIsPinned.check},
        ${DatabaseConstants.colAlbumSortOrder} INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // 3. Album Media Entries (Many-to-Many Join for Virtual Albums)
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableAlbumMedia} (
        ${DatabaseConstants.colAlbumMediaAlbumId} TEXT NOT NULL,
        ${DatabaseConstants.colAlbumMediaMediaId} TEXT NOT NULL,
        ${DatabaseConstants.colAlbumMediaPosition} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colAlbumMediaDateAdded} INTEGER NOT NULL,
        PRIMARY KEY (${DatabaseConstants.colAlbumMediaAlbumId}, ${DatabaseConstants.colAlbumMediaMediaId}),
        FOREIGN KEY (${DatabaseConstants.colAlbumMediaAlbumId}) 
          REFERENCES ${DatabaseConstants.tableAlbums} (${DatabaseConstants.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.colAlbumMediaMediaId}) 
          REFERENCES ${DatabaseConstants.tableMedia} (${DatabaseConstants.colId}) ON DELETE CASCADE
      );
    ''');

    // 4. Tags Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableTags} (
        ${DatabaseConstants.colId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colName} TEXT NOT NULL UNIQUE,
        ${DatabaseConstants.colTagColorValue} INTEGER NOT NULL,
        ${DatabaseConstants.colTagDescription} TEXT,
        ${DatabaseConstants.colTagItemCount} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colTagDateCreated} INTEGER NOT NULL
      );
    ''');

    // 5. Media Tag Entries (Many-to-Many Join)
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableMediaTags} (
        ${DatabaseConstants.colMediaTagMediaId} TEXT NOT NULL,
        ${DatabaseConstants.colMediaTagTagId} TEXT NOT NULL,
        ${DatabaseConstants.colMediaTagDateTagged} INTEGER NOT NULL,
        PRIMARY KEY (${DatabaseConstants.colMediaTagMediaId}, ${DatabaseConstants.colMediaTagTagId}),
        FOREIGN KEY (${DatabaseConstants.colMediaTagMediaId}) 
          REFERENCES ${DatabaseConstants.tableMedia} (${DatabaseConstants.colId}) ON DELETE CASCADE,
        FOREIGN KEY (${DatabaseConstants.colMediaTagTagId}) 
          REFERENCES ${DatabaseConstants.tableTags} (${DatabaseConstants.colId}) ON DELETE CASCADE
      );
    ''');

    // 6. Vault Items Table
    batch.execute('''
      CREATE TABLE ${DatabaseConstants.tableVault} (
        ${DatabaseConstants.colId} TEXT PRIMARY KEY,
        ${DatabaseConstants.colVaultOriginalPath} TEXT NOT NULL,
        ${DatabaseConstants.colVaultOriginalFilename} TEXT NOT NULL,
        ${DatabaseConstants.colVaultEncryptedFilename} TEXT NOT NULL,
        ${DatabaseConstants.colVaultEncryptedThumbnailFilename} TEXT,
        ${DatabaseConstants.colVaultMediaType} TEXT NOT NULL ${ColumnValueRule.vaultMediaType.check},
        ${DatabaseConstants.colVaultMimeType} TEXT NOT NULL,
        ${DatabaseConstants.colVaultSizeBytes} INTEGER NOT NULL,
        ${DatabaseConstants.colVaultIv} TEXT NOT NULL,
        ${DatabaseConstants.colVaultThumbnailIv} TEXT,
        ${DatabaseConstants.colVaultAuthTag} TEXT,
        ${DatabaseConstants.colVaultDateVaulted} INTEGER NOT NULL,
        ${DatabaseConstants.colVaultDateTaken} INTEGER,
        ${DatabaseConstants.colVaultWidth} INTEGER,
        ${DatabaseConstants.colVaultHeight} INTEGER,
        ${DatabaseConstants.colVaultDurationMs} INTEGER,
        ${DatabaseConstants.colVaultTagsJson} TEXT,
        ${DatabaseConstants.colVaultNotes} TEXT
      );
    ''');

    // Indexes for query performance
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_date_taken ON ${DatabaseConstants.tableMedia} (${DatabaseConstants.colMediaDateTaken} DESC);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_date_added ON ${DatabaseConstants.tableMedia} (${DatabaseConstants.colMediaDateAdded} DESC);',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_type ON ${DatabaseConstants.tableMedia} (${DatabaseConstants.colMediaType});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_favorite ON ${DatabaseConstants.tableMedia} (${DatabaseConstants.colMediaIsFavorite});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_vaulted ON ${DatabaseConstants.tableMedia} (${DatabaseConstants.colMediaIsVaulted});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_trash ON ${DatabaseConstants.tableMedia} (${DatabaseConstants.colMediaIsTrash});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_album_media_album_id ON ${DatabaseConstants.tableAlbumMedia} (${DatabaseConstants.colAlbumMediaAlbumId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_tags_tag_id ON ${DatabaseConstants.tableMediaTags} (${DatabaseConstants.colMediaTagTagId});',
    );
    batch.execute(
      'CREATE INDEX IF NOT EXISTS idx_media_tags_media_id ON ${DatabaseConstants.tableMediaTags} (${DatabaseConstants.colMediaTagMediaId});',
    );

    await batch.commit(noResult: true);

    // 7. Full-Text Search Table and Triggers (with FTS5/FTS4 fallback)
    await _createFtsTableAndTriggers(db);

    // 8. Triggers that keep the saved album and tag counts right
    await _createCountTriggers(db);

    // 9. What was sent to which phone over Wi-Fi
    await _createSyncMarksTable(db);
  }

  /// The table that remembers which files went to which other phone.
  ///
  /// A mark goes with its photo: deleting the media row deletes its marks.
  Future<void> _createSyncMarksTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableSyncMarks} (
        ${DatabaseConstants.colSyncMarkMediaId} TEXT NOT NULL,
        ${DatabaseConstants.colSyncMarkPeerId} TEXT NOT NULL,
        ${DatabaseConstants.colSyncMarkSha256} TEXT NOT NULL,
        ${DatabaseConstants.colSyncMarkSizeBytes} INTEGER NOT NULL,
        ${DatabaseConstants.colSyncMarkSentAt} INTEGER NOT NULL,
        PRIMARY KEY (${DatabaseConstants.colSyncMarkMediaId}, ${DatabaseConstants.colSyncMarkPeerId}),
        FOREIGN KEY (${DatabaseConstants.colSyncMarkMediaId})
          REFERENCES ${DatabaseConstants.tableMedia} (${DatabaseConstants.colId})
          ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_sync_marks_peer ON '
      '${DatabaseConstants.tableSyncMarks} (${DatabaseConstants.colSyncMarkPeerId});',
    );
  }

  /// SQL for the number of visible photos linked to one album.
  ///
  /// [albumIdSql] is the SQL that names the album, for example `new.id`.
  /// Visible uses the same rule as the screens
  /// ([DatabaseConstants.visibleMediaCondition]).
  static String _visibleAlbumCountSql(String albumIdSql) =>
      '''
      (SELECT COUNT(*)
         FROM ${DatabaseConstants.tableAlbumMedia} am
         INNER JOIN ${DatabaseConstants.tableMedia} m
           ON m.${DatabaseConstants.colId} = am.${DatabaseConstants.colAlbumMediaMediaId}
        WHERE am.${DatabaseConstants.colAlbumMediaAlbumId} = $albumIdSql
          AND ${DatabaseConstants.visibleMediaCondition('m')})''';

  /// SQL for the number of visible photos linked to one tag.
  static String _visibleTagCountSql(String tagIdSql) =>
      '''
      (SELECT COUNT(*)
         FROM ${DatabaseConstants.tableMediaTags} mt
         INNER JOIN ${DatabaseConstants.tableMedia} m
           ON m.${DatabaseConstants.colId} = mt.${DatabaseConstants.colMediaTagMediaId}
        WHERE mt.${DatabaseConstants.colMediaTagTagId} = $tagIdSql
          AND ${DatabaseConstants.visibleMediaCondition('m')})''';

  /// Creates the index and triggers that keep `item_count` on `albums` and
  /// `tags` equal to the number of visible linked photos (schema 8).
  ///
  /// The database owns this number: no Dart code needs to recount, and a
  /// whole-row write from Dart cannot leave a wrong value behind. SQLite
  /// does not let a trigger fire itself again (`recursive_triggers` is off),
  /// so the guard triggers cannot loop.
  Future<void> _createCountTriggers(Database db) async {
    const albums = DatabaseConstants.tableAlbums;
    const tags = DatabaseConstants.tableTags;
    const albumLinks = DatabaseConstants.tableAlbumMedia;
    const tagLinks = DatabaseConstants.tableMediaTags;
    const media = DatabaseConstants.tableMedia;
    const id = DatabaseConstants.colId;
    const albumCount = DatabaseConstants.colAlbumItemCount;
    const tagCount = DatabaseConstants.colTagItemCount;
    const linkAlbumId = DatabaseConstants.colAlbumMediaAlbumId;
    const linkAlbumMediaId = DatabaseConstants.colAlbumMediaMediaId;
    const linkTagId = DatabaseConstants.colMediaTagTagId;
    const linkTagMediaId = DatabaseConstants.colMediaTagMediaId;
    const vaulted = DatabaseConstants.colMediaIsVaulted;
    const trash = DatabaseConstants.colMediaIsTrash;
    const outOfReach = DatabaseConstants.colMediaIsOutOfReach;

    // The visibility trigger finds a photo's albums by media id; the
    // primary key starts with album_id, so it needs its own index.
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_album_media_media_id '
      'ON $albumLinks ($linkAlbumMediaId);',
    );

    // A photo added to or removed from an album, including removals by a
    // foreign key cascade when the photo or album is deleted.
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_album_count_link_insert
      AFTER INSERT ON $albumLinks
      BEGIN
        UPDATE $albums SET $albumCount = ${_visibleAlbumCountSql('new.$linkAlbumId')}
        WHERE $id = new.$linkAlbumId;
      END;
    ''');
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_album_count_link_delete
      AFTER DELETE ON $albumLinks
      BEGIN
        UPDATE $albums SET $albumCount = ${_visibleAlbumCountSql('old.$linkAlbumId')}
        WHERE $id = old.$linkAlbumId;
      END;
    ''');

    // The same for tags.
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_tag_count_link_insert
      AFTER INSERT ON $tagLinks
      BEGIN
        UPDATE $tags SET $tagCount = ${_visibleTagCountSql('new.$linkTagId')}
        WHERE $id = new.$linkTagId;
      END;
    ''');
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_tag_count_link_delete
      AFTER DELETE ON $tagLinks
      BEGIN
        UPDATE $tags SET $tagCount = ${_visibleTagCountSql('old.$linkTagId')}
        WHERE $id = old.$linkTagId;
      END;
    ''');

    // A photo moved to or from the trash or vault, or hidden or shown by
    // limited media access. Runs only when visibility really changed.
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_count_media_visibility
      AFTER UPDATE OF $vaulted, $trash, $outOfReach ON $media
      WHEN (old.$vaulted = 0 AND old.$trash = 0 AND old.$outOfReach = 0)
        IS NOT (new.$vaulted = 0 AND new.$trash = 0 AND new.$outOfReach = 0)
      BEGIN
        UPDATE $albums SET $albumCount = ${_visibleAlbumCountSql('$albums.$id')}
        WHERE $id IN (
          SELECT $linkAlbumId FROM $albumLinks WHERE $linkAlbumMediaId = new.$id
        );
        UPDATE $tags SET $tagCount = ${_visibleTagCountSql('$tags.$id')}
        WHERE $id IN (
          SELECT $linkTagId FROM $tagLinks WHERE $linkTagMediaId = new.$id
        );
      END;
    ''');

    // Guards: Dart writes whole rows (count included) from the model. These
    // put the true count back whenever the written one is wrong.
    for (final event in ['INSERT', 'UPDATE OF $albumCount']) {
      final name = event == 'INSERT' ? 'insert' : 'update';
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_album_count_guard_$name
        AFTER $event ON $albums
        WHEN new.$albumCount IS NOT ${_visibleAlbumCountSql('new.$id')}
        BEGIN
          UPDATE $albums SET $albumCount = ${_visibleAlbumCountSql('new.$id')}
          WHERE $id = new.$id;
        END;
      ''');
    }
    for (final event in ['INSERT', 'UPDATE OF $tagCount']) {
      final name = event == 'INSERT' ? 'insert' : 'update';
      await db.execute('''
        CREATE TRIGGER IF NOT EXISTS trg_tag_count_guard_$name
        AFTER $event ON $tags
        WHEN new.$tagCount IS NOT ${_visibleTagCountSql('new.$id')}
        BEGIN
          UPDATE $tags SET $tagCount = ${_visibleTagCountSql('new.$id')}
          WHERE $id = new.$id;
        END;
      ''');
    }
  }

  /// Sets every saved album and tag count to its visible count, once, for a
  /// database upgraded to schema 8.
  Future<void> _recountAllAlbumsAndTags(Database db) async {
    await db.execute(
      'UPDATE ${DatabaseConstants.tableAlbums} '
      'SET ${DatabaseConstants.colAlbumItemCount} = '
      '${_visibleAlbumCountSql('${DatabaseConstants.tableAlbums}.${DatabaseConstants.colId}')};',
    );
    await db.execute(
      'UPDATE ${DatabaseConstants.tableTags} '
      'SET ${DatabaseConstants.colTagItemCount} = '
      '${_visibleTagCountSql('${DatabaseConstants.tableTags}.${DatabaseConstants.colId}')};',
    );
  }

  /// Creates the full-text search table, followed by its sync triggers.
  ///
  /// Uses the module found by [FtsSupport.probe] before the database was
  /// opened, or a plain table when no module works. It never tries a module
  /// here and catches the failure: on old SQLite a failed
  /// `CREATE VIRTUAL TABLE` inside a transaction leaves a broken table behind
  /// (see [_removeUnusableSearchTable]).
  Future<void> _createFtsTableAndTriggers(DatabaseExecutor db) async {
    final module = _ftsModule;
    if (module != null) {
      await db.execute(
        module.createTableSql(
          DatabaseConstants.tableMediaSearchFts,
          _ftsColumns,
        ),
      );
    } else {
      AppLogger.warning('No full-text module; search uses a plain table');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS ${DatabaseConstants.tableMediaSearchFts} (
          ${DatabaseConstants.colFtsMediaId} TEXT PRIMARY KEY,
          ${DatabaseConstants.colFtsDisplayName} TEXT,
          ${DatabaseConstants.colFtsUserNotes} TEXT,
          ${DatabaseConstants.colFtsTagsContent} TEXT,
          ${DatabaseConstants.colFtsExifSearchText} TEXT,
          ${DatabaseConstants.colFtsAddress} TEXT
        );
      ''');
    }

    // Triggers for automatic FTS synchronization on media insert/update/delete
    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_media_insert AFTER INSERT ON ${DatabaseConstants.tableMedia}
      BEGIN
        INSERT INTO ${DatabaseConstants.tableMediaSearchFts} (
          ${DatabaseConstants.colFtsMediaId},
          ${DatabaseConstants.colFtsDisplayName},
          ${DatabaseConstants.colFtsUserNotes},
          ${DatabaseConstants.colFtsTagsContent},
          ${DatabaseConstants.colFtsExifSearchText},
          ${DatabaseConstants.colFtsAddress}
        ) VALUES (
          new.${DatabaseConstants.colId},
          new.${DatabaseConstants.colMediaDisplayName},
          COALESCE(new.${DatabaseConstants.colMediaUserNotes}, ''),
          '',
          COALESCE(new.${DatabaseConstants.colMediaExifJson}, ''),
          COALESCE(new.${DatabaseConstants.colMediaAddress}, '')
        );
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_media_update AFTER UPDATE ON ${DatabaseConstants.tableMedia}
      BEGIN
        UPDATE ${DatabaseConstants.tableMediaSearchFts}
        SET
          ${DatabaseConstants.colFtsDisplayName} = new.${DatabaseConstants.colMediaDisplayName},
          ${DatabaseConstants.colFtsUserNotes} = COALESCE(new.${DatabaseConstants.colMediaUserNotes}, ''),
          ${DatabaseConstants.colFtsExifSearchText} = COALESCE(new.${DatabaseConstants.colMediaExifJson}, ''),
          ${DatabaseConstants.colFtsAddress} = COALESCE(new.${DatabaseConstants.colMediaAddress}, '')
        WHERE ${DatabaseConstants.colFtsMediaId} = new.${DatabaseConstants.colId};
      END;
    ''');

    await db.execute('''
      CREATE TRIGGER IF NOT EXISTS trg_media_delete AFTER DELETE ON ${DatabaseConstants.tableMedia}
      BEGIN
        DELETE FROM ${DatabaseConstants.tableMediaSearchFts}
        WHERE ${DatabaseConstants.colFtsMediaId} = old.${DatabaseConstants.colId};
      END;
    ''');
  }

  /// Handles schema migrations between versions.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      // v2: the encrypted preview needs its own initialisation vector. Every
      // file is encrypted under a fresh IV, so the payload's cannot decrypt
      // the preview stored beside it. Existing rows get null, which the
      // reader treats as "no preview" rather than showing the wrong bytes.
      if (oldVersion < 2) {
        await db.execute(
          'ALTER TABLE ${DatabaseConstants.tableVault} '
          'ADD COLUMN ${DatabaseConstants.colVaultThumbnailIv} TEXT;',
        );
      }

      // v3: ensure full-text search table and triggers exist with FTS4/FTS5
      // fallback support. If a previous migration or initial open failed
      // due to missing FTS5, this recreates the search index properly.
      if (oldVersion < 3) {
        if (!await _searchTableExists(db)) {
          await _createFtsTableAndTriggers(db);
        }
      }

      // v4: v3 could create the search table empty, and only the insert
      // trigger adds rows, so photos from before it never became searchable.
      // Adds a row for every photo that has none; a healthy index gains nothing.
      if (oldVersion < 4) {
        await _backfillSearchIndex(db);
      }

      // v5: the allowed values of enum and 0/1 columns (G38). A new database
      // has them as CHECK constraints; an existing one gets triggers, because
      // adding a CHECK means rebuilding the table, and dropping media_items
      // with foreign keys on would delete every album and tag link.
      if (oldVersion < 5) {
        await _addValueCheckTriggers(db);
      }

      // v6: the scan used to save with REPLACE, which fires the insert trigger
      // but not the delete one, so every full rescan left another search row
      // for each photo and searches showed it more than once. The scan no
      // longer does that; this drops the extra copies, keeping one per photo.
      if (oldVersion < 6) {
        await _removeDuplicateSearchRows(db);
      }

      // v7: a flag for items Android does not currently let the app see
      // (limited or no media access). Every old row starts visible; the next
      // scan sets the flag. Its 0/1 rule is added as triggers, like v5.
      if (oldVersion < 7) {
        await db.execute(
          'ALTER TABLE ${DatabaseConstants.tableMedia} '
          'ADD COLUMN ${DatabaseConstants.colMediaIsOutOfReach} '
          'INTEGER NOT NULL DEFAULT 0;',
        );
        for (final sql in ColumnValueRule.mediaIsOutOfReach.triggerSql) {
          await db.execute(sql);
        }
      }

      // v8: the saved album and tag counts included photos in the trash, in
      // the vault and out of reach, and went stale when a photo's visibility
      // changed. Triggers now keep them right; this fixes the old values once.
      if (oldVersion < 8) {
        await _createCountTriggers(db);
        await _recountAllAlbumsAndTags(db);
      }

      // v9: Device Sync remembers which files went to which other phone, so
      // the next send can carry only the rest. A new, empty table.
      if (oldVersion < 9) {
        await _createSyncMarksTable(db);
      }
    } catch (e, st) {
      throw DatabaseMigrationException(
        'Failed to migrate database from version $oldVersion to $newVersion: $e',
        fromVersion: oldVersion,
        toVersion: newVersion,
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Adds a pair of triggers for every [ColumnValueRule], so an upgraded
  /// database refuses the same values a new one refuses by `CHECK`.
  Future<void> _addValueCheckTriggers(Database db) async {
    for (final rule in ColumnValueRule.all) {
      if (ColumnValueRule.addedAfterV5.contains(rule)) continue;
      for (final sql in rule.triggerSql) {
        await db.execute(sql);
      }
    }
  }

  /// Keeps one search row per photo and deletes the rest.
  ///
  /// Does nothing when the search table does not exist, which happens on a
  /// device whose SQLite had neither FTS5 nor FTS4.
  Future<void> _removeDuplicateSearchRows(Database db) async {
    if (!await _searchTableExists(db)) return;

    await db.execute(
      'DELETE FROM ${DatabaseConstants.tableMediaSearchFts} '
      'WHERE rowid NOT IN ('
      'SELECT MIN(rowid) FROM ${DatabaseConstants.tableMediaSearchFts} '
      'GROUP BY ${DatabaseConstants.colFtsMediaId});',
    );
  }

  /// Indexes every media row that has no search row, filled the way the
  /// insert trigger fills it, plus the item's tag names.
  ///
  /// Does nothing when the search table is missing; [_onOpen] builds and
  /// fills it then.
  Future<void> _backfillSearchIndex(DatabaseExecutor db) async {
    if (!await _searchTableExists(db)) return;
    await db.execute('''
      INSERT INTO ${DatabaseConstants.tableMediaSearchFts} (
        ${DatabaseConstants.colFtsMediaId},
        ${DatabaseConstants.colFtsDisplayName},
        ${DatabaseConstants.colFtsUserNotes},
        ${DatabaseConstants.colFtsTagsContent},
        ${DatabaseConstants.colFtsExifSearchText},
        ${DatabaseConstants.colFtsAddress}
      )
      SELECT
        m.${DatabaseConstants.colId},
        m.${DatabaseConstants.colMediaDisplayName},
        COALESCE(m.${DatabaseConstants.colMediaUserNotes}, ''),
        COALESCE((
          SELECT group_concat(t.${DatabaseConstants.colName}, ' ')
          FROM ${DatabaseConstants.tableTags} t
          INNER JOIN ${DatabaseConstants.tableMediaTags} mt
            ON t.${DatabaseConstants.colId} = mt.${DatabaseConstants.colMediaTagTagId}
          WHERE mt.${DatabaseConstants.colMediaTagMediaId} = m.${DatabaseConstants.colId}
        ), ''),
        COALESCE(m.${DatabaseConstants.colMediaExifJson}, ''),
        COALESCE(m.${DatabaseConstants.colMediaAddress}, '')
      FROM ${DatabaseConstants.tableMedia} m
      WHERE m.${DatabaseConstants.colId} NOT IN (
        SELECT ${DatabaseConstants.colFtsMediaId}
        FROM ${DatabaseConstants.tableMediaSearchFts}
      );
    ''');
  }

  /// Closes and resets the database instance.
  Future<void> close() async {
    final currentDb = _database;
    if (currentDb != null && currentDb.isOpen) {
      await currentDb.close();
      _database = null;
    }
  }

  /// Closes database and deletes database file from storage.
  Future<void> deleteDatabaseFile() async {
    await close();
    final dbFactory = _customFactory ?? databaseFactory;
    final customPath = _customPath;
    final String dbPath;
    if (customPath != null) {
      dbPath = customPath;
    } else {
      final databasesPath = await dbFactory.getDatabasesPath();
      dbPath = p.join(databasesPath, DatabaseConstants.databaseName);
    }
    await dbFactory.deleteDatabase(dbPath);
  }
}
