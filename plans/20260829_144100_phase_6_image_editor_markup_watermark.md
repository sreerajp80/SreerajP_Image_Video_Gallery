# Plan — Phase 6: Non-Destructive Image Editor, Markup, Redaction & Watermarking

**Status:** completed

**Date:** 2026-08-29
**Phase:** 6 of 13 (see [docs/implementation_plan.md](../docs/implementation_plan.md))

---

## 1. What this phase must deliver

From the implementation plan, Phase 6 has seven action steps:

1. Transformations: crop (presets and freeform), 90-degree rotate, fine straighten slider, perspective skew.
2. Colour and tone: exposure, contrast, highlights/shadows, temperature, tint, vibrance, RGB curves.
3. Artistic filters and presets (B&W, sepia, vintage, vivid).
4. Markup canvas: freehand doodle, shapes (rectangle, arrow, circle, line), text overlay.
5. Privacy redaction: Gaussian blur, pixelation, blackout brush.
6. Text, timestamp, and logo watermark engine.
7. Non-destructive atomic saving through `AtomicSaver`.

## 2. The issue / gap today

The app can view photos but cannot change them. There is no editor screen,
no edit session state, no pixel pipeline, and no save path. `AtomicSaver`
exists (Phase 2) but nothing calls it yet. The viewer app bar has no way to
open an editor, and the route `/media-viewer/:id/editor` named in
[docs/architecture.md](../docs/architecture.md) is not wired.

## 3. Design decisions

**Non-destructive by construction.** The editor never changes the original
file. All user actions build an immutable `EditSession` — a description of
the edit, not pixels. Pixels are produced only when the user saves, and the
result is written as a **new file** next to the original with a version
suffix (for example `IMG_0001_edit1.jpg`), through `AtomicSaver`. The
original path is never opened for writing. Overwriting is not offered in
this phase.

**Split pure maths from drawing.** Everything that can be a pure function is
a pure function in `lib/services/editor/`, so it is unit tested with no
device: crop rectangles, straighten geometry, perspective corner mapping,
tone lookup tables, curve interpolation, filter preset definitions, markup
geometry, watermark placement. Only the final rasteriser touches the `image`
package.

**Heavy work off the UI thread.** The full-resolution render runs in a
background isolate through `compute`, so a large photo never freezes the UI.
The live preview renders a downscaled copy so sliders stay responsive.

**No new dependencies.** `image: ^4.2.0` is already in `pubspec.yaml` and
covers crop, rotate, colour adjust, Gaussian blur, pixelate, and drawing
primitives. Nothing is added, so the offline and open-source hard rules are
untouched.

**Layering.** `screens/editor` -> `providers/editor_providers` ->
`services/editor` -> `models`. No widget touches files or the `image`
package directly; no service imports `BuildContext`.

## 4. Files to be added

### Models (immutable, `const` constructors + `copyWith`)
- `lib/models/editor/crop_transform.dart` — normalised crop rect, quarter
  turns, straighten angle, horizontal/vertical flip, perspective corner
  offsets, aspect preset enum.
- `lib/models/editor/tone_curve.dart` — one channel curve as a sorted list
  of control points.
- `lib/models/editor/tone_adjustments.dart` — exposure, contrast,
  highlights, shadows, temperature, tint, vibrance, saturation, plus the
  RGB curves.
- `lib/models/editor/filter_preset.dart` — preset id enum (none, mono,
  sepia, vintage, vivid, cool, warm, fade) and its definition.
- `lib/models/editor/markup_layer.dart` — base markup layer plus
  `DoodleStroke`, `ShapeAnnotation` (rectangle, ellipse, line, arrow), and
  `TextAnnotation`.
- `lib/models/editor/redaction_region.dart` — region, mode (blur, pixelate,
  blackout), and strength.
- `lib/models/editor/watermark_config.dart` — mode (text, timestamp, logo),
  content, corner, opacity, scale, colour, margin.
- `lib/models/editor/edit_session.dart` — the whole edit as one immutable
  object: crop, tone, preset, markup list, redaction list, watermark; plus
  `isDirty` and `reset`.

