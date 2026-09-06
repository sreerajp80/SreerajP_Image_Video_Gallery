# Change Log: Phase 5 — Fullscreen Image Viewer & Hardware Video Player

**Date:** 2026-08-29
**Plan:** [plans/20260829_140323_phase_5_fullscreen_viewer_and_video_player.md](../plans/20260829_140323_phase_5_fullscreen_viewer_and_video_player.md)
**Status:** Completed

## What changed

Tapping a tile in the timeline now opens a fullscreen viewer. Photos zoom, pan, rotate,
and swipe away. Videos play with hardware decoding and a full control bar. A swipe-up
drawer shows file facts and camera metadata.

### 1. New route and screen
- Added `/media-viewer/:id` to `lib/core/routing/app_router.dart`, with a
  `mediaViewerPath()` helper.
- `lib/screens/viewer/media_viewer_screen.dart` pages through the same list, in the same
  order, that the timeline showed. It resolves its start page from the id in the route.
- `lib/screens/timeline/timeline_screen.dart` now pushes that route from `_onItemTap`,
  which was an empty placeholder before.

### 2. Image viewer
- `lib/widgets/viewer/interactive_image_view.dart` draws one page on Flutter's built-in
  `InteractiveViewer`: pinch zoom, pan, animated double-tap zoom, and rotation preview.
- It shows the cached thumbnail first and swaps in the original bytes when they arrive,
  so a page never opens blank. A file that is too large, missing, or undecodable stays on
  the thumbnail or shows a message; it never throws.
- Swipe-down to dismiss fades the backdrop and shrinks the page. It is only active on an
  unzoomed photo, so a pan while zoomed in cannot close the viewer by accident.

### 3. Video player
- Added `video_player: ^2.9.1` (BSD-3-Clause). `chewie` was deliberately not added.
- `lib/widgets/viewer/video_player_view.dart` and `video_controls_bar.dart` give
  play/pause, a seek scrubber with timestamps, frame stepping, 10-second skips, repeat,
  and playback speed from 0.25x to 2x.
- A clip that will not load shows a friendly message instead of crashing, and its details
  drawer still works.
- Dragging on the left half changes screen brightness, the right half changes volume, and
  a sideways drag scrubs. `lib/widgets/viewer/gesture_hud.dart` shows what is happening.

### 4. New pure services (all unit tested)
- `lib/services/viewer/viewer_transform_service.dart` — zoom clamping, double-tap target,
  zoom matrix around a focal point, rotation steps, dismiss progress and thresholds.
- `lib/services/video/playback_speed_service.dart` — the speed ladder and its labels.
- `lib/services/video/video_gesture_service.dart` — drag to brightness, volume, or seek,
  plus duration formatting.
- `lib/services/video/frame_step_service.dart` — frame and skip targets, clamped to the
  clip.
- `lib/services/media/exif_reader_service.dart` — EXIF from JPEG headers, off the UI
  thread, returning null on anything corrupt or unsupported.
- `lib/services/device/screen_settings_service.dart` — brightness, volume, and keep-awake
  behind an interface so tests use a fake.

### 5. New models and providers
- `lib/models/viewer_transform.dart` and `lib/models/playback_state.dart`, both immutable
  with `copyWith` and value equality.
- `lib/providers/viewer_providers.dart` holds the service providers, the current page, the
  full-image bytes provider, the EXIF provider, and `VideoPlaybackController`, which is
  the only place that touches `video_player`.

### 6. Details drawer and EXIF caching
- `lib/widgets/viewer/media_details_sheet.dart` shows name, format, size, dimensions,
  duration, dates, folder, and every EXIF field that is present.
- EXIF is parsed the first time a photo's details are opened, then stored through the new
  `MediaDao.updateExif` and `MediaRepository.saveExif`. The existing FTS update trigger
  picks it up, so camera and lens text becomes searchable as a side effect.
