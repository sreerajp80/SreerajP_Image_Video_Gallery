import 'package:flutter/foundation.dart';

/// Why an unlock attempt ended the way it did.
enum VaultAuthStatus {
  /// The vault is now open.
  success,

  /// The PIN did not match.
  wrongPin,

  /// The PIN did not pass the format rules, so it was never even checked.
  invalidPin,

  /// This device has no usable biometric, or none is enrolled.
  biometricUnavailable,

  /// The sensor ran but did not recognise the user.
  biometricFailed,

  /// The user backed out of the prompt.
  cancelled,

  /// Too many wrong PINs; the pad is shut for a while.
  lockedOut,

  /// The keystore or the store underneath failed.
  error,
}

/// Immutable result of one unlock attempt.
@immutable
class VaultAuthOutcome {
  /// How the attempt ended.
  final VaultAuthStatus status;

  /// Wrong PINs entered in a row after this attempt.
  final int failedAttempts;

  /// Seconds the pad stays shut, when [status] is
  /// [VaultAuthStatus.lockedOut].
  final int lockoutSeconds;

  const VaultAuthOutcome({
    required this.status,
    this.failedAttempts = 0,
    this.lockoutSeconds = 0,
  });

  /// The vault opened.
  static const VaultAuthOutcome success = VaultAuthOutcome(
    status: VaultAuthStatus.success,
  );

  /// Whether the vault opened.
  bool get isSuccess => status == VaultAuthStatus.success;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultAuthOutcome &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          failedAttempts == other.failedAttempts &&
          lockoutSeconds == other.lockoutSeconds;

  @override
  int get hashCode => Object.hash(status, failedAttempts, lockoutSeconds);
}
