# Media Format Capabilities Matrix Change Log

**Plan Reference:** `plans/20260818_153500_media_format_capabilities_matrix.md`  
**Date:** 2026-08-18

## Changes Made
- Added a structured **Media Format Capability Matrix** to `docs/Project_Idea.md` under section 2.6.
- Explicitly documented format behavior across three dimensions:
  - **Viewing & Playback**: Supported decode, hardware acceleration, and thumbnailing.
  - **In-Place Editing**: Formats supporting direct non-destructive editing (crop, rotate, filters, watermarks) vs formats requiring prior conversion vs view-only formats (SVG, Camera RAW) vs lossless video trimming.
  - **Supported Conversions & Exports**: Export targets (JPEG, PNG, WEBP, BMP, PDF, GIF, frame grabber).
- Re-indexed subsequent sections (2.7 Organization & Albums, 2.8 Batch Operations).
