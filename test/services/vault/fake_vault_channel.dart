import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hashing;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_crypto_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_payload_digest.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';

/// A [VaultChannel] that works on a host machine, for tests.
///
/// The "cipher" is a byte rotation keyed off the IV. It is not encryption and
/// is not meant to be: the real cipher is AES-256-GCM inside the Android
/// keystore, and a test cannot reach a keystore. What this gives is the shape
/// the services above depend on — a payload written to a path, an IV handed
/// back, and the same bytes returned when that IV is presented again — so the
/// ordering, the roll-back, and the failure handling can all be tested for
/// real.
class FakeVaultChannel implements VaultChannel {
  /// Whether the pretend keystore works.
  bool keystoreReady;

  /// When true, every encrypt fails, which is how a mid-import failure is
  /// tested.
  bool failEncrypt = false;

  /// When true, every decrypt fails.
  bool failDecrypt = false;

  /// Whether the pretend native shredder claims success.
  ///
  /// False makes the shredder service fall back to its Dart overwrite, which
  /// is the path a host machine really takes.
  bool nativeShredSucceeds = false;

  /// Every secure-flag call made, in order. True is an acquire.
  final List<bool> secureFlagCalls = <bool>[];

  /// How many times a master key was asked for.
  int ensureKeyCalls = 0;

  /// Paths the shredder was asked to destroy.
  final List<String> shredded = <String>[];

  /// Pass count each [shredFile] call asked for, in order.
  final List<int> shredPassCounts = <int>[];

  /// The format every encrypt writes. Set it to the legacy format to make
  /// items as an older app version did.
  int writeFormat = AppConstants.vaultPayloadFormatStreaming;

  /// The format each written path was written in, so a read with the wrong
  /// format fails, as it would with the real cipher.
  final Map<String, int> formatOfPath = <String, int>{};

  /// Every keyset path an encrypt or decrypt was given.
  final Set<String> keysetPaths = <String>{};

  /// How many times [forgetDataKey] was called.
  int forgetDataKeyCalls = 0;

  /// How many of the next writes come out damaged on disk: written, reported
  /// as fine, but not reading back the same. What a broken provider or a
  /// bad storage write would look like.
  int corruptNextWrites = 0;

  /// Called before each write, so a test can damage a later one.
  void Function()? onWrite;

  /// Whether this pretend Android has the MediaStore restore route
  /// (Android 10+). Off by default, so older tests keep the path route.
  bool galleryRestore = false;

  /// When true, every gallery restore fails (and writes nothing).
  bool failGalleryRestore = false;

  /// What each gallery restore was asked to write, in order.
  final List<({String displayName, String relativePath, List<int> bytes})>
  galleryRestores =
      <({String displayName, String relativePath, List<int> bytes})>[];

  /// Every path [digestPayload] was asked to read back.
  final List<String> digested = <String>[];

  FakeVaultChannel({this.keystoreReady = true});

  @override
  Future<bool> isKeystoreReady() async => keystoreReady;

  @override
  Future<void> ensureMasterKey() async {
    ensureKeyCalls++;
    if (!keystoreReady) {
      throw const VaultException('no keystore', code: 'keystore_unavailable');
    }
  }

  @override
  Future<VaultCryptoResult> encryptFile({
    String? sourceUri,
    String? sourcePath,
    required String destPath,
    required String destName,
    required String keysetPath,
  }) async {
    keysetPaths.add(keysetPath);
    if (failEncrypt) {
      throw const VaultException('encrypt failed', code: 'vault_failed');
    }
    final path = sourcePath ?? sourceUri ?? '';
    final source = File(path);
    if (!await source.exists()) {
      throw const VaultException('missing source', code: 'vault_failed');
    }
    return _write(await source.readAsBytes(), destPath, destName);
  }

  @override
  Future<VaultCryptoResult> encryptBytes({
    required Uint8List bytes,
    required String destPath,
    required String destName,
    required String keysetPath,
  }) async {
    keysetPaths.add(keysetPath);
    if (failEncrypt) {
      throw const VaultException('encrypt failed', code: 'vault_failed');
    }
    return _write(bytes, destPath, destName);
  }

