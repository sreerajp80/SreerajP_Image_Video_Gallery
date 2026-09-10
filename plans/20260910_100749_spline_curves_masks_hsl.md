# Plan: Spline RGB Curves, Selective Masks, 8-Channel HSL Color Tuner

**Status:** Approved

## Summary

Implement three professional image editing features for the Studio-Grade Non-Destructive Editor:

1. **Spline RGB & Tone Curves** — Upgrade the existing 3-handle smoothstep curve editor to a free-point natural cubic spline system.
2. **Selective Gradient & Radial Masks** — New tool for localized exposure, contrast, temperature, and blur adjustments within linear gradient or radial circle regions.
3. **8-Channel HSL Color Tuner** — Hue, Saturation, and Luminance sliders for 8 discrete color ranges.

## Files Changed

### New Files
- `lib/models/editor/hsl_adjustments.dart`
- `lib/models/editor/selective_mask.dart`
- `lib/services/editor/hsl_service.dart`
- `lib/services/editor/selective_mask_service.dart`
- `lib/widgets/editor/hsl_panel.dart`
- `lib/widgets/editor/selective_mask_panel.dart`
- `lib/widgets/editor/selective_mask_overlay.dart`

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

## Issue

The editor lacks professional-grade color grading tools. The curve editor is limited to 3 fixed handles with smoothstep interpolation. There are no selective masking tools and no per-color-range HSL controls.

## Fix

Add cubic spline interpolation to curves with free-point placement, a new Masks tool with gradient and radial regions, and an 8-channel HSL tuner integrated into the Tune panel. All changes are additive and backward-compatible with existing saved sessions.
