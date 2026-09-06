# Implementation Progress — SreerajP Image Video Gallery

This point-in-time document tracks the live implementation status across all phases of the SreerajP Image Video Gallery project.

**Date:** 2026-08-18  
**Status:** Completed

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [Project_Idea.md](Project_Idea.md)
- [implementation_plan.md](implementation_plan.md)

---

## Overall Phase Status

| Phase | Description | Status | Progress |
|---|---|---|---|
| **Phase 0** | Baseline Documentation & Specification | **Completed** | 100% |
| **Phase 1** | Project Setup, Flavors, Keystore & Theme Baseline | **Completed** | 100% |
| **Phase 2** | Core Domain Models & Database (sqflite + FTS5) | **Completed** | 100% |
| **Phase 3** | Scoped Storage Scanner & Fast Thumbnail Cache | **Completed** | 100% |
| **Phase 4** | Chronological Timeline, Dynamic Grid & Flashbacks | **Completed** | 100% |
| **Phase 5** | Fullscreen Viewer & Hardware Video Player | **Completed** | 100% |
| **Phase 6** | Non-Destructive Image Editor & Markup Suite | **Completed** | 100% |
| **Phase 7** | Format Conversion, Compression & Video Tools | **Completed** | 100% |
| **Phase 8** | Search, Multi-Tag Filtering & Duplicate Detection | **Completed** | 100% |
| **Phase 9** | Virtual Albums, Device Folders & Smart Auto-Albums | **Completed** | 100% |
| **Phase 10** | Secure Private Vault (AES-256-GCM, Biometrics) | **Completed** | 100% |
| **Phase 11** | Batch Operations, Backup/Restore & Local Sync | **Completed** | 100% |
| **Phase 12** | In-Image Scanner (QR/Barcode), OCR, Notes & PDF Images | **Completed** | 100% |
| **Phase 13** | Localization (EN & ML), Settings, About & Hardening | **Completed** | 100% |

---

## Detailed Task Checklist

### Phase 0: Baseline Documentation & Specification
- [x] Create project idea specification ([docs/Project_Idea.md](Project_Idea.md)).
- [x] Create architecture blueprint ([docs/architecture.md](architecture.md)).
- [x] Create security specification ([docs/security.md](security.md)).
- [x] Create release process runbook ([docs/release_process.md](release_process.md)).
- [x] Create workflow rules ([docs/workflow_rules.md](workflow_rules.md)).
- [x] Create dependency catalog ([docs/dependencies.md](dependencies.md)).
- [x] Create project structure guide ([docs/project_structure.md](project_structure.md)).
- [x] Create implementation plan ([docs/implementation_plan.md](implementation_plan.md)).
- [x] Create implementation progress tracker ([docs/implementation_progress.md](implementation_progress.md)).

### Phase 1: Project Setup, Flavors, Keystore & Theme Baseline
- [x] Initialize Flutter project with Tier 1 layer-first structure.
- [x] Configure `dev` and `prod` build flavors in Gradle.
- [x] Configure release signing and `key.properties` handling.
- [x] Configure ProGuard / R8 shrinking rules.
- [x] Implement `AppFlavorConfig` and `ConfigService` for `app_config.json`.
- [x] Implement Material 3 light, dark, and AMOLED True Black themes.

### Phase 2: Core Domain Models & Database (sqflite + SQLite FTS5)
- [x] Implement immutable models (`MediaItem`, `Album`, `Tag`, `ExifData`, `VaultItem`, `FilterOptions`).
- [x] Implement SQLite schema and migrations in `DatabaseHelper` with WAL mode and foreign key constraints.
- [x] Set up SQLite FTS5 full-text search table with automatic sync triggers.
- [x] Implement `AtomicSaver` for safe staging file operations.
- [x] Implement DAOs (`MediaDao`, `AlbumDao`, `TagDao`, `VaultDao`) for encapsulated database access.
- [x] Implement comprehensive unit tests across models, storage, schema, DAOs, and FTS5 search.

