# Architecture — Image & Video Gallery

This document describes the technical architecture, design patterns, component boundaries, data models, and system flows for the Image & Video Gallery application. Read this before modifying or adding models, services, repositories, state providers, or screens.

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [Project_Idea.md](Project_Idea.md)
- [security.md](security.md)
- [guidelines/architecture.md](guidelines/architecture.md)

---

## 1. System Scope & Design Principles

- **Product Name**: Image & Video Gallery
- **Type**: Fully offline-first Android media gallery for viewing, organizing, editing, converting, and securing local images and videos.
- **Platform**: Android only (minSdk 24, targetSdk 35).
- **Target Profiles**: Core Baseline + Sensitive Data Extension + Local-Network-Only Profile.

### Core Architectural Principles
1. **Local Network Only by Design**: No remote server, no cloud telemetry, no HTTP client. All media, indexes, tags, and albums live locally. `android.permission.INTERNET` is declared for the device-to-device transfer feature alone; `LocalAddressRules` refuses any address outside the private ranges, and the listener lives only while the transfer screen is open.
2. **Safe & Non-Destructive Operations**: Media edits are staged in temporary files using `AtomicSaver` before replacement. Original files are never overwritten destructively without explicit user action.
3. **Layer-First Tier 1 Architecture**: Clear unidirectional dependencies (`screens` → `providers` → `repositories` / `services` → `database` / `platform` → `models`).
4. **Hardware-Accelerated & Resource-Aware**: Heavy operations (decoding, filtering, duplicate perceptual hashing) are offloaded to Dart isolates. Memory allocation dynamically scales based on device RAM (`system_info2`).
5. **Never Crash on Bad Media**: Graceful fallbacks and non-blocking notifications for corrupted or unsupported media formats.

---

## 2. Layered Architecture & Component Boundaries

The project follows a **Tier 1 Layer-First** directory layout:

```text
lib/
|-- core/                 # App-wide utilities, config, errors, theme, atomic file saver
|-- models/               # Immutable data classes and domain entities
|-- repositories/         # Abstraction over local database and Android MediaStore
|-- services/             # Pure business logic (EXIF, crypto, image processing, OCR)
|   |-- batch/           # Multi-select batch rules and the sequential runner
|   |-- backup/          # .gallerybak container, serializer, merge plan, ciphers
|   `-- sync/            # Local transfer: address rules, pairing, protocol, sockets
|-- providers/            # Riverpod state notifiers and reactive providers
|-- screens/              # UI screens and navigation destinations
|-- widgets/              # Reusable UI components and visual primitives
|-- theme/                # Material 3 color palettes and typography definitions
|-- l10n/                 # Localization ARB files and generated localizations
`-- main.dart             # App initialization and root widget configuration
```

### Layer Boundary Rules

| Layer | Responsibility | Permitted Dependencies | Forbidden Dependencies |
|---|---|---|---|
| **`models/`** | Immutable entities (`const` constructors, `copyWith`) | Pure Dart only | Any Flutter UI, DB, or services |
| **`services/`** | Specialized computation (crypto, OCR, hashing, image filter) | `models/`, Dart stdlib, low-level packages | `BuildContext`, Flutter UI widgets |
| **`repositories/`** | Data persistence, MediaStore queries, SQLite DB operations | `models/`, `services/`, `sqflite` | `BuildContext`, UI widgets, navigation |
| **`providers/`** | Riverpod state management & user action orchestration | `repositories/`, `services/`, `models/` | Direct SQL queries, raw file mutations |
| **`screens/` & `widgets/`** | Visual rendering, gesture handlers, animations | `providers/`, `models/`, Flutter framework | Raw DB queries, direct file I/O, crypto |

---

## 3. Core Subsystems

