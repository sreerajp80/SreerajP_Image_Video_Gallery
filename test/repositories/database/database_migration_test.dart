import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:path/path.dart' as p;
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// The schema as version 1 shipped it, written out by hand on purpose.
///
/// These must stay literal. Built from [DatabaseConstants], a later rename would
/// quietly change the old schema too, and the test would stop testing an old
/// database at all.
const List<String> _v1Tables = <String>[
  '''CREATE TABLE media_items (
    id TEXT PRIMARY KEY, path TEXT NOT NULL UNIQUE, uri TEXT,
    display_name TEXT NOT NULL, media_type TEXT NOT NULL,
    mime_type TEXT NOT NULL, size_bytes INTEGER NOT NULL,
    date_added INTEGER NOT NULL, date_modified INTEGER NOT NULL,
    date_taken INTEGER, duration_ms INTEGER, width INTEGER, height INTEGER,
    orientation INTEGER NOT NULL DEFAULT 0,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    is_vaulted INTEGER NOT NULL DEFAULT 0,
    is_trash INTEGER NOT NULL DEFAULT 0,
    exif_json TEXT, user_notes TEXT, sha256_hash TEXT, p_hash TEXT,
    latitude REAL, longitude REAL, address TEXT);''',
  '''CREATE TABLE albums (
    id TEXT PRIMARY KEY, name TEXT NOT NULL, album_type TEXT NOT NULL,
    relative_folder_path TEXT, cover_media_id TEXT, cover_path TEXT,
    item_count INTEGER NOT NULL DEFAULT 0, date_created INTEGER NOT NULL,
    date_modified INTEGER NOT NULL, is_pinned INTEGER NOT NULL DEFAULT 0,
    sort_order INTEGER NOT NULL DEFAULT 0);''',
  '''CREATE TABLE album_media_entries (
    album_id TEXT NOT NULL, media_id TEXT NOT NULL,
    position INTEGER NOT NULL DEFAULT 0, date_added INTEGER NOT NULL,
    PRIMARY KEY (album_id, media_id),
    FOREIGN KEY (album_id) REFERENCES albums (id) ON DELETE CASCADE,
    FOREIGN KEY (media_id) REFERENCES media_items (id) ON DELETE CASCADE);''',
  '''CREATE TABLE tags (
    id TEXT PRIMARY KEY, name TEXT NOT NULL UNIQUE,
    color_value INTEGER NOT NULL, description TEXT,
    item_count INTEGER NOT NULL DEFAULT 0, date_created INTEGER NOT NULL);''',
  '''CREATE TABLE media_tag_entries (
    media_id TEXT NOT NULL, tag_id TEXT NOT NULL,
    date_tagged INTEGER NOT NULL, PRIMARY KEY (media_id, tag_id),
    FOREIGN KEY (media_id) REFERENCES media_items (id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags (id) ON DELETE CASCADE);''',
  '''CREATE TABLE vault_items (
    id TEXT PRIMARY KEY, original_path TEXT NOT NULL,
    original_filename TEXT NOT NULL, encrypted_filename TEXT NOT NULL,
    encrypted_thumbnail_filename TEXT, media_type TEXT NOT NULL,
    mime_type TEXT NOT NULL, size_bytes INTEGER NOT NULL, iv TEXT NOT NULL,
    auth_tag TEXT, date_vaulted INTEGER NOT NULL, date_taken INTEGER,
    width INTEGER, height INTEGER, duration_ms INTEGER, tags_json TEXT,
    notes TEXT);''',
];

/// A search table of the plain kind, which any SQLite build can create.
const String _plainSearchTable = '''CREATE TABLE media_search_fts (
    media_id TEXT PRIMARY KEY, display_name TEXT, user_notes TEXT,
    tags_content TEXT, exif_search_text TEXT, address TEXT);''';

