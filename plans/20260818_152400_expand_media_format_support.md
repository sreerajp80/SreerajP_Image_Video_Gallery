# Plan: Expand Media Format Support in Project Idea

**Status:** Implemented

## 1. Issue / Goal
The current `docs/Project_Idea.md` only mentions JPEG, PNG, and WEBP for image format conversion. It needs to be updated with comprehensive format support across viewing (images, videos, animations, RAW), playback, conversion/export, and video tooling.

## 2. Proposed Changes in `docs/Project_Idea.md`
- **Expanded Media Viewing Support**:
  - Standard & Modern Image Formats: JPEG, PNG, WEBP, HEIC/HEIF, AVIF, BMP, WBMP, ICO, SVG.
  - Animated Formats: GIF, Animated WEBP, Animated AVIF with playback controls.
  - Camera RAW Formats: DNG and embedded preview/thumbnail extraction for RAW files (`.dng`, `.cr2`, `.nef`, `.arw`).
- **Comprehensive Video Viewing & Playback**:
  - Container Support: MP4, MKV, WebM, 3GP, MOV, AVI, TS.
  - Codec & Feature Support: H.264 (AVC), H.265 (HEVC), VP8, VP9, AV1, AAC, MP3, Opus, FLAC, HDR10 playback, and high-frame-rate/slow-motion playback (60/120/240 fps).
- **Extended Format Conversion & Export**:
  - Image Conversions: JPEG, PNG, WEBP, BMP, PDF export (multi-image).
  - Video Tools: Video to GIF converter, high-resolution video frame grabber, lossless video trimming/transcoding.
- **Resilient Decoding Guarantees**:
  - Graceful fallback for corrupted/unsupported files or device-specific codec limitations.

## 3. Files to Modify
- `docs/Project_Idea.md`
- `plans/20260818_152400_expand_media_format_support.md`
- `change_log/20260818_152400_expand_media_format_support.md` (upon completion)
