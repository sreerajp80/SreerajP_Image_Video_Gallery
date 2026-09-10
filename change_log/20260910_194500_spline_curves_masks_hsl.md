# Spline RGB Curves, Selective Masks, and 8-Channel HSL Color Tuner

**Plan:** `plans/20260910_100749_spline_curves_masks_hsl.md`

## What changed

Added three professional-grade photo editing tools to the non-destructive image editor:

1. **Spline RGB & Tone Curves (Upgrade)**
   - Replaced fixed 3-point smoothstep interpolation in `ToneCurveService` with a natural cubic spline solver (tridiagonal algorithm).
   - Replaced `CurveEditor` widget to allow free control point placement (tap to add, drag to move, long-press to delete, up to 10 points).
   - Added identity diagonal reference line and white-ring handle indicators.

2. **Selective Gradient & Radial Masks**
   - Created `SelectiveMask` model supporting linear gradient and radial circle shapes, invert toggle, feather, and local adjustments (exposure, contrast, temperature, blur).
   - Added `SelectiveMaskService` computing smooth mask weights and applying localized adjustments.
   - Added `SelectiveMaskPanel` for configuring mask parameters and managing active masks with chip selectors.
   - Added `SelectiveMaskOverlay` for rendering gradient lines, radial circles, and interactive drag handles over the image preview.
   - Added `EditorTool.masks` tool in `EditorToolBar` and wired it into `ImageEditorScreen` and `ImageRenderPipeline`.

3. **8-Channel HSL Color Tuner**
   - Created `HslAdjustments` and `HslChannelAdjustment` models covering 8 discrete color ranges (Red, Orange, Yellow, Green, Cyan, Blue, Purple, Magenta).
   - Created `HslService` calculating angular weights and smooth falloffs across hue boundaries, applying per-channel hue, saturation, and luminance shifts while protecting achromatic pixels.
   - Added `HslPanel` inside the Tune panel with 8 circular color range chips and 3 adjustment sliders.
   - Integrated HSL pass into `ImageRenderPipeline`.

4. **Localization**
   - Added English (`app_en.arb`) and Malayalam (`app_ml.arb`) localizations for all new UI labels, hints, and tooltips.

## Files changed

### New Files
- `lib/models/editor/hsl_adjustments.dart`
- `lib/models/editor/selective_mask.dart`
- `lib/services/editor/hsl_service.dart`
- `lib/services/editor/selective_mask_service.dart`
- `lib/widgets/editor/hsl_panel.dart`
- `lib/widgets/editor/selective_mask_overlay.dart`
- `lib/widgets/editor/selective_mask_panel.dart`
- `test/models/editor/hsl_adjustments_test.dart`
- `test/models/editor/selective_mask_test.dart`
- `test/services/editor/hsl_service_test.dart`
- `test/services/editor/selective_mask_service_test.dart`
- `test/services/editor/tone_curve_service_test.dart`

### Modified Files
- `lib/models/editor/tone_adjustments.dart`
- `lib/models/editor/edit_session.dart`
- `lib/services/editor/tone_curve_service.dart`
- `lib/services/editor/image_render_pipeline.dart`
- `lib/providers/editor_providers.dart`
- `lib/widgets/editor/curve_editor.dart`
- `lib/widgets/editor/tone_slider_panel.dart`
- `lib/widgets/editor/editor_tool_bar.dart`
- `lib/screens/editor/image_editor_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ml.arb`

## Verification

- `flutter analyze` — zero issues.
- `flutter test test/services/editor/ test/models/editor/` — 236 tests passed.
- `dart format lib test` — clean formatting across all modified files.
