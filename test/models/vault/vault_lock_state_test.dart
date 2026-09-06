import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';

void main() {
  group('VaultLockState', () {
    final now = DateTime(2026, 8, 30, 12, 0, 0);

    test('starts unknown, shut, and with a clean slate', () {
      const state = VaultLockState.initial;

      expect(state.status, VaultLockStatus.unknown);
      expect(state.isUnlocked, isFalse);
      expect(state.isSetUp, isFalse);
      expect(state.failedAttempts, 0);
      expect(state.lastActivityAt, isNull);
      expect(state.lockedOutUntil, isNull);
    });

    test('counts locked and unlocked as set up, and notSetUp as not', () {
      expect(
        const VaultLockState(status: VaultLockStatus.locked).isSetUp,
        isTrue,
      );
      expect(
        const VaultLockState(status: VaultLockStatus.unlocked).isSetUp,
        isTrue,
      );
      expect(
        const VaultLockState(status: VaultLockStatus.notSetUp).isSetUp,
        isFalse,
      );
      expect(
        const VaultLockState(status: VaultLockStatus.unknown).isSetUp,
        isFalse,
      );
    });

    group('lockout', () {
      test('is over the moment the deadline is reached', () {
        final state = VaultLockState(
          status: VaultLockStatus.locked,
          lockedOutUntil: now,
        );

        expect(
          state.isLockedOutAt(now.subtract(const Duration(seconds: 1))),
          isTrue,
        );
        // At the deadline exactly, not before it, so a boundary tick lets the
        // user back in rather than holding them another whole second.
        expect(state.isLockedOutAt(now), isFalse);
        expect(
          state.isLockedOutAt(now.add(const Duration(seconds: 1))),
          isFalse,
        );
      });

      test(
        'rounds the remaining time up, so it never reads zero while shut',
        () {
          final state = VaultLockState(
            status: VaultLockStatus.locked,
            lockedOutUntil: now.add(const Duration(milliseconds: 1500)),
          );

          expect(state.remainingLockoutSeconds(now), 2);
        },
      );

      test('reports no remaining time when there is no lockout', () {
        const state = VaultLockState(status: VaultLockStatus.locked);
        expect(state.remainingLockoutSeconds(now), 0);
        expect(state.isLockedOutAt(now), isFalse);
      });
    });

    group('copyWith', () {
      test('changes only what it is given', () {
        final state = VaultLockState(
          status: VaultLockStatus.unlocked,
          lastActivityAt: now,
          failedAttempts: 2,
        );

        final updated = state.copyWith(failedAttempts: 3);

        expect(updated.status, VaultLockStatus.unlocked);
        expect(updated.lastActivityAt, now);
        expect(updated.failedAttempts, 3);
      });

      test('keeps a nullable field when passed null', () {
        final state = VaultLockState(
          status: VaultLockStatus.unlocked,
          lastActivityAt: now,
        );

        expect(state.copyWith().lastActivityAt, now);
      });

      test('empties a nullable field only through its clear flag', () {
        final state = VaultLockState(
          status: VaultLockStatus.unlocked,
          lastActivityAt: now,
          lockedOutUntil: now,
        );

        expect(state.copyWith(clearLastActivity: true).lastActivityAt, isNull);
        expect(state.copyWith(clearLockout: true).lockedOutUntil, isNull);
        // Clearing one leaves the other alone.
        expect(state.copyWith(clearLockout: true).lastActivityAt, now);
      });
    });

    test('equality covers every field', () {
      final base = VaultLockState(
        status: VaultLockStatus.unlocked,
        lastActivityAt: now,
        failedAttempts: 1,
        lockedOutUntil: now,
      );

      expect(
        base,
        VaultLockState(
          status: VaultLockStatus.unlocked,
          lastActivityAt: now,
          failedAttempts: 1,
          lockedOutUntil: now,
        ),
      );
      expect(base.hashCode, isNot(base.copyWith(failedAttempts: 2).hashCode));
      expect(base, isNot(base.copyWith(status: VaultLockStatus.locked)));
      expect(base, isNot(base.copyWith(clearLockout: true)));
    });
  });
}
