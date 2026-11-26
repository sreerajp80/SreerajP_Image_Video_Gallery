import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// How a biometric prompt ended.
enum VaultBiometricResult {
  /// The sensor recognised the user.
  success,

  /// The sensor ran but did not recognise them.
  failed,

  /// The user dismissed the prompt.
  cancelled,

  /// This device has no biometric, or none is enrolled.
  unavailable,
}

/// Asks Android to confirm who is holding the phone.
///
/// A thin wrapper over `local_auth`, and abstract on purpose: a test must
/// never reach a real fingerprint sensor, and the auth service above needs to
/// be exercised against every one of the outcomes above.
///
/// Two uses, and the difference matters:
/// - **Vault PIN mode:** a fingerprint shortcut. [authenticate] is called
///   with `biometricOnly: true`, so the prompt has no "use PIN" button and
///   the phone's own PIN can never stand in for the vault PIN.
/// - **Phone lock mode:** Android's prompt is the lock itself, so
///   `biometricOnly: false` lets the phone's PIN, pattern or password in too.
abstract class VaultBiometricService {
  /// Whether a fingerprint (or other biometric) is enrolled and usable now.
  Future<bool> isAvailable();

  /// Whether the phone has a secure lock screen (PIN, pattern, password or
  /// biometric), which phone-lock mode needs.
  Future<bool> isDeviceSecure();

  /// Shows the prompt. [reason] is the localised line Android displays.
  ///
  /// [biometricOnly] true allows only a biometric; false also allows the
  /// phone's PIN, pattern or password.
  Future<VaultBiometricResult> authenticate({
    required String reason,
    required bool biometricOnly,
  });
}

/// The real service, over `local_auth`.
class LocalAuthBiometricService implements VaultBiometricService {
  final LocalAuthentication _auth;

  LocalAuthBiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<bool> isDeviceSecure() async {
    try {
      // On Android this is "the phone has a secure lock screen, or a
      // biometric". A biometric cannot be enrolled without a secure lock
      // screen, so both mean a lock that Android's prompt can check.
      return await _auth.isDeviceSupported();
    } on LocalAuthException {
      return false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<VaultBiometricResult> authenticate({
    required String reason,
    required bool biometricOnly,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
      );
      return ok ? VaultBiometricResult.success : VaultBiometricResult.failed;
    } on LocalAuthException catch (error) {
      // local_auth 3 shows no error dialogs of its own. The gate screen shows
      // the message for each outcome (vaultBiometricFailed / Unavailable).
      AppLogger.debug('The biometric prompt ended with an error code');
      return resultForCode(error.code);
    } on PlatformException {
      AppLogger.debug('The biometric prompt returned a platform error');
      return VaultBiometricResult.unavailable;
    } on MissingPluginException {
      return VaultBiometricResult.unavailable;
    }
  }

  /// Maps a `local_auth` error code onto an outcome the gate screen can act
  /// on.
  ///
  /// Anything unrecognised is treated as unavailable rather than as a failure,
  /// because the honest answer to an error nobody anticipated is "use the
  /// PIN", not "your fingerprint was wrong".
  static VaultBiometricResult resultForCode(LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.authInProgress:
      case LocalAuthExceptionCode.timeout:
      // The user tapped "use PIN" on the prompt: they chose the other door.
      case LocalAuthExceptionCode.userRequestedFallback:
        return VaultBiometricResult.cancelled;
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return VaultBiometricResult.failed;
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
      case LocalAuthExceptionCode.uiUnavailable:
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return VaultBiometricResult.unavailable;
    }
  }
}
