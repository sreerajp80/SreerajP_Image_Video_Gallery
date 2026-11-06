# Auto-refresh the Timeline when the app opens

Implements plan: `plans/20260926_070635_timeline-auto-refresh-on-open.md`

## What changed

- `lib/screens/timeline/timeline_screen.dart`
  - After the first frame, the Timeline now runs a quick (incremental) scan if
    media permission is granted. Before, a scan only ran when permission changed
    from "not granted" to "granted", which never happens on a normal start
    because the home shell shows the Timeline only after permission is granted.
  - When the app comes back from the background and permission is granted, the
    same quick scan runs, so media added meanwhile appears without a pull.
  - This is the same scan pull-to-refresh uses. A second scan is ignored while
    one is running, so pulling down during the auto scan is safe.
- `test/screens/home/timeline_auto_refresh_test.dart` (new)
  - Checks that opening the Timeline with permission runs exactly one quick
    scan, and that no scan runs without permission.

## Checks

- `dart format`: clean.
- `flutter analyze`: no issues.
- `flutter test`: all tests pass.