const Map<String, Object?> _mediaRow = <String, Object?>{
  'id': 'm1',
  'path': '/storage/emulated/0/DCIM/a.jpg',
  'display_name': 'a.jpg',
  'media_type': 'image',
  'mime_type': 'image/jpeg',
  'size_bytes': 10,
  'date_added': 1,
  'date_modified': 1,
};

const Map<String, Object?> _vaultRow = <String, Object?>{
  'id': 'v1',
  'original_path': '/storage/emulated/0/DCIM/b.jpg',
  'original_filename': 'b.jpg',
  'encrypted_filename': 'b.enc',
  'encrypted_thumbnail_filename': 'b.thumb.enc',
  'media_type': 'image',
  'mime_type': 'image/jpeg',
  'size_bytes': 20,
  'iv': 'payload-iv',
  'date_vaulted': 2,
};

void main() {
  setUpAll(sqfliteFfiInit);

  late Directory tempDir;
  late String dbPath;
  DatabaseHelper? helper;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('db_migration_test');
    dbPath = p.join(tempDir.path, 'old.db');
  });

  tearDown(() async {
    await helper?.close();
    helper = null;
    tempDir.deleteSync(recursive: true);
  });

  /// Writes a database file at an old version, then closes it.
  Future<void> seedOldDatabase({
    required int version,
    required bool withSearchTable,
    Future<void> Function(Database db)? seed,
  }) async {
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onCreate: (db, _) async {
          for (final sql in _v1Tables) {
            await db.execute(sql);
          }
          if (version >= 2) {
            await db.execute(
              'ALTER TABLE vault_items ADD COLUMN thumbnail_iv TEXT;',
            );
          }
          if (withSearchTable) await db.execute(_plainSearchTable);
          await db.insert('media_items', _mediaRow);
          await db.insert('vault_items', _vaultRow);
          await seed?.call(db);
        },
      ),
    );
    await db.close();
  }

  /// Opens [path] the way the app does, which runs any pending upgrade.
  Future<Database> openWithHelper(String path) async {
    helper = DatabaseHelper(
      customPath: path,
      customFactory: databaseFactoryFfi,
    );
    return helper!.database;
  }

  Future<Map<String, Set<String>>> columnsOf(Database db) async {
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' "
      "AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'media_search_fts%';",
    );
    final result = <String, Set<String>>{};
    for (final table in tables) {
      final name = table['name']! as String;
      final columns = await db.rawQuery('PRAGMA table_info($name);');
      result[name] = columns.map((c) => c['name']! as String).toSet();
    }
    return result;
  }

  test('v1 to current adds the thumbnail IV and keeps old rows', () async {
    await seedOldDatabase(version: 1, withSearchTable: true);

    final db = await openWithHelper(dbPath);

    expect(await db.getVersion(), DatabaseConstants.schemaVersion);
    final vault = await db.query(DatabaseConstants.tableVault);
    expect(vault, hasLength(1));
    expect(vault.single['iv'], 'payload-iv');
    expect(vault.single[DatabaseConstants.colVaultThumbnailIv], isNull);
    expect(await db.query(DatabaseConstants.tableMedia), hasLength(1));
  });

  test('v1 with no search table gets one, and its triggers work', () async {
    await seedOldDatabase(version: 1, withSearchTable: false);

    final db = await openWithHelper(dbPath);

    await db.insert(DatabaseConstants.tableMedia, <String, Object?>{
      ..._mediaRow,
      'id': 'm2',
      'path': '/storage/emulated/0/DCIM/new.jpg',
      'display_name': 'new.jpg',
    });
    final indexed = await db.query(
      DatabaseConstants.tableMediaSearchFts,
      where: '${DatabaseConstants.colFtsMediaId} = ?',
      whereArgs: <Object?>['m2'],
    );
    expect(indexed, hasLength(1));
  });

  test('v1 with no search table indexes the photos it already had', () async {
    await seedOldDatabase(
      version: 1,
      withSearchTable: false,
      seed: (db) async {
        await db.update(
          'media_items',
          <String, Object?>{'user_notes': 'beach trip'},
          where: 'id = ?',
          whereArgs: <Object?>['m1'],
        );
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
      },
    );

    final db = await openWithHelper(dbPath);

    final rows = await db.query(
      DatabaseConstants.tableMediaSearchFts,
      where: '${DatabaseConstants.colFtsMediaId} = ?',
      whereArgs: <Object?>['m1'],
    );
    expect(rows, hasLength(1));
    expect(rows.single[DatabaseConstants.colFtsDisplayName], 'a.jpg');
    expect(rows.single[DatabaseConstants.colFtsUserNotes], 'beach trip');
    expect(rows.single[DatabaseConstants.colFtsTagsContent], 'holiday');
  });

  test('v2 with a search table leaves that table and its rows alone', () async {
    await seedOldDatabase(
      version: 2,
      withSearchTable: true,
      seed: (db) async {
        await db.insert('media_search_fts', <String, Object?>{
          'media_id': 'm1',
          'display_name': 'kept.jpg',
        });
        await db.update(
          'vault_items',
          <String, Object?>{'thumbnail_iv': 'thumb-iv'},
          where: 'id = ?',
          whereArgs: <Object?>['v1'],
        );
      },
    );

    final db = await openWithHelper(dbPath);

    expect(await db.getVersion(), DatabaseConstants.schemaVersion);
    final search = await db.query(DatabaseConstants.tableMediaSearchFts);
    expect(search.single[DatabaseConstants.colFtsDisplayName], 'kept.jpg');
    final vault = await db.query(DatabaseConstants.tableVault);
    expect(vault.single[DatabaseConstants.colVaultThumbnailIv], 'thumb-iv');
  });

  test('v3 with a full search index gains no rows and keeps its own', () async {
    await seedOldDatabase(
      version: 3,
      withSearchTable: true,
      seed: (db) async {
        await db.insert('media_search_fts', <String, Object?>{
          'media_id': 'm1',
          'display_name': 'kept.jpg',
          'tags_content': 'holiday',
        });
      },
    );

    final db = await openWithHelper(dbPath);

    final search = await db.query(DatabaseConstants.tableMediaSearchFts);
    expect(search, hasLength(1));
    expect(search.single[DatabaseConstants.colFtsDisplayName], 'kept.jpg');
    expect(search.single[DatabaseConstants.colFtsTagsContent], 'holiday');
  });

  test('v5 to v6 keeps one search row per photo', () async {
    await seedOldDatabase(
      version: 5,
      withSearchTable: true,
      seed: (db) async {
        // A real FTS table has no unique key, which is how the old REPLACE
        // save could leave copies. The plain stand-in table has one, so it is
        // swapped for a keyless one here.
        await db.execute('DROP TABLE media_search_fts;');
        await db.execute(
          'CREATE TABLE media_search_fts (media_id TEXT, display_name TEXT, '
          'user_notes TEXT, tags_content TEXT, exif_search_text TEXT, '
          'address TEXT);',
        );
        for (final name in <String>['first.jpg', 'copy.jpg', 'copy.jpg']) {
          await db.insert('media_search_fts', <String, Object?>{
            'media_id': 'm1',
            'display_name': name,
          });
        }
        await db.insert('media_search_fts', <String, Object?>{
          'media_id': 'm2',
          'display_name': 'other.jpg',
        });
      },
    );

    final db = await openWithHelper(dbPath);

    final search = await db.query(
      DatabaseConstants.tableMediaSearchFts,
      orderBy: DatabaseConstants.colFtsMediaId,
    );
    expect(search, hasLength(2));
    expect(search.first[DatabaseConstants.colFtsDisplayName], 'first.jpg');
    expect(search.last[DatabaseConstants.colFtsMediaId], 'm2');
  });

  test('v6 to v7 adds the out-of-reach flag, 0 for old rows', () async {
    await seedOldDatabase(version: 6, withSearchTable: true);

    final db = await openWithHelper(dbPath);

    final row = (await db.query(DatabaseConstants.tableMedia)).single;
    expect(row[DatabaseConstants.colMediaIsOutOfReach], 0);
    await expectLater(
      db.update(DatabaseConstants.tableMedia, <String, Object?>{
        DatabaseConstants.colMediaIsOutOfReach: 2,
      }),
      throwsA(isA<DatabaseException>()),
    );
  });

  test('v7 to v8 fixes stale album and tag counts', () async {
    await seedOldDatabase(
      version: 7,
      withSearchTable: true,
      seed: (db) async {
        await db.execute(
          'ALTER TABLE media_items '
          'ADD COLUMN is_out_of_reach INTEGER NOT NULL DEFAULT 0;',
        );
        await db.insert('media_items', <String, Object?>{
          ..._mediaRow,
          'id': 'm2',
          'path': '/storage/emulated/0/DCIM/trashed.jpg',
          'is_trash': 1,
        });
        await db.insert('albums', <String, Object?>{
          'id': 'al',
          'name': 'Trip',
          'album_type': 'virtualAlbum',
          'item_count': 5,
          'date_created': 1,
          'date_modified': 1,
        });
        await db.insert('tags', <String, Object?>{
          'id': 'tg',
          'name': 'Sea',
          'color_value': 1,
          'item_count': 5,
          'date_created': 1,
        });
        for (final id in ['m1', 'm2']) {
          await db.insert('album_media_entries', <String, Object?>{
            'album_id': 'al',
            'media_id': id,
            'date_added': 1,
          });
          await db.insert('media_tag_entries', <String, Object?>{
            'media_id': id,
            'tag_id': 'tg',
            'date_tagged': 1,
          });
        }
      },
    );

    final db = await openWithHelper(dbPath);

    final album = (await db.query(DatabaseConstants.tableAlbums)).single;
    expect(album[DatabaseConstants.colAlbumItemCount], 1);
    final tag = (await db.query(DatabaseConstants.tableTags)).single;
    expect(tag[DatabaseConstants.colTagItemCount], 1);

    // The triggers are live after the upgrade, too.
    await db.update(
      DatabaseConstants.tableMedia,
      <String, Object?>{DatabaseConstants.colMediaIsTrash: 0},
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: <Object?>['m2'],
    );
    expect(
      (await db.query(
        DatabaseConstants.tableAlbums,
      )).single[DatabaseConstants.colAlbumItemCount],
      2,
    );
  });

  test('v8 to v9 adds the Device Sync marks table and keeps rows', () async {
    await seedOldDatabase(
      version: 8,
      withSearchTable: true,
      seed: (db) async {
        await db.execute(
          'ALTER TABLE media_items '
          'ADD COLUMN is_out_of_reach INTEGER NOT NULL DEFAULT 0;',
        );
      },
    );

    final db = await openWithHelper(dbPath);

    expect(await db.getVersion(), DatabaseConstants.schemaVersion);
    expect(await db.query(DatabaseConstants.tableMedia), hasLength(1));

    final mediaId =
        (await db.query(DatabaseConstants.tableMedia)).single['id']! as String;
    await db.insert(DatabaseConstants.tableSyncMarks, <String, Object?>{
      DatabaseConstants.colSyncMarkMediaId: mediaId,
      DatabaseConstants.colSyncMarkPeerId: 'peer',
      DatabaseConstants.colSyncMarkSha256: 'abc',
      DatabaseConstants.colSyncMarkSizeBytes: 1,
      DatabaseConstants.colSyncMarkSentAt: 1,
    });
    expect(await db.query(DatabaseConstants.tableSyncMarks), hasLength(1));
  });

  test(
    'an upgraded database has the same count triggers as a fresh one',
    () async {
      Future<Set<String>> countObjects(Database db) async {
        final rows = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE name LIKE 'trg_%count%' "
          "OR name = 'idx_album_media_media_id';",
        );
        return rows.map((r) => r['name']! as String).toSet();
      }

      await seedOldDatabase(version: 1, withSearchTable: true);
      final upgraded = await countObjects(await openWithHelper(dbPath));
      await helper!.close();

      final fresh = await countObjects(
        await openWithHelper(p.join(tempDir.path, 'fresh.db')),
      );

      expect(fresh, hasLength(10));
      expect(upgraded, fresh);
    },
  );

  test('an upgraded database has the same columns as a fresh one', () async {
    await seedOldDatabase(version: 1, withSearchTable: true);
    final upgraded = await columnsOf(await openWithHelper(dbPath));
    await helper!.close();

    final fresh = await columnsOf(
      await openWithHelper(p.join(tempDir.path, 'fresh.db')),
    );

    expect(upgraded, fresh);
  });

  group('allowed column values (schema 5, G38)', () {
    Map<String, Object?> media(String id, {Map<String, Object?>? change}) =>
        <String, Object?>{
          ..._mediaRow,
          'id': id,
          'path': '/storage/emulated/0/DCIM/$id.jpg',
          ...?change,
        };

    Future<void> expectRefused(Future<Object?> Function() write) async {
      await expectLater(write(), throwsA(isA<DatabaseException>()));
    }

    Future<void> checkRules(Database db) async {
      // Every enum value and both flag values are accepted.
      for (final (index, type) in MediaType.values.indexed) {
        await db.insert(
          'media_items',
          media('ok$index', change: <String, Object?>{'media_type': type.name}),
        );
      }
      for (final (index, type) in AlbumType.values.indexed) {
        await db.insert('albums', <String, Object?>{
          'id': 'a$index',
          'name': 'album $index',
          'album_type': type.name,
          'date_created': 1,
          'date_modified': 1,
          'is_pinned': index.isEven ? 1 : 0,
        });
      }

      // Anything else is refused, on insert and on update.
      await expectRefused(
        () => db.insert(
          'media_items',
          media('bad1', change: <String, Object?>{'media_type': 'banana'}),
        ),
      );
      await expectRefused(
        () => db.insert(
          'media_items',
          media('bad2', change: <String, Object?>{'is_favorite': 2}),
        ),
      );
      await expectRefused(
        () => db.update(
          'media_items',
          <String, Object?>{'is_trash': -1},
          where: 'id = ?',
          whereArgs: <Object?>['m1'],
        ),
      );
      await expectRefused(
        () => db.update(
          'albums',
          <String, Object?>{'album_type': 'unknown'},
          where: 'id = ?',
          whereArgs: <Object?>['a0'],
        ),
      );
      await expectRefused(
        () => db.update(
          'vault_items',
          <String, Object?>{'media_type': 'pdf'},
          where: 'id = ?',
          whereArgs: <Object?>['v1'],
        ),
      );
    }

    test('a fresh database refuses bad values by CHECK', () async {
      final db = await openWithHelper(p.join(tempDir.path, 'fresh.db'));
      await db.insert('media_items', _mediaRow);
      await db.insert('vault_items', <String, Object?>{
        ..._vaultRow,
        'thumbnail_iv': 'thumb-iv',
      });
      await checkRules(db);
    });

    test('a v4 database upgraded to v5 refuses the same values by trigger, '
        'and keeps every row and link', () async {
      await seedOldDatabase(
        version: 4,
        withSearchTable: true,
        seed: (db) async {
          await db.insert('albums', <String, Object?>{
            'id': 'kept',
            'name': 'Kept',
            'album_type': 'virtualAlbum',
            'date_created': 1,
            'date_modified': 1,
          });
          await db.insert('album_media_entries', <String, Object?>{
            'album_id': 'kept',
            'media_id': 'm1',
            'date_added': 1,
          });
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
        },
      );

      final db = await openWithHelper(dbPath);

      expect(await db.query('media_items'), hasLength(1));
      expect(await db.query('vault_items'), hasLength(1));
      expect(await db.query('album_media_entries'), hasLength(1));
      expect(await db.query('media_tag_entries'), hasLength(1));

      await checkRules(db);
    });
  });
}
