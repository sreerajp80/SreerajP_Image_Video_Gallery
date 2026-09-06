# Phase 12 — In-Image Scanner (QR/Barcode), Offline OCR, Media Notes & PDF Image Extraction

**Status:** completed

**Plan for:** `docs/implementation_plan.md` → Phase 12
**Date:** 2026-08-31

---

## 1. What Phase 12 asks for

1. In-image QR and barcode detection with one-tap action sheets (Wi-Fi connect, copy, open URL).
2. Offline OCR that pulls selectable text out of screenshots and photos.
3. A markdown notes engine attached to photos and videos.
4. A tool that pulls the images embedded inside a PDF back out as picture files.

None of this exists yet. Everything below is new work, built on what Phases 1–11 already
provide: the MediaStore channel, the document picker channel, the output naming service, the
media database (which already has a `user_notes` column and indexes it for search), and
`mobile_scanner`, which the pairing screen already ships.

---

## 2. Decisions taken before the work starts

### 2.1 OCR engine — Tesseract, not ML Kit

`docs/dependencies.md` pre-approves `google_mlkit_text_recognition`. That package cannot do
this job: ML Kit's on-device text recognition covers Latin, Chinese, Devanagari, Japanese and
Korean only. **There is no Malayalam model.** The app is a bilingual English/Malayalam app, so
the requirement decides the engine.

Chosen: **`flutter_tesseract_ocr`** (BSD-3-Clause). Its only Dart dependencies are `flutter`,
`path` and `path_provider` — no HTTP client, no cloud, nothing on the blocked list. Tesseract
itself is Apache-2.0 and open source, so this also keeps hard rule 1 clean, which the ML Kit
route would not have.

Language data ships as an app asset. Two files from the official `tessdata_fast` set:

| File | Language | Rough size |
|------|----------|-----------|
| `assets/tessdata/eng.traineddata` | English | ~2 MB |
| `assets/tessdata/mal.traineddata` | Malayalam | ~2 MB |

They are fetched once while implementing this phase and committed to the repository. **The app
never downloads them.** The package's README shows a download helper; that code is not used and
must not be copied in.

`docs/dependencies.md` will be updated to record this swap and the reason, so the next reader
does not re-add ML Kit.

**Risk, stated up front:** `flutter_tesseract_ocr` ships Android native code and has an
unverified uploader on pub.dev. If it will not build against this project's Gradle/AGP setup,
I will stop, report it, leave the OCR item unticked, and finish the other three items. I will
not silently swap in a different engine.

### 2.2 Barcode reading — reuse `mobile_scanner`, no new dependency

`mobile_scanner` 5.2.3 is already a dependency and exposes
`MobileScannerController.analyzeImage(path)`, which reads codes out of a still file with no
camera involved. That is exactly what an in-image scan needs.

### 2.3 One-tap actions — a small native channel, not `url_launcher`

Opening a URL, dialling a number, writing an email and reaching the Wi-Fi settings are four
short Android intents. The project already owns five method channels, so a sixth is cheaper and
tighter than a new package: the app decides itself which schemes it will ever hand out
(`http`, `https`, `tel`, `mailto`, `sms`, `geo` — everything else is shown as plain text and
never launched).

Wi-Fi: on API 29 and above the app adds a `WifiNetworkSuggestion` and opens the Wi-Fi panel so
the user taps the network themselves. Below that, and whenever the suggestion is refused, it
opens the Wi-Fi settings and offers to copy the password. The app never silently joins a
network.

### 2.4 Markdown — written here, not pulled in

The notes feature needs a small, well-understood markdown subset. A pure Dart parser producing
immutable blocks is about the same size as wiring up a package, is unit testable line by line,
and keeps every visible string under this project's control. No new dependency.

### 2.5 PDF image extraction — pure Dart

The `pdf` package writes PDFs; it does not read them. Android's `PdfRenderer` renders pages, not
the images inside them. So the extractor is a focused pure Dart PDF object scanner. It supports
what actually turns up in real files:

| Filter | Handling |
|--------|----------|
| `DCTDecode` (JPEG) | Stream bytes written straight out as `.jpg` |
| `FlateDecode`, DeviceRGB / DeviceGray, 8 bits | Inflated with `dart:io` zlib, re-encoded as PNG via `image` |
| `JPXDecode`, `CCITTFaxDecode`, `JBIG2Decode`, `LZWDecode`, `RunLengthDecode` | Listed as found but not extractable, with the reason shown |
| Encrypted PDF (`/Encrypt`) | Refused with a clear message |

It scans objects across the whole file rather than trusting the cross-reference table, so a
slightly broken PDF still yields its pictures. Hard caps on file size, image count and pixel
count stop a hostile file from eating memory.

### 2.6 Scope limits, stated on purpose