### Phase 3: Scoped Storage Scanner, MediaStore Indexing & Fast Thumbnail Cache
- [x] Implement native Kotlin MediaStore channel with granular media permissions.
- [x] Implement `MediaScannerService` (full and incremental scans, stale row cleanup).
- [x] Implement `MediaRepository` over the scanner and `MediaDao`.
- [x] Implement RAM-aware cache sizing using `system_info2`.
- [x] Build multi-tier thumbnail engine (RAM LRU, disk cache, native, isolate fallback).
- [x] Implement corrupted media handling and graceful fallbacks.
- [x] Add Riverpod providers, `MediaThumbnail` widget, and a dev-only scan panel.
- [x] Add unit tests for the resolver, scanner, repository, memory tiers, and caches.

### Phase 4: Chronological Timeline, Dynamic Grid & Flashback Memories
- [x] Build `TimelineScreen` with date headers (Today, Yesterday, day, day + year).
- [x] Implement `TimelineGroupingService` for pure Dart date bucketing and row flattening.
- [x] Implement dynamic pinch-to-zoom grid density (1 to 5 columns) with day re-anchoring.
- [x] Build fast scroll scrubber with a floating date indicator overlay.
- [x] Implement `FlashbackService` and the "On This Day" memories carousel.
- [x] Add visual media badges (video duration, GIF, RAW, HD).
- [x] Wire `go_router` with the timeline at `/` and the existing screen at `/settings`.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for grouping, scroll metrics, flashbacks, models, providers, and badges.

### Phase 5: Fullscreen Image Viewer & Hardware Video Player
- [x] Build `MediaViewerScreen` at `/media-viewer/:id`, paging the timeline order.
- [x] Build interactive image viewer with pinch zoom, pan, double-tap zoom, and rotation.
- [x] Implement swipe-down to dismiss with a fading backdrop.
- [x] Build hardware-accelerated offline video player on `video_player` (ExoPlayer).
- [x] Implement play/pause, seek scrubber, timestamps, frame stepping, skip, and repeat.
- [x] Implement playback speed control from 0.25x to 2x.
- [x] Implement brightness, volume, and seek swipe gestures with an on-screen indicator.
- [x] Add the `playback` native channel for brightness, volume, and keep-awake.
- [x] Build swipe-up EXIF and media details drawer, with lazy EXIF parsing cached in SQLite.
- [x] Remove the network permissions ExoPlayer adds, keeping the app fully offline.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the transform, gesture, speed, frame step, EXIF, model, and provider layers.

### Phase 6: Non-Destructive Image Editor, Markup, Redaction & Watermarking
- [x] Build immutable edit models (`EditSession`, `CropTransform`, `ToneAdjustments`, `ToneCurve`, `FilterPreset`, `MarkupLayer`, `RedactionRegion`, `WatermarkConfig`).
- [x] Build transformation tools (crop presets and freeform, quarter turns, mirrors, straighten, perspective).
- [x] Build tone/lighting adjustments (exposure, contrast, highlights, shadows, warmth, tint, vibrance, saturation) and RGB curves.
- [x] Build artistic filters and presets (mono, sepia, vintage, vivid, cool, warm, fade) with a strength slider.
- [x] Implement markup canvas (freehand doodle, rectangle, circle, line, arrow, text overlay).
- [x] Implement privacy redaction (Gaussian blur, pixelation, blackout) that replaces the real pixels.
- [x] Implement watermark engine (text, timestamp, logo) with position, size, margin, and opacity.
- [x] Build the `ImageRenderPipeline` with a fixed stage order and an isolate render, plus a downscaled live preview.
- [x] Enforce non-destructive atomic saving: a new versioned file beside the original, written through `AtomicSaver`.
- [x] Add `EditSessionNotifier` with undo and redo, the editor screen at `/media-viewer/:id/editor`, and the viewer's Edit action.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the models, geometry, tone tables, curves, presets, redaction, watermark, render pipeline, save naming, and undo history.

