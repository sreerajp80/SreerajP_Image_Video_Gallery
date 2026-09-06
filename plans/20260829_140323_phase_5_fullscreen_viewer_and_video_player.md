# Plan: Phase 5 — Fullscreen Image Viewer & Hardware Video Player

**Status:** completed

## 1. Issue & Objective

Phases 1–4 are done. The app scans the device, indexes media into SQLite, caches
thumbnails, and shows the chronological timeline. But tapping a tile does nothing —
`_onItemTap` in [lib/screens/timeline/timeline_screen.dart](../lib/screens/timeline/timeline_screen.dart)
is an empty method with a "Phase 5 replaces this" comment. There is no way to open a
photo full screen, and no way to play a video at all.

Phase 5 builds that missing half of the app. From
[docs/implementation_plan.md](implementation_plan.md), it must deliver:

1. An interactive fullscreen image viewer — pinch-to-zoom, pan, double-tap zoom,
   rotation, and swipe-down to dismiss.
2. An offline hardware-accelerated video player — play/pause, seek scrubber,
   timestamp, frame stepping, loop, and playback speed from 0.25x to 2x.
3. Brightness and volume swipe gestures over the video surface.
4. A swipe-up drawer showing EXIF and media details.

## 2. Key Design Decisions

**a. The image viewer uses Flutter's built-in `InteractiveViewer`, not `photo_view`.**
[docs/dependencies.md](dependencies.md) pre-approves `photo_view`, but the framework
already gives pinch, pan, and inertia through `InteractiveViewer`. What it does not give
— a double-tap zoom target, 90-degree rotation, and swipe-down dismiss — is short, pure
maths that we want unit-testable anyway. Using the framework keeps the dependency
footprint minimal (principle 3 of the dependency doc) and avoids a third party fighting
our own paging and drag gestures. No new package is added for images.

**b. `video_player` is the one new package.**
There is no pure-Dart way to do hardware-accelerated video. `video_player`
(BSD-3-Clause, Flutter team) wraps Android media3 / ExoPlayer and plays a `content://`
URI directly through `VideoPlayerController.contentUri`, which is exactly what scoped
storage gives us. We do **not** add `chewie`: its control bar carries its own strings and
gestures, which would clash with our `AppLocalizations` rule and with our
brightness/volume gestures. We build the control bar ourselves.

**Offline check (hard rule 2).** `video_player_android` does not declare
`android.permission.INTERNET`; that permission is normally added by the app itself for
network video, and we never will. This plan includes an explicit verification step: build
the dev APK, dump the merged manifest, and confirm no INTERNET permission appears. If any
transitive library ever adds it, we strip it in
`android/app/src/main/AndroidManifest.xml` with
`<uses-permission android:name="android.permission.INTERNET" tools:node="remove"/>`.

**c. Screen brightness and system volume go through our own native channel.**
There is no approved package for screen brightness. Rather than add one, we add a small
second method channel `in.sreerajp.imgvidgal/playback` handled by a new
`PlaybackChannelHandler.kt`. It sets the window brightness attribute, reads and sets the
music stream volume through `AudioManager`, and keeps the screen awake while a video
plays. This is a few dozen lines of Kotlin and needs no extra Android permission.

**d. All gesture and playback maths lives in pure services.**
Widgets must not hold business logic. So the double-tap zoom matrix, the rotation steps,
the dismiss-drag progress, the drag-to-brightness / drag-to-volume / drag-to-seek
mapping, and the speed ladder all live in `lib/services/viewer/` and `lib/services/video/`
as pure functions over plain values. Every one of them is unit tested with no widget and
no device.

**e. EXIF is parsed lazily, in a background isolate, and cached in the database.**
The media table already has an `exif_json` column and `MediaItem` already holds an
`ExifData` field, but nothing fills them. The details drawer is the first feature that
needs real EXIF, so we parse on demand: when the drawer opens for an image, read the bytes
through the existing `MediaStoreChannel.readBytes`, decode the metadata in an isolate
using the already-present `image` package, map it into `ExifData`, and write it back with
a new `MediaDao.updateExif`. Next time it comes straight from SQLite. A corrupt or
unsupported file returns `null` and the drawer simply shows the MediaStore facts (hard
rule 5 — never crash on bad media). Files above a size cap are skipped.

**f. The viewer is a route, not a dialog.**
[docs/architecture.md](architecture.md) specifies `/media-viewer/:id`. We add that route.
The screen resolves its start index by finding the id inside the already loaded timeline
list, so paging left and right walks the same order the user saw in the grid. The details
drawer is an in-screen bottom sheet in this phase; the separate `/media-viewer/:id/info`
sub-route is left to the phase that needs a deep link into it.

## 3. Files to be Changed

### New — models
- `lib/models/playback_state.dart` — immutable video state (position, duration, speed,
  playing, buffering, looping, volume, error flag) with `copyWith`.
- `lib/models/viewer_transform.dart` — immutable zoom / rotation / dismiss state for one
  image, with `copyWith`.

### New — services (pure Dart, unit tested)
- `lib/services/viewer/viewer_transform_service.dart` — double-tap zoom target matrix,
  scale clamping, 90-degree rotation stepping, swipe-down dismiss progress and opacity.
- `lib/services/video/playback_speed_service.dart` — the 0.25x–2.0x ladder, next and
  previous step, clamping, and label text.
- `lib/services/video/video_gesture_service.dart` — maps a vertical drag on the left half
  to a brightness delta, on the right half to a volume delta, and a horizontal drag to a
  seek delta scaled by clip length.
- `lib/services/video/frame_step_service.dart` — frame-forward and frame-back target
  positions, clamped to the clip bounds.
