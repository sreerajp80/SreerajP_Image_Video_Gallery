import 'dart:async';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
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

  DatabaseHelper._internal({String? customPath, DatabaseFactory? customFactory})
    : _customPath = customPath,
      _customFactory = customFactory;

  /// Gets or creates the singleton instance.
  factory DatabaseHelper({String? customPath, DatabaseFactory? customFactory}) {
    if (customPath != null || customFactory != null) {
      return DatabaseHelper._internal(
        customPath: customPath,
        customFactory: customFactory,
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
    final newDb = await _initDatabase();
    _database = newDb;
    return newDb;
  }

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

      return await dbFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: DatabaseConstants.schemaVersion,
          onConfigure: _onConfigure,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
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

  /// Creates initial tables, indexes, triggers, and FTS5 virtual table.
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

  /// Creates the full-text search table with graceful fallback, followed by
  /// synchronization triggers.
  ///
  /// Android OS SQLite does not include FTS5 (`no such module: fts5`), but
  /// provides FTS4 across all supported API levels. On desktop/test environments
  /// FTS5 may be available while FTS4 is not. This method tries FTS5 first, then
  /// FTS4 with unicode61 tokenizer, then plain FTS4, and finally a standard table
  /// so that the database never fails to initialize.
  Future<void> _createFtsTableAndTriggers(Database db) async {
    bool createdFts = false;

    // 1. Try FTS5 (typical in desktop/test environments)
    try {
      await db.execute('''
        CREATE VIRTUAL TABLE IF NOT EXISTS ${DatabaseConstants.tableMediaSearchFts} USING fts5(
          ${DatabaseConstants.colFtsMediaId} UNINDEXED,
          ${DatabaseConstants.colFtsDisplayName},
          ${DatabaseConstants.colFtsUserNotes},
          ${DatabaseConstants.colFtsTagsContent},
          ${DatabaseConstants.colFtsExifSearchText},
          ${DatabaseConstants.colFtsAddress},
          tokenize = 'unicode61'
        );
      ''');
      createdFts = true;
    } catch (error) {
      AppLogger.info('FTS5 is not available; trying FTS4');
      // FTS5 unavailable, try FTS4 below.
    }

    // 2. Try FTS4 with unicode61 tokenizer (standard on Android)
    if (!createdFts) {
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS ${DatabaseConstants.tableMediaSearchFts} USING fts4(
            ${DatabaseConstants.colFtsMediaId},
            ${DatabaseConstants.colFtsDisplayName},
            ${DatabaseConstants.colFtsUserNotes},
            ${DatabaseConstants.colFtsTagsContent},
            ${DatabaseConstants.colFtsExifSearchText},
            ${DatabaseConstants.colFtsAddress},
            notindexed=${DatabaseConstants.colFtsMediaId},
            tokenize=unicode61
          );
        ''');
        createdFts = true;
      } catch (error) {
        AppLogger.info('FTS4 with options is not available; trying basic FTS4');
        // Fall through to basic FTS4
      }
    }

    // 3. Try basic FTS4 without tokenizer
    if (!createdFts) {
      try {
        await db.execute('''
          CREATE VIRTUAL TABLE IF NOT EXISTS ${DatabaseConstants.tableMediaSearchFts} USING fts4(
            ${DatabaseConstants.colFtsMediaId},
            ${DatabaseConstants.colFtsDisplayName},
            ${DatabaseConstants.colFtsUserNotes},
            ${DatabaseConstants.colFtsTagsContent},
            ${DatabaseConstants.colFtsExifSearchText},
            ${DatabaseConstants.colFtsAddress},
            notindexed=${DatabaseConstants.colFtsMediaId}
          );
        ''');
        createdFts = true;
      } catch (error) {
        AppLogger.warning(
          'FTS4 is not available; search uses a plain table',
          error: error,
        );
        // Fall through to plain table
      }
    }

    // 4. Last-resort fallback: standard table so the app never crashes
    if (!createdFts) {
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
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='${DatabaseConstants.tableMediaSearchFts}';",
        );
        if (tables.isEmpty) {
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
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?;",
      <Object?>[DatabaseConstants.tableMediaSearchFts],
    );
    if (tables.isEmpty) return;

    await db.execute(
      'DELETE FROM ${DatabaseConstants.tableMediaSearchFts} '
      'WHERE rowid NOT IN ('
      'SELECT MIN(rowid) FROM ${DatabaseConstants.tableMediaSearchFts} '
      'GROUP BY ${DatabaseConstants.colFtsMediaId});',
    );
  }

  /// Indexes every media row that has no search row, filled the way the
  /// insert trigger fills it, plus the item's tag names.
  Future<void> _backfillSearchIndex(Database db) async {
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
