import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Why a cipher call failed.
enum BackupCryptoFailure {
  /// The password did not open the archive, or the file was damaged.
  ///
  /// With AES-GCM these are the same event from the inside: a failed tag
  /// check says the bytes and the key do not agree, not which of them is
  /// wrong. The message says both, so nobody is told their file is fine
  /// when it is not.
  wrongPasswordOrDamaged,

  /// The call was made with something the platform would not accept.
  invalidArguments,

  /// Anything else.
  failed,
}

/// Thrown when the backup channel refuses a call.
class BackupCryptoException implements Exception {
  final BackupCryptoFailure failure;
  final String message;

  const BackupCryptoException(this.failure, this.message);

  /// Whether this is the everyday case of a mistyped password.
  bool get isWrongPassword =>
      failure == BackupCryptoFailure.wrongPasswordOrDamaged;

  @override
  String toString() => 'BackupCryptoException(${failure.name}): $message';
}

/// Dart side of the `backup` method channel.
///
/// A thin wrapper on purpose. Every byte of key material and every cipher
/// operation lives in Kotlin, and this class only marshals arguments and
/// turns platform errors into something the screen can act on. Nothing here
/// derives a key, and no method returns one.
class BackupCryptoChannel {
  final MethodChannel _channel;

  BackupCryptoChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.backupChannelName);

  /// Draws [length] cryptographically strong random bytes.
  ///
  /// Asked of the platform rather than improvised in Dart. `Random.secure`
  /// exists, but keeping every key-shaped byte coming from one place makes it
  /// possible to say where the app's randomness comes from in one sentence.
  Future<Uint8List> randomBytes(int length) async {
    final bytes = await _invoke<Uint8List>('randomBytes', <String, dynamic>{
      'length': length,
    });
    return bytes ?? Uint8List(0);
  }

  /// Encrypts [sourcePath] into the document at [destUri].
  ///
  /// [header] is written to the front of the file in the clear and fed to the
  /// cipher as additional authenticated data, so the salt and iteration count
  /// it carries are readable but not changeable.
  ///
  /// Returns how many bytes of ciphertext were written.
  Future<int> encryptArchive({
    required String sourcePath,
    required String destUri,
    required Uint8List header,
    required String password,
    required Uint8List salt,
    required Uint8List iv,
    required int iterations,
  }) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'encryptArchive',
      <String, dynamic>{
        'sourcePath': sourcePath,
        'destUri': destUri,
        'header': header,
        'password': password,
        'salt': salt,
        'iv': iv,
        'iterations': iterations,
      },
    );
    return (result?['cipherBytes'] as num?)?.toInt() ?? 0;
  }

  /// Decrypts the document at [sourceUri] out to [destPath].
  ///
  /// [header] must be exactly the bytes the archive begins with: they are
  /// both skipped over and authenticated, so a header read even slightly
  /// wrong shows up as a failed tag rather than as garbled output.
  ///
  /// Returns how many plaintext bytes were written.
  Future<int> decryptArchive({
    required String sourceUri,
    required String destPath,
    required Uint8List header,
    required String password,
    required Uint8List salt,
    required Uint8List iv,
    required int iterations,
  }) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'decryptArchive',
      <String, dynamic>{
        'sourceUri': sourceUri,
        'destPath': destPath,
        'header': header,
        'password': password,
        'salt': salt,
        'iv': iv,
        'iterations': iterations,
      },
    );
    return (result?['plainBytes'] as num?)?.toInt() ?? 0;
  }

  /// Encrypts [bytes] under a key that is already agreed.
  ///
  /// Used by the local transfer, where the key came off the pairing code.
  Future<Uint8List> encryptWithKey({
    required Uint8List key,
    required Uint8List bytes,
    required Uint8List iv,
    Uint8List? aad,
  }) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'encryptWithKey',
      <String, dynamic>{
        'key': key,
        'bytes': bytes,
        'iv': iv,
        if (aad != null) 'aad': aad,
      },
    );
    return (result?['bytes'] as Uint8List?) ?? Uint8List(0);
  }

  /// Decrypts [bytes] under an agreed key.
  ///
  /// A failure here is how the transfer finds out a peer does not hold the
  /// session key, so it is expected rather than exceptional.
  Future<Uint8List> decryptWithKey({
    required Uint8List key,
    required Uint8List bytes,
    required Uint8List iv,
    Uint8List? aad,
  }) async {
    final result = await _invoke<Map<Object?, Object?>>(
      'decryptWithKey',
      <String, dynamic>{
        'key': key,
        'bytes': bytes,
        'iv': iv,
        if (aad != null) 'aad': aad,
      },
    );
    return (result?['bytes'] as Uint8List?) ?? Uint8List(0);
  }

  Future<T?> _invoke<T>(String method, Map<String, dynamic> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw BackupCryptoException(_failureFor(error.code), error.code);
    } on MissingPluginException {
      throw const BackupCryptoException(
        BackupCryptoFailure.failed,
        'The backup channel is not available on this device',
      );
    }
  }

  static BackupCryptoFailure _failureFor(String code) {
    switch (code) {
      case 'wrong_password':
        return BackupCryptoFailure.wrongPasswordOrDamaged;
      case 'invalid_arguments':
        return BackupCryptoFailure.invalidArguments;
      default:
        return BackupCryptoFailure.failed;
    }
  }
}
