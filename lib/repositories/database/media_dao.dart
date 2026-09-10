import 'dart:convert';

import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/folder_path_rules.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object for managing MediaItem records and SQLite FTS5 search queries.
class MediaDao {
  final DatabaseHelper _dbHelper;

  MediaDao({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// Inserts a single [MediaItem].
  Future<void> insertMediaItem(MediaItem item) async {
    try {
      final db = await _db;
      await db.insert(
        DatabaseConstants.tableMedia,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await syncFtsTags(item.id, item.tags);
    } catch (e, st) {
      throw StorageException(
        'Failed to insert media item ${item.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Batch upserts multiple [MediaItem] records atomically.
  Future<void> batchUpsertMediaItems(List<MediaItem> items) async {
    if (items.isEmpty) return;
    try {
      final db = await _db;
      await db.transaction((txn) async {
        final batch = txn.batch();
        for (final item in items) {
          batch.insert(
            DatabaseConstants.tableMedia,
            item.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
    } catch (e, st) {
      throw StorageException(
        'Failed to batch upsert media items: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves a single [MediaItem] by its ID including tags.
  Future<MediaItem?> getMediaItemById(String id) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableMedia,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final tags = await _getTagsForMedia(id);
      return MediaItem.fromMap(results.first, tags: tags);
    } catch (e, st) {
      throw StorageException(
        'Failed to get media item by ID $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves a single [MediaItem] by disk path.
  Future<MediaItem?> getMediaItemByPath(String path) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableMedia,
        where: '${DatabaseConstants.colMediaPath} = ?',
        whereArgs: [path],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final tags = await _getTagsForMedia(results.first['id'] as String);
      return MediaItem.fromMap(results.first, tags: tags);
    } catch (e, st) {
      throw StorageException(
        'Failed to get media item by path $path: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves a single [MediaItem] by content URI.
  Future<MediaItem?> getMediaItemByUri(String uri) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableMedia,
        where: '${DatabaseConstants.colMediaUri} = ?',
        whereArgs: [uri],
        limit: 1,
      );

      if (results.isEmpty) return null;

      final tags = await _getTagsForMedia(results.first['id'] as String);
      return MediaItem.fromMap(results.first, tags: tags);
    } catch (e, st) {
      throw StorageException(
        'Failed to get media item by URI $uri: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Queries media items according to [filter], [limit], and [offset].
  ///
  /// [ftsMatchExpression] narrows the result to rows the full-text index
  /// matches. It must already be a valid FTS5 expression with every user word
  /// quoted; `SearchQueryParser.buildMatchExpression` is the only thing that
  /// should build one. Folding it in here, rather than searching first and
  /// filtering the answer in Dart, keeps a text-plus-filter search to a single
  /// statement with a single sort, which is what stops it slowing down as a
  /// library grows.
  Future<List<MediaItem>> getMediaItems({
    FilterOptions filter = const FilterOptions(),
    String? ftsMatchExpression,
    int? limit,
    int? offset,
  }) async {
    try {
      final db = await _db;
      final whereClauses = <String>[];
      final whereArgs = <dynamic>[];

      // Full-text filter
      if (ftsMatchExpression != null && ftsMatchExpression.isNotEmpty) {
        whereClauses.add('''
          ${DatabaseConstants.colId} IN (
            SELECT ${DatabaseConstants.colFtsMediaId}
            FROM ${DatabaseConstants.tableMediaSearchFts}
            WHERE ${DatabaseConstants.tableMediaSearchFts} MATCH ?
          )
        ''');
        whereArgs.add(ftsMatchExpression);
      }

      // Vault filter (default: non-vaulted)
      whereClauses.add('${DatabaseConstants.colMediaIsVaulted} = 0');

      // Trash filter
      whereClauses.add(
        '${DatabaseConstants.colMediaIsTrash} = ${filter.isTrash ? 1 : 0}',
      );

      // Favorite filter
      if (filter.isFavoriteOnly == true) {
        whereClauses.add('${DatabaseConstants.colMediaIsFavorite} = 1');
      }

      // Media type filter
      if (filter.mediaTypes.isNotEmpty) {
        final typePlaceholders = List.filled(
          filter.mediaTypes.length,
          '?',
        ).join(', ');
        whereClauses.add(
          '${DatabaseConstants.colMediaType} IN ($typePlaceholders)',
        );
        whereArgs.addAll(filter.mediaTypes.map((t) => t.name));
      }

      // Date range filter (on date_taken or fallback date_modified)
      if (filter.startDate != null) {
        whereClauses.add(
          'COALESCE(${DatabaseConstants.colMediaDateTaken}, ${DatabaseConstants.colMediaDateModified}) >= ?',
        );
        whereArgs.add(filter.startDate!.millisecondsSinceEpoch);
      }
      if (filter.endDate != null) {
        whereClauses.add(
          'COALESCE(${DatabaseConstants.colMediaDateTaken}, ${DatabaseConstants.colMediaDateModified}) <= ?',
        );
        whereArgs.add(filter.endDate!.millisecondsSinceEpoch);
      }

      // GPS filter
      if (filter.hasGpsOnly == true) {
        whereClauses.add(
          '${DatabaseConstants.colMediaLatitude} IS NOT NULL AND ${DatabaseConstants.colMediaLongitude} IS NOT NULL',
        );
      }

      // Tag filter
      if (filter.tagIds.isNotEmpty) {
        final tagPlaceholders = List.filled(
          filter.tagIds.length,
          '?',
        ).join(', ');
        if (filter.tagFilterMode == TagFilterMode.andMode) {
          whereClauses.add('''
            ${DatabaseConstants.colId} IN (
              SELECT ${DatabaseConstants.colMediaTagMediaId}
              FROM ${DatabaseConstants.tableMediaTags}
              WHERE ${DatabaseConstants.colMediaTagTagId} IN ($tagPlaceholders)
              GROUP BY ${DatabaseConstants.colMediaTagMediaId}
              HAVING COUNT(DISTINCT ${DatabaseConstants.colMediaTagTagId}) = ?
            )
          ''');
          whereArgs.addAll(filter.tagIds);
          whereArgs.add(filter.tagIds.length);
        } else {
          whereClauses.add('''
            ${DatabaseConstants.colId} IN (
              SELECT ${DatabaseConstants.colMediaTagMediaId}
              FROM ${DatabaseConstants.tableMediaTags}
              WHERE ${DatabaseConstants.colMediaTagTagId} IN ($tagPlaceholders)
            )
          ''');
          whereArgs.addAll(filter.tagIds);
        }
      }

      // Folder filter
      //
      // This is a prefix match plus a "no further separator" test, which
      // together mean "directly inside this folder". Doing it here rather than
      // in Dart matters: the old Dart filter had to read every row of the
      // table before it could drop the ones in other folders.
      if (filter.folderPaths.isNotEmpty) {
        final folderClauses = <String>[];
        for (final folder in filter.folderPaths) {
          folderClauses.add('''
            (${DatabaseConstants.colMediaPath} LIKE ? ESCAPE '${FolderPathRules.likeEscape}'
             AND INSTR(SUBSTR(${DatabaseConstants.colMediaPath}, ?), '${FolderPathRules.separator}') = 0)
          ''');
          whereArgs.add(FolderPathRules.childLikePattern(folder));
          // SUBSTR is 1-based, so the first character after the folder's own
          // separator sits at prefixLength + 1.
          whereArgs.add(FolderPathRules.childPrefixLength(folder) + 1);
        }
        whereClauses.add('(${folderClauses.join(' OR ')})');
      }

      // File size range
      if (filter.minSizeBytes != null) {
        whereClauses.add('${DatabaseConstants.colMediaSizeBytes} >= ?');
        whereArgs.add(filter.minSizeBytes);
      }
      if (filter.maxSizeBytes != null) {
        whereClauses.add('${DatabaseConstants.colMediaSizeBytes} <= ?');
        whereArgs.add(filter.maxSizeBytes);
      }

      // Has at least one tag
      if (filter.hasTagsOnly == true) {
        whereClauses.add('''
          ${DatabaseConstants.colId} IN (
            SELECT ${DatabaseConstants.colMediaTagMediaId}
            FROM ${DatabaseConstants.tableMediaTags}
          )
        ''');
      }

      // Sort Order
      final sortColumn = switch (filter.sortBy) {
        MediaSortField.dateTaken =>
          'COALESCE(${DatabaseConstants.colMediaDateTaken}, ${DatabaseConstants.colMediaDateModified})',
        MediaSortField.dateAdded => DatabaseConstants.colMediaDateAdded,
        MediaSortField.dateModified => DatabaseConstants.colMediaDateModified,
        MediaSortField.displayName => DatabaseConstants.colMediaDisplayName,
        MediaSortField.size => DatabaseConstants.colMediaSizeBytes,
        MediaSortField.duration => DatabaseConstants.colMediaDurationMs,
      };
      final sortDirection = filter.sortDirection == SortDirection.ascending
          ? 'ASC'
          : 'DESC';
      final orderBy = '$sortColumn $sortDirection';

      final results = await db.query(
        DatabaseConstants.tableMedia,
        where: whereClauses.join(' AND '),
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: orderBy,
        limit: limit,
        offset: offset,
      );

      final items = <MediaItem>[];
      for (final row in results) {
        final tags = await _getTagsForMedia(row['id'] as String);
        items.add(MediaItem.fromMap(row, tags: tags));
      }
      return items;
    } catch (e, st) {
      throw StorageException(
        'Failed to query media items: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Searches media items using SQLite FTS5 index.
  Future<List<MediaItem>> searchMediaFts(
    String query, {
    int limit = 50,
    int offset = 0,
  }) async {
    final sanitizedQuery = query.trim();
    if (sanitizedQuery.isEmpty) return const [];

    try {
      final db = await _db;
      // Append wildcard for prefix searching on words
      final ftsQuery = sanitizedQuery
          .replaceAll('"', '""')
          .split(RegExp(r'\s+'))
          .where((s) => s.isNotEmpty)
          .map((s) => '"$s"*')
          .join(' ');

      final results = await db.rawQuery(
        '''
        SELECT m.*
        FROM ${DatabaseConstants.tableMedia} m
        INNER JOIN ${DatabaseConstants.tableMediaSearchFts} fts
          ON m.${DatabaseConstants.colId} = fts.${DatabaseConstants.colFtsMediaId}
        WHERE ${DatabaseConstants.tableMediaSearchFts} MATCH ?
          AND m.${DatabaseConstants.colMediaIsVaulted} = 0
          AND m.${DatabaseConstants.colMediaIsTrash} = 0
        ORDER BY m.${DatabaseConstants.colMediaDateTaken} DESC,
                 m.${DatabaseConstants.colMediaDateAdded} DESC
        LIMIT ? OFFSET ?
      ''',
        [ftsQuery, limit, offset],
      );

      final items = <MediaItem>[];
      for (final row in results) {
        final tags = await _getTagsForMedia(row['id'] as String);
        items.add(MediaItem.fromMap(row, tags: tags));
      }
      return items;
    } catch (e, st) {
      throw StorageException(
        'Failed to execute FTS5 search for "$query": $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Toggles or sets the favorite state for a media item.
  Future<void> updateFavorite(String id, bool isFavorite) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableMedia,
        {DatabaseConstants.colMediaIsFavorite: isFavorite ? 1 : 0},
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update favorite for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Updates user notes and refreshes FTS virtual table index.
  Future<void> updateUserNotes(String id, String? notes) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableMedia,
        {DatabaseConstants.colMediaUserNotes: notes},
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update user notes for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Whether any indexed file already has this content digest.
  ///
  /// Lets an incoming transfer decline a photo this device already holds,
  /// before the bytes are moved rather than after. On a camera roll that has
  /// been shared once already, that is most of what a second transfer would
  /// otherwise re-send.
  Future<bool> hasMediaWithHash(String sha256) async {
    if (sha256.isEmpty) return false;
    try {
      final db = await _db;
      final rows = await db.query(
        DatabaseConstants.tableMedia,
        columns: [DatabaseConstants.colId],
        where: '${DatabaseConstants.colMediaSha256Hash} = ?',
        whereArgs: [sha256],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (e, st) {
      throw StorageException(
        'Failed to look up a media digest: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Reads the columns a backup archive carries, for every indexed file.
  ///
  /// Only the user-owned columns plus what a restore needs to find the same
  /// file again. Width, height, duration and the perceptual hashes are all
  /// facts a rescan works out on its own, so putting them in the archive
  /// would only make it bigger and let it go stale.
  ///
  /// Vaulted and trashed rows are left out. A vault item's metadata belongs
  /// to the vault and is protected by it, and a trashed row is on its way
  /// out; neither is something to carry into a plaintext-shaped archive.
  Future<List<Map<String, Object?>>> getBackupRecords() async {
    try {
      final db = await _db;
      return await db.query(
        DatabaseConstants.tableMedia,
        columns: [
          DatabaseConstants.colId,
          DatabaseConstants.colMediaPath,
          DatabaseConstants.colMediaDisplayName,
          DatabaseConstants.colMediaSizeBytes,
          DatabaseConstants.colMediaDateTaken,
          DatabaseConstants.colMediaSha256Hash,
          DatabaseConstants.colMediaIsFavorite,
          DatabaseConstants.colMediaUserNotes,
          DatabaseConstants.colMediaAddress,
          DatabaseConstants.colMediaLatitude,
          DatabaseConstants.colMediaLongitude,
        ],
        where:
            '${DatabaseConstants.colMediaIsVaulted} = 0 '
            'AND ${DatabaseConstants.colMediaIsTrash} = 0',
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to read the backup records: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Writes back the user-owned fields a restore brought in.
  ///
  /// Every argument is optional and a null one is left alone, which is what
  /// makes the whole operation additive: a restore fills gaps, it never
  /// blanks a note or clears a favourite this device already has. Deciding
  /// *what* to pass is the merge service's job; this only writes it.
  ///
  /// The notes column feeds the full-text index, so it is reindexed here
  /// rather than left for a later scan to notice.
  Future<void> applyBackupRecord(
    String id, {
    bool? isFavorite,
    String? userNotes,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    final values = <String, Object?>{
      if (isFavorite != null)
        DatabaseConstants.colMediaIsFavorite: isFavorite ? 1 : 0,
      if (userNotes != null) DatabaseConstants.colMediaUserNotes: userNotes,
      if (address != null) DatabaseConstants.colMediaAddress: address,
      if (latitude != null) DatabaseConstants.colMediaLatitude: latitude,
      if (longitude != null) DatabaseConstants.colMediaLongitude: longitude,
    };
    if (values.isEmpty) return;

    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableMedia,
        values,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );

      if (userNotes != null || address != null) {
        await _syncFtsTextFor(id);
      }
    } catch (e, st) {
      throw StorageException(
        'Failed to apply the restored fields for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Rewrites the searchable notes and place text for one media row.
  ///
  /// A restored note that never reached the index would be invisible to
  /// search, which is exactly the kind of quiet half-restore that makes
  /// people stop trusting a backup.
  Future<void> _syncFtsTextFor(String id) async {
    final db = await _db;
    final rows = await db.query(
      DatabaseConstants.tableMedia,
      columns: [
        DatabaseConstants.colMediaUserNotes,
        DatabaseConstants.colMediaAddress,
      ],
      where: '${DatabaseConstants.colId} = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return;

    await db.update(
      DatabaseConstants.tableMediaSearchFts,
      {
        DatabaseConstants.colFtsUserNotes:
            rows.first[DatabaseConstants.colMediaUserNotes] ?? '',
        DatabaseConstants.colFtsAddress:
            rows.first[DatabaseConstants.colMediaAddress] ?? '',
      },
      where: '${DatabaseConstants.colFtsMediaId} = ?',
      whereArgs: [id],
    );
  }

  /// Moves or restores item to/from trash bin.
  Future<void> updateTrash(String id, bool isTrash) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableMedia,
        {DatabaseConstants.colMediaIsTrash: isTrash ? 1 : 0},
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update trash state for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Restores every trashed item back to the main library.
  ///
  /// Returns the number of rows restored.
  Future<int> restoreAllFromTrash() async {
    try {
      final db = await _db;
      return await db.update(
        DatabaseConstants.tableMedia,
        {DatabaseConstants.colMediaIsTrash: 0},
        where: '${DatabaseConstants.colMediaIsTrash} = 1',
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to restore all trashed items: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Permanently removes every trashed row from the database.
  ///
  /// Only the database rows are deleted. The original files remain on the
  /// device storage, so a re-scan will index them again. Returns the number
  /// of rows removed.
  Future<int> deleteAllTrashed() async {
    try {
      final db = await _db;
      return await db.delete(
        DatabaseConstants.tableMedia,
        where: '${DatabaseConstants.colMediaIsTrash} = 1',
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete all trashed items: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Permanently removes specific media items by ID from the database.
  Future<int> deleteMediaItems(List<String> ids) async {
    if (ids.isEmpty) return 0;
    try {
      final db = await _db;
      final placeholders = List.filled(ids.length, '?').join(', ');
      return await db.delete(
        DatabaseConstants.tableMedia,
        where: '${DatabaseConstants.colId} IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete media items from database: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Number of items currently sitting in the trash.
  Future<int> getTrashCount() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM ${DatabaseConstants.tableMedia}
        WHERE ${DatabaseConstants.colMediaIsTrash} = 1
          AND ${DatabaseConstants.colMediaIsVaulted} = 0
      ''');
      return (result.first['count'] as int?) ?? 0;
    } catch (e, st) {
      throw StorageException(
        'Failed to get trash count: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Sets vaulted status for an item.
  Future<void> updateVaulted(String id, bool isVaulted) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableMedia,
        {DatabaseConstants.colMediaIsVaulted: isVaulted ? 1 : 0},
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update vaulted state for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Updates cryptographic and perceptual hashes.
  Future<void> updateHashes(String id, {String? sha256, String? pHash}) async {
    try {
      final db = await _db;
      final values = <String, dynamic>{};
      if (sha256 != null) values[DatabaseConstants.colMediaSha256Hash] = sha256;
      if (pHash != null) values[DatabaseConstants.colMediaPHash] = pHash;
      if (values.isEmpty) return;

      await db.update(
        DatabaseConstants.tableMedia,
        values,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update hashes for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Stores parsed EXIF metadata, and the GPS fix it carries.
  ///
  /// The viewer parses EXIF the first time a photo's details are opened, then
  /// saves it here so the next open is a plain database read. The update
  /// trigger keeps the FTS index in step, which is why the camera and lens
  /// text becomes searchable as a side effect.
  Future<void> updateExif(String id, ExifData? exif) async {
    try {
      final db = await _db;
      final values = <String, dynamic>{
        DatabaseConstants.colMediaExifJson: exif == null
            ? null
            : jsonEncode(exif.toMap()),
      };
      if (exif?.latitude != null) {
        values[DatabaseConstants.colMediaLatitude] = exif!.latitude;
      }
      if (exif?.longitude != null) {
        values[DatabaseConstants.colMediaLongitude] = exif!.longitude;
      }

      await db.update(
        DatabaseConstants.tableMedia,
        values,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update EXIF for $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes a media item permanently from the database.
  Future<void> deleteMediaItem(String id) async {
    try {
      final db = await _db;
      await db.delete(
        DatabaseConstants.tableMedia,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete media item $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Reads the media items named by [ids], in the order given.
  ///
  /// Used by the album screens, where the membership table decides the order
  /// and the media table only supplies the rows. Ids that are no longer in the
  /// table are simply left out, so a stale membership row cannot break a
  /// screen.
  Future<List<MediaItem>> getMediaItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return const <MediaItem>[];
    try {
      final db = await _db;
      final placeholders = List.filled(ids.length, '?').join(', ');
      final results = await db.query(
        DatabaseConstants.tableMedia,
        where:
            '${DatabaseConstants.colId} IN ($placeholders) '
            'AND ${DatabaseConstants.colMediaIsVaulted} = 0 '
            'AND ${DatabaseConstants.colMediaIsTrash} = 0',
        whereArgs: ids,
      );

      final byId = <String, MediaItem>{};
      for (final row in results) {
        final id = row['id'] as String;
        final tags = await _getTagsForMedia(id);
        byId[id] = MediaItem.fromMap(row, tags: tags);
      }

      // Re-ordered to match the caller's list. SQL `IN` gives no order of its
      // own, and an album's whole point is the order it was given.
      return <MediaItem>[
        for (final id in ids)
          if (byId.containsKey(id)) byId[id]!,
      ];
    } catch (e, st) {
      throw StorageException(
        'Failed to get media items by ids: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Groups every indexed item by the folder it sits in.
  ///
  /// Returns one row per folder with its path, how many items it holds, and
  /// the id of its newest item, which the albums grid draws as the cover.
  ///
  /// The directory is worked out inside SQL with `RTRIM(path, REPLACE(path,
  /// '/', ''))`: the second argument is every non-separator character of the
  /// path, so trimming those off the right leaves the path up to and including
  /// its last separator. Doing this in one statement is what keeps the albums
  /// screen from reading the whole table.
  ///
  /// The cover comes from SQLite's rule that when a grouped query selects a
  /// bare column alongside a single `MAX`, the bare column is taken from the
  /// row holding that maximum. So `id` here is the id of the folder's newest
  /// item, without a second query per folder.
  Future<List<FolderSummaryRow>> getFolderSummaries() async {
    try {
      final db = await _db;
      const separator = FolderPathRules.separator;
      final results = await db.rawQuery('''
        SELECT
          directory,
          COUNT(*) AS item_count,
          id AS cover_id,
          MAX(sort_key) AS newest
        FROM (
          SELECT
            ${DatabaseConstants.colId} AS id,
            RTRIM(
              ${DatabaseConstants.colMediaPath},
              REPLACE(${DatabaseConstants.colMediaPath}, '$separator', '')
            ) AS directory,
            COALESCE(
              ${DatabaseConstants.colMediaDateTaken},
              ${DatabaseConstants.colMediaDateModified}
            ) AS sort_key
          FROM ${DatabaseConstants.tableMedia}
          WHERE ${DatabaseConstants.colMediaIsVaulted} = 0
            AND ${DatabaseConstants.colMediaIsTrash} = 0
        )
        GROUP BY directory
        ORDER BY item_count DESC
      ''');

      final rows = <FolderSummaryRow>[];
      for (final row in results) {
        final raw = (row['directory'] as String?) ?? '';
        // A file with no separator at all groups under an empty directory,
        // which is not a folder anyone can open, so it is left out.
        if (raw.isEmpty) continue;
        rows.add(
          FolderSummaryRow(
            directory: FolderPathRules.stripTrailingSeparators(raw),
            itemCount: (row['item_count'] as int?) ?? 0,
            coverMediaId: row['cover_id'] as String?,
          ),
        );
      }
      return rows;
    } catch (e, st) {
      throw StorageException(
        'Failed to group media items by folder: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Total count of media items matching active criteria.
  Future<int> getTotalCount({
    bool includeTrash = false,
    bool vaultedOnly = false,
  }) async {
    try {
      final db = await _db;
      final result = await db.rawQuery(
        '''
        SELECT COUNT(*) as count
        FROM ${DatabaseConstants.tableMedia}
        WHERE ${DatabaseConstants.colMediaIsVaulted} = ?
          AND ${DatabaseConstants.colMediaIsTrash} = ?
      ''',
        [vaultedOnly ? 1 : 0, includeTrash ? 1 : 0],
      );
      return (result.first['count'] as int?) ?? 0;
    } catch (e, st) {
      throw StorageException(
        'Failed to get total media count: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Newest `date_modified` value currently indexed, in milliseconds.
  ///
  /// Returns null when the table is empty. Used to drive incremental scans.
  Future<int?> getNewestDateModifiedMs() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT MAX(${DatabaseConstants.colMediaDateModified}) as newest
        FROM ${DatabaseConstants.tableMedia}
        WHERE ${DatabaseConstants.colMediaIsVaulted} = 0
      ''');
      return result.first['newest'] as int?;
    } catch (e, st) {
      throw StorageException(
        'Failed to read newest media modification time: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes indexed media rows whose IDs are not in [seenIds].
  ///
  /// Vaulted items are never touched, because their originals are removed from
  /// MediaStore by design. Returns the number of rows deleted.
  Future<int> deleteMediaItemsMissingFrom(Set<String> seenIds) async {
    try {
      final db = await _db;
      if (seenIds.isEmpty) {
        return db.delete(
          DatabaseConstants.tableMedia,
          where: '${DatabaseConstants.colMediaIsVaulted} = 0',
        );
      }

      // Chunked so the statement stays under the SQLite variable limit.
      const int chunkSize = 500;
      final ids = seenIds.toList(growable: false);
      var deleted = 0;

      await db.transaction((txn) async {
        await txn.execute(
          'CREATE TEMPORARY TABLE IF NOT EXISTS scan_seen_ids '
          '(id TEXT PRIMARY KEY)',
        );
        await txn.execute('DELETE FROM scan_seen_ids');

        for (var start = 0; start < ids.length; start += chunkSize) {
          final chunk = ids.sublist(
            start,
            start + chunkSize > ids.length ? ids.length : start + chunkSize,
          );
          final batch = txn.batch();
          for (final id in chunk) {
            batch.rawInsert(
              'INSERT OR IGNORE INTO scan_seen_ids (id) VALUES (?)',
              [id],
            );
          }
          await batch.commit(noResult: true);
        }

        deleted = await txn.rawDelete('''
          DELETE FROM ${DatabaseConstants.tableMedia}
          WHERE ${DatabaseConstants.colMediaIsVaulted} = 0
            AND ${DatabaseConstants.colId} NOT IN (SELECT id FROM scan_seen_ids)
        ''');

        await txn.execute('DROP TABLE IF EXISTS scan_seen_ids');
      });

      return deleted;
    } catch (e, st) {
      throw StorageException(
        'Failed to remove stale media rows: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Reads one page of items for the duplicate scan, without their tags.
  ///
  /// [getMediaItems] runs a second query per row to collect tag names, which
  /// is fine for a screenful and wasteful across a whole library. The
  /// duplicate scan never looks at tags, so it reads the rows on their own and
  /// saves thousands of queries.
  ///
  /// Ordered by id so paging stays stable while the scan writes hashes back
  /// into the same rows.
  Future<List<MediaItem>> getHashCandidates({
    required int limit,
    required int offset,
  }) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableMedia,
        where:
            '${DatabaseConstants.colMediaIsVaulted} = 0 '
            'AND ${DatabaseConstants.colMediaIsTrash} = 0',
        orderBy: '${DatabaseConstants.colId} ASC',
        limit: limit,
        offset: offset,
      );
      return results
          .map((row) => MediaItem.fromMap(row, tags: const <String>[]))
          .toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to read hash candidates: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Helper to get tag names for a media item.
  Future<List<String>> _getTagsForMedia(String mediaId) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT t.${DatabaseConstants.colName}
      FROM ${DatabaseConstants.tableTags} t
      INNER JOIN ${DatabaseConstants.tableMediaTags} mt
        ON t.${DatabaseConstants.colId} = mt.${DatabaseConstants.colMediaTagTagId}
      WHERE mt.${DatabaseConstants.colMediaTagMediaId} = ?
    ''',
      [mediaId],
    );
    return rows.map((r) => r[DatabaseConstants.colName] as String).toList();
  }

  /// Rewrites the tag words the full-text index holds for one media item.
  ///
  /// Called after every tag change. An empty list writes an empty cell rather
  /// than returning early: if it did not, removing the last tag from a photo
  /// would leave the old tag name in the index and the photo would keep
  /// turning up in searches for a tag it no longer has.
  Future<void> syncFtsTags(String mediaId, List<String> tags) async {
    final db = await _db;
    await db.rawUpdate(
      '''
      UPDATE ${DatabaseConstants.tableMediaSearchFts}
      SET ${DatabaseConstants.colFtsTagsContent} = ?
      WHERE ${DatabaseConstants.colFtsMediaId} = ?
    ''',
      [tags.join(' '), mediaId],
    );
  }
}

/// One folder's row from [MediaDao.getFolderSummaries].
///
/// A plain carrier, not a domain model: the repository turns it into an
/// `AlbumSummary` once it has resolved the cover item.
class FolderSummaryRow {
  /// Directory path, without a trailing separator.
  final String directory;

  /// How many items sit directly in this folder.
  final int itemCount;

  /// Id of the newest item in the folder, or null when it has none.
  final String? coverMediaId;

  const FolderSummaryRow({
    required this.directory,
    required this.itemCount,
    this.coverMediaId,
  });
}
