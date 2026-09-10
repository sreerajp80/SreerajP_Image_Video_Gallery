# Plan: Mark Implemented Editor Features in Feature Improvements Document

**Status:** Approved

## Summary

Update `docs/feature_improvements_and_standout_features.md` to reflect the completion of:
1. **Spline RGB & Tone Curves**
2. **Selective Gradient & Radial Masks**
3. **8-Channel HSL Color Tuner**

## Files Changed

- `docs/feature_improvements_and_standout_features.md`

## Issue

The feature improvements inventory document still lists Spline RGB & Tone Curves, Selective Gradient & Radial Masks, and 8-Channel HSL Color Tuner as pending enhancements, even though they have now been fully implemented and verified in the non-destructive editor.

## Fix

1. In **Section 3.3 (Studio-Grade Non-Destructive Image Editor & Markup)**:
   - Mark **Spline RGB & Tone Curves** as `<br>*(Implemented)*` with implementation details (natural cubic spline via tridiagonal matrix solver, free-point placement, drag, long-press to delete).
   - Mark **Selective Gradient & Radial Masks** as `<br>*(Implemented)*` with implementation details (linear gradient and radial circle shapes, interactive on-screen drag handles, edge feathering, invert, local exposure/contrast/temperature/blur adjustments).
   - Mark **8-Channel HSL Color Tuner** as `<br>*(Implemented)*` with implementation details (8 color ranges, Hue/Saturation/Luminance sliders, smoothstep boundary falloff, achromatic pixel protection).

2. In **Section 7 (Implementation Feasibility & Phased Roadmap Matrix)**:
   - Add completed status entries with `✅ **Completed** (v1.1.0)`.
