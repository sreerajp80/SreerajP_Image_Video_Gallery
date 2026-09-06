# Change Log — Phase 7: Format Conversion, Compression, PDF Export & Video Utilities

**Date:** 2026-08-30
**Plan:** [plans/20260830_102803_phase_7_conversion_pdf_video_tools.md](../plans/20260830_102803_phase_7_conversion_pdf_video_tools.md)
**Phase:** 7 of 13 (see [docs/implementation_plan.md](../docs/implementation_plan.md))

---

## What this change does

The app can now change a picture's format, make it smaller, turn several
photos into one PDF, and work with videos: pull out a still frame, make an
animated GIF, and cut a clip without losing any quality.

Nothing on the device is ever overwritten. Every result is a brand new file
written next to the source under a name that was not already taken.

## The five things the phase had to deliver

1. **Format conversion** — JPEG, PNG, WEBP, and BMP.
2. **PDF export** — one document from many chosen photos.
3. **Resizing and compression** — with a file size preview.
4. **Video to GIF** — with frame rate and size options.
5. **Frame grabber and lossless trim.**

All five are done.

## How each part works

### Format conversion

JPEG, PNG, and BMP are written in pure Dart by the `image` package. WEBP has
no Dart encoder at all, so those pixels go to Android's own
`Bitmap.compress`, which has had a WEBP encoder built in for years. The
decode and the resize before it are the same in both cases.

When the target format cannot hold see-through pixels (JPEG and BMP), the
picture is first placed on a white background. Without that step a
transparent logo would come out as a black rectangle.

### The size preview

The number the screen shows is not a guess. The picture really is encoded at
the settings on screen, on a background isolate, and the byte count of that
result is what is shown. The work waits a short moment after the last slider
move, so dragging a slider does not queue one encode per pixel of finger
movement. Nothing is written to disk until Save is pressed.

### PDF export

Each chosen photo is shrunk and re-encoded as a JPEG first, so a twenty-photo
document stays a sensible size, and that JPEG is then embedded as it is. Page
size, direction, placement, border, and photo quality are all adjustable. A
photo that cannot be read is skipped and counted, rather than failing the
whole export — one damaged file should not cost the user the other pages.

### Video tools

Video work cannot be done in Dart, and the project allows no video processing
library, so all three tools use Android's own media APIs. No new package and
no new permission were needed:

- **Clip facts and frames** — `MediaMetadataRetriever`. Frames are shrunk on
  the Android side before they cross the channel, which keeps a 4K clip from
  sending megabytes per frame during a GIF export.
- **Lossless trim** — `MediaExtractor` plus `MediaMuxer`. The compressed
  audio and video packets are copied straight into a new container. Nothing
  is decoded and nothing is re-encoded, so no quality is lost and the work
  runs at about the speed of a file copy. The cut starts at the last key
  frame at or before the chosen moment, so the trimmed clip can begin a
  fraction early — that is the price of not re-encoding, and the screen says
  so.
- **GIF** — frames are pulled one at a time, planned by a pure Dart timing
  service, and encoded by the `image` package on a background isolate. Frame
  count and length caps stop a long selection from filling memory.

## Files added

### Models
- `lib/models/convert/image_output_format.dart`
- `lib/models/convert/resize_spec.dart`
- `lib/models/convert/conversion_request.dart`
- `lib/models/convert/conversion_result.dart`
- `lib/models/convert/size_estimate.dart`
- `lib/models/convert/pdf_export_options.dart`
- `lib/models/video/video_clip_info.dart`
- `lib/models/video/trim_range.dart`
- `lib/models/video/gif_export_options.dart`

### Services
- `lib/services/convert/output_naming_service.dart` — names and atomically
  writes every file this phase produces; refuses any target equal to the
  source.
- `lib/services/convert/image_resize_service.dart` — pure resize maths.
- `lib/services/convert/image_codec_channel.dart` — the native WEBP encoder.
- `lib/services/convert/format_conversion_service.dart` — decode, resize,
  flatten, encode; isolate entry points for both the Dart and the WEBP paths.
- `lib/services/convert/compression_service.dart` — the real-encode size
  preview and the shared byte-size label.
