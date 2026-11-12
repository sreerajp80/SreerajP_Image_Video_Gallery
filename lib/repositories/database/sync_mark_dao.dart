import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Reads and writes the "sent to that phone" marks.
class SyncMarkDao {
  final DatabaseHelper _dbHelper;

  SyncMarkDao({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// Saves a mark, replacing an older one for the same file and phone.
  ///
  /// A mark whose media row is gone is refused by the foreign key; that is
  /// reported as a [StorageException] like any other failed write.
  Future<void> saveMark(SyncMark mark) async {
    try {
      final db = await _db;
      await db.insert(DatabaseConstants.tableSyncMarks, <String, Object?>{
        DatabaseConstants.colSyncMarkMediaId: mark.mediaId,
        DatabaseConstants.colSyncMarkPeerId: mark.peerId,
        DatabaseConstants.colSyncMarkSha256: mark.sha256,
        DatabaseConstants.colSyncMarkSizeBytes: mark.sizeBytes,
        DatabaseConstants.colSyncMarkSentAt: mark.sentAt.millisecondsSinceEpoch,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, st) {
      throw StorageException(
        'Failed to save a sync mark: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Every mark for one phone, by media id.
  Future<Map<String, SyncMark>> marksForPeer(String peerId) async {
    try {
      final db = await _db;
      final rows = await db.query(
        DatabaseConstants.tableSyncMarks,
        where: '${DatabaseConstants.colSyncMarkPeerId} = ?',
        whereArgs: <Object?>[peerId],
      );
      return <String, SyncMark>{
        for (final row in rows)
          row[DatabaseConstants.colSyncMarkMediaId]! as String: SyncMark(
            mediaId: row[DatabaseConstants.colSyncMarkMediaId]! as String,
            peerId: row[DatabaseConstants.colSyncMarkPeerId]! as String,
            sha256: row[DatabaseConstants.colSyncMarkSha256]! as String,
            sizeBytes: row[DatabaseConstants.colSyncMarkSizeBytes]! as int,
            sentAt: DateTime.fromMillisecondsSinceEpoch(
              row[DatabaseConstants.colSyncMarkSentAt]! as int,
            ),
          ),
      };
    } catch (e, st) {
      throw StorageException(
        'Failed to read sync marks: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Forgets every mark for one phone.
  ///
  /// For when that phone was reset: everything is offered to it again.
  Future<void> clearPeer(String peerId) async {
    try {
      final db = await _db;
      await db.delete(
        DatabaseConstants.tableSyncMarks,
        where: '${DatabaseConstants.colSyncMarkPeerId} = ?',
        whereArgs: <Object?>[peerId],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to clear sync marks: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