### Services
- `lib/services/editor/crop_transform_service.dart` — aspect preset rects,
  clamping a crop inside the image, straighten bounding-box maths, quarter
  turn composition, perspective corner validation.
- `lib/services/editor/tone_curve_service.dart` — curve interpolation over
  control points, clamped to 0–255.
- `lib/services/editor/tone_adjustment_service.dart` — builds 256-entry
  per-channel lookup tables from `ToneAdjustments`; pure and fully tested.
- `lib/services/editor/filter_preset_service.dart` — preset catalogue and
  the `ToneAdjustments` each preset maps to.
- `lib/services/editor/markup_geometry_service.dart` — normalised and pixel
  conversion, arrow head points, stroke bounds, minimum sizes.
- `lib/services/editor/redaction_service.dart` — region clamping and the
  pixel operations (blur, pixelate, blackout) over the `image` package.
- `lib/services/editor/watermark_service.dart` — placement rectangle from
  corner, margin and scale, and timestamp text formatting.
- `lib/services/editor/image_render_pipeline.dart` — applies the session in
  a fixed order (redaction, then crop/straighten/perspective, then
  tone/preset, then markup, then watermark) and returns encoded bytes. Has
  an isolate entry point used through `compute`, plus a fast downscaled
  preview path.
- `lib/services/editor/editor_save_service.dart` — picks a non-clashing
  versioned output name and writes it with `AtomicSaver`; never touches the
  original.

### Providers
- `lib/providers/editor_providers.dart` — service providers, an
  `EditSessionNotifier` with an undo/redo history stack, the preview
  `FutureProvider`, and the save controller.

### Screen and widgets
- `lib/screens/editor/image_editor_screen.dart` — the editor at
  `/media-viewer/:id/editor`, with a tool rail and a live preview.
- `lib/widgets/editor/editor_tool_bar.dart` — tool switcher (crop, tune,
  filters, markup, redact, watermark) and undo/redo/save actions.
- `lib/widgets/editor/crop_overlay.dart` — draggable crop handles, grid,
  aspect chips, straighten slider.
- `lib/widgets/editor/tone_slider_panel.dart` — the tone sliders.
- `lib/widgets/editor/curve_editor.dart` — the RGB curve control.
- `lib/widgets/editor/filter_preset_strip.dart` — preset chooser.
- `lib/widgets/editor/markup_canvas.dart` — draws and captures doodles,
  shapes, and text overlays.
- `lib/widgets/editor/redaction_panel.dart` — blur, pixelate and blackout
  controls.
- `lib/widgets/editor/watermark_panel.dart` — watermark options.

### Tests (mirroring `lib/`)
- `test/models/editor/` — one test file per model (copyWith, equality,
  serialisation, clamping).
- `test/services/editor/` — one test file per service, including the render
  pipeline order, save naming, and graceful failure on corrupt bytes.

## 5. Files to be changed

- `lib/core/constants/app_constants.dart` — editor limits (straighten range,
  slider ranges, preview size, undo depth, output quality, largest editable
  file).
- `lib/core/routing/app_router.dart` — add `media-viewer/:id/editor` and an
  `imageEditorPath()` helper.
- `lib/screens/viewer/media_viewer_screen.dart` — add an Edit action to the
  viewer app bar, shown only for still images.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — every new user-visible
  string, each with an `@key` description.
- `lib/l10n/generated/*` — regenerated by `flutter gen-l10n`.
- `docs/implementation_progress.md` — tick the Phase 6 checklist and set the
  phase row to Completed.

## 6. Safety rules honoured

- Original media files are never written to or deleted (hard rule 4).
- Every decode and parse is wrapped so a corrupt or unsupported file shows a
  message instead of crashing (hard rule 5).
- No new permissions, no networking, no new packages (hard rules 1–3).
- No user-visible literal strings in widgets; all through `AppLocalizations`.

## 7. Verification

1. `flutter gen-l10n`
2. `dart format .`
3. `flutter analyze` — must be clean.
4. `flutter test` — all tests pass, including the new editor tests.
5. Write the change log to `change_log/`.

## 8. Out of scope (later phases)

Format conversion, compression, PDF export and video utilities are Phase 7.
Batch editing is Phase 11. This phase edits one image at a time.
