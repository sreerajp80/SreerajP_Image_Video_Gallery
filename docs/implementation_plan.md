# Implementation Plan — SreerajP Image Video Gallery

This point-in-time document outlines the phased build roadmap, milestones, and technical deliverables for developing the SreerajP Image Video Gallery application.

**Date:** 2026-08-18  
**Scope:** Complete App Implementation Roadmap (Phases 1–13)  
**Status:** Completed

### Project Identity & Namespace Specification

| Attribute | Value |
|-----------|-------|
| App Name | SreerajP Image Video Gallery |
| Android Namespace / Package ID | `in.sreerajp.imgvidgal` |
| Dev Flavor Application ID | `in.sreerajp.imgvidgal.dev` (Display Name: `SreerajP Gallery Dev`) |
| Prod Flavor Application ID | `in.sreerajp.imgvidgal` (Display Name: `SreerajP Image Video Gallery`) |

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [Project_Idea.md](Project_Idea.md)
- [architecture.md](architecture.md)
- [security.md](security.md)

---

## Phase 1: Project Setup, Build Flavors, Keystore & Theme Baseline

### Objective
Initialize the Flutter project structure under namespace `in.sreerajp.imgvidgal`, configure Android build flavors (`dev`, `prod`), establish release signing rules, configure ProGuard, and implement the Material 3 design system.

### Action Steps
1. Create Flutter project structure adhering to Tier 1 layer-first layout.
2. Configure Gradle flavors in `android/app/build.gradle.kts` for `dev` (`in.sreerajp.imgvidgal.dev`) and `prod` (`in.sreerajp.imgvidgal`).
3. Set up `android/gallery-release.jks` keystore handling and `android/key.properties`.
4. Configure R8/ProGuard rules in `android/app/proguard-rules.pro`.
5. Implement `AppFlavorConfig` and `ConfigService` loading `assets/config/app_config.json`.
6. Implement Material 3 themes (Light, Dark, AMOLED True Black) in `lib/theme/`.

---

## Phase 2: Core Domain Models & Database (sqflite + SQLite FTS5)

### Objective
Build all immutable domain models and the local SQLite database schema with Full-Text Search (FTS5).

### Action Steps
1. Create immutable models: `MediaItem`, `Album`, `Tag`, `ExifData`, `VaultItem`, `FilterOptions`.
2. Implement `DatabaseHelper` and schema migrations in `lib/repositories/database/`.
3. Create SQLite tables for media metadata, tags, virtual albums, user notes, and favorites.
4. Set up SQLite FTS5 virtual table for full-text search indexing.
5. Create `AtomicSaver` for safe staging file operations.

---

## Phase 3: Scoped Storage Scanner, MediaStore Indexing & Fast Thumbnail Cache

### Objective
Implement high-performance scanning of Android MediaStore and a multi-tiered, RAM-aware thumbnail caching engine.

### Action Steps
1. Implement `MediaRepository` to query Android MediaStore using scoped media permissions.
2. Implement RAM-aware cache sizing using `system_info2`.
3. Build background isolate thumbnail decoding engine with disk cache in app cache directory.
4. Implement graceful fallbacks for unsupported or corrupted media files.

---

## Phase 4: Chronological Timeline, Dynamic Grid & Flashback Memories

### Objective
Build the primary gallery screen with chronological grouping, dynamic pinch-to-zoom grid density, and "On This Day" memories.

### Action Steps
1. Create `TimelineScreen` with sticky date headers (Today, Yesterday, Month, Year).
2. Implement pinch-to-zoom gesture handling allowing 1 to 5 grid columns.
3. Build fast scroll scrubber with date indicator overlay.
4. Implement "On This Day" / Flashback Memories carousel at top of timeline.
5. Add visual badges (video duration, GIF, RAW, high-resolution).

---

## Phase 5: Fullscreen Image Viewer & Hardware Video Player

### Objective
Develop high-definition interactive image viewing and offline hardware-accelerated video playback.

### Action Steps
1. Implement interactive image viewer with pinch-to-zoom, pan, double-tap zoom, and rotation.
2. Implement offline video player with play/pause, seek scrubber, frame-stepping, and playback speed (0.25x to 2x).
3. Add brightness and volume swipe gesture controls.
4. Build swipe-up EXIF and media details drawer.

---

## Phase 6: Non-Destructive Image Editor, Markup, Redaction & Watermarking

### Objective
Implement the comprehensive built-in image editing suite with atomic versioned saving.

