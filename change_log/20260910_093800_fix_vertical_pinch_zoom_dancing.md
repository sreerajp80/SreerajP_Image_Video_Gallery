# Fix vertical pinch-to-zoom causing image to dance

**Plan:** `plans/20260910_093200_fix_vertical_pinch_zoom_dancing.md`

## What changed

**File:** `lib/screens/viewer/media_viewer_screen.dart`

The `Listener` widget that handles swipe-down-to-dismiss was receiving raw pointer
events from both fingers of a pinch gesture. When one finger moved downward during
a vertical pinch, the dismiss logic activated alongside `InteractiveViewer`'s zoom,
causing the image to jitter.

### Changes

- Added an `_activePointers` counter that increments on `onPointerDown` and
  decrements on `onPointerUp` / `onPointerCancel`.
- Dismiss logic is now skipped when two or more pointers are active.
- If a second finger lands during an in-progress dismiss drag, the dismiss is
  cancelled immediately so `InteractiveViewer` can take over cleanly.
- Added `onPointerCancel` handler to the `Listener` for robustness.

## Verification

- `flutter analyze` — zero issues.
