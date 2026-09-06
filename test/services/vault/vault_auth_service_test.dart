import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_auth_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_key_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_service.dart';

import 'fake_vault_channel.dart';

/// A biometric service that answers however the test tells it to.
class _FakeBiometricService implements VaultBiometricService {
  bool available = true;
  VaultBiometricResult result = VaultBiometricResult.success;
  int authenticateCalls = 0;
  String? lastReason;

  _FakeBiometricService();

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<VaultBiometricResult> authenticate({required String reason}) async {
    authenticateCalls++;
    lastReason = reason;
    return result;
  }
}

void main() {
  group('VaultAuthService', () {
    late InMemoryVaultCredentialStore store;
    late _FakeBiometricService biometrics;
    late FakeVaultChannel channel;
    late VaultAuthService service;

    // A low iteration count would be wrong here: the service uses the real
    // constant, and these tests run it for real. A handful of derivations is
    // acceptable; that is why the PIN cases below are kept few and pointed.
    setUp(() {
      store = InMemoryVaultCredentialStore();
      biometrics = _FakeBiometricService();
      channel = FakeVaultChannel();
      service = VaultAuthService(
        store: store,
        biometricService: biometrics,
        keyService: VaultKeyService(channel: channel),
        pinService: VaultPinService(random: Random(13)),
      );
    });

    group('isSetUp', () {
      test('is false before a PIN is chosen', () async {
        expect(await service.isSetUp(), isFalse);
      });

      test('is true once the vault has been created', () async {
        await service.setUpVault('194627');
        expect(await service.isSetUp(), isTrue);
      });
    });

    group('setUpVault', () {
      test('creates the master key at the same time as the PIN', () async {
        final outcome = await service.setUpVault('194627');

        expect(outcome.isSuccess, isTrue);
        // Discovered now, while the vault is still empty, rather than after
        // photos have been moved into it.
        expect(channel.ensureKeyCalls, greaterThan(0));
      });

      test('stores a salt and a hash, and never the PIN', () async {
        await service.setUpVault('194627');

        final salt = await store.readSalt();
        final hash = await store.readHash();

        expect(salt, isNotNull);
        expect(hash, isNotNull);
        expect(salt, isNot(contains('194627')));
        expect(hash, isNot(contains('194627')));
        expect(await store.readIterations(), AppConstants.vaultPinIterations);
      });

      test('refuses a PIN the rules reject, and stores nothing', () async {
        final outcome = await service.setUpVault('1234');

        expect(outcome.status, VaultAuthStatus.invalidPin);
        expect(await store.hasCredential(), isFalse);
      });

      test('refuses when the device has no usable keystore', () async {
        channel.keystoreReady = false;

        final outcome = await service.setUpVault('194627');

        // No fallback to a weaker key: that would look like a vault while
        // giving almost none of its protection.
        expect(outcome.status, VaultAuthStatus.error);
        expect(await store.hasCredential(), isFalse);
      });
    });

    group('unlockWithPin', () {
      test('opens for the PIN that was set', () async {
        await service.setUpVault('194627');

        expect((await service.unlockWithPin('194627')).isSuccess, isTrue);
      });

      test('refuses a different PIN and counts the try', () async {
        await service.setUpVault('194627');

        final outcome = await service.unlockWithPin('194628');

        expect(outcome.status, VaultAuthStatus.wrongPin);
        expect(outcome.failedAttempts, 1);
      });

      test('carries the running count forward', () async {
        await service.setUpVault('194627');

        final outcome = await service.unlockWithPin(
          '194628',
          failedAttempts: 2,
        );

        expect(outcome.failedAttempts, 3);
      });

      test('shuts the pad once the limit is reached', () async {
        await service.setUpVault('194627');

        final outcome = await service.unlockWithPin(
          '194628',
          failedAttempts: AppConstants.vaultMaxFailedAttempts - 1,
        );

        expect(outcome.status, VaultAuthStatus.lockedOut);
        expect(outcome.lockoutSeconds, AppConstants.vaultLockoutSeconds);
      });

      test('rejects a badly formed PIN without checking it', () async {
        await service.setUpVault('194627');

        final outcome = await service.unlockWithPin('12');

        expect(outcome.status, VaultAuthStatus.invalidPin);
        // Not counted: it was never a guess at the real PIN.
        expect(outcome.failedAttempts, 0);
      });

      test('errors rather than opening when there is no credential', () async {
        final outcome = await service.unlockWithPin('194627');

        expect(outcome.status, VaultAuthStatus.error);
        expect(outcome.isSuccess, isFalse);
      });

      test('still opens a vault made under an older iteration count', () async {
        // What the stored count is for: raising the default later must not
        // strand an existing vault.
        final pinService = VaultPinService(random: Random(3));
        final salt = pinService.generateSalt();
        await store.writeCredential(
          salt: salt,
          hash: pinService.hashPin('194627', salt, iterations: 1000),
          iterations: 1000,
        );

        expect((await service.unlockWithPin('194627')).isSuccess, isTrue);
      });
    });

    group('canUseBiometrics', () {
      test('is true when the device has one and the user left it on', () async {
        expect(await service.canUseBiometrics(), isTrue);
      });

      test('is false when the device has none', () async {
        biometrics.available = false;
        expect(await service.canUseBiometrics(), isFalse);
      });

      test('is false when the user turned the shortcut off', () async {
        await store.writeSettings(
          const VaultSecuritySettings(biometricEnabled: false),
        );

        expect(await service.canUseBiometrics(), isFalse);
      });
    });

    group('unlockWithBiometrics', () {
      test('opens on a successful prompt and passes the reason on', () async {
        final outcome = await service.unlockWithBiometrics(reason: 'Open up');

        expect(outcome.isSuccess, isTrue);
        expect(biometrics.lastReason, 'Open up');
      });

      test('reports a sensor that did not recognise the user', () async {
        biometrics.result = VaultBiometricResult.failed;

        expect(
          (await service.unlockWithBiometrics(reason: 'x')).status,
          VaultAuthStatus.biometricFailed,
        );
      });

      test('reports a dismissed prompt as cancelled, not failed', () async {
        biometrics.result = VaultBiometricResult.cancelled;

        // Backing out is a choice, not a failed attempt, and the gate screen
        // treats it as one.
        expect(
          (await service.unlockWithBiometrics(reason: 'x')).status,
          VaultAuthStatus.cancelled,
        );
      });

      test('does not even prompt when biometrics are switched off', () async {
        await store.writeSettings(
          const VaultSecuritySettings(biometricEnabled: false),
        );

        final outcome = await service.unlockWithBiometrics(reason: 'x');

        expect(outcome.status, VaultAuthStatus.biometricUnavailable);
        expect(biometrics.authenticateCalls, 0);
      });

      test('never counts towards the PIN back-off', () async {
        await service.setUpVault('194627');
        biometrics.result = VaultBiometricResult.failed;

        for (var i = 0; i < 10; i++) {
          await service.unlockWithBiometrics(reason: 'x');
        }

        // A sensor that keeps misreading a wet finger must not be able to shut
        // the door that does work.
        expect((await service.unlockWithPin('194627')).isSuccess, isTrue);
      });
    });

    group('changePin', () {
      test('replaces the PIN for someone who knows the current one', () async {
        await service.setUpVault('194627');

        final outcome = await service.changePin(
          currentPin: '194627',
          newPin: '830514',
        );

        expect(outcome.isSuccess, isTrue);
        expect((await service.unlockWithPin('830514')).isSuccess, isTrue);
        expect((await service.unlockWithPin('194627')).isSuccess, isFalse);
      });

      test('refuses without the current PIN', () async {
        await service.setUpVault('194627');

        final outcome = await service.changePin(
          currentPin: '999888',
          newPin: '830514',
        );

        // Otherwise anyone holding an unlocked phone could take the vault.
        expect(outcome.status, VaultAuthStatus.wrongPin);
        expect((await service.unlockWithPin('194627')).isSuccess, isTrue);
      });

      test('refuses a new PIN the rules reject, leaving the old one', () async {
        await service.setUpVault('194627');

        final outcome = await service.changePin(
          currentPin: '194627',
          newPin: '1111',
        );

        expect(outcome.status, VaultAuthStatus.invalidPin);
        expect((await service.unlockWithPin('194627')).isSuccess, isTrue);
      });

      test('uses a fresh salt, so the stored bytes change', () async {
        await service.setUpVault('194627');
        final firstSalt = await store.readSalt();

        await service.changePin(currentPin: '194627', newPin: '830514');

        expect(await store.readSalt(), isNot(firstSalt));
      });
    });

    group('settings', () {
      test('reads the defaults before anything is saved', () async {
        expect(await service.readSettings(), VaultSecuritySettings.defaults);
      });

      test('round-trips what is written', () async {
        const updated = VaultSecuritySettings(
          autoLockSeconds: 300,
          shredPasses: 3,
        );

        await service.writeSettings(updated);

        expect(await service.readSettings(), updated);
      });
    });

    test('reports whether the device can hold the key', () async {
      expect(await service.isKeystoreReady(), isTrue);
    });
  });
}
