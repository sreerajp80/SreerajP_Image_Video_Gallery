# Fix: scan screen shows "Camera access is needed" right after the user allows the camera

**Status:** completed

## The issue

On the pairing screen, the user taps "Scan their code". Android asks for camera access. The
user taps "Allow". The screen still shows the error panel ("Camera access is needed to scan
the code. You can type the code instead."). The user must go back and tap again to get the
camera.

## Cause

The scanner widget is `lib/widgets/sync/pairing_qr_scanner.dart`.

1. `initState` calls `_start()`. Inside it, `controller.initialize()` makes Android show the
   permission dialog. This call is still waiting while the dialog is open.
2. The dialog sends the app to `inactive`. `_release()` does nothing, because `_controller`
   is still `null`.
3. The user taps "Allow". The app comes back to `resumed`. `didChangeAppLifecycleState`
   sees `_controller == null` and `_failed == false`, so it calls `_start()` **a second
   time**, while the first start is still running.
4. Two starts now open the same camera at the same time. One of them throws (camera busy, or
   "a permission request is already running"). Its `catch` calls `_fail()`, which sets
   `_failed = true`.
5. `build` checks `_failed` first, so the error panel shows, even when the other start
   worked. The working controller may also never be freed, because nothing points to it.

On the second visit, the permission is already given, no dialog appears, the app never
leaves `resumed`, and only one start runs. That is why "go back and tap again" works.

The same widget is used by the QR sync send and receive screens, so they have the same bug.

## Files to change

- `lib/widgets/sync/pairing_qr_scanner.dart`
- `test/widgets/sync/pairing_qr_scanner_test.dart`

## The fix

1. Add a `_starting` flag. `_start()` returns at once if a start is already running. It sets
   the flag at the beginning and clears it in a `finally` block.
2. `didChangeAppLifecycleState` does not call `_start()` while `_starting` is true.
3. Add a start counter (`_startId`). `_release()` raises it. When `initialize()` finishes, if
   the counter changed (the app went to the background for real while the camera was
   starting, not just for the permission dialog), the new controller is disposed instead of
   shown, and the next `resumed` starts a fresh one.
   - Note: the permission dialog itself also sends `inactive`. So step 3 must not throw away
     the start that is waiting on the dialog. To handle this, `_release()` raises the
     counter only when it actually had a controller to free, or when the state is `paused`
     (a real trip to the background). `inactive` alone with no controller leaves the
     running start alone.
4. No auto-retry after a real failure (for example the user taps "Don't allow"). Retrying on
   every resume would show the permission dialog again and again in a loop. The user keeps
   the "Type the code" button, as now.

## Tests

Add a widget test: `listCameras` waits on a `Completer`. While it waits, send `inactive`
then `resumed` to the binding. Check that `listCameras` was called only once and that the
error panel is not shown. Keep the two existing tests.

Then run `flutter analyze` and `flutter test`. Check by hand on a phone: clear the app's
camera permission, open the scan screen, tap "Allow", and the camera preview should appear
straight away.

## Security impact

None. The `CAMERA` permission and how it is asked do not change. The camera is still freed
when the app leaves the foreground and when the screen closes.
