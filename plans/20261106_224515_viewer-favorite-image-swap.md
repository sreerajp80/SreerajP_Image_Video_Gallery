# Plan — Viewer shows the wrong photo after tapping the star

**Status:** completed

**Date:** 2026-11-06

---

## 1. The issue

In the fullscreen viewer, tapping the star (favourite) button changes the picture on screen to
a different photo, usually the first photo in the timeline. The app bar title stays on the old
photo, so the picture and its label no longer match. Rotating the phone has nothing to do with it.
It happens from a normal timeline tile and from On This Day.

### Why it happens (step by step)

1. `ViewerActions.toggleFavorite` (`lib/providers/viewer_providers.dart`) saves the star and then
   calls `ref.invalidate(mediaItemsProvider)` so the grid shows the new star.
2. `timelineItemsProvider` depends on `mediaItemsProvider`, so it reloads. While it reloads, its
   value is "loading, with the old list still kept".
3. `MediaViewerScreen.build` (`lib/screens/viewer/media_viewer_screen.dart`) uses
   `items.when(...)` with the default settings. In Riverpod 3, a reload caused by a dependency
   **does** go to the `loading:` branch (`skipLoadingOnReload` is `false` by default).
4. The `loading:` branch builds the viewer with a **one-item list** holding only the photo the
   viewer was first opened on (`widget.mediaId`).
5. The `PageView` now has one page, so its controller moves its position back to page 0. This
   move happens during layout, so `onPageChanged` is **not** called, and
   `viewerPageIndexProvider` keeps the old index (for example 5).
6. The full list comes back. The `PageView` stays on page 0 and draws the timeline's first photo
   (the "city shot"). The app bar reads `list[viewerPageIndexProvider]` = `list[5]`, the old photo.

So two parts of the screen decide "which photo" in different ways: the picture follows the
`PageController`, and the title follows `viewerPageIndexProvider`. The short loading frame pulls
them apart.

## 2. Files to change

| File | Change |
|---|---|
| `lib/screens/viewer/media_viewer_screen.dart` | Keep the full list on screen during a reload; keep the page in step with the shown item by id |
| `test/screens/viewer/media_viewer_screen_test.dart` | New widget test for the bug |

No ARB, model, repository, database, manifest or dependency change.

## 3. The fix

1. **Do not drop to the one-item list during a reload.** In `build`, call
   `items.when(skipLoadingOnReload: true, ...)`. When an old list is already there, the viewer
   keeps showing it until the new list arrives. The `loading:` branch is then used only on the
   very first load, which is what it was written for.
2. **Follow the item by id, not only by index.** Keep the id of the item in view
   (`_currentItemId`, set on open and in `_onPageChanged`). When a new list arrives, find that id
   in it. If its index is not the page in view, jump the `PageController` to it (after the frame)
   and update `viewerPageIndexProvider`. This also covers the case where the list order changes,
   or an item before the current one leaves the list. If the id is no longer in the list, keep
   the current clamped index (same as today).
3. **Test.** A widget test that opens the viewer on a later item (not index 0), taps the star,
   makes `timelineItemsProvider` reload, and checks that the shown image and the app bar both
   still belong to the same item.

## 4. Checks

- `dart format .`, `flutter analyze` (zero issues), `flutter test`.
- Manual check on a device by the user: open a photo that is not the first one, tap the star,
  and confirm the picture and title stay the same.

## 5. Security impact

None. Only viewer screen state changes. No network, storage, permission or dependency change.

## 6. Risks

- `skipLoadingOnReload: true` means that if a reload fails, the `error:` branch is still used.
  That is the same as today.
- The `jumpToPage` runs after the frame, so on a list change there may be one frame on the old
  index. That is only seen when the list order really changes, not on a star tap.
