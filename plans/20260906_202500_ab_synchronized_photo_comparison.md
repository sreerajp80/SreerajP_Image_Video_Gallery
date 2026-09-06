# A/B Synchronized Photo Comparison

**Status:** Completed

## Files to Change

- `lib/core/routing/app_router.dart` [MODIFY] - Register `/compare` route and path builder helper `photoComparePath`.
- `lib/screens/compare/photo_compare_screen.dart` [NEW] - Main A/B photo comparison screen supporting split-screen and sliding curtain modes, synchronized pan/zoom, swap, and photo changing.
- `lib/widgets/compare/split_comparison_view.dart` [NEW] - Split-screen comparison widget supporting side-by-side and top-to-bottom views with locked/unlocked synchronized pan and pinch-to-zoom.
- `lib/widgets/compare/curtain_comparison_view.dart` [NEW] - Sliding curtain comparison widget with draggable divider line and handle, stacking both photos with synchronized pan and pinch-to-zoom.
- `lib/widgets/compare/compare_metadata_sheet.dart` [NEW] - Side-by-side metadata and EXIF inspection sheet comparing resolution, file size, capture date, camera model, and exposure parameters.
- `lib/widgets/compare/photo_selector_sheet.dart` [NEW] - Bottom sheet allowing users to pick an alternate photo from their gallery to compare as Photo A or Photo B.
- `lib/widgets/batch/selection_app_bar.dart` [MODIFY] - Display "Compare" action button when exactly 2 image items are selected.
- `lib/screens/viewer/media_viewer_screen.dart` [MODIFY] - Add "Compare photo..." option to viewer action menu with quick choices for previous photo, next photo, or gallery picker.
- `lib/l10n/app_en.arb` [MODIFY] - Add English translation strings for comparison modes, synchronization states, swap, and metadata.
- `lib/l10n/app_ml.arb` [MODIFY] - Add Malayalam translation strings for comparison modes, synchronization states, swap, and metadata.
- `test/widgets/compare/photo_compare_screen_test.dart` [NEW] - Unit and widget tests for the A/B comparison screen and its interactions.
- `test/widgets/compare/curtain_comparison_view_test.dart` [NEW] - Widget tests for sliding curtain gesture and divider positioning.

## Issue

The gallery needs a dedicated **A/B Synchronized Photo Comparison** capability (as specified in `docs/feature_improvements_and_standout_features.md §3.2`). Photographers and everyday users need a way to inspect burst shots, focus sharpness, color adjustments, and before-and-after edits between two photos with locked, synchronized pan and pinch-to-zoom, as well as a sliding curtain comparison.

## Fix

1. **Implement A/B Photo Comparison Screen (`photo_compare_screen.dart`):**
   - Provide two distinct visualization modes:
     - **Sliding Curtain Mode:** Overlays both photos at identical dimensions with an interactive vertical or horizontal slider divider. Sliding reveals Photo A on one side and Photo B on the other, while panning and pinch-to-zoom synchronously scale and translate both photos.
     - **Split Screen Mode:** Side-by-side (horizontal) or top-and-bottom (vertical) panes showing Photo A and Photo B.
   - **Synchronized Pan & Pinch-to-Zoom:**
     - A toggle button switches between **Synchronized (Locked)** and **Independent (Unlocked)** gestures.
     - When locked, panning or zooming either photo instantly mirrors the exact translation and scale to the other photo.
     - When unlocked, the user can pan and zoom each photo independently to align subjects that might have slight framing shifts, then re-lock them.
     - Double-tap or dedicated reset button to restore fitted 1.0x scale.
   - **Swap Photos:** A 1-tap swap button exchanges Photo A and Photo B positions.
   - **Switch Photo A / Photo B:** Tapping on either photo's title pill opens a bottom sheet to pick any other photo from the gallery without leaving comparison mode.
   - **Side-by-Side Metadata Comparison:** An inspection modal sheet displaying filename, dimensions, file size, date taken, camera make/model, ISO, aperture, shutter speed, and focal length side-by-side.

2. **Integrate Entry Points:**
   - **Multi-Selection App Bar (`selection_app_bar.dart`):** When exactly 2 items are selected in the timeline or an album, show a "Compare" button in the app bar leading directly to `/compare?firstId=...&secondId=...`.
   - **Fullscreen Viewer (`media_viewer_screen.dart`):** In the viewer's overflow menu for image items, add "Compare photo...", allowing instant comparison with the previous photo, next photo, or a picked photo from the gallery.
   - **App Router (`app_router.dart`):** Register `/compare` route with `photoComparePath` helper.

3. **Localization (`app_en.arb` & `app_ml.arb`):**
   - Add all user-facing strings in English and Malayalam with descriptive `@` entries in `app_en.arb`.
   - Run `flutter gen-l10n`.

4. **Testing and Verification:**
   - Add comprehensive tests in `test/widgets/compare/` covering split mode, curtain mode, lock/unlock synchronization, swap, and metadata sheet.
   - Run `flutter analyze` and `flutter test`.
