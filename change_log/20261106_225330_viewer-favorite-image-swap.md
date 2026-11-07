# Change log — Viewer shows the wrong photo after tapping the star

**Date:** 2026-11-06

**Plan:** `plans/20261106_224515_viewer-favorite-image-swap.md`

---

## What was wrong

In the fullscreen viewer, tapping the star changed the picture to another photo (usually the
first one in the timeline), while the app bar title stayed on the old photo.

The star tap reloads the timeline list. During that reload the viewer dropped to a one-item list,
which moved the `PageView` to page 0 without calling `onPageChanged`. The picture followed the
page, but the title followed `viewerPageIndexProvider`, which still held the old index.

## What changed

### `lib/screens/viewer/media_viewer_screen.dart`

- `items.when(...)` now passes `skipLoadingOnReload: true`. During a reload the old list stays
  on screen. The one-item fallback is used only on the very first load.
- New field `_currentItemId`: the id of the item in view. It is set when the viewer opens and in
  `_onPageChanged`.
- `_buildContent` finds the item in view by id. If its index in the new list differs from the
  page or the stored index, the new `_syncPageTo` moves both after the frame (`jumpToPage` and
  `viewerPageIndexProvider`). If the item is no longer in the list, the viewer keeps the clamped
  index as before and follows the item now at that page.

### `test/screens/viewer/media_viewer_screen_test.dart`

- New test "Tapping the star keeps the same photo and title on screen". It opens the third of
  three photos, taps the star, and checks the title and the shown image both mid-reload and after.
- The test helper now takes an `openId`, uses a fake `ViewerActions` (a star tap only bumps a
  reload counter), and makes the list reload take 50 ms after a star tap.

## Checks

- The new test fails on the old viewer code: after the star tap the title is right but the
  third photo's image is gone. It passes with the fix.
- `dart format` (no changes), `flutter analyze` (no issues), `flutter test` (2226 tests, all
  passed).
- Not yet checked on a device.

## Also found

The same id tracking also fixes a smaller case of the same bug. If the viewer opens while the
timeline list is still loading, the old code opened on page 0 instead of the tapped photo.
This was seen in a test only, not in the app.

## Not changed

- No ARB, model, repository, database, manifest, permission or dependency change.
- Security impact: none.
