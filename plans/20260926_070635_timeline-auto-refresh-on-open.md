# Auto-refresh the Timeline when the app opens

**Status:** completed

## Files to change

- `lib/screens/timeline/timeline_screen.dart`
- `test/screens/home/timeline_auto_refresh_test.dart` (new)

## What the issue is

When the app opens, the Timeline shows only what is already saved in the app's
database. New photos or videos taken since the last visit do not show up until
the user pulls down to refresh.

The Timeline has code that starts a scan, but only when media permission
*changes* from "not granted" to "granted". That change never happens on a
normal start:

1. `HomeShellScreen` waits for the permission check to finish.
2. It builds `TimelineScreen` only after permission is already granted.
3. So the Timeline's permission listener never sees a change, and no scan runs.

The same is true when the user comes back to the app from the background: the
resume handler only re-checks permission, it does not scan.

## Plan for the fix

1. In `_TimelineScreenState.initState`, after the first frame, start a quick
   (incremental) scan if media permission is granted. This is the same scan that
   pull-to-refresh runs today, so it only picks up items changed since the last
   scan and is cheap.
2. In `_onResume` (app comes back to the foreground), if permission is granted,
   run the same quick scan, so photos taken while the app was in the background
   also appear without a pull.
3. No change to the "permission just granted" path. It still runs a full scan.
4. The scan controller already ignores a new scan while one is running
   (`_repository.isScanning`), so a pull-to-refresh during the auto scan is safe.
5. The thin progress bar at the top of the Timeline already shows while a scan
   runs, so the user can see the refresh happen. No new strings are needed.
6. Add a widget test: with permission granted and a fake scan controller,
   building `TimelineScreen` triggers exactly one incremental scan.
7. Run `dart format .`, `flutter analyze`, `flutter test`.
8. Write a change log in `change_log/`.

## Layer notes

The screen only calls the existing `mediaScanControllerProvider` notifier, the
same way pull-to-refresh does. No database or file work is added to the widget.
