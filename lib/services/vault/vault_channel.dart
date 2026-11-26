import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_crypto_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_payload_digest.dart';

/// Everything the vault needs from Android.
///
/// The master key lives inside the Android Keystore and never crosses this
/// boundary: there is no method here that returns a key, and there must never
/// be one. Dart hands over a file and gets back ciphertext, plaintext, or an
/// error.
///
/// Bulk data is encrypted under a data keyset that the master key seals
/// (envelope encryption). `keysetPath` on each call says where that sealed
/// keyset lives; Android loads it on first use and keeps it in memory until
/// [forgetDataKey].
///
/// Abstract so every service above it can be tested with a fake, on a host
/// machine, with no keystore in sight.
abstract class VaultChannel {
  /// Whether a master key exists or can be created on this device.
  ///
  /// False on a device whose keystore is broken or missing. The vault refuses
  /// to open in that case rather than falling back to weaker encryption.
  Future<bool> isKeystoreReady();

  /// Creates the master key if it is not there yet.
  Future<void> ensureMasterKey();

  /// Encrypts the file at [sourceUri] or [sourcePath] into [destPath].
  ///
  /// Streamed on the Android side, so file size does not drive memory use.
  Future<VaultCryptoResult> encryptFile({
    String? sourceUri,
    String? sourcePath,
    required String destPath,
    required String destName,
    required String keysetPath,
  });

  /// Encrypts bytes already in memory into [destPath].
  ///
  /// For previews, which are built in Dart. Writing the plaintext preview to
  /// a file first, only to encrypt it, would put a readable copy of a private
  /// photo on disk; this way only ciphertext is ever written.
  Future<VaultCryptoResult> encryptBytes({
    required Uint8List bytes,
    required String destPath,
    required String destName,
    required String keysetPath,
  });

  /// Decrypts a payload straight into memory.
  ///
  /// Used for photos and previews, so nothing decrypted ever lands on disk.
  /// Refuses anything larger than [maxBytes]. [format] is one of
  /// `AppConstants.vaultPayloadFormat*`.
  Future<Uint8List> decryptToBytes({
    required String sourcePath,
    required String iv,
    required int maxBytes,
    required int format,
    required String keysetPath,
  });

  /// Decrypts a payload into a working file, returning its byte count.
  ///
  /// Only for video, which the platform player cannot read from memory. The
  /// destination always sits inside the app-private vault directory, and the
  /// caller is responsible for shredding it afterwards.
  Future<int> decryptToFile({
    required String sourcePath,
    required String iv,
    required String destPath,
    required int format,
    required String keysetPath,
  });

  /// Decrypts a payload as a stream and returns only the SHA-256 and length
  /// of its plaintext. Nothing decrypted crosses the channel.
  Future<VaultPayloadDigest> digestPayload({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
  });

  /// Whether restores can go through MediaStore (Android 10 and later).
  Future<bool> canRestoreToGallery();

  /// A small JPEG preview (longest side [maxSide]) made from an encrypted
  /// photo entirely in memory, or null when the bytes are not a picture.
  /// Refuses payloads over [maxBytes].
  Future<Uint8List?> previewFromPayload({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
    required int maxSide,
    required int maxBytes,
  });

  /// Decrypts a payload straight into a new gallery file in [relativePath]
  /// (e.g. `DCIM/Camera`), reads it back, and only then makes it visible.
  ///
  /// Returns the new file's uri and path, or null on Android 9 and older,
  /// where nothing is written and the caller uses its path-based route.
  /// Throws `VaultException` when the restore fails; nothing is left behind.
  Future<({String uri, String? path})?> restoreToGallery({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
    required String displayName,
    required String mimeType,
    required bool isVideo,
    required String relativePath,
  });

  /// Drops the data keyset from Android's memory. Called when the vault
  /// locks. Never throws: a lock must always go through.
  Future<void> forgetDataKey();

  /// Overwrites the file at [path] [passes] times, then deletes it.
  ///
  /// Returns whether the file is gone. A file that was already missing counts
  /// as success, because that is the outcome the caller wanted.
  Future<bool> shredFile({required String path, required int passes});

