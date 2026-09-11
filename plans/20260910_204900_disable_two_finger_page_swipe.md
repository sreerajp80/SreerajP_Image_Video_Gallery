# Disable Two-Finger Swipe on PageView So Only Single-Finger Swipes Move to Next Image

**Status:** Completed

## Problem

While trying to pinch-to-zoom (or swiping with two fingers), the media viewer attempts to move to the next image instead of zooming.

### What happens

1. `PageView` listens to horizontal touch drags across the whole page using `PageScrollPhysics()`.
2. When a user pinches with two fingers (especially on rotated or wide images), the fingers move horizontally apart.
3. `PageView`'s horizontal drag recognizer does not distinguish between single-finger and multi-finger gestures. It treats the horizontal movement as a page scroll and tries to navigate to the adjacent image.
4. Because `PageView` captures the gesture arena, `InteractiveViewer`'s pinch-to-zoom gesture is cancelled or fails to respond.
5. In addition, two fingers swiping horizontally across the screen triggers page navigation when it should not. Only a single-finger horizontal swipe should move to the next image.

## Proposed Changes

### Media Viewer Screen

#### [MODIFY] `lib/screens/viewer/media_viewer_screen.dart`
1. Track multi-touch state in `_MediaViewerScreenState` with `bool _isMultiTouch = false;`.
2. In `_onPointerDown`, when `_activePointers >= 2`:
   - Set `_isMultiTouch = true` inside `setState`.
   - This immediately switches `PageView`'s physics to `NeverScrollableScrollPhysics()`, preventing `PageView` from capturing the gesture arena during two-finger touches.
3. In `_onPointerUp` and `_onPointerCancel`, reset `_isMultiTouch = false` only when all pointers are lifted (`_activePointers == 0`), preventing any lingering single finger from accidentally dragging the page.
4. Wire `InteractiveViewer`'s `onInteractionStart` and `onInteractionEnd` (or `onScaleChanged`) so `PageView` remains locked during active zoom and whenever `!_transform.isAtRest`.
5. Update `PageView.builder` physics:
   ```dart
   physics: (_transform.isAtRest && !_isMultiTouch)
       ? const PageScrollPhysics()
       : const NeverScrollableScrollPhysics(),
   ```
   This guarantees that:
   - Double-finger swipes or pinches never move to the next image.
   - Only single-finger horizontal swipes move to the next image when the photo is unzoomed.

### Interactive Image View

#### [MODIFY] `lib/widgets/viewer/interactive_image_view.dart`
- Pass `onInteractionStart` and `onInteractionEnd` callbacks to `InteractiveViewer` as an additional safeguard so multi-finger gestures lock out `PageView` scrolling.

### Tests

#### [MODIFY] `test/widgets/viewer/media_viewer_screen_test.dart`
- Add widget tests verifying:
  1. A two-finger horizontal swipe does NOT move to the next image.
  2. A two-finger pinch zooms the image cleanly without changing pages.
  3. A single-finger horizontal swipe moves to the next image as expected.

## Verification Plan

### Automated Tests
- Run viewer widget tests:
  ```bash
  flutter test test/widgets/viewer/media_viewer_screen_test.dart
  flutter analyze
  ```

### Manual Verification
1. Open an image in the viewer (both rotated and unrotated).
2. Swipe horizontally with two fingers — verify the page does not change.
3. Pinch with two fingers horizontally to zoom — verify the image zooms in smoothly without paging.
4. Swipe horizontally with one finger — verify it smoothly navigates to the next image.
