import 'dart:io';
import 'dart:math';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Moves media out of the public gallery and into the vault.
///
/// The order of the steps is the whole design. The encrypted payload is
/// written first, then the preview, then the database row, and only then is
/// the original touched. Anything that fails before that last step leaves the
/// original exactly where it was, and the half-written payload is deleted on
/// the way out — so a failed import costs the user nothing, which is the only
/// acceptable outcome when the alternative is losing a photo.
///
/// Shredding the original is opt-in. The caller passes [shredOriginals] only
/// after the user has chosen it and confirmed it, because it destroys a file
/// for good.
class VaultImportService {
  final VaultCryptoService _crypto;
  final VaultStorageService _storage;
  final VaultShredderService _shredder;
  final VaultPreviewService _preview;
  final VaultDao _vaultDao;
  final MediaDao _mediaDao;
  final MediaStoreChannel? _mediaStore;
  final Random _random;

  VaultImportService({
    required VaultCryptoService crypto,
    required VaultStorageService storage,
    required VaultShredderService shredder,
    required VaultPreviewService preview,
    required VaultDao vaultDao,
    required MediaDao mediaDao,
    MediaStoreChannel? mediaStore,
    Random? random,
  }) : _crypto = crypto,
       _storage = storage,
       _shredder = shredder,
       _preview = preview,
       _vaultDao = vaultDao,
       _mediaDao = mediaDao,
       _mediaStore = mediaStore,
       _random = random ?? Random.secure();

  /// Imports [items], returning what made it and what did not.
  ///
  /// One bad file does not sink the batch: it is counted and the rest carry
  /// on. Importing forty photos and losing all of them because the ninth was
  /// corrupt would be the wrong trade.
  Future<VaultBatchResult> importItems(
    List<MediaItem> items, {
    bool shredOriginals = false,
    int? shredPasses,
    void Function(int done, int total)? onProgress,
  }) async {
    if (items.isEmpty) return VaultBatchResult.empty;

    final imported = <String>[];
    final toShred = <MediaItem>[];
    var failed = 0;
    var shredded = 0;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      try {
        final vaultItem = await _importOne(item);
        imported.add(vaultItem.id);
        if (shredOriginals) toShred.add(item);
      } catch (error) {
        AppLogger.warning(
          'Moving one item into the vault failed',
          error: error,
        );
        failed++;
      }
      onProgress?.call(index + 1, items.length);
    }

    // Only originals whose import fully succeeded are shredded, and all of
    // them in one go at the end, so Android asks once for the whole set.
    if (toShred.isNotEmpty) {
      // `this.` because the bool parameter has the same name.
      shredded = await this.shredOriginals(toShred, passes: shredPasses);
    }

