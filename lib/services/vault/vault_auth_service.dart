import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_key_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_pin_service.dart';

/// Decides who may open the vault.
///
/// Two ways in, and they are not equal. The PIN is the one that always works:
/// it is checked against a stored salt and PBKDF2 hash and nothing else can
/// stand in for it. Biometrics are a shortcut over the top, offered only when
/// the device has one enrolled and the user has left it switched on, and
/// switching it off costs nothing because the PIN is still there.
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

  /// Whether the vault has ever been set up.
  Future<bool> isSetUp() => _store.hasCredential();

  /// Whether this device can hold the vault's master key.
  Future<bool> isKeystoreReady() => _keyService.isReady();

  /// Whether a biometric prompt can be offered right now.
  ///
  /// Both halves matter: the device must have one enrolled, and the user must
  /// not have turned the shortcut off in vault settings.
  Future<bool> canUseBiometrics() async {
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
        hash: _pinService.hashPin(pin, salt),
        iterations: AppConstants.vaultPinIterations,
      );
      return VaultAuthOutcome.success;
    } on VaultException {
      return const VaultAuthOutcome(status: VaultAuthStatus.error);
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

      if (_pinService.verifyPin(pin, salt, hash, iterations: iterations)) {
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

    final result = await _biometricService.authenticate(reason: reason);
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
        hash: _pinService.hashPin(newPin, salt),
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
