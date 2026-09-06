import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';

/// Why the vault shut itself.
enum VaultLockReason {
  /// The app left the foreground.
  backgrounded,

  /// Nothing was touched for longer than the timeout.
  inactivity,
}

/// Decides when an open vault has to shut.
///
/// Everything here is a pure function of the state passed in. There is no
/// timer, no `BuildContext`, and no listener: the widget layer owns those and
/// asks this class what to do, which is what makes every rule below testable
/// by calling it with a made-up clock.
class VaultLockPolicy {
  VaultLockPolicy._();

  /// The inactivity timeouts the settings screen offers, in seconds.
  static List<int> get timeoutChoicesSeconds =>
      AppConstants.vaultAutoLockChoicesSeconds;

  /// Whether [state] should lock at [now], and why, or null to stay open.
  ///
  /// Backgrounding wins over the timeout, because it is the stronger signal:
  /// the moment the app is not on screen the vault is shut, whatever the
  /// timeout says.
  static VaultLockReason? shouldLock({
    required VaultLockState state,
    required AppLifecycleState lifecycle,
    required int autoLockSeconds,
    required DateTime now,
  }) {
    if (!state.isUnlocked) return null;

    if (locksOnLifecycle(lifecycle)) return VaultLockReason.backgrounded;

    if (isIdle(
      lastActivityAt: state.lastActivityAt,
      autoLockSeconds: autoLockSeconds,
      now: now,
    )) {
      return VaultLockReason.inactivity;
    }

    return null;
  }

  /// Whether this lifecycle state means the app is no longer on screen.
  ///
  /// `inactive` counts, not just `paused`. On Android `inactive` is what
  /// arrives when the app switcher opens or a call comes in, and that is
  /// exactly the moment someone else can see the screen.
  static bool locksOnLifecycle(AppLifecycleState lifecycle) {
    switch (lifecycle) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        return true;
      case AppLifecycleState.resumed:
        return false;
    }
  }

  /// Whether the idle timeout has run out at [now].
  ///
  /// A timeout of zero or less turns the idle rule off; backgrounding still
  /// locks. A missing [lastActivityAt] is treated as idle, because an open
  /// vault that cannot say when it was last touched should not stay open.
  static bool isIdle({
    required DateTime? lastActivityAt,
    required int autoLockSeconds,
    required DateTime now,
  }) {
    if (autoLockSeconds <= 0) return false;
    if (lastActivityAt == null) return true;
    final idleMs = now.difference(lastActivityAt).inMilliseconds;
    return idleMs >= autoLockSeconds * 1000;
  }

  /// Milliseconds left before the idle timeout fires, never below zero.
  ///
  /// The auto-lock widget uses this to size its next timer rather than
  /// polling every second.
  static int remainingIdleMs({
    required DateTime? lastActivityAt,
    required int autoLockSeconds,
    required DateTime now,
  }) {
    if (autoLockSeconds <= 0) return 0;
    if (lastActivityAt == null) return 0;
    final elapsedMs = now.difference(lastActivityAt).inMilliseconds;
    final remaining = autoLockSeconds * 1000 - elapsedMs;
    return remaining > 0 ? remaining : 0;
  }

  /// The state after a wrong PIN at [now].
  ///
  /// Once the attempts reach the limit the pad shuts for a fixed cool-down and
  /// the counter resets, so the delay repeats rather than growing without
  /// bound and stranding someone who simply mistyped.
  static VaultLockState afterFailedAttempt(VaultLockState state, DateTime now) {
    final attempts = state.failedAttempts + 1;
    if (attempts >= AppConstants.vaultMaxFailedAttempts) {
      return state.copyWith(
        failedAttempts: 0,
        lockedOutUntil: now.add(
          const Duration(seconds: AppConstants.vaultLockoutSeconds),
        ),
      );
    }
    return state.copyWith(failedAttempts: attempts, clearLockout: true);
  }
}