### Phase 7: Format Conversion, Compression, PDF Export & Video Utilities
- [x] Build immutable conversion models (`ImageOutputFormat`, `ResizeSpec`, `ConversionRequest`, `ConversionResult`, `SizeEstimate`, `PdfExportOptions`).
- [x] Build immutable video models (`VideoClipInfo`, `TrimRange`, `GifExportOptions`).
- [x] Implement image format conversion (JPEG, PNG, BMP in Dart; WEBP through a native encoder channel).
- [x] Implement dimension resizing (longest side, percent, exact width and height) with pure, tested maths.
- [x] Implement quality compression with a real-encode file size preview, debounced and run on a background isolate.
- [x] Flatten see-through pixels onto white when the target format cannot keep them.
- [x] Implement multi-image PDF export with page size, direction, placement, border, and photo quality options.
- [x] Implement the `VideoToolsChannelHandler` (clip info, frame grabbing, lossless stream-copy trimming) using Android `MediaMetadataRetriever`, `MediaExtractor`, and `MediaMuxer`.
- [x] Implement the video still frame grabber, saving as JPEG or PNG.
- [x] Implement the video-to-GIF converter with frame rate, size, range, and loop options, plus frame and length caps.
- [x] Implement lossless stream-copy video trimming with range clamping and container preservation.
- [x] Enforce non-destructive saving through the shared `OutputNamingService` and `AtomicSaver`: every result is a new file beside the source.
- [x] Add the converter screen at `/media-viewer/:id/convert`, the video tools at `/media-viewer/:id/video-tools`, and the PDF export at `/pdf-export`, with the viewer and timeline actions that reach them.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the models, resize maths, output naming, format conversion, compression, PDF layout and export, GIF frame planning and encoding, frame grabbing, and trim clamping.

### Phase 8: Search, Multi-Tag Filtering & Duplicate Detection (pHash)
- [x] Build immutable search models (`SearchQuery`, `SearchResult`, `SearchHistoryEntry`).
- [x] Build immutable duplicate models (`MediaHashes`, `DuplicateGroup`, `DuplicateScanState`).
- [x] Implement the pure `SearchQueryParser`: `tag:`, `type:`, `place:`, `camera:`, `before:`, `after:` prefixes, and one escaped FTS5 `MATCH` builder that quotes every user word.
- [x] Fold the full-text match into `MediaDao.getMediaItems` as a sub-query, so text plus filters run as one statement with one sort.
- [x] Build the FTS5 search screen at `/search` with a debounced box, recent searches, a filter sheet, and a result grid.
- [x] Implement recent searches in a JSON file written through `AtomicSaver`, with no new package.
- [x] Implement tag creation, renaming, recolouring, and deletion through `TagRepository`, with the shared `TagNameRules` and a fixed twelve-colour palette.
- [x] Make every tag change rewrite the FTS `tags_content` cell, including down to empty, so a removed tag stops being searchable.
- [x] Build the tag screen at `/tags`, the tag filter bar with `AND` / `OR`, and the viewer's tag sheet.
- [x] Implement the native `HashToolsChannelHandler`: streamed SHA-256 and a downsampled 32x32 grayscale decode, so no whole file is ever held in memory.
- [x] Implement pure `pHash` (32x32 DCT, top-left 8x8, median split with a tolerance) and `dHash` (9x8 neighbour compare), plus the Hamming distance.
- [x] Store both perceptual hashes in the single `p_hash` column as `<phash>:<dhash>`, with no schema change.
- [x] Implement the duplicate scan: paged, cancellable, resumable, and reporting progress, skipping files it cannot read.
- [x] Group exact copies by SHA-256 and similar copies by banded pHash buckets plus union-find, so a burst becomes one group and the scan does not go quadratic.
- [x] Implement the `BestPhotoService` scoring and the duplicate cleaner at `/cleaner`.
- [x] Build the side-by-side comparison at `/cleaner/compare/:groupId`, where "Keep Best Photo" moves the other copies to the trash after a confirmation; no file is erased.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the query parser and its escaping, search history, tag rules, the colour palette, both perceptual hashes, grouping, best-photo scoring, the scan service, and both new repositories against a real database.

