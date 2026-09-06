import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';

/// Holds what the vault needs to remember between launches.
///
/// Never the PIN. What is kept is a random salt, the derived hash, and the
/// iteration count used to derive it, so the count can be raised later without
/// stranding vaults that were set up under the old one.
///
/// Abstract so the auth service can be tested against an in-memory store,
/// with no platform keystore involved.
abstract class VaultCredentialStore {
  /// The stored salt, or null when no PIN has been set.
  Future<String?> readSalt();

  /// The stored PIN hash, or null when no PIN has been set.
  Future<String?> readHash();

  /// The iteration count the stored hash was derived with.
  Future<int?> readIterations();

  /// Replaces the stored credential in one go.
  Future<void> writeCredential({
    required String salt,
    required String hash,
    required int iterations,
  });

  /// The stored settings, or the defaults when there are none.
  Future<VaultSecuritySettings> readSettings();

  /// Replaces the stored settings.
  Future<void> writeSettings(VaultSecuritySettings settings);

  /// Whether a PIN has been set at all.
  Future<bool> hasCredential();

  /// Erases the credential and the settings.
  ///
  /// This does not touch the payloads: forgetting the PIN must not quietly
  /// destroy anyone's photos.
  Future<void> clear();
}

/// The real store, backed by `flutter_secure_storage`.
///
/// On Android that means the values sit in `EncryptedSharedPreferences` under
/// a key the Android Keystore holds — not in plain `SharedPreferences`, which
/// the project's security rules forbid for anything sensitive.
class SecureVaultCredentialStore implements VaultCredentialStore {
  final FlutterSecureStorage _storage;

  SecureVaultCredentialStore({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
          );

  static const String _keySalt = 'vault_pin_salt';
  static const String _keyHash = 'vault_pin_hash';
  static const String _keyIterations = 'vault_pin_iterations';
  static const String _keySettings = 'vault_settings';

  @override
  Future<String?> readSalt() => _read(_keySalt);

  @override
  Future<String?> readHash() => _read(_keyHash);

  @override
  Future<int?> readIterations() async {
    final raw = await _read(_keyIterations);
    if (raw == null) return null;
    return int.tryParse(raw);
  }

  @override
  Future<void> writeCredential({
    required String salt,
    required String hash,
    required int iterations,
  }) async {
    // The hash goes in last. If the write is interrupted, the vault is left
    // looking like it has no PIN rather than like it has one nobody can
    // match, and the set-up flow can simply be run again.
    await _write(_keySalt, salt);
    await _write(_keyIterations, iterations.toString());
    await _write(_keyHash, hash);
  }

  @override
  Future<VaultSecuritySettings> readSettings() async {
    final raw = await _read(_keySettings);
    if (raw == null || raw.isEmpty) return VaultSecuritySettings.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return VaultSecuritySettings.defaults;
      return VaultSecuritySettings.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      // Corrupt settings must not lock anyone out. The defaults are the safe
      // ones anyway: biometrics on, and the shortest sensible auto-lock.
      return VaultSecuritySettings.defaults;
    }
  }

  @override
  Future<void> writeSettings(VaultSecuritySettings settings) =>
      _write(_keySettings, jsonEncode(settings.toJson()));

  @override
  Future<bool> hasCredential() async {
    final salt = await readSalt();
    final hash = await readHash();
    return salt != null && salt.isNotEmpty && hash != null && hash.isNotEmpty;
  }

  @override
  Future<void> clear() async {
    await _delete(_keyHash);
    await _delete(_keySalt);
    await _delete(_keyIterations);
    await _delete(_keySettings);
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (error, stackTrace) {
      throw VaultException(
        'The secure vault settings could not be read',
        code: 'store_read_failed',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (error, stackTrace) {
      throw VaultException(
        'The secure vault settings could not be saved',
        code: 'store_write_failed',
        cause: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } on PlatformException {
      // A key that will not delete is not worth failing the whole reset over.
    }
  }
}

/// An in-memory [VaultCredentialStore], for tests.
class InMemoryVaultCredentialStore implements VaultCredentialStore {
  String? _salt;
  String? _hash;
  int? _iterations;
  VaultSecuritySettings _settings = VaultSecuritySettings.defaults;

  @override
  Future<String?> readSalt() async => _salt;

  @override
  Future<String?> readHash() async => _hash;

  @override
  Future<int?> readIterations() async => _iterations;

  @override
  Future<void> writeCredential({
    required String salt,
    required String hash,
    required int iterations,
  }) async {
    _salt = salt;
    _hash = hash;
    _iterations = iterations;
  }

  @override
  Future<VaultSecuritySettings> readSettings() async => _settings;

  @override
  Future<void> writeSettings(VaultSecuritySettings settings) async {
    _settings = settings;
  }

  @override
  Future<bool> hasCredential() async =>
      (_salt?.isNotEmpty ?? false) && (_hash?.isNotEmpty ?? false);

  @override
  Future<void> clear() async {
    _salt = null;
    _hash = null;
    _iterations = null;
    _settings = VaultSecuritySettings.defaults;
  }
}
