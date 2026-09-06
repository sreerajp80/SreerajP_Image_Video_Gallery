# Change Log: Phase 3 — Scoped Storage Scanner, MediaStore Indexing & Fast Thumbnail Cache

**Date:** 2026-08-29
**Implements:** [plans/20260829_094030_phase_3_mediastore_scanner_and_thumbnail_cache.md](../plans/20260829_094030_phase_3_mediastore_scanner_and_thumbnail_cache.md)
**Status:** Completed

---

## 1. What Changed

The app can now read the real photos and videos on the device, save them into the
local database, and show fast thumbnails for them.

Before this change the database was always empty, because nothing read the device.

### Reading the device (native Kotlin)
A small platform channel (`in.sreerajp.imgvidgal/mediastore`) was written instead of
adding a third-party gallery package, so the approved dependency list stays unchanged.
It handles granular media permissions, pages over the MediaStore, and returns
hardware-backed thumbnails. All heavy work runs on a background executor, and each
call catches its own failures so a bad file cannot crash the app.

### Scanning and indexing (Dart)
`MediaScannerService` pages through the channel in batches of 200, maps each row to
an immutable `MediaItem`, and writes it with `MediaDao.batchUpsertMediaItems`. It
supports a full scan and a cheaper incremental scan, emits live progress, counts and
skips unreadable rows, and removes database rows for files that are gone.

Stale rows are removed only after a **full** scan with **full** permission. With
Android 14 "selected photos" access the hidden items are not missing, only unseen, so
deleting them would lose real data.

### Thumbnails
A four-step lookup, cheapest first: RAM cache, disk cache, native MediaStore
thumbnail, then a pure Dart decode in a background isolate. If all four fail the
service returns null and the widget shows a placeholder. Requests for the same key
that arrive together share one generation, so fast scrolling cannot decode the same
item many times.

Cache sizes come from device RAM: under 4 GB uses 256 px thumbnails with a small
cache, 4–6 GB uses 384 px, and 6 GB or more uses 512 px with the largest cache. If
RAM cannot be read, the smallest tier is used.

---

## 2. Files Added

### Android native
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreQueryBuilder.kt`

### Dart source
- `lib/services/media/media_store_channel.dart` (channel contract, `MediaStoreEntry`, `MediaPermissionStatus`)
- `lib/services/media/media_permission_service.dart`
- `lib/services/media/media_type_resolver.dart`
- `lib/services/media/media_scanner_service.dart` (`ScanPhase`, `ScanProgress`, `ScanResult`)
- `lib/repositories/media_repository.dart`
- `lib/core/device/device_memory_service.dart` (`DeviceMemoryTier`, `ThumbnailCacheConfig`)
- `lib/services/thumbnail/thumbnail_memory_cache.dart`
- `lib/services/thumbnail/thumbnail_disk_cache.dart`
- `lib/services/thumbnail/thumbnail_decoder_isolate.dart`
- `lib/services/thumbnail/thumbnail_service.dart`
- `lib/providers/media_providers.dart`
- `lib/widgets/media/media_thumbnail.dart`
- `lib/widgets/dev/media_scan_panel.dart` (dev flavor only; Phase 4 replaces it)

### Android resources
- `android/app/src/main/res/values/colors.xml`
- `android/app/src/main/res/drawable/ic_launcher_foreground.xml`
- `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
- `android/app/src/main/res/mipmap/ic_launcher.xml`

### Tests
- `test/services/media/fake_media_store_channel.dart` (shared fake device)
- `test/services/media/media_type_resolver_test.dart`
- `test/services/media/media_scanner_service_test.dart`
- `test/repositories/media_repository_test.dart`
- `test/core/device/device_memory_service_test.dart`
- `test/services/thumbnail/thumbnail_memory_cache_test.dart`
- `test/services/thumbnail/thumbnail_disk_cache_test.dart`
- `test/services/thumbnail/thumbnail_service_test.dart`

---

## 3. Files Modified

- `pubspec.yaml` — added `system_info2`, `crypto`, and `image` (all on the approved list).
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` — registers the
  channel, forwards permission results, and disposes it.
- `lib/core/constants/app_constants.dart` — scan batch size, channel name, cache tier
  thresholds, thumbnail sizes, and cache budgets.
- `lib/core/errors/app_exception.dart` — added `MediaScanException`,
  `PermissionDeniedException`, and `ThumbnailException`.
- `lib/repositories/database/media_dao.dart` — added `getNewestDateModifiedMs()` for
  incremental scans and `deleteMediaItemsMissingFrom()` for stale row cleanup. These
  two were not in the plan's file list but are needed by the planned scan behaviour.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — 13 new keys with `@` descriptions,
  covering permissions, scan progress, and empty states. Generated files refreshed.
- `lib/screens/home_screen.dart` — shows the dev-only scan panel for the `dev` flavor.

---

## 4. Pre-existing Problems Fixed Along the Way

Three Phase 1 gaps blocked the release build check. They were not part of the Phase 3
plan, but the build could not be verified without fixing them:

1. `android/app/build.gradle.kts` — `java.util.Properties()` did not compile, because
   in the Gradle Kotlin DSL `java` resolves to the Java plugin extension, not the
   package. Fixed with a top-level `import java.util.Properties`.
2. `android/gradle.properties` — `android.useAndroidX` was missing, so any AndroidX
   dependency failed the build. Added it along with `enableJetifier=false` and JVM
   memory settings.
3. No launcher icon existed, so resource linking failed on `mipmap/ic_launcher`. Added
   a **placeholder** vector icon (adaptive for Android 8+, layer-list for 7.x).
   **This placeholder must be replaced with the real artwork before any production
   release.**

---

## 5. Rule Compliance

- **Offline**: no networking package added. The merged debug manifest was checked and
  declares only `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`,
  `READ_MEDIA_VISUAL_USER_SELECTED`, `READ_EXTERNAL_STORAGE` (capped at API 32), and
  `USE_BIOMETRIC`. No `android.permission.INTERNET`.
- **Scoped storage**: MediaStore APIs and granular permissions only.
- **Non-destructive**: Phase 3 only reads media. The only writes are to the app cache
  directory and the app database.
- **No crash on bad input**: every decode path returns null, and each failed scan row
  is counted and skipped.
- **Layer boundaries**: widgets read providers, providers use the repository, the
  repository uses DAOs and services. No SQL or file I/O in a widget, and no
  `BuildContext` in a service.
- **Privacy**: no file paths, EXIF values, or GPS data are logged in any build.
- **Localization**: every new user-visible string comes from `AppLocalizations`.

---

## 6. Verification

| Check | Result |
|---|---|
| `flutter pub get` | Success |
| `flutter gen-l10n` | Success — English and Malayalam regenerated |
| `dart format .` | 36 files formatted |
| `flutter analyze` | **No issues found** |
| `flutter test` | **116 tests passed** (76 from Phases 1–2, 40 new) |
| `flutter build apk --flavor dev --debug` | **Success** |
| Merged manifest permission check | No INTERNET permission |

One test needed a fix during the run: the disk cache eviction test first ordered files
by real write time, which the filesystem timestamp resolution could not tell apart.
It now sets modification times explicitly, so the least-recently-used order is tested
without depending on timing.

---

## 7. Known Limits (Handled in Later Phases)

- Video thumbnails come only from the native MediaStore path; there is no pure Dart
  fallback for video frames (Phase 5).
- `sha256Hash` and `pHash` columns stay empty until Phase 8.
- EXIF is limited to what MediaStore reports; full EXIF parsing is Phase 5.
- The dev scan panel is temporary and is replaced by the timeline screen in Phase 4.