### Phase 9: Virtual Albums, Device Folders & Smart Auto-Albums
- [x] Build immutable album models (`AlbumSummary`, `SmartAlbum`) and add the `smartPanoramas` and `smartRecentlyAdded` types.
- [x] Add file size range and "has tags" fields to `FilterOptions`, each with its own `clear...` flag.
- [x] Build the pure `AlbumNameRules`, mirroring `TagNameRules` so albums and tags behave the same way.
- [x] Build the pure `FolderPathRules`: parent directory, display name, and the escaped `LIKE` pattern, handling both separators.
- [x] Build the pure `SmartAlbumService`: the six rules, the route keys, the panorama shape test, and the recent window.
- [x] Implement virtual album management through `AlbumRepository` (create, rename, delete, add, remove, reorder, custom cover, pin).
- [x] Fix `AlbumDao.addMediaToAlbum`, which wrote position 0 every time, so every item in an album tied at the same position.
- [x] Add `getAlbumsByType`, `getMediaIdsForAlbum`, `getAlbumIdsForMedia`, `addMediaToAlbums`, `setMediaOrder`, `setCover`, and `setPinned` to `AlbumDao`.
- [x] Move folder filtering out of Dart and into SQL as an exact-parent match, so opening one folder no longer reads the whole table.
- [x] Escape `%`, `_`, and the escape character in the folder pattern, so a folder called `100%` matches only itself.
- [x] Group media by physical device directories with one `GROUP BY`, taking each folder's count and newest item together.
- [x] Implement dynamic smart auto-albums (Favourites, Videos, GIFs, RAW, Panoramas, Recently Added), computed fresh rather than stored.
- [x] Keep a smart album's own rule ahead of the user's filter, so a filter can narrow an album but never widen it past its name.
- [x] Build the shared multi-dimensional filter sheet (type, favourites, location, tags, date range, file size, sort) and point both search and the album screens at it.
- [x] Add the albums screen at `/albums`, one album at `/albums/:id`, smart albums at `/albums/auto/:type`, folders at `/albums/folder/:path`, and reordering at `/albums/:id/reorder`.
- [x] Add the album card, name dialog, "add to album" sheet, cover chooser, and the shared album media grid.
- [x] Add the Albums action to the timeline and the "add to album" action to the viewer.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the models, name rules, path rules, all six smart album rules, the folder and size and tag queries, album ordering and covers, the repository, and the album route round trip.

### Phase 10: Secure Private Vault (AES-256-GCM, Biometrics, Shredding, FLAG_SECURE)
- [x] Build immutable vault models (`VaultLockState`, `VaultSecuritySettings`, `VaultAuthOutcome`, `VaultCryptoResult`, `VaultBatchResult`).
- [x] Generate the AES-256 master key inside the Android Keystore, asking for StrongBox and falling back when a device advertises it but cannot use it.
- [x] Keep the key on the Android side only: no channel method returns key material, and Dart never sees a key byte.
- [x] Implement streamed AES-256-GCM encryption and decryption natively, so a gigabyte video never has to fit in memory.
- [x] Let the keystore draw the IV, since the key requires randomised encryption, and store that IV beside each payload.
- [x] Give the encrypted preview its own IV in a new `thumbnail_iv` column, with a schema migration to version 2 — one IV cannot decrypt two files.
- [x] Add `encryptBytes`, so a preview built in memory is never written out in the clear just to be encrypted.
- [x] Implement PBKDF2-HMAC-SHA256 PIN hashing in pure Dart over `crypto`, with a per-vault salt, a stored iteration count, and a constant-time compare.
- [x] Store the salt and hash in `flutter_secure_storage`, never the PIN, and never in plain `SharedPreferences`.
- [x] Implement BiometricPrompt through `local_auth` with device-credential fallback, as a shortcut over the PIN rather than a replacement for it.
- [x] Keep biometric failures away from the PIN back-off, so a misreading sensor cannot shut the door that works.
- [x] Implement the wrong-PIN back-off: a repeating cool-down held in the lock state, not in storage, so restarting the app is not a way around it.
- [x] Implement multi-pass shredding natively (zero pass, random pass, descriptor sync, unlink) with a Dart fallback, and say plainly where it stops working.
- [x] Make shredding an original opt-in, off by default, and behind a second confirmation that names how many files go.
- [x] Order the import so the payload is written before the row and the original is touched last; roll back the payload if anything fails.
- [x] Order the export the other way, writing the file back out before anything inside the vault is disturbed.
- [x] Implement `FLAG_SECURE` scoped to the vault screens, counted on both sides so nested screens do not clear it early.
- [x] Implement auto-lock on backgrounding and on a configurable idle timeout, with the rules in a pure, tested policy class.
- [x] Keep the vault directory app-private with a `.nomedia` marker and random hex file names, so the listing itself says nothing.
- [x] Sweep on every unlock: shred decrypted working files a crash left behind, and delete payloads no row points at.
- [x] Decrypt photos and previews to memory only; decrypt video to an app-private working file that is shredded on close.
- [x] Add the vault gate at `/vault`, the settings at `/vault/settings`, the in-vault viewer at `/vault/viewer/:id`, and the timeline and viewer entry points.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the models, PIN rules, PBKDF2 against the RFC 6070 vectors, the lock policy, naming, crypto, auth, shredding, import roll-back, export, the repository, the DAO, and the vault routes.