  @override
  Future<Uint8List> decryptToBytes({
    required String sourcePath,
    required String iv,
    required int maxBytes,
    required int format,
    required String keysetPath,
  }) async {
    keysetPaths.add(keysetPath);
    final bytes = await _read(sourcePath, iv, format);
    if (bytes.length > maxBytes) {
      throw const VaultException('too large', code: 'vault_failed');
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
    keysetPaths.add(keysetPath);
    final bytes = await _read(sourcePath, iv, format);
    final destination = File(destPath);
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(bytes, flush: true);
    return bytes.length;
  }

  @override
  Future<VaultPayloadDigest> digestPayload({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
  }) async {
    digested.add(sourcePath);
    keysetPaths.add(keysetPath);
    return _digest(await _read(sourcePath, iv, format));
  }

  /// What [previewFromPayload] returns; null means "not a picture".
  Uint8List? payloadPreview = Uint8List.fromList(<int>[0xFF, 0xD8, 7, 7]);

  /// How many times [previewFromPayload] was called.
  int payloadPreviewCalls = 0;

  @override
  Future<Uint8List?> previewFromPayload({
    required String sourcePath,
    required String iv,
    required int format,
    required String keysetPath,
    required int maxSide,
    required int maxBytes,
  }) async {
    payloadPreviewCalls++;
    final plain = await _read(sourcePath, iv, format);
    if (plain.length > maxBytes) {
      throw const VaultException('too large', code: 'vault_failed');
    }
    return payloadPreview;
  }

  @override
  Future<bool> canRestoreToGallery() async => galleryRestore;

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
    if (!galleryRestore) return null;
    if (failGalleryRestore) {
      throw const VaultException('restore failed', code: 'vault_failed');
    }
    final bytes = await _read(sourcePath, iv, format);
    galleryRestores.add((
      displayName: displayName,
      relativePath: relativePath,
      bytes: bytes,
    ));
    final n = galleryRestores.length;
    return (
      uri: 'content://media/external/images/media/$n',
      path: '/storage/emulated/0/$relativePath/$displayName',
    );
  }

  @override
  Future<void> forgetDataKey() async {
    forgetDataKeyCalls++;
  }

  @override
  Future<bool> shredFile({required String path, required int passes}) async {
    shredded.add(path);
    shredPassCounts.add(passes);
    if (!nativeShredSucceeds) return false;
    final file = File(path);
    if (await file.exists()) await file.delete();
    return true;
  }

  @override
  Future<void> setSecureFlag(bool enabled) async {
    secureFlagCalls.add(enabled);
  }

  /// Writes the pretend ciphertext and reports the IV it used.
  Future<VaultCryptoResult> _write(
    Uint8List plain,
    String destPath,
    String destName,
  ) async {
    // A fresh IV per file, exactly as the real cipher insists on.
    final iv = base64Encode(
      utf8.encode('${DateTime.now().microsecondsSinceEpoch}$destName'),
    );
    final destination = File(destPath);
    await destination.parent.create(recursive: true);
    onWrite?.call();
    final cipher = _transform(plain, iv);
    if (corruptNextWrites > 0 && cipher.isNotEmpty) {
      corruptNextWrites--;
      cipher[0] ^= 0xFF;
    }
    await destination.writeAsBytes(cipher, flush: true);
    formatOfPath[destPath] = writeFormat;
    return VaultCryptoResult(
      fileName: destName,
      iv: iv,
      cipherSizeBytes: plain.length,
      format: writeFormat,
      plain: _digest(plain),
    );
  }

  Future<Uint8List> _read(String sourcePath, String iv, int format) async {
    if (failDecrypt) {
      throw const VaultException('decrypt failed', code: 'vault_failed');
    }
    final written = formatOfPath[sourcePath];
    if (written != null && written != format) {
      throw const VaultException('wrong format', code: 'payload_tampered');
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const VaultException('missing payload', code: 'vault_failed');
    }
    return _transform(await source.readAsBytes(), iv);
  }

  VaultPayloadDigest _digest(List<int> bytes) => VaultPayloadDigest(
    sha256: hashing.sha256.convert(bytes).toString(),
    plainBytes: bytes.length,
  );

  /// The stand-in transform: its own inverse, so one function does both ways.
  Uint8List _transform(Uint8List bytes, String iv) {
    final key = iv.codeUnits.fold<int>(0, (sum, unit) => (sum + unit) & 0xFF);
    return Uint8List.fromList(
      bytes.map((byte) => byte ^ key).toList(growable: false),
    );
  }
}
