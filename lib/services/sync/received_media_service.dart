import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/domain/sync/folder_name_rules.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/send_limit_rules.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_exchange_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_transfer_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

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
  final AlbumRepository _albumRepository;

  /// Puts vault entries into this phone's vault. Null where there is none,
  /// and then every vault entry is refused.
  final VaultTransferService? _vault;

  /// Where staging files go. Resolved once and reused.
  Directory? _stagingRoot;

  ReceivedMediaService({
    required MediaStoreChannel mediaStore,
    required MediaRepository mediaRepository,
    required MediaDao mediaDao,
    required TagRepository tagRepository,
    required AlbumRepository albumRepository,
    VaultTransferService? vault,
  }) : _vault = vault,
       _mediaStore = mediaStore,
       _mediaRepository = mediaRepository,
       _mediaDao = mediaDao,
       _tagRepository = tagRepository,
       _albumRepository = albumRepository;

  /// Paths of everything this session landed, in arrival order.
  final List<String> receivedPaths = <String>[];

  /// Files that landed and still need their details applied.
  ///
  /// The details (favourite, notes, tags, albums, place) can only be written
  /// once the scan has given the new file a row in the database. Writing
  /// them straight after the copy would find no row and lose them.
  final List<({String path, TransferEntry entry})> _pending =
      <({String path, TransferEntry entry})>[];

  /// Whether any file had to go to the app's own directory rather than the
  /// shared gallery.
  ///
  /// True only on Android 9 and below. The screen uses it to say where the
  /// photos actually went, instead of leaving somebody hunting the camera
  /// roll for files that are not in it.
  bool usedFallbackDirectory = false;

  /// Clears what one session collected, ready for the next.
  void reset() {
    vaultReceivedCount = 0;
    receivedPaths.clear();
    _pending.clear();
    usedFallbackDirectory = false;
  }

  /// How many files this session put into the vault.
  int vaultReceivedCount = 0;

  @override
  Future<bool> alreadyHave(TransferEntry entry) async {
    final sha256 = entry.sha256;
    if (sha256.isEmpty) return false;
    // A vault file is always taken. The same photo sitting in the public
    // gallery here does not make the private copy arrive.
    if (entry.vault) return false;
    try {
      return await _mediaDao.hasMediaWithHash(sha256);
    } catch (error) {
      AppLogger.warning(
        'The duplicate check before receiving failed',
        error: error,
      );
      // If the check itself fails, take the file. Receiving a duplicate is a
      // far smaller problem than silently refusing a photo the user wanted.
      return false;
    }
  }

  /// Free space on the shared storage, in bytes, or null when unknown.
  Future<int?> freeSpaceBytes() async {
    try {
      return await _mediaStore.freeSpaceBytes();
    } catch (error) {
      AppLogger.debug('Reading free space failed');
      return null;
    }
  }

  @override
  Future<bool> hasRoomFor(int bytes) async {
    final free = await freeSpaceBytes();
    // Unknown free space is not a reason to refuse. Android itself stops a
    // write that does not fit, and that file is then reported as failed.
    if (free == null) return true;
    return SendLimitRules.fitsOneFile(freeBytes: free, fileBytes: bytes);
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

    // A vault file never goes near MediaStore or the public gallery. With no
    // vault here it is refused, and the staged copy is removed.
    if (entry.vault) {
      final vault = _vault;
      if (vault == null) {
        await _deleteQuietly(staged);
        throw const VaultException(
          'This phone cannot take vault files',
          code: 'not_set_up',
        );
      }
      final item = await vault.importReceived(
        staged: staged,
        displayName: name,
        mimeType: entry.mimeType,
        mediaType: MediaType.fromString(entry.mediaTypeName),
        dateTaken: entry.dateTakenMs == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(entry.dateTakenMs!),
        tags: entry.tagNames,
        notes: entry.userNotes,
      );
      vaultReceivedCount++;
      return item.id;
    }

    final isVideo = entry.mediaTypeName == 'video';

    final published = await _mediaStore.publishFile(
      sourcePath: staged.path,
      displayName: name,
      mimeType: entry.mimeType,
      isVideo: isVideo,
      // `Drishya Sync/<sender folder>`. Photos and videos share it, so one
      // folder on the other phone stays one folder here.
      relativeDir: FolderNameRules.receiveDirectoryFor(entry.sourceFolder),
      underPictures: true,
    );

    if (!published.usedMediaStore) usedFallbackDirectory = true;

    // The staged copy has served its purpose. It is app-private, but leaving
    // a second copy of every received photo on the device would quietly
    // double what a transfer costs in storage.
    await _deleteQuietly(staged);

    final landedPath = published.path ?? published.uri;
    receivedPaths.add(landedPath);
    _pending.add((path: landedPath, entry: entry));
    return landedPath;
  }

  /// Asks the scanner to pick up everything that arrived, then applies the
  /// details that travelled with each file.
  ///
  /// Called once per send rather than after each file: a rescan per photo on
  /// a forty-photo transfer would be forty passes over the library.
  Future<void> indexReceived() async {
    if (_pending.isEmpty) return;
    try {
      await _mediaRepository.scanDevice(incremental: true);
    } catch (error) {
      AppLogger.warning('Indexing received photos failed', error: error);
      // A failed scan means the photos show up on the next one. They are on
      // the device either way, which is the part that matters. Their details
      // are tried below anyway, in case the scan got far enough.
    }

    final pending = List<({String path, TransferEntry entry})>.from(_pending);
    _pending.clear();

    List<Album>? albums;
    for (final landed in pending) {
      albums ??= await _virtualAlbums();
      await _applyMetadata(landed.entry, landed.path, albums);
    }
  }

  /// Carries the sender's details onto the new file.
  ///
  /// Best effort, and deliberately so: the photo itself is safely in the
  /// gallery by this point, and losing a tag is not a reason to report the
  /// transfer as failed.
  Future<void> _applyMetadata(
    TransferEntry entry,
    String path,
    List<Album> albums,
  ) async {
    try {
      final item = await _mediaRepository.getMediaItemByPath(path);
      if (item == null) return;

      // The digest was checked on arrival, so it is known to be right. Saving
      // it lets the next transfer skip this file without moving it again.
      if (entry.sha256.isNotEmpty) {
        await _mediaDao.updateHashes(item.id, sha256: entry.sha256);
      }

      final notes = entry.userNotes;
      final address = entry.address;
      await _mediaDao.applyBackupRecord(
        item.id,
        isFavorite: entry.isFavorite ? true : null,
        userNotes: notes != null && notes.isNotEmpty ? notes : null,
        address: address != null && address.isNotEmpty ? address : null,
        latitude: item.latitude == null ? entry.latitude : null,
        longitude: item.longitude == null ? entry.longitude : null,
      );

      // Tags travel as names, not ids: the sender's ids mean nothing here.
      // A name that already exists is reused rather than duplicated.
      for (final name in entry.tagNames) {
        if (name.trim().isEmpty) continue;
        try {
          final tag = await _tagRepository.findOrCreateTag(name);
          await _tagRepository.addTagToMedia(item.id, tag.id);
        } catch (error) {
          AppLogger.debug('A received tag name was refused');
          // One name the tag rules refuse. The others still land.
        }
      }

      // Albums by the same rule: matched by name, case ignored, and made
      // when this phone has none of that name.
      for (final name in entry.albumNames) {
        final key = name.trim().toLowerCase();
        if (key.isEmpty) continue;
        try {
          var album = _albumNamed(albums, key);
          if (album == null) {
            album = await _albumRepository.createAlbum(name.trim());
            albums.add(album);
          }
          await _albumRepository.addMedia(album.id, item.id);
        } catch (error) {
          AppLogger.debug('A received album name was refused');
          // One name the album rules refuse. The others still land.
        }
      }
    } catch (error) {
      AppLogger.warning(
        'Saving details for a received photo failed',
        error: error,
      );
      // The file is in the gallery; the metadata is a bonus, not the point.
    }
  }

  Future<List<Album>> _virtualAlbums() async {
    try {
      return List<Album>.from(await _albumRepository.getVirtualAlbums());
    } catch (error) {
      AppLogger.debug('Reading albums before applying received ones failed');
      return <Album>[];
    }
  }

  static Album? _albumNamed(List<Album> albums, String key) {
    for (final album in albums) {
      if (album.name.trim().toLowerCase() == key) return album;
    }
    return null;
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
      // Safe to ignore: app-private staging space that goes with the cache.
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
      // Safe to ignore: app-private staging space that goes with the cache.
    }
  }
}
