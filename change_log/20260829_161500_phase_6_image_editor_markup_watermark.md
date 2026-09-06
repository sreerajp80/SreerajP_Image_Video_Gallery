# Change Log — Phase 6: Non-Destructive Image Editor, Markup, Redaction & Watermarking

**Date:** 2026-08-29
**Plan:** [plans/20260829_144100_phase_6_image_editor_markup_watermark.md](../plans/20260829_144100_phase_6_image_editor_markup_watermark.md)
**Phase:** 6 of 13 — see [docs/implementation_plan.md](../docs/implementation_plan.md)

---

## What was built

The app can now edit a photo without ever changing the original file.

Tapping the new **Edit** button in the fullscreen viewer opens the editor at
`/media-viewer/:id/editor`. It has six tools: crop, tune, filters, markup,
hide, and watermark. Every action builds an immutable description of the
edit. Nothing is drawn onto real pixels until the user taps **Save copy**,
and even then the result is written as a **new file beside the original**
(`IMG_0001_edit1.jpg`, then `_edit2`, and so on). The original is only ever
read.

### 1. Edit models (new, all immutable)

- `lib/models/editor/crop_transform.dart` — `NormalizedRect`,
  `CropAspectPreset`, `PerspectiveSkew`, `CropTransform`.
- `lib/models/editor/tone_curve.dart` — `CurvePoint`, `ToneCurve`.
- `lib/models/editor/tone_adjustments.dart` — the eight sliders plus four
  curves.
- `lib/models/editor/filter_preset.dart` — `FilterPresetId` and strength.
- `lib/models/editor/markup_layer.dart` — a sealed `MarkupLayer` with
  `DoodleStroke`, `ShapeAnnotation`, and `TextAnnotation`.
- `lib/models/editor/redaction_region.dart` — area, mode, strength.
- `lib/models/editor/watermark_config.dart` — mode, content, position,
  opacity, size, margin.
- `lib/models/editor/edit_session.dart` — the whole edit as one object, with
  `isDirty`, `reset`, and JSON round-tripping.

Every model reads back safely from a bad or older map: unknown enum names
fall back to a neutral value and an unreadable markup layer is dropped
rather than taking the session down.

### 2. Services (new)

- `crop_transform_service.dart` — crop clamping, aspect reshaping, pixel
  conversion, quarter-turn wrapping, straighten bounds, the largest upright
  rectangle inside a tilted photo, and perspective corner mapping.
- `tone_curve_service.dart` — point cleaning, smoothstep interpolation, and
  the 256-entry lookup tables.
- `tone_adjustment_service.dart` — per-channel tables for exposure,
  contrast, highlights, shadows, warmth and tint, plus the per-pixel
  saturation and vibrance maths.
- `filter_preset_service.dart` — the catalogue of looks and how a strength
  slider scales each one.
- `markup_geometry_service.dart` — normalised and pixel conversion, stroke
  widths, shape bounds, arrow heads, and what counts as drawable.
- `markup_render_service.dart` — draws the layers onto pixels, including
  text rasterised from the bundled bitmap font and scaled to any size.
- `redaction_service.dart` — Gaussian blur, averaged pixelation, and
  blackout, applied to the real pixels.
- `watermark_service.dart` — timestamp formatting, sizes, and placement in
  any of nine positions.
- `image_render_pipeline.dart` — the whole render, in a fixed stage order:
  geometry, then redaction, then tone and filter, then markup, then
  watermark. It runs on a background isolate through `compute` and also has
  a downscaled preview path.
- `editor_save_service.dart` — picks a free versioned name and writes it
  through `AtomicSaver`; refuses outright if the target would ever be the
  original path.

### 3. State

- `lib/providers/editor_providers.dart` — service providers,
  `EditSessionNotifier` with an undo and redo history, the debounced preview
  provider, the tool and pen settings, and the save controller.

### 4. Screen and widgets

- `lib/screens/editor/image_editor_screen.dart` — the editor itself.
- `lib/widgets/editor/` — `editor_tool_bar.dart`, `editor_slider_row.dart`,
  `crop_overlay.dart` (draggable box plus the crop controls),
  `tone_slider_panel.dart`, `curve_editor.dart`, `filter_preset_strip.dart`,
  `markup_canvas.dart` (canvas plus the markup controls),
  `redaction_panel.dart`, and `watermark_panel.dart`.

---

## Files changed

- `lib/core/constants/app_constants.dart` — editor limits: largest editable
  file, preview size and debounce, undo depth, straighten and perspective
  ranges, minimum crop, JPEG quality, output suffix, blur and pixelate caps.
- `lib/core/routing/app_router.dart` — the `media-viewer/:id/editor` route
  and an `imageEditorPath()` helper.
- `lib/screens/viewer/media_viewer_screen.dart` — an Edit action in the
  viewer app bar, shown only for still images.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — 108 new strings, each
  with an `@key` description; `flutter gen-l10n` re-run.
- `docs/implementation_progress.md` — Phase 6 marked complete.

---

## Decisions worth recording

**No new packages.** The `image` package was already a dependency and covers
crop, rotate, perspective rectify, blur, pixelate, and drawing. The offline
and open-source hard rules are untouched, and no permission changed.

**Redaction really removes the detail.** The blur, pixelate, and blackout
tools replace the pixels in the rendered output rather than laying something
over them, so nothing can be peeled back off the saved copy.

**Redaction and markup work in the shown coordinates.** Both are recorded
against the image as the editor is displaying it, that is after any crop or
rotation. That keeps a single coordinate space for everything the user drags
on screen.

**Text is drawn from a bundled bitmap font, scaled.** The `image` package
ships fixed-size fonts, so text is drawn once at the largest one and then
resized to whatever height is asked for. No font file was added.

**The logo watermark is picked from the gallery.** The app has no file
browser and adds no picker package, so the indexed photos are the picker.
Reading the logo tries the file directly first and then falls back to the
repository, which goes through the MediaStore under scoped storage. If the
logo cannot be read at all, the watermark is skipped and the save still
succeeds.

**One drag is one undo step.** Sliders report continuously for the live
preview, and a change that does not actually alter the session is dropped,
so the history holds real steps rather than noise.

---

## Safety and hard rules

- Original media files are never written to or deleted (hard rule 4).
- A corrupt or unsupported file raises `ImageRenderException`, which the
  screen turns into a message; a single bad markup layer or an unreadable
  logo is skipped rather than failing the save (hard rule 5).
- Files over the editable size limit are refused with a message instead of
  risking an out-of-memory kill.
- No user-visible literal strings in widgets; everything goes through
  `AppLocalizations`.
- No networking, no new permissions, no blocked dependency (hard rules 1–3).

---

## Verification

- `flutter gen-l10n` — regenerated English and Malayalam.
- `dart format .` — 144 files formatted.
- `flutter analyze` — **No issues found.**
- `flutter test` — **474 tests passed**, including 223 new ones across the
  editor models, services, render pipeline, save naming, and undo history.

---

## Not in this phase

Format conversion, compression, PDF export, and the video utilities are
Phase 7. Batch editing is Phase 11. This phase edits one image at a time.