    return VaultBatchResult(
      succeededIds: imported,
      failedCount: failed,
      shreddedCount: shredded,
    );
  }

  /// Writes over and deletes the public originals. Returns how many are gone.
  ///
  /// On a device this goes through MediaStore ([MediaStoreChannel]
  /// .secureDeleteMedia). Opening the public file by its path, as this used
  /// to, fails on Android 11+: the app may read a photo it did not create but
  /// not write to it, so the overwrite and the delete both failed quietly and
  /// the original stayed. The path shredder is kept only for when there is no
  /// MediaStore channel (tests, a host machine).
  ///
  /// Public so a batch that imports one photo at a time (for progress and
  /// Cancel) can still shred them all in one call at the end, and Android
  /// asks once. Only pass items whose import has already succeeded.
  Future<int> shredOriginals(List<MediaItem> items, {int? passes}) async {
    if (items.isEmpty) return 0;
    final passCount = (passes ?? AppConstants.vaultDefaultShredPasses).clamp(
      AppConstants.vaultMinShredPasses,
      AppConstants.vaultMaxShredPasses,
    );
    final mediaStore = _mediaStore;
    if (mediaStore != null) {
      try {
        final outcomes = await mediaStore.secureDeleteMedia(
          targets: <({String uri, String path})>[
            for (final item in items) (uri: item.uri ?? '', path: item.path),
          ],
          passes: passCount,
        );
        // Only a real overwrite counts as shredded. A file that was deleted
        // without being written over is gone, but not shredded.
        return outcomes
            .where((o) => o == MediaDeleteOutcome.overwritten)
            .length;
      } catch (error) {
        AppLogger.warning('Shredding the originals failed', error: error);
        return 0;
      }
    }

    var count = 0;
    for (final item in items) {
      if (item.path.isEmpty) continue;
      if (await _shredder.shred(item.path, passes: passCount)) count++;
    }
    return count;
  }

  /// Imports one item, cleaning up after itself if anything goes wrong.
  Future<VaultItem> _importOne(MediaItem item) async {
    if (item.size > AppConstants.vaultMaxImportBytes) {
      throw const VaultException(
        'The file is too large for the vault',
        code: 'too_large',
      );
    }

    // 1. The payload. Nothing about the original changes yet.
    final payload = await _crypto.encryptToPayload(
      sourceUri: item.uri,
      sourcePath: item.path,
    );

    String? thumbnailName;
    String? thumbnailIv;
    try {
      // 2. The preview, built in memory and encrypted without ever being
      // written out in the clear. A preview that cannot be made is not fatal.
      final previewBytes = await _preview.buildPreview(item);
      if (previewBytes != null && previewBytes.isNotEmpty) {
        final thumbnail = await _crypto.encryptThumbnailBytes(previewBytes);
        thumbnailName = thumbnail.fileName;
        // Its own IV, kept beside its own file. The payload's would not
        // decrypt it, and handing the cipher the wrong one would fail the
        // authentication tag rather than quietly returning rubbish.
        thumbnailIv = thumbnail.iv;
      }

      // 3. The record. The IV is stored beside the payload because decryption
      // needs it; the key it goes with never leaves the keystore.
      final vaultItem = VaultItem(
        id: _newId(),
        originalPath: item.path,
        originalFilename: item.displayName,
        encryptedFilename: payload.fileName,
        encryptedThumbnailFilename: thumbnailName,
        mediaType: item.mediaType,
        mimeType: item.mimeType,
        sizeBytes: payload.cipherSizeBytes,
        iv: payload.iv,
        thumbnailIv: thumbnailIv,
        dateVaulted: DateTime.now(),
        dateTaken: item.dateTaken,
        width: item.width,
        height: item.height,
        durationMs: item.durationMs,
        tags: item.tags,
        notes: item.userNotes,
      );
      await _vaultDao.insertVaultItem(vaultItem);

      // 4. Hide it from the gallery. Every media query already excludes
      // vaulted rows, so this is what makes it disappear from the timeline,
      // albums, search, and the duplicate scan at once.
      await _mediaDao.updateVaulted(item.id, true);

      return vaultItem;
    } catch (error) {
      // Roll back everything this import wrote. An encrypted file nobody has
      // a record of is dead weight the user can neither see nor delete.
      await _deleteQuietly(payload.fileName);
      if (thumbnailName != null) await _deleteQuietly(thumbnailName);
      rethrow;
    }
  }

  /// Deletes a payload written by an import that then failed.
  ///
  /// A plain delete, not a shred: this file has never been anything but
  /// ciphertext, and its plaintext original is still sitting untouched where
  /// it always was.
  Future<void> _deleteQuietly(String fileName) async {
    try {
      final file = File(await _storage.pathFor(fileName));
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Safe to ignore: the orphan sweep at the next unlock removes it.
      // Already gone, or unreachable. Either way there is nothing useful to
      // do about it here, and the orphan sweep will catch it.
    }
  }

  /// A random identifier for a vault record.
  ///
  /// Random rather than derived from the media id, so the record cannot be
  /// tied back to a public gallery item by anyone reading the table.
  String _newId() {
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
