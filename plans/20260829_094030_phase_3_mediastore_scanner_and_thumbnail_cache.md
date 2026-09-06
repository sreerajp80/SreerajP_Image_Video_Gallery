# Plan: Phase 3 — Scoped Storage Scanner, MediaStore Indexing & Fast Thumbnail Cache

**Status:** completed

## 1. Issue & Objective

Phases 1 and 2 are done. The app has themes, flavors, config, domain models, and a
SQLite database with DAOs. But nothing reads real media from the device yet, so the
database stays empty.

Phase 3 fills that gap. It must:

1. Read images and videos from the Android MediaStore using only scoped, granular
   media permissions.
2. Save (index) what it finds into the existing `media` table through `MediaDao`.
3. Size the thumbnail caches based on how much RAM the device has.
4. Decode and cache thumbnails in a background isolate so the UI thread stays smooth.
5. Never crash on a corrupt, missing, or unsupported file — always fall back safely.

Phase 3 builds the data engine only. Phase 4 will build the timeline screen that uses
it. No new UI screen is added here, apart from a small dev-only test panel on the
existing home screen so the work can be seen running on a real device.

## 2. Key Design Decision — Native Channel, Not a Third-Party Gallery Package

The common Flutter package for MediaStore access (`photo_manager`) is **not** in the
approved list in [dependencies.md](../docs/dependencies.md). Rather than add an
unapproved package, this plan queries MediaStore directly from a small Kotlin platform
channel that we own.

Reasons:
- Keeps the dependency list exactly as approved, so the offline hard rule stays easy to prove.
- MediaStore gives us `ContentResolver.loadThumbnail()`, which uses the device's own
  hardware-backed thumbnail service. This is far faster than decoding full images in Dart.
- Permission requests are handled in the same channel, so `permission_handler`
  (also not on the approved list) is not needed.

Trade-off: more Kotlin code to maintain, and platform-channel code cannot be covered by
`flutter test`. The plan handles this by keeping all logic (mapping, paging, cache
sizing, LRU eviction, disk keys, fallbacks) in pure Dart classes that take the channel
as an injected interface, so those classes are fully unit-testable with a fake.

If you prefer adding `photo_manager` instead, say so and I will re-plan.

## 3. Dependencies to Add

| Package | Version | Why | License |
|---|---|---|---|
| `system_info2` | `^4.0.0` | Read total device RAM to size caches (named in the plan and in the dependency catalog) | MIT |
| `crypto` | `^3.0.3` | Stable hash-based cache keys for disk thumbnails | BSD-3-Clause |
| `image` | `^4.2.0` | Pure Dart fallback decode and downscale in an isolate when the native thumbnail fails | Apache-2.0 |

All three are on the approved list, are open source, make no network calls, and do not
declare `android.permission.INTERNET`. `image` is also needed later for Phases 6 and 7.

No `dev_dependencies` change is needed.

## 4. Files to Create