### Action Steps
1. Build transformations: crop (presets and freeform), 90-degree rotate, fine straighten slider, perspective skew.
2. Implement color & tone controls: exposure, contrast, highlights/shadows, temperature, tint, vibrance, RGB curves.
3. Build artistic filters & presets (B&W, sepia, vintage, vivid).
4. Implement markup canvas: freehand doodle, shapes (rectangles, arrows, circles), text overlay.
5. Implement privacy redaction: Gaussian blur, pixelation, blackout brush.
6. Build text, timestamp, and logo watermark engine.
7. Enforce non-destructive atomic saving via `AtomicSaver`.

---

## Phase 7: Format Conversion, Compression, PDF Export & Video Utilities

### Objective
Provide multi-format image and video conversion, compression, and document export utilities.

### Action Steps
1. Implement image format conversion (JPEG, PNG, WEBP, BMP).
2. Implement PDF document export from multiple selected images.
3. Implement image dimension resizing and quality compression with file size preview.
4. Build video-to-GIF converter with framerate and resolution options.
5. Build video still frame grabber and lossless stream-copy video trimming.

---

## Phase 8: Search, Multi-Tag Filtering & Duplicate Detection (pHash)

### Objective
Implement full-text search, custom tag management, and perceptual duplicate detection.

### Action Steps
1. Build FTS5 search interface for filenames, tags, notes, EXIF data, and locations.
2. Implement custom tag creation, color coding, and multi-tag filtering (`AND` / `OR`).
3. Build visual duplicate & similar photo finder using SHA-256 and perceptual hashing (`pHash` / `dHash`).
4. Implement side-by-side comparison screen with "Keep Best Photo / Delete Rest" assistant.

---

## Phase 9: Virtual Albums, Device Folders & Smart Auto-Albums

### Objective
Provide comprehensive album organization for both physical directories and user-defined virtual collections.

### Action Steps
1. Implement virtual album management (create, rename, delete, reorder items, custom cover).
2. Group media by physical device folders (Camera, Screenshots, Downloads, etc.).
3. Build smart dynamic auto-albums (Favorites, Videos, GIFs, RAW, Panoramas, Recently Added).
4. Implement smart multi-dimensional filter sheets.

---

## Phase 10: Secure Private Vault (AES-256-GCM, Biometrics, Shredding, FLAG_SECURE)

### Objective
Build the private encrypted vault with biometric authentication, hardware-backed encryption, and anti-forensic shredding.

### Action Steps
1. Integrate Android Keystore for master encryption key generation.
2. Implement AES-256-GCM authenticated encryption for private media files.
3. Implement BiometricPrompt authentication via `local_auth` with PIN fallback.
4. Implement multi-pass zero-fill anti-forensic media shredding.
5. Enforce `FLAG_SECURE` window protection to prevent screenshots and screen recordings.
6. Implement auto-lock on app backgrounding and configurable inactivity timeout.

---

## Phase 11: Batch Operations, Backup/Restore & Local P2P Wi-Fi Sync

### Objective
Implement multi-select batch tools, encrypted full backups, and direct device-to-device local transfer.

### Action Steps
1. Build multi-select batch mode for format conversion, tagging, album assignment, watermarking, and vault import.
2. Implement password-protected encrypted backup and restore (`.gallerybak`).
3. Build zero-cloud peer-to-peer (P2P) local Wi-Fi transfer using local sockets and QR pairing.

---

## Phase 12: In-Image Scanner (QR/Barcode) & Offline OCR

### Objective
Integrate on-device media intelligence for scanning barcodes, QR codes, and extracting text from images.

### Action Steps
1. Implement in-image QR and barcode detection with one-tap action sheets (Wi-Fi connect, copy, open URL).
2. Implement offline OCR for extracting selectable text from screenshots and photos.
3. Build custom markdown notes attachment engine for photos and videos.
4. Implement PDF embedded image extraction tool.

---

## Phase 13: Localization (English & Malayalam), Settings, About Screen & Hardening

### Objective
Deliver bilingual UI with bi-directional text flow, config-driven About screen, and release verification.

### Action Steps
1. Create complete ARB localization files for English (`app_en.arb`) and Malayalam (`app_ml.arb`).
2. Integrate `AdaptiveDirectionality` and `detectTextDirection` across all text views.
3. Build Settings screen and dynamic About screen consuming `app_config.json`.
4. Run full test suite (`flutter test`), analyze (`flutter analyze`), and release build verification (`--obfuscate`).
