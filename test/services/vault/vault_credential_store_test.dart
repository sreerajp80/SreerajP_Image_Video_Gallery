import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_mode.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';

/// The storage options that decide whether a user keeps access to their
/// vault after an update. A change here must be a decision, never an
/// accident, so each one is pinned by a test.
void main() {
  final options = SecureVaultCredentialStore.androidOptions.toMap();

  test('a storage error never wipes the vault PIN', () {
    expect(options['resetOnError'], 'false');
  });

  test('data from flutter_secure_storage 9 is moved, with a backup', () {
    expect(options['migrateOnAlgorithmChange'], 'true');
    expect(options['migrateWithBackup'], 'true');
  });

  test('flutter_secure_storage is pinned to an exact version', () {
    // A change to the vault's storage must be a deliberate edit (G39).
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(
        r'^\s*flutter_secure_storage:\s*\d+\.\d+\.\d+\s*$',
        multiLine: true,
      ).hasMatch(pubspec),
      isTrue,
    );
  });

  group('lock mode', () {
    const pin = <String, String>{
      'vault_pin_salt': 'c2FsdA==',
      'vault_pin_hash': 'aGFzaA==',
      'vault_pin_iterations': '120000',
    };

    Future<VaultLockMode?> modeWith(Map<String, String> stored) {
      FlutterSecureStorage.setMockInitialValues(stored);
      return SecureVaultCredentialStore().readLockMode();
    }

    test('nothing stored means no vault', () async {
      expect(await modeWith(const <String, String>{}), isNull);
    });

    test(
      'a PIN with no stored mode is a PIN vault, not the new default',
      () async {
        // Every vault made before the lock choice existed.
        expect(await modeWith(pin), VaultLockMode.vaultPin);
      },
    );

    test('a stored phone-lock mode wins, even over a stale PIN', () async {
      expect(
        await modeWith(<String, String>{
          ...pin,
          'vault_lock_mode': 'phoneLock',
        }),
        VaultLockMode.phoneLock,
      );
    });

    test('a PIN mode with no PIN left is not a usable vault', () async {
      expect(
        await modeWith(const <String, String>{'vault_lock_mode': 'vaultPin'}),
        isNull,
      );
    });

    test('clearPin keeps the mode; clear removes everything', () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        ...pin,
        'vault_lock_mode': 'phoneLock',
      });
      final store = SecureVaultCredentialStore();

      await store.clearPin();
      expect(await store.hasCredential(), isFalse);
      expect(await store.readLockMode(), VaultLockMode.phoneLock);

      await store.clear();
      expect(await store.readLockMode(), isNull);
    });
  });
}
