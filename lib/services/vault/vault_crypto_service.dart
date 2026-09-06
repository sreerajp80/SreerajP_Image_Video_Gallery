import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_crypto_result.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

/// Encrypts and decrypts vault payloads.
///
/// Sits between the repository and the channel, and owns two decisions the
/// layers either side of it should not have to make: where a payload goes, and
/// whether a decrypt is allowed to go through memory.
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
    );
    return workingPath;
  }
}
