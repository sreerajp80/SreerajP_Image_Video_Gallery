# Plan — Phase 7: Format Conversion, Compression, PDF Export & Video Utilities

**Status:** completed

**Date:** 2026-08-30
**Phase:** 7 of 13 (see [docs/implementation_plan.md](../docs/implementation_plan.md))

---

## 1. What this phase must deliver

From the implementation plan, Phase 7 has five action steps:

1. Image format conversion (JPEG, PNG, WEBP, BMP).
2. PDF document export from several chosen images.
3. Image resizing and quality compression, with a file size preview.
4. Video to GIF converter, with framerate and resolution options.
5. Video still frame grabber, and lossless stream-copy video trimming.

## 2. The issue / gap today

The app can view and edit a photo, but it cannot change a file's format,
make it smaller, or turn photos into a PDF. It also has no video tools at
all: no way to pull a still frame out of a clip, no GIF export, and no trim.

The route `/media-viewer/:id/convert` named in
[docs/architecture.md](../docs/architecture.md) is not wired. There is no
`lib/services/convert/` folder, no PDF writer, and no native helper for
video frames or trimming.

## 3. Design decisions

**Never touch the original.** Every output is a brand new file written next
to the source under a fresh, unused name (for example `IMG_0001_conv1.webp`,
`IMG_0001_resized1.jpg`, `CLIP_0007_trim1.mp4`). Writing goes through
`AtomicSaver`, so a half-written file is never left behind. No original is
opened for writing and none is deleted (hard rule 4).

**Pure maths split from pixels.** Resize target maths, output naming, PDF
page layout, GIF frame timing, and trim range validation are pure functions
in their own services, so they are unit tested with no device and no files.
Only the encoders touch the `image` package or the platform.

**Heavy work off the UI thread.** Decoding, resizing, re-encoding, and PDF
building all run through `compute` in a background isolate, the same way the
Phase 6 render pipeline does. The UI only ever holds the finished bytes.

**The size preview is real, not a guess.** When the user moves the quality
or size sliders, the app encodes the image with those exact settings in the
background and reports the true byte count. Nothing is written to disk until
the user presses Save. The work is debounced so dragging a slider stays
smooth.

**WEBP is encoded natively.** The Dart `image` package can read WEBP but
cannot write it. Android's own `Bitmap.compress` can, so WEBP output goes
through a small Kotlin channel. JPEG, PNG, and BMP stay in pure Dart.

**Video tools are native, and the trim is lossless.** Video work cannot be
done in pure Dart, and no video processing package is allowed. Android's own
APIs cover everything the phase needs, with no new package and no new
permission:

- `MediaMetadataRetriever` for clip information and for pulling still frames
  at a chosen time (used by both the frame grabber and the GIF export).
- `MediaExtractor` + `MediaMuxer` for trimming by copying the compressed
  audio and video packets straight across. Nothing is re-encoded, so there
  is no quality loss and the trim is fast. The cut is snapped to the nearest
  sync (key) frame before the chosen start, which is what "stream copy"
  means in practice.

**One new package: `pdf`.** It is already listed as an approved baseline
package in [docs/dependencies.md](../docs/dependencies.md) (Apache-2.0). It
has no HTTP, cloud, analytics, or network dependency. The companion
`printing` package is **not** added, because we write the PDF bytes
ourselves through `AtomicSaver`.

**Layering.** `screens/convert` and `screens/video` -> `providers` ->
`services/convert` and `services/video` -> platform channels -> `models`.
No widget opens a file or calls the `image` package; no service imports
`BuildContext`.

## 4. Files to be added

### Dart models (immutable, `const` constructors + `copyWith`)

- `lib/models/convert/image_output_format.dart` — `ImageOutputFormat` enum
  (jpeg, png, webp, bmp) with extension, MIME type, whether it takes a
  quality value, and whether it keeps transparency.
- `lib/models/convert/resize_spec.dart` — resize mode (none, longest side,
  exact size, percent), target numbers, and keep-aspect flag.
- `lib/models/convert/conversion_request.dart` — the whole conversion as one
  object: output format, quality, `ResizeSpec`, strip-metadata flag.
- `lib/models/convert/conversion_result.dart` — output path, byte size,
  final width and height, and the size saved against the original.
