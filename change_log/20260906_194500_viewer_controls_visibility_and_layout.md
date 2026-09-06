# Change Log: Viewer Controls Visibility and Layout Improvement

**Date:** 2026-09-06
**Plan:** `plans/20260906_194500_viewer_controls_visibility_and_layout.md`

## Summary

Improved the visibility, contrast, layout, and behavior of the fullscreen media viewer controls.

## Details of Changes

1. **Rebalanced Controls (Top and Bottom Bars):**
   - In `lib/screens/viewer/media_viewer_screen.dart`, split the overcrowded 11-button top row into a clean top app bar and an ergonomic bottom bar for images.
   - **Top Bar (`_ViewerAppBar`):** Displays the Back button, full file title (with ellipsis and double text-shadows for high readability), Favorite toggle button, and a clean overflow `PopupMenuButton` for secondary operations (Vault, Album, Tags, Convert, Code Scanner, Text Extraction, Notes, Video Tools).
   - **Bottom Bar (`_ImageViewerBottomBar`):** Provides 5 primary thumb-reachable image tools: **Edit** (`Icons.tune`), **Rotate Left** (`Icons.rotate_left`), **Rotate Right** (`Icons.rotate_right`), **Details** (`Icons.info_outline`), and **Trash** (`Icons.delete_outline`).
2. **High-Contrast Background Scrims and Circular Buttons:**
   - Redesigned the top bar gradient from `Colors.black87` to `Colors.transparent` with adequate bottom padding.
   - Added a matching bottom bar gradient from `Colors.black87` at the bottom edge to `Colors.transparent`.
   - Wrapped action buttons in semi-translucent dark circular backgrounds (`Colors.black38`) so that buttons and text remain 100% visible against any background, including solid white images.
3. **Fixed Auto-Hide Timer on Images:**
   - Modified `_restartChromeTimer` to only run the auto-hide countdown for video playback. On still photos, controls remain visible until the user taps the screen to toggle full-screen immersion.
4. **Added Trash and Undo Support to Viewer:**
   - Added `_moveToTrash` in `MediaViewerScreen` with a confirmation dialog and a SnackBar with an `Undo` button.
5. **Localization:**
   - Added viewer trash strings in `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb`.
6. **Automated Testing:**
   - Added widget tests in `test/widgets/viewer/media_viewer_screen_test.dart` validating control presence, layout, tap-to-toggle behavior, and non-auto-hiding chrome for photos.
