import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object for managing tags and media tagging relationships.
class TagDao {
  final DatabaseHelper _dbHelper;

  TagDao({DatabaseHelper? dbHelper}) : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// Inserts or updates a [Tag].
  Future<void> insertTag(Tag tag) async {
    try {
      final db = await _db;
      await db.insert(
        DatabaseConstants.tableTags,
        tag.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to insert tag ${tag.name}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Updates an existing [Tag].
  Future<void> updateTag(Tag tag) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableTags,
        tag.toMap(),
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [tag.id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update tag ${tag.name}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes a tag by its ID.
  Future<void> deleteTag(String tagId) async {
    try {
      final db = await _db;
      await db.delete(
        DatabaseConstants.tableTags,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [tagId],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete tag $tagId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves a tag by its ID.
  Future<Tag?> getTagById(String tagId) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableTags,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [tagId],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return Tag.fromMap(results.first);
    } catch (e, st) {
      throw StorageException(
        'Failed to get tag by ID $tagId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves a tag by its unique name.
  Future<Tag?> getTagByName(String name) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableTags,
        where: 'LOWER(${DatabaseConstants.colName}) = LOWER(?)',
        whereArgs: [name.trim()],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return Tag.fromMap(results.first);
    } catch (e, st) {
      throw StorageException(
        'Failed to get tag by name $name: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Returns all tags ordered by name.
  Future<List<Tag>> getAllTags() async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableTags,
        orderBy: '${DatabaseConstants.colName} ASC',
      );
      return results.map((r) => Tag.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get all tags: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Attaches a tag to a media item.
  Future<void> addTagToMedia(String mediaId, String tagId) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.insert(
          DatabaseConstants.tableMediaTags,
          {
            DatabaseConstants.colMediaTagMediaId: mediaId,
            DatabaseConstants.colMediaTagTagId: tagId,
            DatabaseConstants.colMediaTagDateTagged:
                DateTime.now().millisecondsSinceEpoch,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        // Update tag item count
        final countResult = await txn.rawQuery(
          '''
          SELECT COUNT(*) as count FROM ${DatabaseConstants.tableMediaTags}
          WHERE ${DatabaseConstants.colMediaTagTagId} = ?
        ''',
          [tagId],
        );
        final count = (countResult.first['count'] as int?) ?? 0;

        await txn.update(
          DatabaseConstants.tableTags,
          {DatabaseConstants.colTagItemCount: count},
          where: '${DatabaseConstants.colId} = ?',
          whereArgs: [tagId],
        );
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to add tag $tagId to media $mediaId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Removes a tag from a media item.
  Future<void> removeTagFromMedia(String mediaId, String tagId) async {
    try {
      final db = await _db;
      await db.transaction((txn) async {
        await txn.delete(
          DatabaseConstants.tableMediaTags,
          where:
              '${DatabaseConstants.colMediaTagMediaId} = ? AND ${DatabaseConstants.colMediaTagTagId} = ?',
          whereArgs: [mediaId, tagId],
        );

        final countResult = await txn.rawQuery(
          '''
          SELECT COUNT(*) as count FROM ${DatabaseConstants.tableMediaTags}
          WHERE ${DatabaseConstants.colMediaTagTagId} = ?
        ''',
          [tagId],
        );
        final count = (countResult.first['count'] as int?) ?? 0;

        await txn.update(
          DatabaseConstants.tableTags,
          {DatabaseConstants.colTagItemCount: count},
          where: '${DatabaseConstants.colId} = ?',
          whereArgs: [tagId],
        );
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to remove tag $tagId from media $mediaId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Renames a tag, keeping everything else about it.
  ///
  /// The name column is unique, so a clash is a database error. Callers are
  /// expected to have checked the name with `TagNameRules` first; this is the
  /// last line of defence, not the first.
  Future<void> renameTag(String tagId, String name) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableTags,
        {DatabaseConstants.colName: name},
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [tagId],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to rename tag $tagId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Ids of every media item carrying [tagId].
  ///
  /// Used when a tag is renamed or deleted, so the search index of each
  /// affected item can be rewritten.
  Future<List<String>> getMediaIdsForTag(String tagId) async {
    try {
      final db = await _db;
      final rows = await db.query(
        DatabaseConstants.tableMediaTags,
        columns: [DatabaseConstants.colMediaTagMediaId],
        where: '${DatabaseConstants.colMediaTagTagId} = ?',
        whereArgs: [tagId],
      );
      return rows
          .map((r) => r[DatabaseConstants.colMediaTagMediaId] as String)
          .toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get media ids for tag $tagId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Replaces the whole tag set of one media item in a single transaction.
  ///
  /// Used by the tag sheet, where the user ticks and unticks several tags and
  /// then the whole set is written at once. Doing it in one transaction means
  /// a photo is never briefly left with half its tags.
  Future<void> setTagsForMedia(String mediaId, Set<String> tagIds) async {
    try {
      final db = await _db;
      final now = DateTime.now().millisecondsSinceEpoch;

      await db.transaction((txn) async {
        final existing = await txn.query(
          DatabaseConstants.tableMediaTags,
          columns: [DatabaseConstants.colMediaTagTagId],
          where: '${DatabaseConstants.colMediaTagMediaId} = ?',
          whereArgs: [mediaId],
        );
        final before = existing
            .map((r) => r[DatabaseConstants.colMediaTagTagId] as String)
            .toSet();

        for (final tagId in before.difference(tagIds)) {
          await txn.delete(
            DatabaseConstants.tableMediaTags,
            where:
                '${DatabaseConstants.colMediaTagMediaId} = ? '
                'AND ${DatabaseConstants.colMediaTagTagId} = ?',
            whereArgs: [mediaId, tagId],
          );
        }

        for (final tagId in tagIds.difference(before)) {
          await txn.insert(
            DatabaseConstants.tableMediaTags,
            {
              DatabaseConstants.colMediaTagMediaId: mediaId,
              DatabaseConstants.colMediaTagTagId: tagId,
              DatabaseConstants.colMediaTagDateTagged: now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }

        // Recount only the tags that actually changed.
        for (final tagId in before.union(tagIds)) {
          if (before.contains(tagId) && tagIds.contains(tagId)) continue;
          await _recountTagIn(txn, tagId);
        }
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to set tags for media $mediaId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Recomputes and stores the stored item count of one tag.
  ///
  /// The count is a cached number on the tag row, kept so the tag list does
  /// not need a count query per row. Anything that changes the junction table
  /// outside this DAO should call this afterwards.
  Future<void> recountTag(String tagId) async {
    try {
      final db = await _db;
      await _recountTagIn(db, tagId);
    } catch (e, st) {
      throw StorageException(
        'Failed to recount tag $tagId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  Future<void> _recountTagIn(DatabaseExecutor executor, String tagId) async {
    final countResult = await executor.rawQuery(
      '''
      SELECT COUNT(*) as count FROM ${DatabaseConstants.tableMediaTags}
      WHERE ${DatabaseConstants.colMediaTagTagId} = ?
    ''',
      [tagId],
    );
    final count = (countResult.first['count'] as int?) ?? 0;

    await executor.update(
      DatabaseConstants.tableTags,
      {DatabaseConstants.colTagItemCount: count},
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [tagId],
    );
  }

  /// Gets all tags associated with a specific media item.
  Future<List<Tag>> getTagsForMedia(String mediaId) async {
    try {
      final db = await _db;
      final results = await db.rawQuery(
        '''
        SELECT t.*
        FROM ${DatabaseConstants.tableTags} t
        INNER JOIN ${DatabaseConstants.tableMediaTags} mt
          ON t.${DatabaseConstants.colId} = mt.${DatabaseConstants.colMediaTagTagId}
        WHERE mt.${DatabaseConstants.colMediaTagMediaId} = ?
        ORDER BY t.${DatabaseConstants.colName} ASC
      ''',
        [mediaId],
      );

      return results.map((r) => Tag.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get tags for media $mediaId: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Every media-to-tag link in the database, as raw id pairs.
  ///
  /// Read in one go by the backup collector. Walking the media table and
  /// asking for each item's tags would be one query per photo, which on a
  /// large library is thousands of round trips to build a file that is a few
  /// hundred kilobytes.
  Future<List<({String mediaId, String tagId})>> getAllMediaTagLinks() async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableMediaTags,
        columns: [
          DatabaseConstants.colMediaTagMediaId,
          DatabaseConstants.colMediaTagTagId,
        ],
      );

      return results
          .map(
            (r) => (
              mediaId: r[DatabaseConstants.colMediaTagMediaId] as String,
              tagId: r[DatabaseConstants.colMediaTagTagId] as String,
            ),
          )
          .toList(growable: false);
    } catch (e, st) {
      throw StorageException(
        'Failed to read the media tag links: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
