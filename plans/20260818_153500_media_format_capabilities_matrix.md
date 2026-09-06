# Media Format Capabilities Matrix Plan

**Status:** Completed

## 1. Overview
Clarify and formalize format support boundaries in the Project Idea document by adding a dedicated Media Format Capability Matrix defining View-Only, Editable, and Convertible formats.

## 2. Files to Change
- `docs/Project_Idea.md`

## 3. The Issue
While `docs/Project_Idea.md` lists general viewing formats, editing features, and output conversion targets, it does not explicitly specify the exact operational boundaries per format category (e.g., which formats are strictly View-Only like RAW previews/SVG vs fully Editable raster images vs Convertible/developable formats).

## 4. Proposed Fix
Add a dedicated subsection **2.6 Media Format Capability Matrix** (and adjust subsequent section numbers) in `docs/Project_Idea.md` with a structured breakdown:
- **Standard Raster Images** (`.jpg`, `.jpeg`, `.png`, `.webp`, `.bmp`, `.wbmp`, `.ico`): Full viewing, full editing (crop, rotate, filters, watermark), conversion to JPG/PNG/WEBP/BMP/PDF.
- **Next-Gen Formats** (`.heic`, `.heif`, `.avif`): Full viewing/decoding, editable via auto-conversion to standard raster, export/convert to standard formats.
- **Vector Graphics** (`.svg`): Scalable viewing/rendering, View-Only (no pixel editing), export/rasterization to PNG/PDF.
- **Camera RAW** (`.dng`, `.cr2`, `.nef`, `.arw`): Embedded preview/thumbnail viewing, View-Only (no direct in-place editing), conversion/development of preview to JPG/PNG.
- **Animated Formats** (Animated `.gif`, Animated `.webp`, Animated `.avif`): Multi-frame playback controls, frame extraction, video/GIF conversion.
- **Videos** (`.mp4`, `.mkv`, `.webm`, `.3gp`, `.mov`, `.avi`, `.ts`): Full playback with hardware acceleration, lossless stream-copy trimming, conversion (Video to GIF, Frame Grabber to JPG/PNG).

## 5. Verification
- Verify formatting and readability in `docs/Project_Idea.md`.
