import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_crypto_result.dart';
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
  }) async {
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
  }) async {
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
  }) async {
    final bytes = await _read(sourcePath, iv);
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
  }) async {
    final bytes = await _read(sourcePath, iv);
    final destination = File(destPath);
    await destination.parent.create(recursive: true);
    await destination.writeAsBytes(bytes, flush: true);
    return bytes.length;
  }

  @override
  Future<bool> shredFile({required String path, required int passes}) async {
    shredded.add(path);
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
    await destination.writeAsBytes(_transform(plain, iv), flush: true);
    return VaultCryptoResult(
      fileName: destName,
      iv: iv,
      cipherSizeBytes: plain.length,
    );
  }

  Future<Uint8List> _read(String sourcePath, String iv) async {
    if (failDecrypt) {
      throw const VaultException('decrypt failed', code: 'vault_failed');
    }
    final source = File(sourcePath);
    if (!await source.exists()) {
      throw const VaultException('missing payload', code: 'vault_failed');
    }
    return _transform(await source.readAsBytes(), iv);
  }

  /// The stand-in transform: its own inverse, so one function does both ways.
  Uint8List _transform(Uint8List bytes, String iv) {
    final key = iv.codeUnits.fold<int>(0, (sum, unit) => (sum + unit) & 0xFF);
    return Uint8List.fromList(
      bytes.map((byte) => byte ^ key).toList(growable: false),
    );
  }
}