### Phase 11: Batch Operations, Backup/Restore & Local P2P Wi-Fi Sync
- [x] Narrow hard rule 2 from "no sockets at all" to "local network only, never the internet", and rewrite it in `CLAUDE.md`, `AGENTS.md`, `docs/security.md`, `docs/Project_Idea.md`, `docs/architecture.md` and `docs/dependencies.md`.
- [x] Declare `INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE` and `CAMERA` in the manifest, each with the reason written beside it, and keep `WAKE_LOCK` removed from the merge.
- [x] Build the pure `LocalAddressRules`, the one place that decides whether an address may be talked to, and the test that fails if a public address is ever accepted.
- [x] Build immutable batch models (`BatchAction`, `BatchProgress`, `BatchOutcome`).
- [x] Build the pure `BatchActionRules`: which actions a selection allows, why one is blocked, and which need a second confirmation.
- [x] Build `BatchRunnerService`: sequential, cancellable between files, and never sinking the whole batch for one bad file.
- [x] Build `GalleryBatchHandler`, delegating every action to the Phase 6 to 10 services rather than reimplementing any of them.
- [x] Add app-wide selection state, so ticks survive moving between the timeline, an album and a search.
- [x] Add long-press selection, the tick overlay, the selection app bar and the batch action bar, with blocked actions greyed out and explained rather than hidden.
- [x] Build immutable backup models (`BackupManifest`, `BackupPayload`, `BackupMediaRecord`, `RestorePlan`, `RestoreSummary`).
- [x] Build the pure `BackupFormat`: the `GBAK` container header, its encode and decode, and every refusal a wrong file earns.
- [x] Build the pure `BackupSerializer`: an exact JSON round trip that ignores a field from a newer version rather than throwing.
- [x] Build `BackupCollectorService`, keeping a media record when it carries user data *or* anchors a tag or album link, so an album of plain photos does not restore empty.
- [x] Build the pure `BackupMergeService`: four matching routes (id, digest, path, fingerprint), each local file claimed once, and nothing invented for a photo that is not on the device.
- [x] Build `BackupApplyService`, which only ever adds and fills gaps: no delete list, and no note or favourite already on the device is replaced by an older one.
- [x] Implement the native `BackupChannelHandler`: PBKDF2-HMAC-SHA256 key derivation, streamed AES-256-GCM with the header as authenticated data, and the session cipher the transfer reuses.
- [x] Implement the native `DocumentPickerChannelHandler`, so the Storage Access Framework replaces a storage permission entirely.
- [x] Build `BackupService` and `RestoreService`, staging app-private and deleting in a `finally` so no plaintext copy survives a crash.
- [x] Add the backup screen at `/backup`, the password dialog with its no-recovery warning, and the restore preview that shows the plan before a single row is written.
- [x] Build immutable sync models (`PairingPayload`, `TransferManifest`, `TransferProgress`, `TransferOutcome`, `SyncRole`, `SyncPhase`).
- [x] Build the pure `PairingCodec`: the QR string, the six-group typed fallback in a reduced alphabet, and refusal of a wrong version, a bad checksum or a non-local address.
- [x] Carry a short pairing secret rather than the key, and derive the same AES key on both sides, so the typed code is a real fallback and not a weaker one.
- [x] Build the pure `TransferProtocol` and `FrameReader`: length-prefixed frames, reassembly across arbitrary reads, and refusal of an oversized or unknown frame before anything is allocated.
- [x] Build `TransferCryptoService`: per-frame IVs, the HMAC handshake proof, and a constant-time comparison.
- [x] Build `P2pServerService`, which binds to the device's own address, refuses `0.0.0.0` and any non-local peer, accepts one peer, and closes its port the moment pairing completes.
- [x] Build `P2pClientService`, which checks the address before it opens a socket and again after.
- [x] Build `P2pConnection`: the handshake, a frame queue that cannot drop what arrives between reads, an idle timeout, and a close path every failure runs through.
- [x] Build `TransferExchangeService`, checking every incoming file against its promised length and digest, and sanitising every peer-supplied file name.
- [x] Build `ReceivedMediaService` and the native `publishFile`, writing through MediaStore with `IS_PENDING` so no other app sees a half-copied photo, and never overwriting an existing file.
- [x] Build `TransferSessionService`, which owns the server or client for one session and guarantees the socket closes.
- [x] Add the transfer screens at `/sync`, `/sync/receive` and `/sync/send`, with the listener started and stopped by the screen itself, on backgrounding, and on every failure.
- [x] Add the QR pairing card, the camera scanner, and the typed-code fallback that works with no camera at all.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the address rules, the pairing codec, both derivation routes, the frame protocol, the batch rules and runner, the backup container, serializer and merge plan, the selection state, the new routes, and a real loopback socket moving real files end to end.