- `lib/services/media/exif_reader_service.dart` — bytes to `ExifData`, isolate-friendly
  and null-safe on corrupt input.
- `lib/services/device/screen_settings_service.dart` — Dart side of the playback channel
  (brightness, volume, keep-awake), behind an abstract class so tests can fake it.

### New — screens and widgets
- `lib/screens/viewer/media_viewer_screen.dart` — the paged fullscreen viewer, chrome
  overlay, app bar actions, dismiss handling.
- `lib/widgets/viewer/interactive_image_view.dart` — one zoomable, rotatable image page.
- `lib/widgets/viewer/video_player_view.dart` — the video surface plus gesture layer.
- `lib/widgets/viewer/video_controls_bar.dart` — play/pause, seek scrubber, timestamps,
  frame step, loop, speed menu.
- `lib/widgets/viewer/gesture_hud.dart` — floating brightness / volume / seek indicator
  shown while a gesture is active.
- `lib/widgets/viewer/media_details_sheet.dart` — the swipe-up EXIF and details drawer.

### New — providers
- `lib/providers/viewer_providers.dart` — current page index, full-image bytes family
  provider, EXIF family provider, the video controller notifier, and the screen settings
  provider.

### New — native
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/playback/PlaybackChannelHandler.kt`

### Changed
- `pubspec.yaml` — add `video_player: ^2.9.1`.
- `lib/core/constants/app_constants.dart` — playback channel name, zoom limits, speed
  ladder bounds, frame step milliseconds, EXIF size cap, chrome auto-hide delay.
- `lib/core/routing/app_router.dart` — add `/media-viewer/:id`.
- `lib/screens/timeline/timeline_screen.dart` — `_onItemTap` pushes the viewer route.
- `lib/repositories/database/media_dao.dart` — add `updateExif`.
- `lib/repositories/media_repository.dart` — expose `saveExif` and `readOriginalBytes`.
- `lib/providers/media_providers.dart` — wire the new repository and service providers.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` — register the
  playback handler and dispose it.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — every new visible string, each with an
  `@key` description in the English file. Then run `flutter gen-l10n`.
- `docs/implementation_progress.md` — flip Phase 5 to Completed and tick its boxes.
- `docs/dependencies.md` — record `video_player` as adopted, and note that `chewie` and
  `photo_view` were considered and not used.

### New — tests
- `test/models/playback_state_test.dart`
- `test/models/viewer_transform_test.dart`
- `test/services/viewer/viewer_transform_service_test.dart`
- `test/services/video/playback_speed_service_test.dart`
- `test/services/video/video_gesture_service_test.dart`
- `test/services/video/frame_step_service_test.dart`
- `test/services/media/exif_reader_service_test.dart`
- `test/providers/viewer_providers_test.dart`

## 4. Implementation Steps

1. Add `video_player` to `pubspec.yaml`, run `flutter pub get`, then build the dev debug
   APK and dump the merged manifest to confirm no `android.permission.INTERNET`.
2. Add the new constants to `AppConstants`.
3. Write the immutable models `PlaybackState` and `ViewerTransform`.
4. Write the four pure services (transform, speed, gesture, frame step) with their tests.
5. Write `ExifReaderService` over the `image` package, add `MediaDao.updateExif`, and
   expose `saveExif` and `readOriginalBytes` on `MediaRepository`.
6. Add `PlaybackChannelHandler.kt`, register it in `MainActivity.kt`, and write the Dart
   `ScreenSettingsService` against it with a fake for tests.
7. Add `lib/providers/viewer_providers.dart`.
8. Build `InteractiveImageView`, then `VideoPlayerView` with `VideoControlsBar`,
   `GestureHud`, and `MediaDetailsSheet`.
9. Build `MediaViewerScreen` combining them, wire the `/media-viewer/:id` route, and make
   both the timeline tile tap and the flashback carousel tap open it.
10. Add all English and Malayalam strings, then run `flutter gen-l10n`.
11. Run `dart format .`, `flutter analyze` (must be zero warnings), and `flutter test`.
12. Update `docs/implementation_progress.md` and `docs/dependencies.md`, then write the
    change log in `change_log/`.

## 5. Rules Followed

- **Offline (hard rule 2):** no networking package; merged manifest checked for INTERNET.
- **Scoped storage (hard rule 3):** video plays from the `content://` URI; image bytes
  come through the existing MediaStore channel. No new file permission is requested.
- **Non-destructive (hard rule 4):** this phase only reads media. Rotation is a view
  transform held in memory; nothing is written back to the original file.
- **Never crash (hard rule 5):** an unreadable image falls back to the cached thumbnail
  and then to an error tile; a video that fails to initialise shows a message instead of
  throwing; EXIF failures return null.
- **Layers:** widgets call providers only. Services take no `BuildContext`. No SQL, file
  I/O, or channel call sits in a widget.
- **Localization:** no raw user-visible string literal; every label goes through
  `AppLocalizations` in both `en` and `ml`.
- **Security:** nothing about a file path, EXIF, or GPS is ever logged.

## 6. Risks

- **Codec support varies by device.** ExoPlayer will not decode everything. The player
  always shows a friendly failure state rather than crashing, and the details drawer still
  works for a file that will not play.
- **Very large images.** Decoding a 100 MP photo can spike memory. The full-bytes read is
  capped by file size; above the cap the viewer stays on the high-resolution thumbnail.
- **Gesture overlap.** Pinch-zoom, horizontal paging, and swipe-down dismiss share one
  surface. Dismiss and paging are only active while the image sits at its unzoomed scale,
  and that decision is made by the transform service, not by the widget.
