# Change Log: A/B Synchronized Photo Comparison

**Date:** 2026-09-06
**Plan:** `plans/20260906_202500_ab_synchronized_photo_comparison.md`

## Summary

Implemented the A/B Synchronized Photo Comparison feature, providing side-by-side and sliding curtain comparison modes with locked or independent synchronized pan and pinch-to-zoom, detailed metadata inspection, and multiple entry points from multi-selection and the fullscreen viewer.

## Details of Changes

1. **A/B Comparison Screen:**
   - Created `lib/screens/compare/photo_compare_screen.dart` hosting both comparison modes, top action bar controls, and a floating controller tray.
   - Provided instant mode switching between Sliding Curtain and Split View (side-by-side or top-and-bottom).
   - Added 1-tap photo swap button and photo changing pills that open the photo selector.
   - Added reset zoom button restoring 1.0x fitted scale.

2. **Comparison Widgets:**
   - Created `lib/widgets/compare/curtain_comparison_view.dart`: Stacked photos within a shared `InteractiveViewer` with a draggable divider handle and smooth clipping for 100% synchronized pan and zoom inspection.
   - Created `lib/widgets/compare/split_comparison_view.dart`: Split screen with synchronized or independent pan and pinch-to-zoom, allowing users to align framing independently and re-lock synchronization.
   - Created `lib/widgets/compare/compare_metadata_sheet.dart`: Modal bottom sheet comparing EXIF camera attributes (aperture, shutter speed, ISO, focal length) and file details (dimensions, megapixels, file size, date) side-by-side.
   - Created `lib/widgets/compare/photo_selector_sheet.dart`: Thumbnail grid picker to swap either photo directly from the user's gallery.

3. **Navigation & Entry Points:**
   - Registered `/compare` route in `lib/core/routing/app_router.dart` with `photoComparePath` query builder.
   - In `lib/widgets/batch/selection_app_bar.dart`, added a Compare action button that appears whenever exactly 2 images are ticked in selection mode.
   - In `lib/screens/viewer/media_viewer_screen.dart`, added a "Compare photo..." option to the viewer menu with quick options to compare with the previous photo, next photo, or a selected gallery photo.

4. **Bilingual Localization:**
   - Added comprehensive translation keys in `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` for all comparison modes, orientation options, sync states, and metadata labels.
   - Regenerated localization with `flutter gen-l10n`.

5. **Testing & Verification:**
   - Created `test/widgets/compare/photo_compare_screen_test.dart` testing curtain mode, split mode, lock/unlock sync toggle, photo swap, and metadata sheet.
   - Created `test/widgets/compare/curtain_comparison_view_test.dart` verifying draggable divider handle and transformations.
   - Created `test/widgets/batch/selection_app_bar_test.dart` verifying Compare button visibility on exactly 2 selected items.
   - Ran `flutter analyze` (0 issues) and full test suite (`flutter test`, 1,837 passing tests).