### Android native (Kotlin)
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
  - Method channel `in.sreerajp.imgvidgal/mediastore`.
  - `hasPermissions` / `requestPermissions` — granular `READ_MEDIA_IMAGES` and
    `READ_MEDIA_VIDEO` on API 33+, `READ_MEDIA_VISUAL_USER_SELECTED` handling on
    API 34+, `READ_EXTERNAL_STORAGE` on API 32 and below. Reports
    `granted` / `partial` / `denied` / `permanentlyDenied`.
  - `queryMedia(offset, limit, sinceDateModified)` — pages over `MediaStore.Files`
    (images plus videos) returning id, content URI, relative path, display name, MIME
    type, size, date added, date modified, date taken, width, height, duration, orientation.
  - `loadThumbnail(uri, width, height)` — `ContentResolver.loadThumbnail()` on API 29+,
    with the older `MediaStore.Images/Video.Thumbnails` path below that, returned as JPEG bytes.
  - `getMediaCount()` — total item count, used for scan progress.
  - Every call is wrapped so a `SecurityException`, `FileNotFoundException`, or decode
    failure returns a typed error result instead of throwing into Flutter.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreQueryBuilder.kt`
  - Cursor projection, selection, and sort-order construction, kept separate for clarity.

### Dart — platform bridge (`lib/services/media/`)
- `lib/services/media/media_store_channel.dart`
  - `abstract class MediaStoreChannel` (the injectable interface) plus
    `PlatformMediaStoreChannel` (the real `MethodChannel` implementation).
  - Converts raw platform maps into `MediaStoreEntry` objects, and platform errors into
    `MediaScanException` / `PermissionDeniedException`.
- `lib/services/media/media_permission_service.dart`
  - `MediaPermissionStatus` enum (`granted`, `partial`, `denied`, `permanentlyDenied`)
    and a thin service to check and request media permissions.
- `lib/services/media/media_type_resolver.dart`
  - Pure function mapping MIME type plus file extension to `MediaType`
    (`image`, `video`, `gif`, `rawImage`, `svg`). Covers RAW extensions
    (`.dng`, `.cr2`, `.nef`, `.arw`, `.orf`, `.rw2`) and unknown types
    (defaults to `image`, never throws).

### Dart — scanning and indexing
- `lib/services/media/media_scanner_service.dart`
  - Pages through the channel in batches (default 200), maps each entry to a `MediaItem`,
    and writes them with `MediaDao.batchUpsertMediaItems`.
  - Emits a `ScanProgress` stream (`scanned`, `total`, `phase`).
  - Supports a full scan and an incremental scan (`sinceDateModified` taken from the
    newest indexed row), plus removal of database rows whose files no longer exist.
  - Counts and skips unreadable entries instead of aborting the whole scan.
- `lib/repositories/media_repository.dart`
  - The layer that providers talk to. Wraps `MediaDao` and `MediaScannerService`:
    `scanDevice()`, `getMediaItems(FilterOptions)`, `getMediaItemById()`,
    `toggleFavorite()`, `getTotalCount()`. Holds no `BuildContext`.

### Dart — thumbnail engine
- `lib/core/device/device_memory_service.dart`
  - Reads total RAM through `system_info2`, returns a `DeviceMemoryTier`
    (`low` under 4 GB, `medium` 4–6 GB, `high` 6 GB and above) and a
    `ThumbnailCacheConfig` (memory entry limit, thumbnail pixel size, disk cache byte
    budget). Falls back to the `low` tier if RAM cannot be read.
- `lib/services/thumbnail/thumbnail_memory_cache.dart`
  - Pure Dart LRU cache of decoded thumbnail bytes, bounded by both entry count and
    total bytes. No Flutter or platform dependency, so it is fully unit-testable.
- `lib/services/thumbnail/thumbnail_disk_cache.dart`
  - Stores JPEG thumbnails under the app cache directory
    (`<cache>/thumbnails/<size>/<hash>.jpg`). The key is a hash of
    `id + dateModified + size`, so an edited file invalidates its own thumbnail.
  - Enforces the byte budget with least-recently-used file eviction.
- `lib/services/thumbnail/thumbnail_decoder_isolate.dart`
  - Top-level isolate entry point used with `Isolate.run` for the pure Dart fallback
    path: decode bytes with `image`, downscale to the target size, re-encode as JPEG.
    Returns `null` (never throws) for corrupt input.
- `lib/services/thumbnail/thumbnail_service.dart`
  - The public API: `Future<Uint8List?> getThumbnail(MediaItem, {int? size})`.
  - Order: memory cache, then disk cache, then native `loadThumbnail`, then isolate
    fallback decode, then `null` (the caller shows a placeholder).
  - Coalesces duplicate in-flight requests for the same key, so fast scrolling does not
    decode the same item many times.

### Dart — providers
- `lib/providers/media_providers.dart`
  - `mediaStoreChannelProvider`, `mediaPermissionServiceProvider`,
    `deviceMemoryConfigProvider`, `mediaRepositoryProvider`, `thumbnailServiceProvider`,
    `mediaScanControllerProvider` (an `AsyncNotifier` exposing scan state and progress),
    and `mediaItemsProvider` (the media list for a given `FilterOptions`).

### Dart — widget
- `lib/widgets/media/media_thumbnail.dart`
  - Small widget that requests a thumbnail through the provider, shows a placeholder
    while loading, and a broken-media icon on failure. No file I/O or SQL inside the widget.

### Localization
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — add keys, each with an `@` description:
  `permissionRequired`, `permissionRequiredBody`, `grantPermission`, `openSettings`,
  `scanningMedia`, `scanProgress`, `scanComplete`, `noMediaFound`, `mediaUnavailable`.
  Then run `flutter gen-l10n`.

## 5. Files to Modify

- `pubspec.yaml` — add the three dependencies above.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` — register the
  channel handler and forward `onRequestPermissionsResult`.