### Phase 12: In-Image Scanner (QR/Barcode) & Offline OCR
- [x] Drop `google_mlkit_text_recognition` before it was ever added: it has no Malayalam model, and it is a closed-source binary. Adopt `flutter_tesseract_ocr` instead, and write the reason into `docs/dependencies.md` so nobody re-adds ML Kit.
- [x] Ship `eng.traineddata` and `mal.traineddata` in `assets/tessdata/`, so the language data is in the app and is never downloaded.
- [x] Build the pure `BarcodePayloadParser`: every code kind, the `WIFI:` escaping rule, and a product barcode that must not be offered as a phone number.
- [x] Build the pure `ScanActionResolver`, the one place that decides what a code may do, on a permitted list of schemes rather than a forbidden one.
- [x] Build `ImageScanService` on `mobile_scanner`'s `analyzeImage`, so a still file is read with no camera and no camera permission.
- [x] Build the native `IntentChannelHandler` and its Dart side, checking the scheme on both, and never using `Intent.parseUri`.
- [x] Make Wi-Fi joining a suggestion the user confirms, never a silent join, with the password copied as sensitive so it stays out of the clipboard preview.
- [x] Add the `<queries>` entries the six permitted schemes need, and `CHANGE_WIFI_STATE`, each with its reason beside it.
- [x] Build `OcrService` and `TesseractOcrEngine` behind an `OcrEngine` interface, with a timeout, a size cap, and a failure reason for every way it can go wrong.
- [x] Build the pure `OcrTextCleaner`, which tidies spacing and drops stray marks but never changes reading order and never corrects a word.
- [x] Build the pure `MarkdownParser` and `MarkdownView`, covering the subset a note needs, and never throwing on half-typed markdown.
- [x] Store notes in the media row's existing `user_notes` column, so the update trigger makes them searchable with nothing extra written.
- [x] Make `MediaNotesService.append` add to a note rather than replace it, so text saved from a scanned code cannot wipe out what the user wrote.
- [x] Check a link inside a note against the same scheme rule as a scanned code, and make a refused link neither underlined nor tappable.
- [x] Build the pure `PdfLexer`, which walks the whole file instead of trusting the cross-reference table, and survives a truncated or hostile one.
- [x] Build the pure `PdfImageExtractor`: JPEG copied out byte for byte, Flate RGB and grey re-encoded as PNG, every other filter listed with its reason, and an encrypted file refused rather than opened.
- [x] Cap the PDF file size, image count, pixel count and decoded size, and check a declared size before allocating for it.
- [x] Add native `copyToCache`, and delete the app-private copy of the picked PDF in a `finally`.
- [x] Publish extracted pictures through MediaStore under fresh names, so the tool needs no storage permission and nothing is overwritten.
- [x] Leave vault items out of the scanner and the reader, and say why: both need a file path, and writing a plaintext copy out would work against Phase 10.
- [x] Add the routes at `/media-viewer/:id/scan`, `/media-viewer/:id/text`, `/media-viewer/:id/notes` and `/pdf-images`, with the viewer overflow menu and the note line in the details sheet.
- [x] Add English and Malayalam strings for every new user-visible label.
- [x] Add unit tests for the payload parser, the action resolver, the scan service, the OCR service and cleaner, the markdown parser and view, the notes service against a real database including the search index, the PDF lexer and extractor against hand-built files, the extraction service, the models and the new routes.

