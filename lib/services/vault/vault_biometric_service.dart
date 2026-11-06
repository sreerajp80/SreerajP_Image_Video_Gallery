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
/// This is a convenience over the PIN, never a replacement for it. Whatever
/// this returns, the PIN still opens the vault, and nothing else does.
abstract class VaultBiometricService {
  /// Whether this device can run a biometric prompt right now.
  Future<bool> isAvailable();

  /// Shows the prompt. [reason] is the localised line Android displays.
  Future<VaultBiometricResult> authenticate({required String reason});
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
  Future<VaultBiometricResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(localizedReason: reason);
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
