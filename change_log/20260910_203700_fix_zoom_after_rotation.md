# Fix Zoom and Layout After Rotating in Media Viewer

**Plan:** `plans/20260910_203500_fix_zoom_after_rotation.md`

## What changed

### 1. Viewer Transform Service
**File:** `lib/services/viewer/viewer_transform_service.dart`
- Added `quarterTurns(int degrees)` helper method to convert rotation in degrees (0, 90, 180, 270) to quarter-turn integer units (0, 1, 2, 3) for `RotatedBox`.

### 2. Interactive Image View
**File:** `lib/widgets/viewer/interactive_image_view.dart`
- Replaced paint-only `Transform.rotate` with layout-aware `RotatedBox(quarterTurns: service.quarterTurns(widget.rotationDegrees), child: content)`. This ensures that when rotated, `Image.memory` with `BoxFit.contain` receives transposed constraints and cleanly fits inside the screen boundaries without overflowing.
- Added `didUpdateWidget` to reset `_transformationController.value = Matrix4.identity()` whenever rotation changes. This ensures zooming and panning start clean from the fitted scale on every rotation step.

### 3. Media Viewer Screen
**File:** `lib/screens/viewer/media_viewer_screen.dart`
- Updated `_rotate` to reset `scale: 1.0` in `_transform` so `isAtRest` is kept accurate.

### 4. Tests
- Added unit tests in `test/services/viewer/viewer_transform_service_test.dart` for `quarterTurns`.
- Added widget tests in `test/widgets/viewer/media_viewer_screen_test.dart` verifying that rotation updates `RotatedBox`, fits the image, and permits double-tap and pinch zooming in and out.

## Verification

- `flutter test test/services/viewer/viewer_transform_service_test.dart test/widgets/viewer/media_viewer_screen_test.dart` — All 21 tests passed.
- `flutter analyze` — No issues found.
- `dart format .` — Cleanly formatted.
