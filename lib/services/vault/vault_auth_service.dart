import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_mode.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_key_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/vault/vault_pin_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_service.dart';

/// Decides who may open the vault.
///
/// The vault has one of two locks ([VaultLockMode]):
/// - **Phone lock:** Android's own prompt decides — a fingerprint, or the
///   phone's PIN, pattern or password. Needs a secure lock screen.
/// - **Vault PIN:** the app's own PIN, checked against a stored salt and
///   PBKDF2 hash. A fingerprint may be a shortcut over the top, but only a
///   fingerprint: the prompt is asked for with `biometricOnly: true`, so the
///   phone's own PIN can never open a PIN vault.
///
/// Both are an app-level gate in front of the same Keystore key, which is not
/// tied to either.
///
/// The keystore is checked before either. A device with no usable keystore
/// cannot hold the master key, so there is nothing to unlock and the vault
/// says so plainly rather than accepting a PIN and failing later.
class VaultAuthService {
  final VaultCredentialStore _store;
  final VaultPinService _pinService;
  final VaultBiometricService _biometricService;
  final VaultKeyService _keyService;

  VaultAuthService({
    required VaultCredentialStore store,
    required VaultBiometricService biometricService,
    required VaultKeyService keyService,
    VaultPinService? pinService,
  }) : _store = store,
       _biometricService = biometricService,
       _keyService = keyService,
       _pinService = pinService ?? VaultPinService();

  /// Whether the vault has ever been set up, in either mode.
  Future<bool> isSetUp() async => await _store.readLockMode() != null;

  /// How the vault opens, or null when it has not been set up.
  Future<VaultLockMode?> lockMode() => _store.readLockMode();

  /// Whether this phone has a secure lock screen, which phone lock needs.
  Future<bool> canUsePhoneLock() => _biometricService.isDeviceSecure();

  /// Whether this device can hold the vault's master key.
  Future<bool> isKeystoreReady() => _keyService.isReady();

  /// Whether the fingerprint shortcut can be offered right now.
  ///
  /// Only in vault-PIN mode (in phone-lock mode the fingerprint is already
  /// part of the prompt), only when one is enrolled, and only when the user
  /// has not turned the shortcut off in vault settings.
  Future<bool> canUseBiometrics() async {
    if (await _store.readLockMode() != VaultLockMode.vaultPin) return false;
    final settings = await _store.readSettings();
    if (!settings.biometricEnabled) return false;
    return _biometricService.isAvailable();
  }

