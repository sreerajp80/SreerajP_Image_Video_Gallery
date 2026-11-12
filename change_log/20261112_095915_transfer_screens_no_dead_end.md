# Change log: No dead end after a transfer ends, and received files show at once

Implements plan `plans/20261112_095135_transfer_screens_no_dead_end.md`.

## What changed

### Scanning again after a transfer
- `lib/services/sync/transfer_session_service.dart`: new `reset()`. It stops
  anything still running, closes all sockets, and puts the state back to
  `idle`. A `_quiet` flag drops the late "connection lost" messages from the
  old session's loops, so they cannot cover the clean state. The flag is
  cleared when the next `host()` or `join()` starts.
- `lib/screens/sync/sync_send_screen.dart` (scan screen):
  - calls `reset()` when it closes (was `stop()`), and once when it opens if
    an old result is still there;
  - new "Scan another code" and "Close" buttons on the done and failed
    screens; "Scan another code" resets the session and the `_handled` flag,
    so the camera comes back and reads the next code;
  - "Type the code" on a failed scan now works: it resets the session first.
- `lib/screens/sync/sync_receive_screen.dart` (show-code screen): calls
  `reset()` when it closes; new "Show a new code" (fresh secret and port) and
  "Close" buttons on the done and failed screens.
- `lib/widgets/sync/transfer_session_body.dart`: new `endActions` slot,
  shown under the done and failed screens.

### Received files show in the timeline
- `lib/core/domain/sync/sync_selection_rules.dart`: new pure
  `refreshAfterReceive(...)`, which says whether the library or the vault
  must reload after a send.
- `listenToTransfer` (in `sync_receive_screen.dart`, used by both screens):
  on the receiving side, when the received count goes up, raises
  `mediaLibraryVersionProvider`, `albumRevisionProvider` and
  `tagRevisionProvider`; when the vault count goes up, raises
  `vaultRevisionProvider`. Once per send, after the files are indexed.

### Text
- New keys in `app_en.arb`, `app_ml.arb`, `app_sa.arb`:
  `actionSyncScanAnother`, `actionSyncShowNewCode`, `actionSyncClose`.
  Generated files updated with `flutter gen-l10n`.
- The two new Sanskrit lines ("अन्यः सङ्केतोऽन्वीक्ष्यताम्",
  "नूतनः सङ्केतः दर्श्यताम्") need the owner's review. "पिधीयताम्" is the
  same word the app already uses for "Close".

### Tests
- `test/services/sync/transfer_session_reset_test.dart` (new): `reset()`
  returns an ended session to `idle`, tells listeners, and a new session
  after it reports again.
- `test/widgets/sync/transfer_session_body_test.dart` (new): end buttons
  show on done and failed, not on a live transfer.
- `test/core/domain/sync/sync_selection_rules_test.dart`: cases for
  `refreshAfterReceive`.

## Checks
- `dart format .`: no changes. `flutter analyze`: no issues.
- `flutter test`: all 2478 tests pass.
- Not yet checked on two real phones.

## Security impact
Local transfer only. "Show a new code" opens a listener only from the
show-code screen while it is on top, as before. `reset()` closes every
socket before it clears the state. No new permission or package.
