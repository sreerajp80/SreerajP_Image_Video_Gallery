# Disable Two-Finger Swipe on PageView & Protect Zoom

**Plan:** `plans/20260910_204900_disable_two_finger_page_swipe.md`

## What changed

### 1. Media Viewer Screen
**File:** `lib/screens/viewer/media_viewer_screen.dart`
- Added `_isMultiTouch` state tracking when two or more pointers are touching the screen.
- In `_onPointerDown`, when `_activePointers >= 2`, immediately set `_isMultiTouch = true`.
- In `_onPointerUp` and `_onPointerCancel`, reset `_isMultiTouch = false` only when all pointers have left the screen (`_activePointers == 0`).
- Updated `PageView.builder` physics to `(_transform.isAtRest && !_isMultiTouch) ? const PageScrollPhysics() : const NeverScrollableScrollPhysics()`. This guarantees:
  - Two-finger horizontal swipes do not move to the next image.
  - Two-finger pinch gestures zoom smoothly without `PageView` capturing touch events.
  - Only single-finger horizontal swipes navigate between images.

### 2. Interactive Image View
**File:** `lib/widgets/viewer/interactive_image_view.dart`
- Wired `onInteractionStart` and `onInteractionEnd` to `InteractiveViewer` as an additional multi-touch safeguard to keep `PageView` scrolling locked during active zoom gestures.

### 3. Tests
**File:** `test/widgets/viewer/media_viewer_screen_test.dart`
- Added widget tests confirming that:
  - Two-finger horizontal swipe does not page to the next image.
  - Single-finger horizontal swipe pages to the next image.

## Verification

- `flutter test test/widgets/viewer/media_viewer_screen_test.dart` — All 4 tests passed.
- `flutter test` — All 1896 tests in the test suite passed.
- `flutter analyze` — No issues found.
- `dart format .` — Cleanly formatted.
