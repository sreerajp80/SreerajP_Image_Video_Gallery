# Phase 12 — In-Image Scanner, Offline OCR, Media Notes & PDF Image Extraction

**Date:** 2026-08-31
**Implements:** `plans/20260831_094833_phase_12_scanner_ocr_notes_pdf.md`
**Covers:** `docs/implementation_plan.md` → Phase 12

---

## 1. What was built

Four features, all of them reading something out of a file the user already has, and none of
them touching a network.

1. **In-image QR and barcode scanning** with one-tap actions.
2. **Offline OCR** in English and Malayalam.
3. **A markdown notes engine** on photos and videos.
4. **A tool that pulls the pictures back out of a PDF.**

---

## 2. Decisions taken during the work

### 2.1 Tesseract replaced ML Kit, before ML Kit was ever added

`docs/dependencies.md` had pre-approved `google_mlkit_text_recognition` for OCR. It cannot do
this job: **ML Kit has no Malayalam model** — its on-device text recognition covers Latin,
Chinese, Devanagari, Japanese and Korean only. Since the app is bilingual, the requirement
picked the engine.

`flutter_tesseract_ocr` was used instead. It is BSD-3-Clause, wraps Tesseract4Android (the
maintained successor to `tess-two`), and its only Dart dependencies are `flutter`, `path` and
`path_provider` — no HTTP client. Tesseract itself is Apache-2.0, so this also keeps hard rule
1 clean, which the ML Kit route would not have.

`eng.traineddata` and `mal.traineddata` (from the official `tessdata_fast` set, about 4 MB and
5 MB) are committed under `assets/tessdata/` and shipped in the APK. The app never downloads
them. The plugin's README shows a network fetch helper; that code is not used.

The dependencies doc now records both the swap and the reason, so nobody re-adds ML Kit.

### 2.2 No launcher package: the app owns its own intents

Handing a scanned code to another app is four short Android intents, and the app already owned
six method channels. `IntentChannelHandler` does it directly rather than taking `url_launcher`.
Owning that code is the point — the list of schemes the app will ever launch lives in one
place and is checked twice.

### 2.3 Two places where the plan was departed from

- **The PDF tool's entry point** went into the timeline's overflow menu, not the settings
  screen the plan named. Every other tool (transfer, backup, cleaner, vault, PDF export) is
  already there; the settings screen is the About screen.
- **Scanner strings are prefixed `codeScan`, not `scan`.** `scanFailed` and friends already
  meant the media-library scan. Reusing the prefix would have been confusing at best and a
  key collision at worst.

---

## 3. A behaviour bug found and fixed while testing

A 13-digit EAN barcode was being read as a phone number, so the app offered to dial the side
of a cereal box. The rule now requires a leading `+` or a separator (space, dash, bracket)
before a bare number counts as a phone number, since a product barcode is a plain run of
digits. Tests cover both directions.

---

## 4. Files changed

### 4.1 Configuration, native and docs

| File | Change |
|------|--------|
| `pubspec.yaml` | Added `flutter_tesseract_ocr`; registered `assets/tessdata/` and `assets/tessdata_config.json` |
| `assets/tessdata/eng.traineddata`, `assets/tessdata/mal.traineddata` | New — language data, committed |
| `assets/tessdata_config.json` | New — the file list the plugin reads (this exact path is hard-coded by the plugin) |
| `lib/core/constants/app_constants.dart` | Intent channel name, permitted schemes, scan and OCR caps and timeouts, note length cap, PDF caps, output folder names |
| `android/app/src/main/AndroidManifest.xml` | `CHANGE_WIFI_STATE` with its reason, and a `<queries>` block naming the six schemes the app may launch |
| `android/.../MainActivity.kt` | Registers and disposes the new intent handler |
| `android/.../tools/IntentChannelHandler.kt` | New — `openUri`, `openWifiSettings`, `suggestWifiNetwork`, `copyToClipboard`, with the scheme check |
| `android/.../backup/DocumentPickerChannelHandler.kt` | Added `copyToCache`, with a size cap enforced while copying |
| `docs/dependencies.md` | Tesseract row in; ML Kit and `url_launcher` recorded as considered and not used, with reasons |
| `docs/architecture.md` | New §3.6 for the subsystem; route tree brought up to date |
| `docs/security.md` | New §12 covering all four features; `CHANGE_WIFI_STATE` added to the permission table |
| `docs/implementation_progress.md` | Phase 12 ticked |
| `CLAUDE.md`, `AGENTS.md` | Two rules added: what `CHANGE_WIFI_STATE` is for, and the permitted-scheme rule |

### 4.2 Models

`lib/models/scan/` — `scanned_code.dart`, `scanned_code_kind.dart`, `wifi_credentials.dart`,
`scan_action.dart`
`lib/models/ocr/` — `ocr_language.dart`, `ocr_result.dart`
`lib/models/notes/` — `markdown_block.dart`, `markdown_span.dart`, `media_note.dart`
`lib/models/pdf/` — `pdf_image_entry.dart`, `pdf_extraction_result.dart`

### 4.3 Services

