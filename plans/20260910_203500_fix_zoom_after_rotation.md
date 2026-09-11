# Fix Zoom and Layout After Rotating in Media Viewer

**Status:** Completed

## Problem

After rotating an image in the media viewer, users cannot zoom in or out properly.

### What happens

1. In `lib/widgets/viewer/interactive_image_view.dart`, rotation is currently drawn using `Transform.rotate` inside `InteractiveViewer`.
2. In Flutter, `Transform.rotate` rotates pixels on the screen during the paint phase, but it **does not update the layout box or dimensions** of the child widget.
3. When a tall (portrait) image is rotated by 90° or 270° into landscape:
   - The layout box remains tall and narrow.
   - The painted image extends far beyond the left and right edges of the screen because it was not re-fitted to the viewport width.
   - Users cannot zoom out to see the whole image because the zoom scale is already at minimum (1.0).
   - Because the layout bounds do not match the rotated pixels, `InteractiveViewer`'s internal pan and zoom constraints (`_boundaryRect`) clamp movement along the wrong axes.
   - Panning or pinching horizontally conflicts with the parent `PageView`, causing the viewer to accidentally scroll to the next image instead of zooming or panning.
4. When rotating, `_transformationController` in `InteractiveImageView` was not reset to identity, leaving stale zoom and translation offsets active from the previous orientation.

## Proposed Changes

### 1. Helper in `ViewerTransformService`

#### [MODIFY] `lib/services/viewer/viewer_transform_service.dart`
- Add `quarterTurns(int degrees)` to convert any rotation (0°, 90°, 180°, 270°) into a quarter turn integer (0, 1, 2, 3) suitable for `RotatedBox`.

### 2. Layout-aware rotation and controller reset in `InteractiveImageView`

#### [MODIFY] `lib/widgets/viewer/interactive_image_view.dart`
- Replace `Transform.rotate` with `RotatedBox(quarterTurns: service.quarterTurns(widget.rotationDegrees), child: content)`.
  `RotatedBox` adjusts layout constraints prior to painting, ensuring that `Image.memory` with `BoxFit.contain` fits the rotated photo cleanly inside the viewport without overflowing.
- Add `didUpdateWidget` to reset `_transformationController.value = Matrix4.identity()` whenever `widget.rotationDegrees` changes, so the viewer starts fresh at the fitted scale (1.0).

### 3. Reset transform scale on rotation in `MediaViewerScreen`

#### [MODIFY] `lib/screens/viewer/media_viewer_screen.dart`
- In `_rotate({required bool clockwise})`, set `scale: 1.0` when updating `_transform` so that `_transform.isAtRest` is true and page transforms stay consistent.

### 4. Tests

#### [MODIFY] `test/services/viewer/viewer_transform_service_test.dart`
- Add unit tests for `quarterTurns`.

#### [MODIFY] `test/widgets/viewer/media_viewer_screen_test.dart`
- Add widget tests verifying that rotating an image fits within the viewport and allows zooming in and out cleanly.

## Verification Plan

### Automated Tests
- Run all tests:
  ```bash
  flutter test test/services/viewer/viewer_transform_service_test.dart
  flutter test test/widgets/viewer/media_viewer_screen_test.dart
  flutter test
  flutter analyze
  ```

### Manual Verification
1. Open any photo (portrait or landscape) in the media viewer.
2. Tap "Rotate Right" or "Rotate Left".
3. Check that the rotated photo cleanly fits on screen without overflowing or clipping.
4. Double tap or pinch to zoom in on the rotated photo.
5. Pan around the zoomed image.
6. Pinch or double tap to zoom back out to fitted view.
