import 'dart:async';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

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
        await db.execute('PRAGMA journal_mode = WAL;');
      } catch (_) {}
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
        ${DatabaseConstants.colMediaType} TEXT NOT NULL,
        ${DatabaseConstants.colMediaMimeType} TEXT NOT NULL,
        ${DatabaseConstants.colMediaSizeBytes} INTEGER NOT NULL,
        ${DatabaseConstants.colMediaDateAdded} INTEGER NOT NULL,
        ${DatabaseConstants.colMediaDateModified} INTEGER NOT NULL,
        ${DatabaseConstants.colMediaDateTaken} INTEGER,
        ${DatabaseConstants.colMediaDurationMs} INTEGER,
        ${DatabaseConstants.colMediaWidth} INTEGER,
        ${DatabaseConstants.colMediaHeight} INTEGER,
        ${DatabaseConstants.colMediaOrientation} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colMediaIsFavorite} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colMediaIsVaulted} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colMediaIsTrash} INTEGER NOT NULL DEFAULT 0,
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
        ${DatabaseConstants.colAlbumType} TEXT NOT NULL,
        ${DatabaseConstants.colAlbumRelativeFolderPath} TEXT,
        ${DatabaseConstants.colAlbumCoverMediaId} TEXT,
        ${DatabaseConstants.colAlbumCoverPath} TEXT,
        ${DatabaseConstants.colAlbumItemCount} INTEGER NOT NULL DEFAULT 0,
        ${DatabaseConstants.colAlbumDateCreated} INTEGER NOT NULL,
        ${DatabaseConstants.colAlbumDateModified} INTEGER NOT NULL,
        ${DatabaseConstants.colAlbumIsPinned} INTEGER NOT NULL DEFAULT 0,
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
        ${DatabaseConstants.colVaultMediaType} TEXT NOT NULL,
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
    } catch (_) {
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
      } catch (_) {
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
      } catch (_) {
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
