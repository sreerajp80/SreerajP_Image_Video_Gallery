# Pull-to-refresh works on short lists

Implements plan: `plans/20261112_095828_pull_to_refresh_short_lists.md`

## What was wrong

Pull-to-refresh did nothing on the Timeline when all its photos fit on one
screen (seen on an Android 10 phone with 3 photos; a phone with many photos
worked). With the default Android scroll physics, a list that fits on screen
does not scroll, so `RefreshIndicator` never saw an overscroll. The Folders tab
grid had the same problem with only a few folders.

## What changed

- `lib/widgets/timeline/timeline_body.dart` — the timeline's
  `CustomScrollView` now uses `AlwaysScrollableScrollPhysics`.
- `lib/screens/home/folders_tab.dart` — the filled folders `GridView` now uses
  `AlwaysScrollableScrollPhysics`.
- `test/widgets/timeline/timeline_body_refresh_test.dart` (new) — builds a
  timeline shorter than the screen, flings down, and checks `onRefresh` runs.
  It fails without the fix and passes with it.

Long lists keep the same feel: the physics still clamps at the edges on
Android.

## Checks

- `dart format`: clean.
- `flutter analyze`: no issues.
- `flutter test`: all 2479 tests pass.
- Not yet checked by hand on the phone.
