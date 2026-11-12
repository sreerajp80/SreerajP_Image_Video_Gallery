# Plan: No dead end after a transfer ends, and received files show at once

**Status:** completed

## The issue

After a transfer ends, the phone that scanned the code cannot scan the next
one. The screen stays on "Transfer finished" and there is no way out except
the back arrow. Going back and opening "Scan the other phone" again shows the
same old "Transfer finished" screen, not the camera.

Causes found in the code:

1. **The session state is never cleared when a screen closes.**
   `transferSessionProvider` lives for the whole app. `stop()` closes the
   socket but leaves the state at `done` (or `failed`). The scan screen
   (`SyncSendScreen`) shows the camera only when the phase is `idle`, and
   nothing sets it back to `idle` until a new code is joined — which needs
   the camera. So the scan screen is stuck for the rest of the app run.
   (The show-code screen escapes only because it calls `host()` on open,
   which resets; even so it can flash the old Done screen for one frame.)
2. **The Done screen has no buttons.** `TransferSessionBody` shows the
   counts and nothing else. The scan screen has no "Scan another code"; the
   show-code screen has no "Show a new code". A quick send now ends by
   itself after each batch (plan `20261112_092209_quick_send_auto_finish`),
   so this dead end is hit after every quick send.
3. **The "Type the code" button on a failed scan does nothing.** It sets
   `_typing = true`, but the body shows the typing view only when the phase
   is `idle`, and the phase stays `failed`.
4. **`_handled` stays true** on the scan screen after the first code, so
   even if the camera came back it would ignore every new code.

5. **Received files do not show in the timeline.** After each send the
   receiver calls `ReceivedMediaService.indexReceived()`, which runs
   `scanDevice` straight on the repository. The new rows are written to the
   database, but the lists only reload when `mediaLibraryVersionProvider`
   goes up, and only `MediaScanController` raises it. So the timeline keeps
   its old list. A later scan does not help either: the file is already
   indexed, so that scan finds "nothing new" and does not raise the counter.
   The file shows only after the app restarts. Albums, tags (the sender's
   tags and albums are applied to the new file) and the vault list have the
   same gap: `albumRevisionProvider`, `tagRevisionProvider` and
   `vaultRevisionProvider` are never raised by a transfer.

Checked and fine (no change): the `bye` handling on the receiver, the
quick-send auto-finish, the listener being closed on leave and on
backgrounding (hard rule 2), the address check before connecting, and
clearing the quick-send selection.

## The fix

1. **Service** (`lib/services/sync/transfer_session_service.dart`): add
   `Future<void> reset()`. It calls `stop()`, then emits a fresh
   `TransferSessionState` (phase `idle`), so the next screen starts clean.
2. **Both transfer screens** call `reset()` instead of `stop()` in
   `dispose`. Leaving a screen now closes the socket *and* forgets the old
   result. The scan screen also calls `reset()` once when it opens (after
   the first frame), in case an old state is still there.
3. **Done and failed screens get real buttons** (in `TransferSessionBody`,
   through a new `endActions` widget slot, so each screen decides what fits):
   - Scan screen: **"Scan another code"** (primary) → `reset()`, set
     `_handled = false`, `_typing = false`; the camera comes back at once.
     Plus **"Close"** (text button) → back.
   - Show-code screen: **"Show a new code"** (primary) → `host()` again,
     which makes a fresh secret and port. Plus **"Close"** → back.
   - On a failure the same buttons show; the scan screen keeps
     "Type the code" too, and it now really works (it calls `reset()`
     first, fixing cause 3).
4. **Refresh the library after files arrive** (cause 5). In
   `listenToTransfer` (`lib/screens/sync/sync_receive_screen.dart`, called
   by both screens), on the receiving side, when `totals.receivedCount` goes
   up compared with the previous state, raise `mediaLibraryVersionProvider`,
   `albumRevisionProvider` and `tagRevisionProvider`. When
   `vaultReceivedCount` goes up, raise `vaultRevisionProvider`. This runs
   after `indexReceived()` has finished, because the totals are only updated
   after it. It fires once per send, not per file, so a 40-photo send
   reloads the timeline once. The rule "did the count go up?" goes in a
   small pure function in `lib/core/domain/sync/sync_selection_rules.dart`
   (`receivedMoreThanBefore(previous, next)`) so it can be tested.
5. **New text** in all three ARB files, short labels (§8.6):
   - `actionSyncScanAnother`: "Scan another code" / "അടുത്ത കോഡ് സ്കാൻ ചെയ്യുക" /
     "अन्यं सङ्केतं पश्य"
   - `actionSyncShowNewCode`: "Show a new code" / "പുതിയ കോഡ് കാണിക്കുക" /
     "नूतनं सङ्केतं दर्शय"
   - "Close" reuses an existing close label if there is one; otherwise a new
     `actionSyncClose`: "Close" / "അടയ്ക്കുക" / "पिधेहि".
   The Sanskrit lines are new, so they need your review (as for G9).
   Then `flutter gen-l10n`.
6. **Tests**
   - `test/core/domain/sync/sync_selection_rules_test.dart`: cases for
     `receivedMoreThanBefore` (count up → true; same, down, or sender side
     → false; vault count up → vault refresh only).
   - `test/services/sync/transfer_session_reset_test.dart` (new): after a
     state that is not idle, `reset()` emits an `idle` state with no
     totals, failure or pairing.
   - `test/widgets/sync/transfer_session_body_test.dart` (new): the Done
     and failed phases show the given end buttons.

## Files to change

- `lib/services/sync/transfer_session_service.dart`
- `lib/core/domain/sync/sync_selection_rules.dart`
- `test/core/domain/sync/sync_selection_rules_test.dart`
- `lib/widgets/sync/transfer_session_body.dart`
- `lib/screens/sync/sync_send_screen.dart`
- `lib/screens/sync/sync_receive_screen.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, `lib/l10n/app_sa.arb`
  (+ generated files via `flutter gen-l10n`)
- `test/services/sync/transfer_session_reset_test.dart` (new)
- `test/widgets/sync/transfer_session_body_test.dart` (new)

## Security impact

Local transfer only. "Show a new code" opens a new listener, but only from
the show-code screen while it is on top — the same rule as today. `reset()`
always closes sockets before it clears the state, so no port is left open.
No new permission or package.

## Checks

- `dart format .`, `flutter analyze`, `flutter test`.
- On two phones: quick send one photo (sender shows code, receiver scans).
  Both reach Done. On the receiver tap "Scan another code" → camera opens;
  on the sender pick another photo, show the code, scan it → second transfer
  works. Also: go back from Done and open "Scan the other phone" again → the
  camera shows, not the old result. After receiving, go back to the
  timeline → the new photo is there without restarting the app, and its
  album and tags show too.
