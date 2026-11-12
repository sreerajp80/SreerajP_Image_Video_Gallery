# Change log: A quick send ends by itself when everything has gone

Implements plan: `plans/20261112_092209_quick_send_auto_finish.md`

## Why

After a quick send of "Selected photos", the sender was left on a picker
with nothing more to pick, and the receiver kept waiting for a send that
could not come. Both phones needed a manual Finish or Stop.

## What changed

- `lib/core/domain/sync/sync_selection_rules.dart`: new pure rule
  `shouldAutoFinish({finishWhenDone, outcome})`. True only when asked to
  and the send had no failed file and no failure.
- `lib/services/sync/transfer_session_service.dart`: `sendBatch` takes an
  optional `finishWhenDone` flag (default false). After the batch reaches
  `batchDone`, if `shouldAutoFinish` is true it calls `finish()`, which sends
  `bye`. The receiver already turns `bye` into its Done screen.
- `lib/widgets/sync/transfer_session_body.dart`: `onSend` sets
  `finishWhenDone` for a quick send whose plan holds nothing back
  (`!plan.hasLeftOver`).
- `test/core/domain/sync/sync_selection_rules_test.dart` (new): tests for
  `shouldAutoFinish` — clean send, flag off, a failed file, and failures
  (cancelled, no space, connection lost).

Device Sync and phone move are unchanged. A quick send with a failed file,
a failure, or files held back by the limits stays open as before. No new
text, so no ARB changes.

## Security impact

Local transfer only. The connection now closes sooner, never later.

## Checks

- `dart format`: no changes needed.
- `flutter analyze`: no issues.
- `flutter test`: all tests passed.
- Not yet checked on two real phones.