- `MediaRepository.readOriginalBytes` reads original bytes through the existing MediaStore
  channel, with a size cap so a very large photo cannot exhaust memory.

### 7. Native
- New `PlaybackChannelHandler.kt` on the `playback` method channel: window brightness,
  media stream volume, and keep-screen-on. It needs no extra Android permission and never
  changes a device-wide setting.
- `MainActivity.kt` registers and disposes it beside the existing MediaStore handler.

### 8. Staying fully offline
- `video_player` itself declares no `INTERNET` permission, but its ExoPlayer dependency
  declares `INTERNET`, `ACCESS_NETWORK_STATE`, and `WAKE_LOCK` for streaming. All three
  are now removed in `android/app/src/main/AndroidManifest.xml` with `tools:node="remove"`.
- Verified by building the dev APK and listing permissions in the packaged manifest. The
  result is media permissions and biometrics only — no network permission of any kind.

### 9. Localization
- 39 new keys in `lib/l10n/app_en.arb`, each with an `@key` description, and the matching
  Malayalam strings in `lib/l10n/app_ml.arb`. `flutter gen-l10n` was run.

## Files added

- `lib/models/playback_state.dart`, `lib/models/viewer_transform.dart`
- `lib/services/viewer/viewer_transform_service.dart`
- `lib/services/video/playback_speed_service.dart`, `video_gesture_service.dart`,
  `frame_step_service.dart`
- `lib/services/media/exif_reader_service.dart`
- `lib/services/device/screen_settings_service.dart`
- `lib/providers/viewer_providers.dart`
- `lib/screens/viewer/media_viewer_screen.dart`
- `lib/widgets/viewer/interactive_image_view.dart`, `video_player_view.dart`,
  `video_controls_bar.dart`, `gesture_hud.dart`, `media_details_sheet.dart`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/playback/PlaybackChannelHandler.kt`
- Tests: `test/models/playback_state_test.dart`, `test/models/viewer_transform_test.dart`,
  `test/services/viewer/viewer_transform_service_test.dart`,
  `test/services/video/playback_speed_service_test.dart`,
  `test/services/video/video_gesture_service_test.dart`,
  `test/services/video/frame_step_service_test.dart`,
  `test/services/media/exif_reader_service_test.dart`,
  `test/providers/viewer_providers_test.dart`

## Files changed

- `pubspec.yaml`, `pubspec.lock` — added `video_player`.
- `lib/core/constants/app_constants.dart` — viewer and playback constants.
- `lib/core/routing/app_router.dart` — the viewer route.
- `lib/screens/timeline/timeline_screen.dart` — tile tap opens the viewer.
- `lib/repositories/database/media_dao.dart` — `updateExif`.
- `lib/repositories/media_repository.dart` — `readOriginalBytes`, `saveExif`, optional
  MediaStore channel.
- `lib/providers/media_providers.dart` — passes the channel to the repository.
- `android/app/src/main/AndroidManifest.xml` — removes the ExoPlayer network permissions.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, and the generated localizations.
- `docs/implementation_progress.md`, `docs/dependencies.md`.

## Verification

- `flutter analyze` — no issues.
- `flutter test` — 251 tests pass, 80 of them added by this phase.
- `dart format .` — applied.
- `flutter build apk --flavor dev --debug` — succeeds; the packaged manifest lists only
  `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`,
  `READ_EXTERNAL_STORAGE` (maxSdkVersion 32), and `USE_BIOMETRIC`.

## Notes and limits

- The viewer was not run on a physical device in this session. Gesture behaviour, codec
  support, and the brightness and volume channel are best confirmed on real hardware.
- Rotation is a preview only. Nothing is written back to the original file, which keeps
  the non-destructive rule intact; a saved rotation belongs to the Phase 6 editor.
- Frame stepping assumes 30 fps, because MediaStore does not report a frame rate.
- EXIF is read from JPEG headers. HEIC, PNG, WEBP, and RAW files show their MediaStore
  facts and a short note instead of camera metadata.
