import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';

/// Single entry point for media data used by the provider layer.
///
/// It joins the indexed database ([MediaDao]) with the device scanner
/// ([MediaScannerService]). It holds no `BuildContext` and knows nothing about
/// widgets, so the UI never talks to SQL or the platform channel directly.
class MediaRepository {
  final MediaDao _mediaDao;
  final MediaScannerService _scanner;

  /// Used to read original bytes for the fullscreen viewer.
  ///
  /// Optional so tests that only exercise the database can leave it out; the
  /// byte readers then simply return null instead of failing.
  final MediaStoreChannel? _channel;

  MediaRepository({
    required MediaDao mediaDao,
    required MediaScannerService scanner,
    MediaStoreChannel? channel,
  }) : _mediaDao = mediaDao,
       _scanner = scanner,
       _channel = channel;

  /// Live progress of the running scan.
  Stream<ScanProgress> get scanProgress => _scanner.progressStream;

  /// Whether a scan is currently running.
  bool get isScanning => _scanner.isScanning;

  /// Reads the device MediaStore and indexes it into the database.
  Future<ScanResult> scanDevice({bool incremental = false}) {
    return _scanner.scan(incremental: incremental);
  }

  /// Returns indexed media items matching [filter], newest first by default.
  ///
  /// Folder filtering used to happen here, in Dart, after the whole result had
  /// been read. It now runs inside the query, so asking for one folder no
  /// longer reads every row in the table first.
  Future<List<MediaItem>> getMediaItems({
    FilterOptions filter = const FilterOptions(),
    int? limit,
    int? offset,
  }) {
    return _mediaDao.getMediaItems(
      filter: filter,
      limit: limit,
      offset: offset,
    );
  }

  /// Returns the indexed items named by [ids], in the order given.
  Future<List<MediaItem>> getMediaItemsByIds(List<String> ids) {
    return _mediaDao.getMediaItemsByIds(ids);
  }

  /// Returns a single indexed item, or null when it is not indexed.
  Future<MediaItem?> getMediaItemById(String id) {
    return _mediaDao.getMediaItemById(id);
  }

  /// Returns a single indexed item by its file path.
  Future<MediaItem?> getMediaItemByPath(String path) {
    return _mediaDao.getMediaItemByPath(path);
  }

  /// Returns a single indexed item by its content URI.
  Future<MediaItem?> getMediaItemByUri(String uri) {
    return _mediaDao.getMediaItemByUri(uri);
  }

  /// Marks an item as favorite or removes the mark.
  Future<void> setFavorite(String id, bool isFavorite) {
    return _mediaDao.updateFavorite(id, isFavorite);
  }

  /// Flips the favorite flag and returns the new value.
  Future<bool> toggleFavorite(String id) async {
    final item = await _mediaDao.getMediaItemById(id);
    final next = !(item?.isFavorite ?? false);
    await _mediaDao.updateFavorite(id, next);
    return next;
  }

  /// Saves the markdown note written about an item.
  ///
  /// Passing null clears it. The media table's update trigger keeps the search
  /// index in step, so a note becomes searchable the moment it is written and
  /// nothing else has to be told about it.
  Future<void> setUserNotes(String id, String? notes) {
    return _mediaDao.updateUserNotes(id, notes);
  }

  /// Moves an item to the trash bin or restores it.
  Future<void> setTrash(String id, bool isTrash) {
    return _mediaDao.updateTrash(id, isTrash);
  }

  /// Restores every trashed item back to the main library.
  Future<int> restoreAllFromTrash() {
    return _mediaDao.restoreAllFromTrash();
  }

  /// Permanently removes every trashed row from the database.
  ///
  /// Only the database rows are deleted. The original files remain on the
  /// device storage, so a re-scan will index them again.
  Future<int> emptyTrash() {
    return _mediaDao.deleteAllTrashed();
  }

  /// Permanently deletes [items] from both the device storage and database.
  ///
  /// Returns true if deletion was confirmed and executed, false if cancelled.
  Future<bool> deletePermanently(List<MediaItem> items) async {
    if (items.isEmpty) return true;
    final channel = _channel;
    if (channel != null) {
      final uris = items
          .map((e) => e.uri)
          .whereType<String>()
          .where((u) => u.isNotEmpty)
          .toList();
      final paths = items
          .map((e) => e.path)
          .where((p) => p.isNotEmpty)
          .toList();
      final success = await channel.deleteMedia(uris: uris, paths: paths);
      if (!success) return false;
    }
    await _mediaDao.deleteMediaItems(items.map((e) => e.id).toList());
    return true;
  }

  /// Number of items currently sitting in the trash.
  Future<int> getTrashCount() {
    return _mediaDao.getTrashCount();
  }

  /// Number of indexed, non-vaulted, non-trashed items.
  Future<int> getTotalCount() {
    return _mediaDao.getTotalCount();
  }

  /// Reads the original bytes of an item, or null when they cannot be read.
  ///
  /// The viewer uses this to show a photo at full resolution. Files larger than
  /// [maxBytes] return null so a huge image cannot exhaust memory; the viewer
  /// then stays on its high-resolution thumbnail.
  Future<Uint8List?> readOriginalBytes(
    MediaItem item, {
    int maxBytes = AppConstants.viewerFullImageMaxBytes,
  }) async {
    final channel = _channel;
    if (channel == null) return null;
    if (item.size > maxBytes) return null;

    final uri = item.uri;
    if (uri == null || uri.isEmpty) return null;

    try {
      return await channel.readBytes(uri, maxBytes: maxBytes);
    } catch (_) {
      // An unreadable or deleted file must never break the viewer.
      return null;
    }
  }

  /// Saves EXIF parsed by the viewer so later opens read it from the database.
  Future<void> saveExif(String id, ExifData? exif) {
    return _mediaDao.updateExif(id, exif);
  }
}
