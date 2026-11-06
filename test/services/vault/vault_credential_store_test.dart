import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
}
