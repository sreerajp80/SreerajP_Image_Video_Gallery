# Plan: Update Roadmap Matrix Versioning to Match App Version 2.4.1

**Status:** Pending Approval

## Summary

Update Section 7 (Implementation Feasibility & Phased Roadmap Matrix) of `docs/feature_improvements_and_standout_features.md` to align with the actual app version `2.4.1` (`assets/config/app_config.json` and `pubspec.yaml`).

## Files Changed

- `docs/feature_improvements_and_standout_features.md`

## Issue

Section 7 previously listed completed features as `(v1.1.0)` and future target milestones as `v1.1.0`–`v1.5.0`, which is out of sync with the application's actual current release version `2.4.1` (build `12`).

## Fix

1. Update completed features to reflect current version:
   - `A/B Synchronized Photo Comparison` → `✅ **Completed** (v2.4.1)`
   - `Spline RGB & Tone Curves` → `✅ **Completed** (v2.4.1)`
   - `Selective Gradient & Radial Masks` → `✅ **Completed** (v2.4.1)`
   - `8-Channel HSL Color Tuner` → `✅ **Completed** (v2.4.1)`

2. Re-align subsequent roadmap milestones starting from `v2.5.0`:
   - Near-term targets → `v2.5.0`
   - Mid-term targets → `v2.6.0`
   - Advanced targets → `v2.7.0`
   - Long-term targets → `v2.8.0` / `v3.0.0`
