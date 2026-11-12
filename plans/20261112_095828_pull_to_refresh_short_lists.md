# Pull-to-refresh does nothing when the list is short

**Status:** completed

## Issue

On a phone with only a few photos (seen on an Android 10 test phone with 3
photos), pulling down on the Timeline does not refresh it. No spinner shows and
no scan runs.

Cause: `RefreshIndicator` only reacts when the list inside it reports an
overscroll at the top. The Timeline's `CustomScrollView` uses the default
Android scroll physics (`ClampingScrollPhysics`). When the content is shorter
than the screen, there is nothing to scroll, so the list ignores the drag and
never reports an overscroll. The refresh never starts.

It is not tied to one phone. Any device whose timeline fits on one screen has
the same problem. Phones with many photos work, which hides the bug.

The empty-state versions already handle this (`scrollable: true` and
`AlwaysScrollableScrollPhysics`). The filled versions do not.

The Folders tab's filled `GridView` has the same bug when there are only a few
folders.

## Files to change

- `lib/widgets/timeline/timeline_body.dart` — add
  `physics: const AlwaysScrollableScrollPhysics()` to the `CustomScrollView`.
- `lib/screens/home/folders_tab.dart` — add the same physics to the filled
  `GridView.builder`.
- `test/widgets/timeline/timeline_body_refresh_test.dart` (new) — widget test:
  build a `RefreshIndicator` + short timeline content, fling down, and check
  that `onRefresh` was called. The test fails without the fix.

## Fix

`AlwaysScrollableScrollPhysics` lets a list accept a drag even when its
content fits on screen. It keeps the platform's normal feel (clamping on
Android), so long lists behave as before.

Check afterwards that the pinch-to-zoom `GestureDetector` around the timeline
and the fast-scroll scrubber still work.

## Verification

- `flutter analyze` and `flutter test`.
- On the Android 10 phone with 3 photos: pull down on Timeline and on Folders;
  the spinner should show and the scan should run.

## Security impact

None. UI scroll behaviour only; no permissions, storage or network change.