- `lib/models/convert/size_estimate.dart` — byte count and pixel size of a
  trial encode, with a helper for the percent saved.
- `lib/models/convert/pdf_export_options.dart` — page size (A4, Letter, fit
  to image), orientation, margin, fit mode (contain or fill), and the JPEG
  quality used for the embedded photos.
- `lib/models/video/gif_export_options.dart` — frames per second, longest
  side, start and end time, loop flag, frame cap.
- `lib/models/video/video_clip_info.dart` — duration, size, rotation, and
  frame rate reported by the platform.
- `lib/models/video/trim_range.dart` — start and end in milliseconds, with
  duration and validity helpers.

### Dart services

- `lib/services/convert/output_naming_service.dart` — builds the next unused
  `<name>_<suffix><n>.<ext>` path beside a source file, and writes bytes
  through `AtomicSaver`. Refuses any target equal to the source. Shared by
  every Phase 7 save path.
- `lib/services/convert/image_resize_service.dart` — pure maths turning a
  `ResizeSpec` plus a source size into a final pixel size, with clamping,
  aspect keeping, and a minimum of 1 pixel.
- `lib/services/convert/image_codec_channel.dart` — thin wrapper over the
  native WEBP encoder channel, with a clear failure when the platform says
  no.
- `lib/services/convert/format_conversion_service.dart` — decode, resize,
  re-encode into the chosen format; JPEG/PNG/BMP in Dart through an isolate,
  WEBP through the channel. Flattens transparency onto white when the target
  cannot keep it. Throws a plain exception on a corrupt or unsupported file.
- `lib/services/convert/compression_service.dart` — runs a real encode at the
  chosen settings in the background and returns a `SizeEstimate`; nothing is
  written to disk.
- `lib/services/convert/pdf_layout_service.dart` — pure page maths: page
  points for A4/Letter/fit-to-image, and the rectangle an image of a given
  size gets on that page for contain or fill, with margins honoured.
- `lib/services/convert/pdf_export_service.dart` — builds the document with
  the `pdf` package from a list of image paths, downscaling and re-encoding
  each photo first so a 20-photo PDF stays a sane size, then writes it with
  `AtomicSaver`. Skips a file it cannot read instead of failing the export,
  and reports what was skipped.

### Dart services (video)

- `lib/services/video/video_tools_channel.dart` — Dart side of the native
  channel: `readClipInfo`, `grabFrame`, `trim`.
- `lib/services/video/video_frame_service.dart` — grabs one frame at a
  position and saves it as JPEG or PNG through the naming service.
- `lib/services/video/gif_frame_planner.dart` — pure maths: turns a
  `GifExportOptions` plus a clip duration into the exact list of frame
  timestamps, respecting fps, the time range, and the frame cap.
- `lib/services/video/gif_export_service.dart` — pulls each planned frame
  from the platform, shrinks it to the chosen longest side, encodes an
  animated GIF with the `image` package, and saves it.
- `lib/services/video/video_trim_service.dart` — validates and clamps the
  range (pure), then asks the platform to stream-copy the cut.

### Providers

- `lib/providers/convert_providers.dart` — service providers, the conversion
  request notifier, the debounced size-estimate `FutureProvider`, the save
  controller, and the PDF export controller with its picked-image set.
- `lib/providers/video_tools_providers.dart` — clip info provider, GIF option
  notifier, trim range notifier, and the three run controllers (frame, GIF,
  trim) with progress state.

### Screens and widgets

- `lib/screens/convert/format_converter_screen.dart` — the converter and
  resizer at `/media-viewer/:id/convert`: format chips, quality slider,
  resize panel, live size preview, Save.
- `lib/screens/convert/pdf_export_screen.dart` — at `/pdf-export`: pick
  images from the indexed library, set page options, export.
- `lib/screens/video/video_tools_screen.dart` — at
  `/media-viewer/:id/video-tools`: three tabs for frame grab, GIF, and trim.
- `lib/widgets/convert/format_chip_row.dart` — output format chooser.
- `lib/widgets/convert/resize_panel.dart` — resize mode, width/height,
  percent, and keep-aspect control.
- `lib/widgets/convert/size_preview_card.dart` — original size, new size,
  percent saved, and the new pixel dimensions.