### 3.1 Media Indexing & Thumbnail Engine
- **MediaStore Scanner**: Queries Android MediaStore for images and videos using granular media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`).
- **RAM-Aware Memory Scaling (`system_info2`)**:
  - Low-RAM devices (< 4 GB): Conservative memory cache (100 thumbnails max, 256px resolution).
  - High-RAM devices (≥ 6 GB): High-capacity LRU memory cache (500+ thumbnails, 512px resolution).
- **Background Isolate Workers**: Thumbnail generation, high-res RAW preview decoding, and perceptual hashing run in background isolates to keep the UI thread running at a steady 60/120 FPS.

### 3.2 State Management (Riverpod)
- All shared application state is managed using **Riverpod** providers (`NotifierProvider`, `AsyncNotifierProvider`, `FutureProvider`).
- Providers expose immutable state objects and clear intent methods (e.g. `galleryTimelineProvider`, `albumListProvider`, `vaultStateProvider`, `editorStateProvider`).
- State mutations are reactive; UI screens rebuild selectively via `ref.watch()`.

### 3.3 Database & Search Subsystem (SQLite + FTS5)
- **Local Database**: `sqflite` manages metadata, custom tags, virtual albums, user markdown notes, and favorites.
- **Full-Text Search Engine**: SQLite FTS5 virtual table indexes filenames, custom tags, user notes, EXIF camera models, and reverse-geocoded location strings for instant search.
- **Visual Duplicate & Similar Photo Finder**:
  - Exact duplicates indexed via SHA-256 content hashes.
  - Visually similar photos (bursts, similar angles) indexed via 64-bit perceptual hashes (`pHash` / `dHash`).

### 3.4 Non-Destructive Image Editor & Converter
- **Image Editor Pipeline**:
  - Transformations: Crop (preset & freeform), rotate, straighten (-45° to +45°), perspective correction.
  - Tone & Color Tuning: Exposure, contrast, highlights/shadows, temperature, tint, vibrance, RGB curve adjustments.
  - Markup & Annotations: Freehand doodle, geometric shapes, customizable text badges.
  - Privacy Redaction: Gaussian blur, pixelation, blackout brush.
  - Watermarking: Customizable text, date/time stamp, and PNG logo watermark overlays.
- **Atomic File Saving (`AtomicSaver`)**: Edits and format conversions are written to a temporary staging file first (`.tmp`), verified for integrity, and then swapped atomically to the target destination.

### 3.5 Secure Private Vault Subsystem
- **Android Keystore Integration**: Master key generated and stored inside the hardware-backed Android Keystore.
- **AES-256-GCM Encryption**: Vault files and metadata are encrypted with unique random 96-bit IVs and authentication tags.
- **Anti-Forensic Media Shredding**: Overwrites original media bytes with multi-pass random data and zeroes before deleting file links.
- **`FLAG_SECURE` Native Window Protection**: Blocks OS screenshot capture, screen recording, and blurs previews in Android's recent apps switcher.

### 3.6 In-Image Intelligence Subsystem (Phase 12)

Four features that read something out of a file the user already has. All of it
runs on the device; none of it reaches a network.

- **In-Image Code Scanner**: `ImageScanService` reads QR codes and barcodes out of a
  still file through `mobile_scanner`'s `analyzeImage`, so no camera is opened and no
  camera permission is needed. `BarcodePayloadParser` types the payload (`WIFI:`, `tel:`,
  `mailto:`, a bare domain, plain text) and `ScanActionResolver` decides which actions the
  code earns. Both are pure.
- **Outgoing Intent Gate**: `IntentChannel` and `IntentChannelHandler` are the only place
  the app builds an intent out of text it did not get from the user's own typing. Six
  schemes are permitted (`http`, `https`, `tel`, `mailto`, `sms`, `geo`); every other is
  refused on the Dart side and again in Kotlin. See `docs/security.md` §11.
- **Offline OCR**: `OcrService` reads text through `TesseractOcrEngine`, which wraps
  Tesseract4Android. English and Malayalam language data ships in `assets/tessdata/` and
  is never downloaded. `OcrTextCleaner` tidies the output without changing reading order
  or correcting a single word. The engine sits behind the `OcrEngine` interface, so the
  service is tested with no native reader.
- **Markdown Notes**: `MarkdownParser` turns a note into immutable blocks and spans, drawn
  by `MarkdownView`. Notes live in the media row's existing `user_notes` column, which the
  update trigger mirrors into the FTS index, so a note is searchable the moment it is
  saved. `MediaNotesService` appends rather than replaces, so text saved from a scanned
  code cannot wipe out what the user wrote.
- **PDF Image Extraction**: `PdfLexer` and `PdfImageExtractor` are a pure Dart PDF object
  scanner. They walk the whole file rather than trusting the cross-reference table, so a
  slightly broken PDF still gives up its pictures. JPEG streams are copied out byte for
  byte; Flate RGB and grey images are re-encoded as PNG; anything else is listed with the
  reason it was skipped. Encrypted files are refused. `PdfExtractionService` publishes the
  saved pictures through MediaStore, so the tool needs no storage permission.

> Vault items are deliberately outside this subsystem. Vault media decrypts to memory only,
> and both the code decoder and Tesseract need a file path; writing a plaintext copy out to
> disk so they could read it would work against Phase 10.

---

## 4. Navigation & Route Hierarchy

Navigation is declarative, handled by **`go_router`**:

```text
/ (Timeline Screen)
|-- /media-viewer/:id (Fullscreen Image / Video Viewer)
|   |-- /media-viewer/:id/info (Media Details Drawer)
|   |-- /media-viewer/:id/editor (Non-destructive Image Editor)
|   |-- /media-viewer/:id/convert (Format Converter & Resizer)
|   |-- /media-viewer/:id/video-tools (Trim, GIF export, frame grab)
|   |-- /media-viewer/:id/scan (In-Image QR & Barcode Scanner)
|   |-- /media-viewer/:id/text (Offline OCR - extracted text)
|   `-- /media-viewer/:id/notes (Markdown Notes Editor)
|-- /albums (Albums Grid)
|   |-- /albums/:id (Album Media Grid)
|   `-- /albums/auto/:type (Smart Dynamic Albums)
|-- /tags (Tags Management & Filtering)
|-- /search (FTS5 Multi-criteria Search)
|-- /cleaner (Duplicate & Similar Media Cleaner)
|-- /vault (Private Vault - Biometric/PIN Gated)
|   `-- /vault/viewer/:id (Secure In-Vault Media Viewer)
|-- /pdf-export (Photos out to a PDF document)
|-- /pdf-images (Pictures pulled back out of a PDF)
|-- /backup (Encrypted Backup & Restore - .gallerybak)
|-- /sync (Local Wi-Fi Transfer - owns the socket listener)
|   |-- /sync/receive (Shows the pairing code, waits for a peer)
|   `-- /sync/send (Reads the peer's pairing code)
`-- /settings (Settings & Preferences)
    `-- /settings/about (About Screen - Config-Driven)
```

---

## 5. UI/UX & Localization Architecture

- **Material 3 Design System**: Dynamic color palettes (Material You) with custom light, dark, and AMOLED True Black themes.
- **Bi-directional Multi-Script Support**:
  - Full localizations for English (`en`) and Malayalam (`ml`).
  - Text direction detected dynamically per field using `detectTextDirection` and wrapped in `AdaptiveDirectionality`.
- **Config-Driven About Screen**: The About screen dynamically loads metadata from `assets/config/app_config.json` via `ConfigService` as specified in project standards.

---

## 6. Testing & Quality Assurance Architecture

```text
test/
|-- core/                 # Unit tests for utilities, error handlers, AtomicSaver
|-- models/               # Model serialization, copyWith, and equality tests
|-- repositories/         # Mocked database and media query tests
|-- services/             # Pure logic tests (crypto, pHash, EXIF parser, format converter)
|-- providers/            # Riverpod state notifier unit and integration tests
|-- widgets/              # Widget and interaction tests for custom components
`-- helpers/              # Test fixtures, mock factories, and sample media files
```

- **Critical Test Areas**:
  - `AtomicSaver` crash recovery and atomic swap integrity.
  - AES-256-GCM encryption/decryption roundtrip and Keystore failure fallbacks.
  - Perceptual hash similarity distance calculation accuracy.
  - SQLite FTS5 search query parser with multi-tag `AND`/`OR` logic.
  - Image conversion and metadata stripping safety.
