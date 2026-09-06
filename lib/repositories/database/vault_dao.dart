import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:sqflite/sqflite.dart';

/// Data Access Object for managing private encrypted vault records.
class VaultDao {
  final DatabaseHelper _dbHelper;

  VaultDao({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper();

  Future<Database> get _db => _dbHelper.database;

  /// Inserts a newly encrypted [VaultItem] record.
  Future<void> insertVaultItem(VaultItem item) async {
    try {
      final db = await _db;
      await db.insert(
        DatabaseConstants.tableVault,
        item.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to insert vault item ${item.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes a vault record by its ID.
  Future<void> deleteVaultItem(String id) async {
    try {
      final db = await _db;
      await db.delete(
        DatabaseConstants.tableVault,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete vault item $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves a vaulted item record by ID.
  Future<VaultItem?> getVaultItemById(String id) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableVault,
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (results.isEmpty) return null;
      return VaultItem.fromMap(results.first);
    } catch (e, st) {
      throw StorageException(
        'Failed to get vault item by ID $id: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves all vaulted item records ordered by date vaulted.
  Future<List<VaultItem>> getAllVaultItems({int? limit, int? offset}) async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableVault,
        orderBy: '${DatabaseConstants.colVaultDateVaulted} DESC',
        limit: limit,
        offset: offset,
      );
      return results.map((r) => VaultItem.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get all vault items: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Updates an existing vault record in place.
  ///
  /// Used for renaming, notes, and tag edits — everything that changes the
  /// record without touching the encrypted payload beside it.
  Future<void> updateVaultItem(VaultItem item) async {
    try {
      final db = await _db;
      await db.update(
        DatabaseConstants.tableVault,
        item.toMap(),
        where: '${DatabaseConstants.colId} = ?',
        whereArgs: [item.id],
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to update vault item ${item.id}: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Retrieves several vault records by ID, newest first.
  ///
  /// Returns an empty list for an empty request rather than building a query
  /// with no placeholders, which SQLite would reject.
  Future<List<VaultItem>> getVaultItemsByIds(List<String> ids) async {
    if (ids.isEmpty) return const <VaultItem>[];
    try {
      final db = await _db;
      final placeholders = List.filled(ids.length, '?').join(', ');
      final results = await db.query(
        DatabaseConstants.tableVault,
        where: '${DatabaseConstants.colId} IN ($placeholders)',
        whereArgs: ids,
        orderBy: '${DatabaseConstants.colVaultDateVaulted} DESC',
      );
      return results.map((r) => VaultItem.fromMap(r)).toList();
    } catch (e, st) {
      throw StorageException(
        'Failed to get vault items by IDs: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Deletes several vault records in one statement.
  Future<void> deleteVaultItems(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      final db = await _db;
      final placeholders = List.filled(ids.length, '?').join(', ');
      await db.delete(
        DatabaseConstants.tableVault,
        where: '${DatabaseConstants.colId} IN ($placeholders)',
        whereArgs: ids,
      );
    } catch (e, st) {
      throw StorageException(
        'Failed to delete vault items: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Every payload and preview file name the vault knows about.
  ///
  /// The orphan sweep compares this with what is actually on disk, so an
  /// import that wrote its payload and then failed before inserting its row
  /// does not leave an encrypted file nobody can see or reach.
  Future<Set<String>> getAllEncryptedFilenames() async {
    try {
      final db = await _db;
      final results = await db.query(
        DatabaseConstants.tableVault,
        columns: [
          DatabaseConstants.colVaultEncryptedFilename,
          DatabaseConstants.colVaultEncryptedThumbnailFilename,
        ],
      );
      final names = <String>{};
      for (final row in results) {
        final payload = row[DatabaseConstants.colVaultEncryptedFilename];
        if (payload is String && payload.isNotEmpty) names.add(payload);
        final thumb = row[DatabaseConstants.colVaultEncryptedThumbnailFilename];
        if (thumb is String && thumb.isNotEmpty) names.add(thumb);
      }
      return names;
    } catch (e, st) {
      throw StorageException(
        'Failed to list vault filenames: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Returns total count of items in the vault.
  Future<int> getVaultItemsCount() async {
    try {
      final db = await _db;
      final result = await db.rawQuery('''
        SELECT COUNT(*) as count FROM ${DatabaseConstants.tableVault}
      ''');
      return (result.first['count'] as int?) ?? 0;
    } catch (e, st) {
      throw StorageException(
        'Failed to get vault items count: $e',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