- **Vault items are not scanned or OCR'd in this phase.** Vault photos decrypt to memory only,
  and both the barcode reader and Tesseract need a file path. Writing a plaintext copy out to
  disk to read a QR code would work against Phase 10. Notes on vault items already exist
  separately and are untouched here.
- OCR reads still images only, never a video frame.
- Extracted text is never written anywhere by itself. The user copies it, or chooses to append
  it to that photo's notes.

---

## 3. Files to be changed

### 3.1 Configuration and docs

| File | Change |
|------|--------|
| `pubspec.yaml` | Add `flutter_tesseract_ocr`; register `assets/tessdata/` |
| `assets/tessdata/eng.traineddata` | New — English language data (committed) |
| `assets/tessdata/mal.traineddata` | New — Malayalam language data (committed) |
| `assets/tessdata/tessdata_config.json` | New — the file list the package reads |
| `docs/dependencies.md` | Record the Tesseract choice, retire the ML Kit OCR row, note why `url_launcher` was not taken |
| `docs/architecture.md` | Add the scanner, OCR, notes and PDF-extraction services to the layer map |
| `docs/security.md` | Write down: no network for OCR data, the schemes the app will launch, the Wi-Fi rule, the PDF input caps |
| `docs/implementation_progress.md` | Tick Phase 12 |
| `lib/core/constants/app_constants.dart` | Channel name for intents, OCR language codes, PDF caps, notes length cap |
| `android/app/src/main/AndroidManifest.xml` | `<queries>` entries for the intents the app may launch, each with the reason beside it |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` | Register the new intent channel handler |

### 3.2 Native (Kotlin)

| File | Change |
|------|--------|
| `android/.../tools/IntentChannelHandler.kt` | New — `openUrl`, `dial`, `email`, `sms`, `geo`, `openWifiSettings`, `suggestWifiNetwork`, `copyToClipboard`. Every scheme checked before an intent is built |
| `android/.../backup/DocumentPickerChannelHandler.kt` | Add `copyToCache(uri)`, so a picked PDF can be read as a file and deleted after |

### 3.3 Models (all immutable, `const` + `copyWith`)

| File | Purpose |
|------|---------|
| `lib/models/scan/scanned_code.dart` | One decoded code: raw value, kind, display text, format |
| `lib/models/scan/scanned_code_kind.dart` | url, wifi, phone, email, sms, geo, contact, calendar, text |
| `lib/models/scan/wifi_credentials.dart` | SSID, security type, password, hidden flag |
| `lib/models/scan/scan_action.dart` | An offered action and whether it is allowed, with the reason if not |
| `lib/models/ocr/ocr_language.dart` | English, Malayalam, both |
| `lib/models/ocr/ocr_result.dart` | Full text, line list, language used, duration |
| `lib/models/notes/markdown_block.dart` | Heading, paragraph, bullet, numbered, task, quote, code, rule |
| `lib/models/notes/markdown_span.dart` | Plain, bold, italic, strikethrough, code, link |
| `lib/models/notes/media_note.dart` | Media id, markdown text, updated time |
| `lib/models/pdf/pdf_image_entry.dart` | Object number, size, colour space, filter, extractable flag and reason, bytes |
| `lib/models/pdf/pdf_extraction_result.dart` | The entries found, what was skipped, what was refused |

### 3.4 Services

| File | Purpose |
|------|---------|
| `lib/services/scan/barcode_payload_parser.dart` | Pure. Raw string → typed `ScannedCode`, including the `WIFI:` escape rules |
| `lib/services/scan/scan_action_resolver.dart` | Pure. Which actions a code earns, and why one is refused |
| `lib/services/scan/image_scan_service.dart` | Wraps `analyzeImage` behind a small interface so tests need no camera |
| `lib/services/scan/intent_channel.dart` | Dart side of the intent channel; refuses any scheme not on the list |
| `lib/services/ocr/ocr_engine.dart` | Interface, so tests use a fake engine |
| `lib/services/ocr/tesseract_ocr_engine.dart` | Real engine; copies the traineddata assets out once, then reads |
| `lib/services/ocr/ocr_service.dart` | Language choice, caps, timeout, graceful failure |
| `lib/services/ocr/ocr_text_cleaner.dart` | Pure. Trims noise lines, collapses runs of spaces, keeps order |
| `lib/services/notes/markdown_parser.dart` | Pure. Markdown text → blocks and spans |
| `lib/services/notes/media_notes_service.dart` | Read, write, append, length cap, keeps the search index right |
| `lib/services/pdf/pdf_lexer.dart` | Pure. PDF tokens and objects |
| `lib/services/pdf/pdf_image_extractor.dart` | Pure. Finds image objects, decodes the filters listed above |
| `lib/services/pdf/pdf_extraction_service.dart` | Runs the extractor on a picked file and saves what the user keeps |

### 3.5 Repository and providers

| File | Change |
|------|--------|
| `lib/repositories/media_repository.dart` | Add `updateUserNotes` on top of the DAO call that already exists |
| `lib/providers/scan_providers.dart` | New |
| `lib/providers/ocr_providers.dart` | New |
| `lib/providers/notes_providers.dart` | New |
| `lib/providers/pdf_tools_providers.dart` | New |

### 3.6 Screens and widgets

| File | Change |
|------|--------|
| `lib/screens/scan/image_scan_screen.dart` | New — codes found in one picture, each with its actions |
| `lib/screens/ocr/extracted_text_screen.dart` | New — selectable text, language picker, copy, append to notes |
| `lib/screens/notes/media_notes_screen.dart` | New — write and preview tabs, saves on leaving |
| `lib/screens/pdf/pdf_image_extract_screen.dart` | New — pick a PDF, see what is inside, save the ones ticked |
| `lib/widgets/scan/scanned_code_card.dart` | New |
| `lib/widgets/scan/wifi_credentials_sheet.dart` | New |
| `lib/widgets/notes/markdown_view.dart` | New — renders parsed blocks |
| `lib/widgets/notes/notes_preview_tile.dart` | New — the notes line in the details sheet |
| `lib/widgets/pdf/pdf_image_tile.dart` | New |
| `lib/screens/viewer/media_viewer_screen.dart` | Add an overflow menu: Scan codes, Extract text, Notes |
| `lib/widgets/viewer/media_details_sheet.dart` | Show the note, tap to edit |
| `lib/screens/home_screen.dart` | Entry point for the PDF tool |
| `lib/core/routing/app_router.dart` | `media-viewer/:id/scan`, `media-viewer/:id/text`, `media-viewer/:id/notes`, `pdf-images` |

### 3.7 Localization

| File | Change |
|------|--------|
| `lib/l10n/app_en.arb` | Every new label, each with its `@key` description |
| `lib/l10n/app_ml.arb` | The same keys in Malayalam |

### 3.8 Tests (mirroring `lib/`)

| File | Covers |
|------|--------|
| `test/services/scan/barcode_payload_parser_test.dart` | Every code kind, the `WIFI:` escapes, junk input |
| `test/services/scan/scan_action_resolver_test.dart` | Allowed actions, and that a `javascript:` or `file:` URL is never openable |
| `test/services/scan/image_scan_service_test.dart` | No code found, several codes, a decoder that throws |
| `test/services/ocr/ocr_service_test.dart` | Language choice, empty result, engine failure, timeout |
| `test/services/ocr/ocr_text_cleaner_test.dart` | Line and space rules |
| `test/services/notes/markdown_parser_test.dart` | Every block and inline form, and malformed markdown that must not throw |
| `test/services/notes/media_notes_service_test.dart` | Save, append, length cap |
| `test/services/pdf/pdf_lexer_test.dart` | Objects, dictionaries, streams, a truncated file |
| `test/services/pdf/pdf_image_extractor_test.dart` | A hand-built JPEG-in-PDF, a Flate RGB image, an unsupported filter, an encrypted file, the caps |
| `test/models/scan/`, `test/models/ocr/`, `test/models/notes/`, `test/models/pdf/` | Equality, `copyWith`, JSON where used |
| `test/core/routing/app_router_test.dart` | The four new routes |
| `test/widgets/notes/markdown_view_test.dart` | Rendering, and that a bad link is not tappable |

---

## 4. Order of work

1. Constants, models, and the pure parsers with their tests (barcode payload, markdown, PDF lexer).
2. The intent channel, Kotlin side and Dart side, with the scheme rules.
3. Barcode scan service, provider, screen, and the viewer menu entry.
4. Notes: repository method, service, parser view, screen, details-sheet line.
5. PDF: `copyToCache`, extractor service, screen, saving through the existing publish path.
6. OCR last, because it is the one piece a build problem can block: dependency, assets, engine,
   service, screen.
7. English and Malayalam strings, then `flutter gen-l10n`.
8. `dart format .`, `flutter analyze` (must be zero), `flutter test` (must be green).
9. Tick `docs/implementation_progress.md`, update the three docs, write the change log.

---

## 5. Rules this change must not break

- No HTTP client, no cloud, no telemetry. Tesseract runs on device, on files the user already has.
- Text pulled out of a photo is never logged and never leaves the device.
- No widget touches a DAO, a socket, or the file system directly.
- Every visible string comes from `AppLocalizations`, in both English and Malayalam.
- Nothing overwrites an original file. Extracted PDF images are new files written through
  MediaStore under fresh names.
- Vault contents are not read by the scanner or the OCR engine.
