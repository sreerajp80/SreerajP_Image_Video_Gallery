# Change log: scan screen no longer shows the camera error right after "Allow"

Implements plan: `plans/20261112_091807_camera_permission_double_start.md`

## What was wrong

When the user allowed camera access on the pairing scan screen, the screen still showed
"Camera access is needed to scan the code". The permission dialog sent the app to `inactive`
and back to `resumed` while the first camera start was still waiting. On `resumed`, the
scanner saw no camera yet and started a second one. The two starts fought over the camera,
one failed, and that failure switched the screen to the error panel.

## What changed

- `lib/widgets/sync/pairing_qr_scanner.dart`
  - New `_starting` flag: `_start()` returns at once if a start is already running, and
    `resumed` does not start a camera while one is starting.
  - New `_startId` counter, raised only on `paused` (a real trip out of the app, not the
    permission dialog). A start that began before that is stale: its camera is freed instead
    of shown, and its failure does not show the error panel.
  - When a stale start ends and the app is back in front, a fresh start runs, because the
    `resumed` that would have started it was skipped while the old start was running.
  - Shared check `_canStart` for "may a camera start now".
  - No auto-retry after a real failure (for example "Don't allow"), so the permission dialog
    cannot loop.
- `test/widgets/sync/pairing_qr_scanner_test.dart`
  - New test: `inactive` then `resumed` during a start does not start a second camera and does
    not show the error panel.
  - New test: leaving the app during a start ignores the stale start's failure and starts
    fresh on return.

The QR sync send and receive screens use the same scanner, so they get the fix too.

## Checks

- `dart format`: done.
- `flutter analyze`: no issues.
- `flutter test`: all tests pass, including the 2 new ones.
- Not yet checked on a real phone.

## Security impact

None. The `CAMERA` permission and how it is asked are unchanged. The camera is still freed
when the app leaves the foreground and when the screen closes.
