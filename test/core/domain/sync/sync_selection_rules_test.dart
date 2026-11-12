import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/sync_selection_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';

void main() {
  group('SyncSelectionRules.shouldAutoFinish', () {
    const clean = TransferOutcome(sentCount: 3);

    test('ends a clean send when asked to', () {
      expect(
        SyncSelectionRules.shouldAutoFinish(
          finishWhenDone: true,
          outcome: clean,
        ),
        isTrue,
      );
    });

    test('keeps the pairing open when not asked to', () {
      expect(
        SyncSelectionRules.shouldAutoFinish(
          finishWhenDone: false,
          outcome: clean,
        ),
        isFalse,
      );
    });

    test('keeps the pairing open when a file failed', () {
      expect(
        SyncSelectionRules.shouldAutoFinish(
          finishWhenDone: true,
          outcome: const TransferOutcome(sentCount: 2, failedCount: 1),
        ),
        isFalse,
      );
    });

    test('keeps the pairing open on a failure', () {
      for (final failure in [
        TransferFailure.cancelled,
        TransferFailure.noSpace,
        TransferFailure.connectionLost,
      ]) {
        expect(
          SyncSelectionRules.shouldAutoFinish(
            finishWhenDone: true,
            outcome: TransferOutcome(sentCount: 1, failure: failure),
          ),
          isFalse,
          reason: failure.name,
        );
      }
    });
  });

  group('SyncSelectionRules.refreshAfterReceive', () {
    ({bool library, bool vault}) refresh(int r0, int r1, int v0, int v1) =>
        SyncSelectionRules.refreshAfterReceive(
          receivedBefore: r0,
          receivedNow: r1,
          vaultBefore: v0,
          vaultNow: v1,
        );

    test('reloads the library when more files arrived', () {
      expect(refresh(0, 1, 0, 0), (library: true, vault: false));
      expect(refresh(3, 5, 0, 0), (library: true, vault: false));
    });

    test('reloads nothing when the counts did not go up', () {
      expect(refresh(2, 2, 1, 1), (library: false, vault: false));
    });

    test('a new session starting from zero is not new files', () {
      expect(refresh(4, 0, 2, 0), (library: false, vault: false));
    });

    test('reloads the vault only when vault files arrived', () {
      expect(refresh(0, 0, 0, 2), (library: false, vault: true));
    });
  });
}
