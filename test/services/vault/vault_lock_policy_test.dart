import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_lock_policy.dart';

void main() {
  group('VaultLockPolicy', () {
    final now = DateTime(2026, 8, 30, 12, 0, 0);

    VaultLockState open({DateTime? lastActivity, int failedAttempts = 0}) {
      return VaultLockState(
        status: VaultLockStatus.unlocked,
        lastActivityAt: lastActivity ?? now,
        failedAttempts: failedAttempts,
      );
    }

    group('shouldLock', () {
      test('says nothing when the vault is already shut', () {
        for (final status in <VaultLockStatus>[
          VaultLockStatus.locked,
          VaultLockStatus.notSetUp,
          VaultLockStatus.unknown,
        ]) {
          expect(
            VaultLockPolicy.shouldLock(
              state: VaultLockState(status: status),
              lifecycle: AppLifecycleState.paused,
              autoLockSeconds: 60,
              now: now,
            ),
            isNull,
            reason: 'nothing to lock when the status is $status',
          );
        }
      });

      test('locks the moment the app leaves the screen', () {
        expect(
          VaultLockPolicy.shouldLock(
            state: open(),
            lifecycle: AppLifecycleState.paused,
            autoLockSeconds: 60,
            now: now,
          ),
          VaultLockReason.backgrounded,
        );
      });

      test('backgrounding beats the timeout, even a fresh one', () {
        // The vault was touched this instant, so the idle rule says stay open.
        // It still locks: somebody else can see the screen now.
        expect(
          VaultLockPolicy.shouldLock(
            state: open(lastActivity: now),
            lifecycle: AppLifecycleState.inactive,
            autoLockSeconds: 300,
            now: now,
          ),
          VaultLockReason.backgrounded,
        );
      });

      test('stays open while in the foreground and recently touched', () {
        expect(
          VaultLockPolicy.shouldLock(
            state: open(lastActivity: now.subtract(const Duration(seconds: 5))),
            lifecycle: AppLifecycleState.resumed,
            autoLockSeconds: 60,
            now: now,
          ),
          isNull,
        );
      });

      test('locks after the idle timeout runs out', () {
        expect(
          VaultLockPolicy.shouldLock(
            state: open(
              lastActivity: now.subtract(const Duration(seconds: 61)),
            ),
            lifecycle: AppLifecycleState.resumed,
            autoLockSeconds: 60,
            now: now,
          ),
          VaultLockReason.inactivity,
        );
      });
    });

    group('locksOnLifecycle', () {
      test('is false only while the app is on screen', () {
        expect(
          VaultLockPolicy.locksOnLifecycle(AppLifecycleState.resumed),
          isFalse,
        );
      });

      test('is true for every state that is not resumed', () {
        // `inactive` matters as much as `paused`: on Android it is what
        // arrives when the app switcher opens, which is exactly when a private
        // photo must not be on screen.
        for (final state in <AppLifecycleState>[
          AppLifecycleState.inactive,
          AppLifecycleState.paused,
          AppLifecycleState.detached,
          AppLifecycleState.hidden,
        ]) {
          expect(
            VaultLockPolicy.locksOnLifecycle(state),
            isTrue,
            reason: '$state means the vault is not being watched',
          );
        }
      });
    });

    group('isIdle', () {
      test('is true exactly at the timeout, not a tick later', () {
        expect(
          VaultLockPolicy.isIdle(
            lastActivityAt: now.subtract(const Duration(seconds: 30)),
            autoLockSeconds: 30,
            now: now,
          ),
          isTrue,
        );
        expect(
          VaultLockPolicy.isIdle(
            lastActivityAt: now.subtract(const Duration(milliseconds: 29999)),
            autoLockSeconds: 30,
            now: now,
          ),
          isFalse,
        );
      });

      test('holds at each timeout the settings screen offers', () {
        for (final seconds in AppConstants.vaultAutoLockChoicesSeconds) {
          expect(
            VaultLockPolicy.isIdle(
              lastActivityAt: now.subtract(Duration(seconds: seconds - 1)),
              autoLockSeconds: seconds,
              now: now,
            ),
            isFalse,
            reason: 'one second short of $seconds is not yet idle',
          );
          expect(
            VaultLockPolicy.isIdle(
              lastActivityAt: now.subtract(Duration(seconds: seconds)),
              autoLockSeconds: seconds,
              now: now,
            ),
            isTrue,
            reason: '$seconds of nothing is idle',
          );
        }
      });

      test('treats a missing last activity as idle', () {
        // An open vault that cannot say when it was last touched should not
        // stay open on the strength of not knowing.
        expect(
          VaultLockPolicy.isIdle(
            lastActivityAt: null,
            autoLockSeconds: 60,
            now: now,
          ),
          isTrue,
        );
      });

      test('is never idle when the timeout is off', () {
        expect(
          VaultLockPolicy.isIdle(
            lastActivityAt: now.subtract(const Duration(days: 1)),
            autoLockSeconds: 0,
            now: now,
          ),
          isFalse,
        );
      });
    });

    group('remainingIdleMs', () {
      test('counts down from the last touch', () {
        expect(
          VaultLockPolicy.remainingIdleMs(
            lastActivityAt: now.subtract(const Duration(seconds: 20)),
            autoLockSeconds: 60,
            now: now,
          ),
          40 * 1000,
        );
      });

      test('never goes below zero', () {
        expect(
          VaultLockPolicy.remainingIdleMs(
            lastActivityAt: now.subtract(const Duration(seconds: 600)),
            autoLockSeconds: 60,
            now: now,
          ),
          0,
        );
      });

      test('is zero when there is nothing to count', () {
        expect(
          VaultLockPolicy.remainingIdleMs(
            lastActivityAt: null,
            autoLockSeconds: 60,
            now: now,
          ),
          0,
        );
        expect(
          VaultLockPolicy.remainingIdleMs(
            lastActivityAt: now,
            autoLockSeconds: 0,
            now: now,
          ),
          0,
        );
      });
    });

    group('afterFailedAttempt', () {
      test('counts up while there are tries left', () {
        final state = VaultLockPolicy.afterFailedAttempt(
          const VaultLockState(status: VaultLockStatus.locked),
          now,
        );

        expect(state.failedAttempts, 1);
        expect(state.lockedOutUntil, isNull);
      });

      test('shuts the pad once the limit is reached', () {
        final state = VaultLockPolicy.afterFailedAttempt(
          VaultLockState(
            status: VaultLockStatus.locked,
            failedAttempts: AppConstants.vaultMaxFailedAttempts - 1,
          ),
          now,
        );

        expect(
          state.lockedOutUntil,
          now.add(const Duration(seconds: AppConstants.vaultLockoutSeconds)),
        );
        expect(state.isLockedOutAt(now), isTrue);
      });

      test('resets the counter when it shuts the pad', () {
        final state = VaultLockPolicy.afterFailedAttempt(
          VaultLockState(
            status: VaultLockStatus.locked,
            failedAttempts: AppConstants.vaultMaxFailedAttempts - 1,
          ),
          now,
        );

        // The cool-down repeats rather than growing without bound, so someone
        // who simply keeps mistyping is delayed, not stranded.
        expect(state.failedAttempts, 0);
      });

      test('clears an expired lockout on the next wrong try', () {
        final state = VaultLockPolicy.afterFailedAttempt(
          VaultLockState(
            status: VaultLockStatus.locked,
            lockedOutUntil: now.subtract(const Duration(minutes: 5)),
          ),
          now,
        );

        expect(state.lockedOutUntil, isNull);
        expect(state.failedAttempts, 1);
      });
    });

    test('offers the timeouts the settings screen shows', () {
      expect(
        VaultLockPolicy.timeoutChoicesSeconds,
        AppConstants.vaultAutoLockChoicesSeconds,
      );
      expect(VaultLockPolicy.timeoutChoicesSeconds, contains(30));
      expect(VaultLockPolicy.timeoutChoicesSeconds, contains(60));
      expect(VaultLockPolicy.timeoutChoicesSeconds, contains(300));
    });
  });
}
