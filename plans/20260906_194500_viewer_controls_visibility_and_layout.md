# Viewer Controls Visibility and Layout Improvement

**Status:** Completed

## Files to Change

- `lib/screens/viewer/media_viewer_screen.dart` - Restructure viewer chrome into high-contrast top and bottom bars, fix auto-hide timer for images, and add trash action.
- `lib/l10n/app_en.arb` - Add localization strings for viewer trash action if needed.
- `lib/l10n/app_ml.arb` - Add Malayalam localization entries for added keys.
- `test/screens/media_viewer_screen_test.dart` (or `test/widgets/viewer/`) - Unit/widget tests verifying control visibility and actions.

## Issue

1. **Poor Contrast on Bright Images:** The top bar gradient starts at `Alignment.bottomCenter` as transparent and rises to `Colors.black87` at the top. Because the icons sit at the bottom of the bar, the background directly behind the white icons is virtually transparent. When viewing an image with white or bright backgrounds (like YouTube or web screenshots), the icons are almost invisible.
2. **Top Bar Overcrowding:** 11 action icons are crammed into a single horizontal row on the top bar. On standard phone screens, this exceeds the available screen width, completely squeezes the title text to 0 width, and makes the buttons crowded and hard to distinguish.
3. **No Bottom Controls for Full-Screen Images:** While videos have a bottom control bar (`VideoControlsBar`), images have no bottom bar. Essential actions (edit, rotate, info, trash) are not easily reachable.
4. **Premature Auto-Hide:** `_restartChromeTimer()` hides the chrome after 3.5 seconds unconditionally, even on images, despite the intention to keep controls visible on photos until the user taps the screen.

## Fix

1. **Split Controls into Top and Bottom Bars:**
   - **Top Bar (`_ViewerAppBar`):**
     - Back button to exit fullscreen.
     - Item display name with ellipsis and text shadow, clearly readable with generous space.
     - Favorite button (star).
     - Overflow menu (`Icons.more_vert`) containing secondary actions: Move to Vault, Add to Album, Edit Tags, Convert Format, Scan Codes, Extract Text, and Notes.
   - **Bottom Bar (`_ImageViewerBottomBar` for images):**
     - Edit (`Icons.tune`) -> Opens image editor.
     - Rotate Left (`Icons.rotate_left`) -> Rotates image counter-clockwise.
     - Rotate Right (`Icons.rotate_right`) -> Rotates image clockwise.
     - Details (`Icons.info_outline`) -> Opens EXIF details sheet.
     - Trash (`Icons.delete_outline`) -> Moves item to trash with confirmation and undo option.
2. **High-Contrast Protective Scrims & Icon Styling:**
   - Top Bar: Gradient from `Colors.black87` at the top to `Colors.transparent` at the bottom with generous padding.
   - Bottom Bar: Gradient from `Colors.black87` at the bottom to `Colors.transparent` at the top.
   - Circular/pill dark translucent backgrounds (`Colors.black38`) on buttons or clear contrast boundaries ensuring 100% visibility against pure white `#FFFFFF` images.
3. **Fix Auto-Hide on Photos:**
   - Check if current item is video before arming the auto-hide timer; keep chrome persistent for images until user explicitly taps to toggle.
4. **Smooth Transitions:**
   - Use smooth animated opacity for chrome appearance and disappearance.