- `lib/widgets/convert/pdf_options_panel.dart` — page size, orientation,
  margin, fit mode, quality.
- `lib/widgets/convert/pdf_image_picker_grid.dart` — tick-box grid of
  indexed photos, in order, with a count.
- `lib/widgets/video/frame_grab_panel.dart` — position scrubber, frame
  preview, output format, Save.
- `lib/widgets/video/gif_options_panel.dart` — fps, longest side, range,
  loop, and the estimated frame count.
- `lib/widgets/video/trim_range_bar.dart` — a two-handle range bar over the
  clip with start and end times.

### Native Kotlin

- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/ImageToolsChannelHandler.kt`
  — `encodeWebp(bytes, quality, lossless)`.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/VideoToolsChannelHandler.kt`
  — `readClipInfo(path)`, `grabFrame(path, positionMs, maxSide)`,
  `trim(sourcePath, targetPath, startMs, endMs)` using `MediaExtractor` and
  `MediaMuxer` with no re-encoding. All work runs on a background thread and
  answers on the main thread; every call is wrapped so a broken file gives an
  error result, never a crash.

### Tests (mirroring `lib/`)

- `test/models/convert/` — `image_output_format_test.dart`,
  `resize_spec_test.dart`, `conversion_request_test.dart`,
  `pdf_export_options_test.dart`.
- `test/models/video/` — `gif_export_options_test.dart`,
  `trim_range_test.dart`, `video_clip_info_test.dart`.
- `test/services/convert/` — `output_naming_service_test.dart`,
  `image_resize_service_test.dart`, `format_conversion_service_test.dart`
  (real encode of small generated images, plus corrupt-bytes handling),
  `compression_service_test.dart`, `pdf_layout_service_test.dart`,
  `pdf_export_service_test.dart` (checks the file starts with `%PDF` and
  that unreadable inputs are skipped).
- `test/services/video/` — `gif_frame_planner_test.dart`,
  `video_trim_service_test.dart` (range clamping against a fake channel),
  `video_frame_service_test.dart` (fake channel).
- `test/services/video/fake_video_tools_channel.dart` — test double, in the
  style of the existing `fake_media_store_channel.dart`.

## 5. Files to be changed

- `pubspec.yaml` — add `pdf` (approved in `docs/dependencies.md`). No other
  new dependency.
- `lib/core/constants/app_constants.dart` — Phase 7 limits: the two new
  channel names, convert/resize/GIF/trim bounds, output suffixes, quality
  defaults, preview debounce, PDF page constants, largest convertible file.
- `lib/core/routing/app_router.dart` — add `media-viewer/:id/convert`,
  `media-viewer/:id/video-tools`, and `/pdf-export`, plus path helpers.
- `lib/screens/viewer/media_viewer_screen.dart` — add a Convert action for
  still images and a Video tools action for videos in the viewer app bar.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` —
  create and dispose the two new channel handlers.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — every new user-visible
  string, each with an `@key` description.
- `lib/l10n/generated/*` — regenerated by `flutter gen-l10n`.
- `docs/implementation_progress.md` — tick the Phase 7 checklist and set the
  Phase 7 row to Completed.

## 6. Safety rules honoured

- Originals are only ever read; every result is a new file (hard rule 4).
- Every decode, metadata read, and platform call is wrapped, so a corrupt or
  unsupported file shows a message instead of crashing (hard rule 5).
- No new permission, no networking, no proprietary SDK. The one new package
  is open source and already approved (hard rules 1–3).
- Files over the size limit are refused with a message rather than risking
  an out-of-memory kill.
- No user-visible literal strings in widgets; all through `AppLocalizations`.

## 7. Verification

1. `flutter pub get`
2. `flutter gen-l10n`
3. `dart format .`
4. `flutter analyze` — must be clean.
5. `flutter test` — all tests pass, including the new Phase 7 tests.
6. Write the change log to `change_log/`.

## 8. Out of scope (later phases)

Multi-select batch conversion across the whole library is Phase 11. Search
and duplicate detection are Phase 8. OCR and QR scanning of frames are
Phase 12. Video re-encoding (changing codec, bitrate, or resolution of a
clip) is deliberately not offered: it needs a heavyweight encoder, so the
only video outputs here are the lossless trim, still frames, and GIF.