### Phase 13: Localization (English & Malayalam), Settings, About Screen & Hardening
- [x] Complete the English (`app_en.arb`) and Malayalam (`app_ml.arb`) ARB files: 779 keys each, every key with an `@` description, and the only shared values are technical labels (GIF, RAW, A4, 16:9) that must not be translated.
- [x] Build the pure `detectTextDirection`, following the Unicode first-strong rule, with digits, punctuation, symbols and emoji treated as neutral so a note opening with a number still takes its direction from the first real word.
- [x] Build `AdaptiveDirectionality` and apply it only to text the app did not write: notes and their previews, recognised text, scanned code payloads, tag names, album names, file names in the viewer and its details rows, recent searches, and the About screen's config values. Translated labels are left alone, because they already follow the chosen language.
- [x] Add the immutable `AppSettings` model, reading field by field so one bad value in a hand-edited file cannot cost the user every other preference.
- [x] Add `AppSettingsService`, keeping preferences in one small JSON file written through `AtomicSaver` — the pattern the recent-searches store already uses, so no new package was needed and `shared_preferences` was deliberately not added.
- [x] Add `appSettingsProvider`, which saves every change as it is made, and the derived `localeProvider`, `themeProvider`, `confirmDestructiveProvider` and `showFlashbacksProvider`.
- [x] Load the settings in `main()` before the first frame, so the app opens in the chosen theme and language instead of flashing the defaults.
- [x] Add language selection (System default, English, Malayalam) wired to `MaterialApp.locale`, taking effect at once with no restart.
- [x] Make the theme and the grid density survive a restart; both were forgotten on every launch before.
- [x] Build the Settings screen at `/settings`, replacing the Phase 1 scratch screen, with appearance, language, safety, a plain statement of the storage and privacy position, the dev-only scan panel, and a confirmed reset.
- [x] Build the config-driven About screen at `/settings/about`, rendering `details` as data with no hard-coded field names, skipping empty entries, and opening an email row through the existing `IntentChannel` so outgoing intents keep a single gate.
- [x] Correct `assets/config/app_config.json`, which still claimed "Zero INTERNET permission" — untrue since Phase 11. An About screen that oversells its privacy is worse than none.
- [x] Fix `AtomicSaver.writeString`, which encoded with `String.codeUnits` and would have silently destroyed every Malayalam character on the way to disk.
- [x] Add the `-dontwarn com.google.android.play.core.**` rule that the release build needs, without adding the proprietary Play Core SDK that hard rule 1 forbids.
- [x] Add unit and widget tests for the direction detector, the directionality wrapper, the settings model, the settings store, the settings providers, and both new screens.
- [x] Run the full check: `flutter gen-l10n`, `dart format .`, `flutter analyze` clean, 1793 tests passing, and an obfuscated split-per-ABI production APK built for all three ABIs.
