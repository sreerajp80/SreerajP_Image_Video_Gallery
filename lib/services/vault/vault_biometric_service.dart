import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

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
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  @override
  Future<VaultBiometricResult> authenticate({required String reason}) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          // False, so the device PIN, pattern, or password is offered as a
          // second way in. It is the fallback Android already knows how to
          // present, and the vault's own PIN is still there behind it.
          biometricOnly: false,
          // The prompt is dismissed when the app leaves the foreground, which
          // is the same moment the vault auto-locks. Leaving it up would mean
          // a prompt outliving the state it was guarding.
          stickyAuth: false,
          useErrorDialogs: true,
        ),
      );
      return ok ? VaultBiometricResult.success : VaultBiometricResult.failed;
    } on PlatformException catch (error) {
      return _resultForCode(error.code);
    } on MissingPluginException {
      return VaultBiometricResult.unavailable;
    }
  }

  /// Maps a platform error code onto an outcome the gate screen can act on.
  ///
  /// Anything unrecognised is treated as unavailable rather than as a failure,
  /// because the honest answer to an error nobody anticipated is "use the
  /// PIN", not "your fingerprint was wrong".
  VaultBiometricResult _resultForCode(String code) {
    switch (code) {
      case 'NotAvailable':
      case 'NotEnrolled':
      case 'PasscodeNotSet':
      case 'OtherOperatingSystem':
        return VaultBiometricResult.unavailable;
      case 'LockedOut':
      case 'PermanentlyLockedOut':
        return VaultBiometricResult.failed;
      case 'auth_in_progress':
      case 'UserCanceled':
        return VaultBiometricResult.cancelled;
      default:
        return VaultBiometricResult.unavailable;
    }
  }
}