  /// Turns the secure window flag on or off.
  ///
  /// Calls are counted on the Android side, so nested vault screens each ask
  /// for it and the flag only clears when the last one lets go.
  Future<void> setSecureFlag(bool enabled);
}

/// The real [VaultChannel], talking to `VaultChannelHandler` on Android.
class PlatformVaultChannel implements VaultChannel {
  final MethodChannel _channel;

  PlatformVaultChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.vaultChannelName);

  @override
  Future<bool> isKeystoreReady() async {
    try {
      return await _channel.invokeMethod<bool>('isKeystoreReady') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      // A host machine or a test with no Android side attached.
      return false;
    }
  }

  @override
  Future<void> ensureMasterKey() async {
    await _invoke<bool>('ensureMasterKey', const <String, Object?>{});
  }

  @override
  Future<VaultCryptoResult> encryptFile({
    String? sourceUri,
    String? sourcePath,
    required String destPath,
    required String destName,
    required String keysetPath,
  }) async {
    if ((sourceUri == null || sourceUri.isEmpty) &&
        (sourcePath == null || sourcePath.isEmpty)) {
      throw const VaultException(
        'There is no source file to encrypt',
        code: 'no_source',
      );
    }

    final map =
        await _invoke<Map<Object?, Object?>>('encryptFile', <String, Object?>{
          'sourceUri': sourceUri,
          'sourcePath': sourcePath,
          'destPath': destPath,
          'keysetPath': keysetPath,
        });

    final iv = map?['iv'];
    final size = map?['sizeBytes'];
    final format = map?['format'];
    final digest = _digestFrom(map);
    if (iv is! String ||
        iv.isEmpty ||
        size is! num ||
        format is! int ||
        digest == null) {
      throw const VaultException(
        'The file could not be encrypted',
        code: 'bad_encrypt_result',
      );
    }

    return VaultCryptoResult(
      fileName: destName,
      iv: iv,
      cipherSizeBytes: size.toInt(),
      format: format,
      plain: digest,
    );
  }

  @override
  Future<VaultCryptoResult> encryptBytes({
    required Uint8List bytes,
    required String destPath,
    required String destName,
    required String keysetPath,
  }) async {
    if (bytes.isEmpty) {
      throw const VaultException(
        'There is nothing to encrypt',
        code: 'no_source',
      );
    }

    final map = await _invoke<Map<Object?, Object?>>(
      'encryptBytes',
      <String, Object?>{
        'bytes': bytes,
        'destPath': destPath,
        'keysetPath': keysetPath,
      },
    );

    final iv = map?['iv'];
    final size = map?['sizeBytes'];
    final format = map?['format'];
    final digest = _digestFrom(map);
    if (iv is! String ||
        iv.isEmpty ||
        size is! num ||
        format is! int ||
        digest == null) {
      throw const VaultException(
        'The preview could not be encrypted',
        code: 'bad_encrypt_result',
      );
    }

    return VaultCryptoResult(
      fileName: destName,
      iv: iv,
      cipherSizeBytes: size.toInt(),
      format: format,
      plain: digest,
    );
  }

  @override
  Future<Uint8List> decryptToBytes({
    required String sourcePath,
    required String iv,
    required int maxBytes,
    required int format,
    required String keysetPath,
  }) async {
    final bytes = await _invoke<Uint8List>('decryptToBytes', <String, Object?>{
      'sourcePath': sourcePath,
      'iv': iv,
      'maxBytes': maxBytes,
      'format': format,
      'keysetPath': keysetPath,
    });
    if (bytes == null || bytes.isEmpty) {
      throw const VaultException(
        'The item could not be decrypted',
        code: 'empty_plaintext',
      );
    }
    return bytes;
  }

  @override
  Future<int> decryptToFile({
    required String sourcePath,
    required String iv,
    required String destPath,
    required int format,
    required String keysetPath,
  }) async {
    final written = await _invoke<int>('decryptToFile', <String, Object?>{
      'sourcePath': sourcePath,
      'iv': iv,
      'destPath': destPath,
      'format': format,
      'keysetPath': keysetPath,
    });
    if (written == null || written <= 0) {
      throw const VaultException(
        'The item could not be decrypted',
        code: 'empty_plaintext',
      );
    }
    return written;
  }

  @override
  Future<VaultPayloadDigest> digestPayload({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
  }) async {
    final map = await _invoke<Map<Object?, Object?>>(
      'digestPayload',
      <String, Object?>{
        'sourcePath': sourcePath,
        'iv': iv,
        'format': format,
        'keysetPath': keysetPath,
      },
    );
    final digest = _digestFrom(map);
    if (digest == null) {
      throw const VaultException(
        'The item could not be checked',
        code: 'verify_failed',
      );
    }
    return digest;
  }

  /// The plaintext digest in a channel answer, or null when it is missing.
  static VaultPayloadDigest? _digestFrom(Map<Object?, Object?>? map) {
    final sha = map?['sha256'];
    final bytes = map?['plainBytes'];
    if (sha is! String || sha.length != 64 || bytes is! num) return null;
    return VaultPayloadDigest(sha256: sha, plainBytes: bytes.toInt());
  }

  @override
  Future<Uint8List?> previewFromPayload({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
    required int maxSide,
    required int maxBytes,
  }) async {
    final bytes =
        await _invoke<Uint8List>('previewFromPayload', <String, Object?>{
          'sourcePath': sourcePath,
          'iv': iv,
          'format': format,
          'keysetPath': keysetPath,
          'maxSide': maxSide,
          'maxBytes': maxBytes,
        });
    return bytes == null || bytes.isEmpty ? null : bytes;
  }

  @override
  Future<bool> canRestoreToGallery() async {
    try {
      return await _channel.invokeMethod<bool>('canRestoreToGallery') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<({String uri, String? path})?> restoreToGallery({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
    required String displayName,
    required String mimeType,
    required bool isVideo,
    required String relativePath,
  }) async {
    final map = await _invoke<Map<Object?, Object?>>(
      'restoreToGallery',
      <String, Object?>{
        'sourcePath': sourcePath,
        'iv': iv,
        'format': format,
        'keysetPath': keysetPath,
        'displayName': displayName,
        'mimeType': mimeType,
        'isVideo': isVideo,
        'relativePath': relativePath,
      },
    );
    if (map?['supported'] == false) return null;
    final uri = map?['uri'];
    if (uri is! String || uri.isEmpty) {
      throw const VaultException(
        'The item could not be restored',
        code: 'restore_failed',
      );
    }
    final path = map?['path'];
    return (uri: uri, path: path is String ? path : null);
  }

  @override
  Future<void> forgetDataKey() async {
    try {
      await _channel.invokeMethod<bool>('forgetDataKey');
    } on PlatformException {
      // Nothing to report; the lock itself has already happened in Dart.
    } on MissingPluginException {
      // A host machine or a test with no Android side attached.
    }
  }

  @override
  Future<bool> shredFile({required String path, required int passes}) async {
    try {
      final ok = await _channel.invokeMethod<bool>(
        'shredFile',
        <String, Object?>{'path': path, 'passes': passes},
      );
      return ok ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<void> setSecureFlag(bool enabled) async {
    try {
      await _channel.invokeMethod<void>('setSecureFlag', <String, Object?>{
        'enabled': enabled,
      });
    } on PlatformException {
      // The window flag is a hardening measure, not a correctness one. Losing
      // it must not stop the user reaching their own photos, so this is not
      // rethrown — but it is also never silently reported as applied.
    } on MissingPluginException {
      // Nothing to protect off Android.
    }
  }

  /// Runs a channel call, turning every platform failure into a
  /// [VaultException].
  ///
  /// The message deliberately never carries a path or a file name. A vault
  /// error can end up in a log, and a log naming a vault file would give away
  /// part of what the vault exists to hide.
  Future<T?> _invoke<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error, stackTrace) {
      throw VaultException(
        _messageForCode(error.code),
        code: error.code,
        cause: error.code,
        stackTrace: stackTrace,
      );
    } on MissingPluginException catch (error, stackTrace) {
      throw VaultException(
        'The secure vault is not available on this device',
        code: 'channel_missing',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'payload_tampered':
        return 'The item failed its integrity check and was not opened';
      case 'invalid_arguments':
        return 'The vault was asked for something it cannot do';
      default:
        return 'The secure vault operation failed';
    }
  }
}