  /// Creates the vault with [pin].
  ///
  /// Generates the master key at the same time, so a keystore that cannot hold
  /// it is discovered now — while the vault is still empty — rather than after
  /// someone has moved their photos into it.
  Future<VaultAuthOutcome> setUpVault(String pin) async {
    if (!VaultPinRules.isValid(pin)) {
      return const VaultAuthOutcome(status: VaultAuthStatus.invalidPin);
    }

    try {
      if (!await _keyService.isReady()) {
        return const VaultAuthOutcome(status: VaultAuthStatus.error);
      }
      await _keyService.ensureKey();

      final salt = _pinService.generateSalt();
      await _store.writeCredential(
        salt: salt,
        hash: await _pinService.hashPinInBackground(pin, salt),
        iterations: AppConstants.vaultPinIterations,
      );
      await _store.writeLockMode(VaultLockMode.vaultPin);
      return VaultAuthOutcome.success;
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// Creates the vault with the phone's own lock.
  ///
  /// Runs Android's prompt once first, so a lock that does not work is found
  /// now, while the vault is still empty. The master key is created here too,
  /// for the same reason as in [setUpVault].
  Future<VaultAuthOutcome> setUpWithPhoneLock({required String reason}) async {
    try {
      if (!await _keyService.isReady()) {
        return const VaultAuthOutcome(status: VaultAuthStatus.error);
      }
      if (!await _biometricService.isDeviceSecure()) {
        return const VaultAuthOutcome(
          status: VaultAuthStatus.phoneLockUnavailable,
        );
      }
      final outcome = await _runPhoneLockPrompt(reason);
      if (!outcome.isSuccess) return outcome;

      await _keyService.ensureKey();
      await _store.writeLockMode(VaultLockMode.phoneLock);
      return VaultAuthOutcome.success;
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// Opens a phone-lock vault with Android's prompt.
  ///
  /// Wrong tries are counted and locked out by Android itself, not by the
  /// app's PIN back-off.
  Future<VaultAuthOutcome> unlockWithPhoneLock({required String reason}) async {
    try {
      if (await _store.readLockMode() != VaultLockMode.phoneLock) {
        return const VaultAuthOutcome(status: VaultAuthStatus.error);
      }
      if (!await _biometricService.isDeviceSecure()) {
        return const VaultAuthOutcome(
          status: VaultAuthStatus.phoneLockUnavailable,
        );
      }
      return await _runPhoneLockPrompt(reason);
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// Moves a PIN vault to phone lock.
  ///
  /// Only for an open vault (the screen asking is behind the gate). Android's
  /// prompt must pass first, so nobody ends up with a lock they cannot open.
  /// The mode is written before the PIN is erased: an interruption leaves a
  /// phone-lock vault with an unused PIN, never a vault with no way in.
  Future<VaultAuthOutcome> switchToPhoneLock({required String reason}) async {
    try {
      if (!await _biometricService.isDeviceSecure()) {
        return const VaultAuthOutcome(
          status: VaultAuthStatus.phoneLockUnavailable,
        );
      }
      final outcome = await _runPhoneLockPrompt(reason);
      if (!outcome.isSuccess) return outcome;

      await _store.writeLockMode(VaultLockMode.phoneLock);
      await _store.clearPin();
      return VaultAuthOutcome.success;
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// Moves a phone-lock vault to its own PIN.
  ///
  /// Only for an open vault. The PIN is stored before the mode changes, so an
  /// interruption leaves the vault on phone lock, still openable.
  Future<VaultAuthOutcome> switchToVaultPin(String newPin) async {
    if (!VaultPinRules.isValid(newPin)) {
      return const VaultAuthOutcome(status: VaultAuthStatus.invalidPin);
    }
    try {
      final salt = _pinService.generateSalt();
      await _store.writeCredential(
        salt: salt,
        hash: await _pinService.hashPinInBackground(newPin, salt),
        iterations: AppConstants.vaultPinIterations,
      );
      await _store.writeLockMode(VaultLockMode.vaultPin);
      return VaultAuthOutcome.success;
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// Android's prompt with the phone's PIN, pattern or password allowed.
  Future<VaultAuthOutcome> _runPhoneLockPrompt(String reason) async {
    final result = await _biometricService.authenticate(
      reason: reason,
      biometricOnly: false,
    );
    switch (result) {
      case VaultBiometricResult.success:
        return VaultAuthOutcome.success;
      case VaultBiometricResult.failed:
        return const VaultAuthOutcome(status: VaultAuthStatus.biometricFailed);
      case VaultBiometricResult.cancelled:
        return const VaultAuthOutcome(status: VaultAuthStatus.cancelled);
      case VaultBiometricResult.unavailable:
        return const VaultAuthOutcome(
          status: VaultAuthStatus.phoneLockUnavailable,
        );
    }
  }

  /// Checks [pin] against the stored credential.
  ///
  /// [failedAttempts] is what the caller has counted so far; the returned
  /// outcome carries the new count, or a lockout once the limit is reached.
  /// The counter lives in the lock state rather than in the store, so it is
  /// cleared by locking the vault, not by restarting the app — a restart must
  /// not be a way to reset the back-off.
  Future<VaultAuthOutcome> unlockWithPin(
    String pin, {
    int failedAttempts = 0,
  }) async {
    if (!VaultPinRules.isValid(pin)) {
      return VaultAuthOutcome(
        status: VaultAuthStatus.invalidPin,
        failedAttempts: failedAttempts,
      );
    }

    try {
      final salt = await _store.readSalt();
      final hash = await _store.readHash();
      if (salt == null || hash == null || salt.isEmpty || hash.isEmpty) {
        return const VaultAuthOutcome(status: VaultAuthStatus.error);
      }

      final iterations =
          await _store.readIterations() ?? AppConstants.vaultPinIterations;

      if (await _pinService.verifyPinInBackground(
        pin,
        salt,
        hash,
        iterations: iterations,
      )) {
        return VaultAuthOutcome.success;
      }

      final attempts = failedAttempts + 1;
      if (attempts >= AppConstants.vaultMaxFailedAttempts) {
        return const VaultAuthOutcome(
          status: VaultAuthStatus.lockedOut,
          lockoutSeconds: AppConstants.vaultLockoutSeconds,
        );
      }
      return VaultAuthOutcome(
        status: VaultAuthStatus.wrongPin,
        failedAttempts: attempts,
      );
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// Runs the biometric prompt.
  ///
  /// [reason] is the localised line Android shows, passed in because a service
  /// must not reach for `AppLocalizations` itself.
  ///
  /// A biometric failure never counts towards the PIN back-off. They are
  /// separate doors, and a sensor that keeps misreading a wet finger should
  /// not be able to shut the door that does work.
  Future<VaultAuthOutcome> unlockWithBiometrics({
    required String reason,
  }) async {
    if (!await canUseBiometrics()) {
      return const VaultAuthOutcome(
        status: VaultAuthStatus.biometricUnavailable,
      );
    }

    // Fingerprint only. Allowing the device credential here would let the
    // phone's own PIN open a vault that has its own PIN.
    final result = await _biometricService.authenticate(
      reason: reason,
      biometricOnly: true,
    );
    switch (result) {
      case VaultBiometricResult.success:
        return VaultAuthOutcome.success;
      case VaultBiometricResult.failed:
        return const VaultAuthOutcome(status: VaultAuthStatus.biometricFailed);
      case VaultBiometricResult.cancelled:
        return const VaultAuthOutcome(status: VaultAuthStatus.cancelled);
      case VaultBiometricResult.unavailable:
        return const VaultAuthOutcome(
          status: VaultAuthStatus.biometricUnavailable,
        );
    }
  }

  /// Replaces the PIN, but only for someone who can produce the current one.
  ///
  /// Without the current PIN this would be a way past the lock for anyone who
  /// picked up an unlocked phone.
  Future<VaultAuthOutcome> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    if (!VaultPinRules.isValid(newPin)) {
      return const VaultAuthOutcome(status: VaultAuthStatus.invalidPin);
    }

    final check = await unlockWithPin(currentPin);
    if (!check.isSuccess) return check;

    try {
      final salt = _pinService.generateSalt();
      await _store.writeCredential(
        salt: salt,
        hash: await _pinService.hashPinInBackground(newPin, salt),
        iterations: AppConstants.vaultPinIterations,
      );
      return VaultAuthOutcome.success;
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
    }
  }

  /// The stored vault settings.
  Future<VaultSecuritySettings> readSettings() => _store.readSettings();

  /// Replaces the stored vault settings.
  Future<void> writeSettings(VaultSecuritySettings settings) =>
      _store.writeSettings(settings);
}
