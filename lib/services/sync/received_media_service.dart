import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_exchange_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Puts an arriving file into the gallery, and its metadata into the database.
///
/// This is the only place a transferred file becomes a real photo, and it is
/// deliberately the last step. Everything before it happens in an app-private
/// staging directory, so a transfer that is cancelled, times out, or fails its
/// digest check leaves nothing behind in the user's pictures.
///
/// Nothing is ever overwritten. MediaStore renames a clashing file, and the
/// pre-Android-10 fallback numbers it, so hard rule 4 holds for files that
/// came from another device just as it does for ones the editor saved.
class ReceivedMediaService implements IncomingFileSink {
  final MediaStoreChannel _mediaStore;
  final MediaRepository _mediaRepository;
  final MediaDao _mediaDao;
  final TagRepository _tagRepository;

  /// Where staging files go. Resolved once and reused.
  Directory? _stagingRoot;

  ReceivedMediaService({
    required MediaStoreChannel mediaStore,
    required MediaRepository mediaRepository,
    required MediaDao mediaDao,
    required TagRepository tagRepository,
  }) : _mediaStore = mediaStore,
       _mediaRepository = mediaRepository,
       _mediaDao = mediaDao,
       _tagRepository = tagRepository;

  /// Paths of everything this session landed, in arrival order.
  final List<String> receivedPaths = <String>[];

  /// Whether any file had to go to the app's own directory rather than the
  /// shared gallery.
  ///
  /// True only on Android 9 and below. The screen uses it to say where the
  /// photos actually went, instead of leaving somebody hunting the camera
  /// roll for files that are not in it.
  bool usedFallbackDirectory = false;

  @override
  Future<bool> alreadyHave(String sha256) async {
    if (sha256.isEmpty) return false;
    try {
      return await _mediaDao.hasMediaWithHash(sha256);
    } catch (_) {
      // If the check itself fails, take the file. Receiving a duplicate is a
      // far smaller problem than silently refusing a photo the user wanted.
      return false;
    }
  }

  @override
  Future<File> openStaging(TransferEntry entry) async {
    final root = await _staging();
    final file = File(
      p.join(
        root.path,
        '${DateTime.now().microsecondsSinceEpoch}_'
        '${TransferExchangeService.safeFileName(entry.displayName)}',
      ),
    );
    await file.parent.create(recursive: true);
    return file;
  }

  @override
  Future<String> commit(TransferEntry entry, File staged) async {
    final name = TransferExchangeService.safeFileName(entry.displayName);
    final isVideo = entry.mediaTypeName == 'video';

    final published = await _mediaStore.publishFile(
      sourcePath: staged.path,
      displayName: name,
      mimeType: entry.mimeType,
      isVideo: isVideo,
      relativeDir: AppConstants.syncReceiveDirectoryName,
    );

    if (!published.usedMediaStore) usedFallbackDirectory = true;

    // The staged copy has served its purpose. It is app-private, but leaving
    // a second copy of every received photo on the device would quietly
    // double what a transfer costs in storage.
    await _deleteQuietly(staged);

    final landedPath = published.path ?? published.uri;
    receivedPaths.add(landedPath);

    await _applyMetadata(entry, landedPath);
    return landedPath;
  }

  /// Carries the sender's favourite mark, note and tags onto the new file.
  ///
  /// Best effort, and deliberately so: the photo itself is safely in the
  /// gallery by this point, and losing a tag is not a reason to report the
  /// transfer as failed. The scan that follows will index the file either way.
  Future<void> _applyMetadata(TransferEntry entry, String path) async {
    try {
      final item = await _mediaRepository.getMediaItemByPath(path);
      if (item == null) return;

      if (entry.isFavorite) {
        await _mediaRepository.setFavorite(item.id, true);
      }
      if (entry.userNotes != null && entry.userNotes!.isNotEmpty) {
        await _mediaDao.updateUserNotes(item.id, entry.userNotes);
      }

      // Tags travel as names, not ids: the sender's ids mean nothing here.
      // A name that already exists is reused rather than duplicated.
      for (final name in entry.tagNames) {
        if (name.trim().isEmpty) continue;
        try {
          final tag = await _tagRepository.findOrCreateTag(name);
          await _tagRepository.addTagToMedia(item.id, tag.id);
        } catch (_) {
          // One name the tag rules refuse. The others still land.
        }
      }
    } catch (_) {
      // The file is in the gallery; the metadata is a bonus, not the point.
    }
  }

  /// Asks the scanner to pick up everything that arrived.
  ///
  /// Called once at the end rather than after each file: a rescan per photo
  /// on a forty-photo transfer would be forty passes over the library.
  Future<void> indexReceived() async {
    if (receivedPaths.isEmpty) return;
    try {
      await _mediaRepository.scanDevice(incremental: true);
    } catch (_) {
      // A failed scan means the photos show up on the next one. They are on
      // the device either way, which is the part that matters.
    }
  }

  /// Deletes any staging file a crash or a cancel left behind.
  ///
  /// Called when the transfer screen opens, so a killed session does not
  /// leave half-received photos taking up space for good.
  Future<void> sweepStaging() async {
    try {
      final root = await _staging();
      if (!await root.exists()) return;

      await for (final entity in root.list()) {
        if (entity is File) await _deleteQuietly(entity);
      }
    } catch (_) {
      // Nothing useful to do; it is app-private space.
    }
  }

  Future<Directory> _staging() async {
    final cached = _stagingRoot;
    if (cached != null) return cached;

    final base = await getApplicationSupportDirectory();
    final root = Directory(p.join(base.path, 'incoming_transfers'));
    await root.create(recursive: true);
    _stagingRoot = root;
    return root;
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // App-private staging; it goes with the cache.
    }
  }
}