`lib/services/scan/` — `barcode_payload_parser.dart`, `scan_action_resolver.dart`,
`image_scan_service.dart`, `intent_channel.dart`
`lib/services/ocr/` — `ocr_engine.dart`, `ocr_service.dart`, `ocr_text_cleaner.dart`
`lib/services/notes/` — `markdown_parser.dart`, `media_notes_service.dart`
`lib/services/pdf/` — `pdf_lexer.dart`, `pdf_image_extractor.dart`, `pdf_extraction_service.dart`

### 4.4 Repository, providers, screens and widgets

| File | Change |
|------|--------|
| `lib/repositories/media_repository.dart` | Added `setUserNotes` |
| `lib/providers/media_providers.dart` | Added `mediaItemProvider`, one item by id |
| `lib/providers/scan_providers.dart`, `ocr_providers.dart`, `notes_providers.dart`, `pdf_tools_providers.dart` | New |
| `lib/screens/scan/image_scan_screen.dart` | New |
| `lib/screens/ocr/extracted_text_screen.dart` | New |
| `lib/screens/notes/media_notes_screen.dart` | New |
| `lib/screens/pdf/pdf_image_extract_screen.dart` | New |
| `lib/widgets/scan/scanned_code_card.dart`, `lib/widgets/notes/markdown_view.dart`, `lib/widgets/notes/notes_preview_tile.dart`, `lib/widgets/pdf/pdf_image_tile.dart` | New |
| `lib/screens/viewer/media_viewer_screen.dart` | Overflow menu: scan codes, extract text, notes |
| `lib/widgets/viewer/media_details_sheet.dart` | Shows the note, tap to edit |
| `lib/screens/timeline/timeline_screen.dart` | Menu entry for the PDF image tool |
| `lib/core/routing/app_router.dart` | Four routes and their path builders |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | 141 new keys each, every one with a description |

### 4.5 Tests

`test/services/scan/` (3 files), `test/services/ocr/` (2), `test/services/notes/` (2),
`test/services/pdf/` (4, including a hand-built PDF fixture builder),
`test/models/scan|notes|pdf/` (3), `test/widgets/notes/markdown_view_test.dart`,
`test/core/routing/scanner_tools_routes_test.dart`.

---

## 5. Safety rules this change keeps

- **No network.** No HTTP client was added. OCR runs on the device against language data in
  the app's own assets. Handing a URL to the browser is the browser's connection, not this
  app's; no socket is opened here.
- **A scanned code is untrusted input.** Intents are built only for `http`, `https`, `tel`,
  `mailto`, `sms` and `geo`. `javascript:`, `file:`, `content:`, `intent:` and everything else
  are shown as text and never launched. Checked in Dart, then again in Kotlin;
  `Intent.parseUri` is never used. A test asserts the dangerous schemes stay unopenable.
- **The app never joins a Wi-Fi network by itself.** It suggests, and the user taps.
- **Nothing private reaches a log.** `ScannedCode`, `WifiCredentials`, `OcrResult` and
  `MediaNote` all report sizes and kinds in `toString`, never their contents. Tests assert it.
- **Nothing is overwritten.** Extracted pictures are new files published through MediaStore
  under fresh names.
- **Nothing crashes on bad input.** The payload parser, the markdown parser, the PDF lexer and
  the PDF extractor all refuse rather than throw, and are tested against truncated, malformed
  and random input.
- **The vault is untouched.** Neither the scanner nor the reader works on vault media, because
  both need a file path and writing a plaintext copy out would work against Phase 10.
- **No storage permission was added.** The PDF comes in through the Storage Access Framework
  and the pictures go out through MediaStore. One permission was added, `CHANGE_WIFI_STATE`,
  for the Wi-Fi suggestion alone.

---

## 6. Verification

| Check | Result |
|---|---|
| `dart format .` | 30 files reflowed, clean afterwards |
| `flutter analyze` | No issues found |
| `flutter test` | 1713 tests, all passing |
| `flutter gen-l10n` | Clean; both ARB files hold the same 749 keys |
| `flutter build apk --flavor dev --debug` | Built. This was the plan's stated risk: the Tesseract plugin does compile against this project's Gradle setup |
| Merged manifest permissions | Exactly the declared set. Tesseract added none, `WAKE_LOCK` is still removed, `CHANGE_WIFI_STATE` is the only addition |
| Packaged assets | Both `.traineddata` files and the config are in the APK |

---

## 7. Worth knowing

- **Malayalam OCR accuracy is fair, not excellent.** Tesseract does well on clean screenshots
  and printed text, and poorly on handwriting or a photo taken at an angle. That is the engine's
  limit, not a wiring problem, and no offline engine available to this app does better on
  Malayalam today. Reading both languages at once is slower and slightly less accurate than
  either alone, which is why English is the default rather than "both".
- **`flutter_tesseract_ocr` has an unverified uploader on pub.dev.** It builds and its
  dependency list is clean, but it is the one package here worth re-checking on any upgrade.
  If it ever becomes a problem, the escape route is a small `OcrChannelHandler.kt` calling
  Tesseract4Android directly — `OcrEngine` is already an interface, so only one class would
  need replacing.
- **The APK grew by roughly 23 MB**: about 9 MB of language data and about 14 MB for the
  Tesseract native library.
