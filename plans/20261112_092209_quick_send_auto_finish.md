# Plan: End a quick send on its own when everything has gone

**Status:** completed

## The issue

A quick send starts from photos picked in the gallery ("Selected photos").
The transfer screen then works the same way it does for Device Sync and
phone move: after each send it keeps the connection open and shows the
picker again, so the user can send more.

For a quick send this leads to two dead ends:

- **Sender:** the picker lists only "Selected photos"
  (`selectionOnly: quickSend` in `lib/providers/sync_providers.dart`).
  After they are sent, nothing is left to pick. "Send" is greyed out and
  the screen says "All sent. Pick more to send, or tap Finish." — but there
  is nothing more to pick.
- **Receiver:** it stays on "Connected. Waiting for the other phone to
  send." with a spinner, and waits until the sender taps Finish or Stop.

## The fix

When a quick send's batch ends fully well, the sender ends the pairing by
itself, the same way the Finish button does today. Finish already sends a
`bye` frame; the receiver already turns that into the Done screen
(`_receiveLoop` in `transfer_session_service.dart`). So both phones reach
Done with no new protocol step.

"Fully well" means all of these:

1. The purpose is quick send.
2. The plan that was sent had no left-over files (nothing held back by the
   free-space, file-count or size cap rules).
3. The batch had no failed files and no failure (not cancelled, no
   "no space").

If any of these is false, the screen stays as it is today, so the user can
retry failed files or send the rest. Device Sync and phone move do not
change.

### How

- `lib/core/domain/sync/sync_selection_rules.dart` (domain layer): add a
  pure function `shouldAutoFinish({required bool finishWhenDone,
  required TransferOutcome outcome})` that returns true only when
  `finishWhenDone` is true, `outcome.failure == null` and
  `outcome.failedCount == 0`. Pure, so it is easy to test.
- `lib/services/sync/transfer_session_service.dart` (service layer):
  `sendBatch(items, {bool finishWhenDone = false})`. After the batch, it
  emits `batchDone` as today, then, if `shouldAutoFinish(...)` is true,
  calls `finish()`. The service does not need to know about "quick send";
  it gets one plain flag.
- `lib/widgets/sync/transfer_session_body.dart` (widget): in `onSend`, pass
  `finishWhenDone: purpose == TransferPurpose.quickSend && !plan.hasLeftOver`.
- Test: `test/core/domain/sync/sync_selection_rules_test.dart` (new) for
  `shouldAutoFinish`: true on a clean outcome with the flag; false without
  the flag; false with failed files; false with a failure (cancelled, no
  space).

No new text, so no ARB changes. The sender's Done screen already shows
"Done" and the counts; the receiver's Done screen already shows the counts
and where the files went.

## Files to change

- `lib/core/domain/sync/sync_selection_rules.dart`
- `lib/services/sync/transfer_session_service.dart`
- `lib/widgets/sync/transfer_session_body.dart`
- `test/core/domain/sync/sync_selection_rules_test.dart` (new)

## Security impact

Touches the local transfer feature only. It closes the connection sooner,
never later, so it keeps hard rule 2 and opens nothing new.

## Checks

- `dart format .`, `flutter analyze`, `flutter test`.
- On two phones: quick send a few photos. Both phones should reach Done
  without tapping Finish. Then a quick send that fails part-way (for example
  turn off Wi-Fi on the receiver) should stay on the picker.