- `lib/services/convert/pdf_layout_service.dart` — pure page maths.
- `lib/services/convert/pdf_export_service.dart` — the document builder.
- `lib/services/video/video_tools_channel.dart`
- `lib/services/video/video_frame_service.dart`
- `lib/services/video/gif_frame_planner.dart` — pure frame timing maths.
- `lib/services/video/gif_export_service.dart`
- `lib/services/video/video_trim_service.dart`

### Providers
- `lib/providers/convert_providers.dart`
- `lib/providers/video_tools_providers.dart`

### Screens and widgets
- `lib/screens/convert/format_converter_screen.dart`
- `lib/screens/convert/pdf_export_screen.dart`
- `lib/screens/video/video_tools_screen.dart`
- `lib/widgets/convert/format_chip_row.dart`
- `lib/widgets/convert/resize_panel.dart`
- `lib/widgets/convert/size_preview_card.dart`
- `lib/widgets/convert/pdf_options_panel.dart`
- `lib/widgets/convert/pdf_image_picker_grid.dart`
- `lib/widgets/video/frame_grab_panel.dart`
- `lib/widgets/video/gif_options_panel.dart`
- `lib/widgets/video/trim_range_bar.dart`

### Native Kotlin
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/ImageToolsChannelHandler.kt`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/VideoToolsChannelHandler.kt`

### Tests
- `test/models/convert/` — four files.
- `test/models/video/` — three files.
- `test/services/convert/` — five files, including a PDF export test that
  checks the written file really begins with `%PDF`.
- `test/services/video/` — four files plus `fake_video_tools_channel.dart`.

## Files changed

- `pubspec.yaml` — added `pdf`, the one new dependency.
- `lib/core/constants/app_constants.dart` — the Phase 7 limits: channel
  names, quality and size ranges, output name suffixes, PDF page constants,
  GIF caps, and the shortest trim allowed.
- `lib/core/routing/app_router.dart` — the three new routes and their path
  helpers.
- `lib/screens/viewer/media_viewer_screen.dart` — a Convert action for still
  pictures and a Video tools action for clips.
- `lib/screens/timeline/timeline_screen.dart` — an Export as PDF action.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` — the
  two new channel handlers are created and disposed.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` — 87 new keys, each with an
  `@key` description; the generated files were rebuilt.
- `docs/implementation_progress.md` — Phase 7 ticked and marked Completed.

## New routes

| Route | Screen |
|---|---|
| `/media-viewer/:id/convert` | Format converter and resizer |
| `/media-viewer/:id/video-tools` | Frame grab, GIF, and trim |
| `/pdf-export` | PDF document export |

## Dependency note

`pdf` (Apache-2.0) was the only package added, and it was already on the
approved list in [docs/dependencies.md](../docs/dependencies.md). It brings
in `archive`, `barcode`, `bidi`, `crypto`, `image`, `meta`, `path_parsing`,
`vector_math`, and `xml` — none of them networking packages.

The lock file does list a transitive `http`. That comes from the
`package_info_plus` package added back in Phase 1, for its web
implementation, and not from `pdf`. No blocked package was added and the app
still has no `android.permission.INTERNET`.

The companion `printing` package was deliberately **not** added: the PDF
bytes are written by the app itself through `AtomicSaver`.

## Safety rules honoured

- Originals are only ever read. Every output is a new file, written through
  `AtomicSaver` so a failure part way through leaves nothing behind.
- Every decode, metadata read, and platform call is wrapped. A corrupt or
  unsupported file produces a message, never a crash. The native handlers
  catch `Throwable`, so even an out-of-memory inside a platform decoder comes
  back as an error result.
- Files over the size limit are refused with a message rather than risking an
  out-of-memory kill.
- No new permission, no networking, no proprietary SDK.
- No user-visible literal strings in widgets; everything goes through
  `AppLocalizations`.

## Deliberately left out

Video re-encoding — changing a clip's codec, bitrate, or resolution — is not
offered. It needs a heavyweight encoder that the offline and open-source
rules make impractical, so the only video outputs here are the lossless trim,
still frames, and GIF. Batch conversion across the whole library remains
Phase 11.

## Verification

| Step | Result |
|---|---|
| `flutter pub get` | Resolved, `pdf` 3.13.0 |
| `flutter gen-l10n` | Regenerated, English and Malayalam |
| `dart format .` | 196 files, 24 changed |
| `flutter analyze` | No issues found |
| `flutter test` | 636 tests, all passed |
| `flutter build apk --flavor dev --debug` | Built, so the new Kotlin compiles |
