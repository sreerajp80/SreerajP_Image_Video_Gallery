import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  VaultBiometricResult map(LocalAuthExceptionCode code) =>
      LocalAuthBiometricService.resultForCode(code);

  test('the user backing out is a cancel, not a failure', () {
    for (final code in <LocalAuthExceptionCode>[
      LocalAuthExceptionCode.userCanceled,
      LocalAuthExceptionCode.systemCanceled,
      LocalAuthExceptionCode.authInProgress,
      LocalAuthExceptionCode.timeout,
      LocalAuthExceptionCode.userRequestedFallback,
    ]) {
      expect(map(code), VaultBiometricResult.cancelled, reason: '$code');
    }
  });

  test('a lockout is reported as failed', () {
    expect(
      map(LocalAuthExceptionCode.temporaryLockout),
      VaultBiometricResult.failed,
    );
    expect(
      map(LocalAuthExceptionCode.biometricLockout),
      VaultBiometricResult.failed,
    );
  });

  test('anything about the device itself sends the user to the PIN', () {
    for (final code in <LocalAuthExceptionCode>[
      LocalAuthExceptionCode.noCredentialsSet,
      LocalAuthExceptionCode.noBiometricsEnrolled,
      LocalAuthExceptionCode.noBiometricHardware,
      LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable,
      LocalAuthExceptionCode.uiUnavailable,
      LocalAuthExceptionCode.deviceError,
      LocalAuthExceptionCode.unknownError,
    ]) {
      expect(map(code), VaultBiometricResult.unavailable, reason: '$code');
    }
  });

  test('every code has an outcome', () {
    for (final code in LocalAuthExceptionCode.values) {
      expect(map(code), isA<VaultBiometricResult>());
    }
  });
}
