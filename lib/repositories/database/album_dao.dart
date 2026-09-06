import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object for managing Albums and album media membership entries.
class AlbumDao {
  final DatabaseHelper _dbHelper;

  AlbumDao({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// Inserts or replaces an [Album].
  Future<void> insertAlbum(Album album) async {
    try {
      final db = await _db;
      await db.insert(
        DatabaseConstants.tableAlbums,
        album.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to insert album ${album.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Updates an existing [Album].
  Future<void> updateAlbum(Album album) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableAlbums,
        album.toMap(),
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [album.id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update album ${album.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes an album by ID. Cascade deletion removes junction records.
  Future<void> deleteAlbum(String albumId) async {
    try {
      final db = await _db;
      await db.delete(
        DatabaseConstants.tableAlbums,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [albumId],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves an album by its ID.
  Future<Album?> getAlbumById(String albumId) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableAlbums,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [albumId],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return Album.fromMap(results.first);
    } catch (e, st) {
      throw StorageException(
        'Failed to get album by ID $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Returns all albums ordered by pinned status and sort order.
  Future<List<Album>> getAllAlbums() async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableAlbums,
        orderBy:
            '${DatabaseConstants.colAlbumIsPinned} DESC, ${DatabaseConstants.colAlbumSortOrder} ASC, ${DatabaseConstants.colName} ASC',
      );
      return results.map((r) => Album.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get all albums: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Adds a media item to a virtual album.
  ///
  /// Without [position] the item goes on the end. That default matters: the
  /// old code wrote 0 every time, so every item in an album tied at the same
  /// position and the stored order meant nothing.
  Future<void> addMediaToAlbum(
    String albumId,
    String mediaId, {
    int? position,
  }) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        final at = position ?? await _nextPosition(txn, albumId);
        await txn.insert(
          DatabaseConstants.tableAlbumMedia,
          {
            DatabaseConstants.colAlbumMediaAlbumId: albumId,
            DatabaseConstants.colAlbumMediaMediaId: mediaId,
            DatabaseConstants.colAlbumMediaPosition: at,
            DatabaseConstants.colAlbumMediaDateAdded:
                DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _refreshCount(txn, albumId);
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to add media $mediaId to album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Adds one media item to several albums at once.
  ///
  /// One transaction, so the "add to albums" sheet either lands everywhere or
  /// nowhere rather than leaving a half-applied set behind.
  Future<void> addMediaToAlbums(
    String mediaId,
    Iterable<String> albumIds,
  ) async {
    final ids = albumIds.toList(growable: false);
    if (ids.isEmpty) return;
    try {
      final db = await _db;
      await db.transaction((txn) async {
        for (final albumId in ids) {
          await txn.insert(
            DatabaseConstants.tableAlbumMedia,
            {
              DatabaseConstants.colAlbumMediaAlbumId: albumId,
              DatabaseConstants.colAlbumMediaMediaId: mediaId,
              DatabaseConstants.colAlbumMediaPosition: await _nextPosition(
                txn,
                albumId,
              ),
              DatabaseConstants.colAlbumMediaDateAdded:
                  DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await _refreshCount(txn, albumId);
        }
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to add media $mediaId to albums: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Removes a media item from an album.
  Future<void> removeMediaFromAlbum(String albumId, String mediaId) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseConstants.tableAlbumMedia,
          where:
              '${DatabaseConstants.colAlbumMediaAlbumId} = ? AND ${DatabaseConstants.colAlbumMediaMediaId} = ?',
          whereArgs: [albumId, mediaId],
        );

        await _refreshCount(txn, albumId);
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to remove media $mediaId from album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves media items contained in a specific album.
  Future<List<MediaItem>> getMediaForAlbum(
    String albumId, {
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _db;
      final args = <dynamic>[albumId];
      final sql = StringBuffer('''
        SELECT m.*
        FROM ${DatabaseConstants.tableMedia} m
        INNER JOIN ${DatabaseConstants.tableAlbumMedia} am
          ON m.${DatabaseConstants.colId} = am.${DatabaseConstants.colAlbumMediaMediaId}
        WHERE am.${DatabaseConstants.colAlbumMediaAlbumId} = ?
          AND m.${DatabaseConstants.colMediaIsVaulted} = 0
          AND m.${DatabaseConstants.colMediaIsTrash} = 0
        ORDER BY am.${DatabaseConstants.colAlbumMediaPosition} ASC, m.${DatabaseConstants.colMediaDateTaken} DESC
      ''');

      if (limit != null) {
        sql.write(' LIMIT ?');
        args.add(limit);
        if (offset != null) {
          sql.write(' OFFSET ?');
          args.add(offset);
        }
      }

      final results = await db.rawQuery(sql.toString(), args);
      return results.map((r) => MediaItem.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get media for album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Albums of one kind, in the order the grid shows them.
  Future<List<Album>> getAlbumsByType(AlbumType type) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableAlbums,
        where: '${DatabaseConstants.colAlbumType} = ?',
        whereArgs: [type.name],
        orderBy:
            '${DatabaseConstants.colAlbumIsPinned} DESC, ${DatabaseConstants.colAlbumSortOrder} ASC, ${DatabaseConstants.colName} ASC',
      );
      return results.map((r) => Album.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get albums of type ${type.name}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// The media ids in one album, in album order.
  ///
  /// Returned separately from the items themselves so a reorder screen can
  /// work with the order alone, without loading every row.
  Future<List<String>> getMediaIdsForAlbum(String albumId) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableAlbumMedia,
        columns: [DatabaseConstants.colAlbumMediaMediaId],
        where: '${DatabaseConstants.colAlbumMediaAlbumId} = ?',
        whereArgs: [albumId],
        orderBy:
            '${DatabaseConstants.colAlbumMediaPosition} ASC, ${DatabaseConstants.colAlbumMediaDateAdded} ASC',
      );
      return results
          .map((r) => r[DatabaseConstants.colAlbumMediaMediaId] as String)
          .toList(growable: false);
    } catch (e, st) {
      throw StorageException(
        'Failed to get media ids for album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Every album membership row in the database, with its position.
  ///
  /// Read in one go by the backup collector, for the same reason as the tag
  /// links: one query per album on a library with a hundred albums is a
  /// hundred round trips to build one small file.
  Future<List<({String albumId, String mediaId, int position})>>
  getAllAlbumMediaLinks() async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableAlbumMedia,
        columns: [
          DatabaseConstants.colAlbumMediaAlbumId,
          DatabaseConstants.colAlbumMediaMediaId,
          DatabaseConstants.colAlbumMediaPosition,
        ],
        orderBy:
            '${DatabaseConstants.colAlbumMediaAlbumId} ASC, '
            '${DatabaseConstants.colAlbumMediaPosition} ASC',
      );

      return results
          .map(
            (r) => (
              albumId: r[DatabaseConstants.colAlbumMediaAlbumId] as String,
              mediaId: r[DatabaseConstants.colAlbumMediaMediaId] as String,
              position:
                  (r[DatabaseConstants.colAlbumMediaPosition] as int?) ?? 0,
            ),
          )
          .toList(growable: false);
    } catch (e, st) {
      throw StorageException(
        'Failed to read the album membership rows: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// The ids of every album one media item belongs to.
  ///
  /// The "add to album" sheet uses this to tick the albums it is already in.
  Future<List<String>> getAlbumIdsForMedia(String mediaId) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableAlbumMedia,
        columns: [DatabaseConstants.colAlbumMediaAlbumId],
        where: '${DatabaseConstants.colAlbumMediaMediaId} = ?',
        whereArgs: [mediaId],
      );
      return results
          .map((r) => r[DatabaseConstants.colAlbumMediaAlbumId] as String)
          .toList(growable: false);
    } catch (e, st) {
      throw StorageException(
        'Failed to get albums for media $mediaId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Writes a whole new order for one album's items.
  ///
  /// Every position is rewritten from the given list rather than shuffling
  /// single values about, and it all happens in one transaction, so the album
  /// can never be left holding a half-applied order.
  Future<void> setMediaOrder(String albumId, List<String> orderedIds) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        for (var i = 0; i < orderedIds.length; i++) {
          await txn.update(
            DatabaseConstants.tableAlbumMedia,
            {DatabaseConstants.colAlbumMediaPosition: i},
            where:
                '${DatabaseConstants.colAlbumMediaAlbumId} = ? AND ${DatabaseConstants.colAlbumMediaMediaId} = ?',
            whereArgs: [albumId, orderedIds[i]],
          );
        }
        await txn.update(
          DatabaseConstants.tableAlbums,
          {
            DatabaseConstants.colAlbumDateModified:
                DateTime.now().millisecondsSinceEpoch,
          },
          where: '${DatabaseConstants.colId} = ?',
          whereArgs: [albumId],
        );
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to reorder album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Sets, or clears, the item whose thumbnail covers the album.
  Future<void> setCover(
    String albumId,
    String? mediaId, {
    String? coverPath,
  }) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableAlbums,
        {
          DatabaseConstants.colAlbumCoverMediaId: mediaId,
          DatabaseConstants.colAlbumCoverPath: coverPath,
          DatabaseConstants.colAlbumDateModified:
              DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [albumId],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to set cover for album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Pins an album to the top of the grid, or unpins it.
  Future<void> setPinned(String albumId, bool isPinned) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableAlbums,
        {
          DatabaseConstants.colAlbumIsPinned: isPinned ? 1 : 0,
          DatabaseConstants.colAlbumDateModified:
              DateTime.now().millisecondsSinceEpoch,
        },
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [albumId],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to pin album $albumId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// The position a newly added item should take: one past the last one.
  Future<int> _nextPosition(DatabaseExecutor txn, String albumId) async {
    final result = await txn.rawQuery(
      '''
      SELECT MAX(${DatabaseConstants.colAlbumMediaPosition}) AS highest
      FROM ${DatabaseConstants.tableAlbumMedia}
      WHERE ${DatabaseConstants.colAlbumMediaAlbumId} = ?
    ''',
      [albumId],
    );
    final highest = result.first['highest'] as int?;
    return highest == null ? 0 : highest + 1;
  }

  /// Recounts an album's items and stamps it as changed.
  ///
  /// Recounting rather than adding or subtracting one keeps the stored count
  /// right even when a membership row went away through a foreign key cascade,
  /// which no Dart code here would otherwise see.
  Future<void> _refreshCount(DatabaseExecutor txn, String albumId) async {
    final countResult = await txn.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${DatabaseConstants.tableAlbumMedia}
      WHERE ${DatabaseConstants.colAlbumMediaAlbumId} = ?
    ''',
      [albumId],
    );
    final count = (countResult.first['count'] as int?) ?? 0;

    await txn.update(
      DatabaseConstants.tableAlbums,
      {
        DatabaseConstants.colAlbumItemCount: count,
        DatabaseConstants.colAlbumDateModified:
            DateTime.now().millisecondsSinceEpoch,
      },
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [albumId],
    );
  }
}
