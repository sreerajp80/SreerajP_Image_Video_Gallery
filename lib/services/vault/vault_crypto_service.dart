import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_crypto_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_payload_digest.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

/// Encrypts and decrypts vault payloads.
///
/// Sits between the repository and the channel, and owns two decisions the
/// layers either side of it should not have to make: where a payload goes, and
/// whether a decrypt is allowed to go through memory.
///
/// Every write uses the current format
/// ([AppConstants.vaultPayloadFormatStreaming]): bulk AES on the normal CPU
/// under a data keyset that the Keystore master key seals. Reads follow the
/// format stored in the row, so old items still open.
///
/// Photos and previews decrypt into a `Uint8List` and are shown from there, so
/// no decrypted image is ever written to disk. A video cannot be played from
/// memory by the platform player, so it decrypts into a working file inside
/// the app-private vault directory — never the public cache and never the
/// temporary directory — and the caller shreds that file the moment the player
/// closes.
class VaultCryptoService {
  final VaultChannel _channel;
  final VaultStorageService _storage;
  final VaultNamingService _naming;

  VaultCryptoService({
    required VaultChannel channel,
    required VaultStorageService storage,
    VaultNamingService? naming,
  }) : _channel = channel,
       _storage = storage,
       _naming = naming ?? VaultNamingService();

  /// Encrypts an original into a new payload inside the vault directory.
  Future<VaultCryptoResult> encryptToPayload({
    String? sourceUri,
    String? sourcePath,
  }) async {
    final name = _naming.newPayloadName();
    return _channel.encryptFile(
      sourceUri: sourceUri,
      sourcePath: sourcePath,
      destPath: await _storage.pathFor(name),
      destName: name,
      keysetPath: await _keysetPath(),
    );
  }

  /// Encrypts a whole photo already in memory into a new media payload.
  ///
  /// Used by the format upgrade, which decrypts an old photo into memory and
  /// writes it again in the new format without it ever touching disk in the
  /// clear.
  Future<VaultCryptoResult> encryptBytesToPayload(Uint8List bytes) async {
    final name = _naming.newPayloadName();
    return _channel.encryptBytes(
      bytes: bytes,
      destPath: await _storage.pathFor(name),
      destName: name,
      keysetPath: await _keysetPath(),
    );
  }

  /// Encrypts preview bytes into a new preview payload.
  ///
  /// Takes bytes rather than a path on purpose. The preview is built in
  /// memory, and writing it out in the clear just so it could be encrypted
  /// would leave a readable copy of a private photo on disk, however briefly.
  Future<VaultCryptoResult> encryptThumbnailBytes(Uint8List bytes) async {
    final name = _naming.newThumbnailName();
    return _channel.encryptBytes(
      bytes: bytes,
      destPath: await _storage.pathFor(name),
      destName: name,
      keysetPath: await _keysetPath(),
    );
  }

  /// Decrypts a payload into memory.
  ///
  /// Refuses anything over [AppConstants.vaultMaxDecryptToMemoryBytes], which
  /// is what stops a video from being pulled into memory by a caller that
  /// meant to ask for a photo.
  Future<Uint8List> decryptToMemory({
    required String fileName,
    required String iv,
    required int format,
  }) async {
    if (fileName.isEmpty || iv.isEmpty) {
      throw const VaultException(
        'The item is missing what it needs to be decrypted',
        code: 'incomplete_record',
      );
    }
    return _channel.decryptToBytes(
      sourcePath: await _storage.pathFor(fileName),
      iv: iv,
      maxBytes: AppConstants.vaultMaxDecryptToMemoryBytes,
      format: format,
      keysetPath: await _keysetPath(),
    );
  }

  /// Decrypts a payload into a working file and returns its path.
  ///
  /// Only for video. The caller must shred the returned path when it is done
  /// with it; the shredder service is what does that, and the sweep on vault
  /// open catches any that a crash left behind.
  Future<String> decryptToWorkingFile({
    required String fileName,
    required String iv,
    required int format,
  }) async {
    if (fileName.isEmpty || iv.isEmpty) {
      throw const VaultException(
        'The item is missing what it needs to be decrypted',
        code: 'incomplete_record',
      );
    }
    final workingPath = await _storage.pathFor(
      _naming.workingNameFor(fileName),
    );
    await _channel.decryptToFile(
      sourcePath: await _storage.pathFor(fileName),
      iv: iv,
      destPath: workingPath,
      format: format,
      keysetPath: await _keysetPath(),
    );
    return workingPath;
  }

  /// Reads back a payload just written and checks it gives back exactly
  /// the plaintext that went in.
  ///
  /// Called before anything readable is let go: before an old file is
  /// deleted, an original hidden or shredded, or a received copy dropped.
  /// Throws `VaultException(code: 'verify_failed')` on any mismatch or read
  /// failure; the caller then deletes the new file and keeps the old copy.
  Future<void> verifyWritten(VaultCryptoResult written) async {
    final VaultPayloadDigest actual;
    try {
      actual = await _channel.digestPayload(
        sourcePath: await _storage.pathFor(written.fileName),
        iv: written.iv,
        format: written.format,
        keysetPath: await _keysetPath(),
      );
    } on VaultException catch (error, stackTrace) {
      throw VaultException(
        'A vault file could not be read back after it was written',
        code: 'verify_failed',
        cause: error.code,
        stackTrace: stackTrace,
      );
    }
    if (actual != written.plain) {
      throw const VaultException(
        'A vault file did not read back the same as what was written',
        code: 'verify_failed',
      );
    }
  }

  /// Whether restores can go through MediaStore (Android 10 and later).
  Future<bool> canRestoreToGallery() => _channel.canRestoreToGallery();

  /// A preview JPEG made from a photo payload in memory, or null when it is
  /// not a picture. Nothing decrypted is written anywhere.
  Future<Uint8List?> previewFromPayload({
    required String fileName,
    required String iv,
    required int format,
  }) async {
    if (fileName.isEmpty || iv.isEmpty) return null;
    return _channel.previewFromPayload(
      sourcePath: await _storage.pathFor(fileName),
      iv: iv,
      format: format,
      keysetPath: await _keysetPath(),
      maxSide: AppConstants.vaultThumbnailSize,
      maxBytes: AppConstants.vaultMaxDecryptToMemoryBytes,
    );
  }

  /// Decrypts [item]'s payload straight into a new gallery file named
  /// [displayName] in [relativePath], read back before it becomes visible.
  ///
  /// Null on Android 9 and older (nothing written). Throws on failure.
  Future<({String uri, String? path})?> restoreToGallery({
    required String fileName,
    required String iv,
    required int format,
    required String displayName,
    required String mimeType,
    required bool isVideo,
    required String relativePath,
  }) async {
    if (fileName.isEmpty || iv.isEmpty) {
      throw const VaultException(
        'The item is missing what it needs to be decrypted',
        code: 'incomplete_record',
      );
    }
    return _channel.restoreToGallery(
      sourcePath: await _storage.pathFor(fileName),
      iv: iv,
      format: format,
      keysetPath: await _keysetPath(),
      displayName: displayName,
      mimeType: mimeType,
      isVideo: isVideo,
      relativePath: relativePath,
    );
  }

  /// Drops the data keyset from memory. Called when the vault locks.
  Future<void> forgetDataKey() => _channel.forgetDataKey();

  Future<String> _keysetPath() =>
      _storage.pathFor(AppConstants.vaultDataKeyFileName);
}