- `lib/core/constants/app_constants.dart` — add cache tier constants (thumbnail size per
  tier, disk cache budget, scan batch size, cache folder name).
- `lib/core/errors/app_exception.dart` — add `MediaScanException`,
  `PermissionDeniedException`, and `ThumbnailException`.
- `lib/screens/home_screen.dart` — a dev-flavor-only card showing permission state, a
  "Scan device media" button, live scan progress, the indexed count, and a small
  thumbnail strip. This is the on-device proof that Phase 3 works; Phase 4 replaces it.

## 6. Tests to Add

All tests use a `FakeMediaStoreChannel`, so no device or native code is needed.

- `test/services/media/media_type_resolver_test.dart` — MIME and extension mapping, RAW
  extensions, unknown and empty input.
- `test/services/media/media_scanner_service_test.dart` — paging across batches, mapping
  to `MediaItem`, the incremental scan filter, progress stream values, skipping bad
  entries, and removal of stale rows. Uses `sqflite_common_ffi` like the Phase 2 DAO tests.
- `test/repositories/media_repository_test.dart` — the repository delegates correctly and
  applies `FilterOptions`.
- `test/core/device/device_memory_service_test.dart` — tier boundaries at 4 GB and 6 GB,
  and the safe fallback when RAM is unknown.
- `test/services/thumbnail/thumbnail_memory_cache_test.dart` — LRU order, eviction by
  entry count, eviction by byte budget, and `clear()`.
- `test/services/thumbnail/thumbnail_disk_cache_test.dart` — key stability, key change
  when `dateModified` changes, write and read round trip, and budget eviction, using a
  temporary directory.
- `test/services/thumbnail/thumbnail_service_test.dart` — the lookup order (memory, disk,
  native, fallback), request coalescing, and `null` on total failure.

## 7. Safety and Rule Compliance

- **Offline**: no networking package added; no `android.permission.INTERNET`.
- **Scoped storage**: MediaStore APIs and granular media permissions only. No
  `MANAGE_EXTERNAL_STORAGE`, and no broad legacy storage permission above API 32.
- **Non-destructive**: Phase 3 only reads media. The only writes are to the app's own
  cache directory and the app database.
- **No crash on bad input**: every decode path returns `null`, and every failed scan
  entry is counted and skipped.
- **Layer boundaries**: widgets call providers, providers call the repository, the
  repository calls DAOs and services. No SQL or file I/O in widgets, and no
  `BuildContext` in services.
- **Privacy**: no file paths, EXIF values, or GPS data are logged, in any build.
- **Localization**: all new user-visible text goes through `AppLocalizations`.

## 8. Verification Steps

1. `flutter pub get`
2. `flutter gen-l10n`
3. `dart format .`
4. `flutter analyze` — must report zero issues.
5. `flutter test` — all Phase 1, Phase 2, and new Phase 3 tests pass.
6. `flutter build apk --flavor dev --debug` — confirms the Kotlin channel compiles.
7. Update [implementation_progress.md](../docs/implementation_progress.md): mark Phase 3
   as Completed at 100% and tick its four checklist items.
8. Write the change log to `change_log/`.

## 9. Out of Scope for Phase 3

- The timeline screen, sticky headers, pinch-to-zoom grid, and scrubber (Phase 4).
- Full-screen viewer and video playback (Phase 5).
- SHA-256 and perceptual hash computation (Phase 8). The `MediaItem` columns already
  exist and stay empty for now.
- EXIF parsing beyond what MediaStore already provides (Phase 5).
