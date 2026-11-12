import 'dart:io';
import 'dart:math';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

/// Copies the private vault to another phone during a phone move.
///
/// Only when the user turned it on and unlocked the vault first. The vault
/// key never leaves the keystore; it cannot. So each item is decrypted here,
/// sent over the already-encrypted transfer link, and encrypted again on the
/// other phone with that phone's own key.
///
/// **Sending side.** [openPlain] decrypts one item into a working file inside
/// the app-private vault folder (never the public cache, never MediaStore),
/// and [closePlain] shreds it the moment that file has been sent, whether it
/// went or not. A crash in between leaves a working file that the sweep on
/// the next vault unlock shreds.
///
/// **Receiving side.** [importReceived] takes a staged file from the transfer
/// (app-private too), encrypts it into this phone's vault, adds the row, and
/// shreds the staged plaintext on every path out. It follows the same order
/// as the import from the gallery: payload first, then preview, then row, and
/// any failure removes what it wrote.
///
/// Nothing is removed from the sending phone's vault. It is a copy.
class VaultTransferService {
  final VaultCryptoService _crypto;
  final VaultStorageService _storage;
  final VaultShredderService _shredder;
  final VaultPreviewService _preview;
  final VaultDao _vaultDao;

  /// Whether this phone has a vault that can take items: set up, with a
  /// working keystore key.
  final Future<bool> Function() _isReady;

  final Random _random;

  VaultTransferService({
    required VaultCryptoService crypto,
    required VaultStorageService storage,
    required VaultShredderService shredder,
    required VaultPreviewService preview,
    required VaultDao vaultDao,
    required Future<bool> Function() isReady,
    Random? random,
  }) : _crypto = crypto,
       _storage = storage,
       _shredder = shredder,
       _preview = preview,
       _vaultDao = vaultDao,
       _isReady = isReady,
       _random = random ?? Random.secure();

  /// Whether this phone can receive vault items. Never throws.
  Future<bool> isReady() async {
    try {
      return await _isReady();
    } catch (error) {
      AppLogger.debug('Checking whether the vault can receive failed');
      return false;
    }
  }

  // ---------------------------------------------------------------- sender

  /// Every item in the vault, oldest first.
  Future<List<VaultItem>> items() async {
    final all = List<VaultItem>.from(await _vaultDao.getAllVaultItems())
      ..sort((a, b) => a.dateVaulted.compareTo(b.dateVaulted));
    return all;
  }

  /// Decrypts [item] into a working file and returns it.
  ///
  /// The caller must hand the file to [closePlain] when done with it.
  Future<File> openPlain(VaultItem item) async {
    final path = await _crypto.decryptToWorkingFile(
      fileName: item.encryptedFilename,
      iv: item.iv,
    );
    return File(path);
  }

  /// Shreds a working file from [openPlain]. Never throws.
  Future<void> closePlain(File file) async {
    try {
      await _shredder.shred(file.path);
    } catch (error) {
      AppLogger.warning('Shredding a sent vault file failed', error: error);
      // The sweep on the next unlock tries again.
    }
  }

  // -------------------------------------------------------------- receiver

  /// Puts a received file into this phone's vault.
  ///
  /// [staged] is shredded on every path out, success or not.
  Future<VaultItem> importReceived({
    required File staged,
    required String displayName,
    required String mimeType,
    required MediaType mediaType,
    DateTime? dateTaken,
    List<String> tags = const <String>[],
    String? notes,
  }) async {
    String? payloadName;
    String? thumbnailName;
    try {
      if (!await isReady()) {
        throw const VaultException(
          'This phone has no vault to receive into',
          code: 'not_set_up',
        );
      }

      final length = await staged.length();
      if (length <= 0 || length > AppConstants.vaultMaxImportBytes) {
        throw const VaultException(
          'The file is too large for the vault',
          code: 'too_large',
        );
      }

      // 1. The payload, encrypted with this phone's own key.
      final payload = await _crypto.encryptToPayload(sourcePath: staged.path);
      payloadName = payload.fileName;

      // 2. The preview. One that cannot be made is not fatal.
      String? thumbnailIv;
      final previewBytes = await _preview.buildPreview(
        _asMediaItem(staged, displayName, mimeType, mediaType, length),
      );
      if (previewBytes != null && previewBytes.isNotEmpty) {
        final thumbnail = await _crypto.encryptThumbnailBytes(previewBytes);
        thumbnailName = thumbnail.fileName;
        thumbnailIv = thumbnail.iv;
      }

      // 3. The record, last. There is no gallery row to hide: the file was
      // never in the gallery on this phone.
      final item = VaultItem(
        id: _newId(),
        originalPath: '',
        originalFilename: displayName,
        encryptedFilename: payload.fileName,
        encryptedThumbnailFilename: thumbnailName,
        mediaType: mediaType,
        mimeType: mimeType,
        sizeBytes: payload.cipherSizeBytes,
        iv: payload.iv,
        thumbnailIv: thumbnailIv,
        dateVaulted: DateTime.now(),
        dateTaken: dateTaken,
        tags: tags,
        notes: notes,
      );
      await _vaultDao.insertVaultItem(item);
      return item;
    } catch (error) {
      if (payloadName != null) await _deleteQuietly(payloadName);
      if (thumbnailName != null) await _deleteQuietly(thumbnailName);
      if (error is AppException) rethrow;
      throw VaultException(
        'Putting a received file into the vault failed',
        code: 'receive_failed',
        cause: error,
      );
    } finally {
      // The plaintext copy goes whatever happened above.
      try {
        await _shredder.shred(staged.path);
      } catch (_) {
        // Safe to ignore: the staging sweep at the next transfer deletes it.
      }
    }
  }

  /// A stand-in gallery item, only so the preview service can read the file.
  static MediaItem _asMediaItem(
    File file,
    String name,
    String mimeType,
    MediaType type,
    int size,
  ) {
    final now = DateTime.now();
    return MediaItem(
      id: 'vault-receive',
      path: file.path,
      displayName: name,
      mediaType: type,
      mimeType: mimeType,
      size: size,
      dateAdded: now,
      dateModified: now,
    );
  }

  Future<void> _deleteQuietly(String fileName) async {
    try {
      final file = File(await _storage.pathFor(fileName));
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Safe to ignore: the orphan sweep at the next unlock removes it.
    }
  }

  /// A random identifier, by the same rule as a gallery import.
  String _newId() {
    final buffer = StringBuffer();
    for (var i = 0; i < 16; i++) {
      buffer.write(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }
}
