import 'package:flutter/foundation.dart';

/// Where the vault currently stands.
enum VaultLockStatus {
  /// Nothing has been read yet; the gate is still deciding what to show.
  unknown,

  /// No PIN has ever been set, so the vault has to be created first.
  notSetUp,

  /// Set up, but shut. Nothing can be decrypted in this state.
  locked,

  /// Open. Payloads may be decrypted until something locks it again.
  unlocked,
}

/// Immutable snapshot of the vault lock.
///
/// [lastActivityAt] is what the inactivity timeout is measured from, and
/// [failedAttempts] is what the PIN pad's back-off is measured from. Both are
/// kept here rather than inside a widget so the whole rule set stays a pure
/// function of this object.
@immutable
class VaultLockState {
  /// Where the vault stands.
  final VaultLockStatus status;

  /// When the user last touched the vault, or null while it is shut.
  final DateTime? lastActivityAt;

  /// Wrong PINs entered in a row since the last success.
  final int failedAttempts;

  /// When the pad stops refusing new attempts, or null when it is not shut
  /// out.
  final DateTime? lockedOutUntil;

  const VaultLockState({
    this.status = VaultLockStatus.unknown,
    this.lastActivityAt,
    this.failedAttempts = 0,
    this.lockedOutUntil,
  });

  /// The state before anything has been read.
  static const VaultLockState initial = VaultLockState();

  /// Whether the vault is open.
  bool get isUnlocked => status == VaultLockStatus.unlocked;

  /// Whether the vault has been created at all.
  bool get isSetUp =>
      status == VaultLockStatus.locked || status == VaultLockStatus.unlocked;

  /// Whether the pad is refusing attempts at [now].
  bool isLockedOutAt(DateTime now) {
    final until = lockedOutUntil;
    return until != null && now.isBefore(until);
  }

  /// Seconds left on the back-off at [now], or zero when there is none.
  int remainingLockoutSeconds(DateTime now) {
    final until = lockedOutUntil;
    if (until == null || !now.isBefore(until)) return 0;
    return (until.difference(now).inMilliseconds / 1000).ceil();
  }

  /// Creates a copy with updated properties.
  ///
  /// The two nullable fields need explicit clear flags: passing null to
  /// [lastActivityAt] means "leave it alone", so [clearLastActivity] and
  /// [clearLockout] are how they are actually emptied.
  VaultLockState copyWith({
    VaultLockStatus? status,
    DateTime? lastActivityAt,
    int? failedAttempts,
    DateTime? lockedOutUntil,
    bool clearLastActivity = false,
    bool clearLockout = false,
  }) {
    return VaultLockState(
      status: status ?? this.status,
      lastActivityAt: clearLastActivity
          ? null
          : (lastActivityAt ?? this.lastActivityAt),
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedOutUntil: clearLockout
          ? null
          : (lockedOutUntil ?? this.lockedOutUntil),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultLockState &&
          runtimeType == other.runtimeType &&
          status == other.status &&
          lastActivityAt == other.lastActivityAt &&
          failedAttempts == other.failedAttempts &&
          lockedOutUntil == other.lockedOutUntil;

  @override
  int get hashCode =>
      Object.hash(status, lastActivityAt, failedAttempts, lockedOutUntil);
}
