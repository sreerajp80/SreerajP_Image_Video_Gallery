# Guideline Batch 3 — error handling, accessibility, memory, hard-coded text

**Status:** completed

> Done: [change_log/20261102_140936_guideline-batch-3-errors-a11y-memory.md](../change_log/20261102_140936_guideline-batch-3-errors-a11y-memory.md).

**Date:** 2026-11-02
**Part of:** [plans/20261102_131432_strict-guideline-adherence.md](20261102_131432_strict-guideline-adherence.md) (Batch 3)
**Gaps:** G31, G32, G33, G34, G35, G36, G37 in [docs/known_gaps.md](../docs/known_gaps.md)

**Security impact:** G31 adds log lines, so each one must follow the "never log" list
(`docs/security.md` §9). File names, paths and photo metadata are private, so they must never
be logged. G32 removes file names from three exception messages for the same reason. G33 changes
how a refused "open with" link is reported, but not what is refused. No permission, storage or
network rule changes.

---

## 1. What the issue is

Checked in the code today:

| Gap | What is there | Rule |
|---|---|---|
| G31 | 266 `catch` blocks in `lib/`. 103 in `services/` and 7 in `repositories/` neither rethrow, log nor set an error state: 55 are empty and 40 return a default value. | Standard §11.2 ("never silently swallow an error that changes state"; log detail at the service or repository layer), §14.5 |
| G32 | `AppException` is `abstract`, not `sealed`. 6 raw throws: 3 `StateError` in `gallery_batch_handler.dart`, 1 in `vault_import_service.dart`, 2 `ArgumentError` in `perceptual_hash_service.dart`. Three messages contain the photo's file name. | Standard §11.3; security "never log private metadata" |
| G33 | When Kotlin refuses an "open with" link it returns `null`, so the user sees nothing. When opening fails later, `main.dart` only logs it. That handling also sits in `main.dart` with a `dynamic` repository. | Standard §11.2, §11.4; hard rule 5; "keep `main.dart` thin" |
| G34 | The five drawing tools (crop, curve, markup, redaction, selective mask) use `CustomPaint` and pan gestures, and have no `Semantics`. | Standard §7.3 |
| G35 | Small hit areas: markup pen colors 30 dp, tag color picker about 34 dp, mask handles 28 dp, compare handle 44 dp. Others may exist. | Standard §7.1 (48 dp) |
| G36 | Nothing clears the image cache on memory pressure. No `cacheWidth` anywhere, including the grid thumbnail. | Standard §9.2, §10.4 |
| G37 | Text built in Dart: `'... releases'` and `' mm'` in 4 widgets. Five separate byte formatters (`KB`/`MB`/`GB`), and none uses `formattingLocale`. | Standard §8.2; `CLAUDE.md` localization rules |

---

## 2. Plan for the fix

Work goes in this order, smallest risk first. `flutter analyze` and `flutter test` must pass
after each step.

### Step 1 — G32: typed exceptions
- Make `AppException` `sealed` and every subclass `final`, so a `switch` over errors must cover every case.
- Add two new types:
  - `ValidationException`, for bad input such as the hash-size checks;
  - `BatchItemException`, for a batch item that could not be read or moved.
- Replace the 6 raw throws. The messages no longer name the file; the caller already knows which item failed.
- **Risk:** `sealed` means every direct subclass must live in `app_exception.dart`. They already do.
- **Added during work (owner chose this option on 2026-11-02):** 19 feature exceptions
  (`ConversionException`, `RestoreException`, `TransferSessionException` and others) implemented
  `Exception` directly, outside the hierarchy. `AppException` gets one open abstract branch,
  `FeatureException`, and those 19 classes now extend it, staying in their own files. This keeps
  the layers as they are; core does not import services. Where a message joined a raw error into
  its text (`'... $error'`), the error moves to `cause` instead, so paths inside it do not become
  part of the message.

### Step 2 — G37: one formatter for sizes and units
- New `lib/core/formatting/unit_format.dart` (core layer, no widgets):
  - `formatBytes(int bytes, AppLocalizations l10n, Locale locale)`;
  - `formatMillimetres(double value, int decimals, AppLocalizations l10n, Locale locale)`.
- Numbers go through `NumberFormat` with `formattingLocale(...)`.
- New ARB keys, in all three languages, with `@` descriptions:
  - `unitBytesKb`, `unitBytesMb`, `unitBytesGb` (placeholder `{value}`);
  - `unitMillimetres`;
  - `forensicShutterCount` (plural).
- Replace the five byte formatters (`trash_screen`, `pdf_image_tile`, `transfer_progress_view`,
  `media_details_sheet`, `compression_service`)
  and the four `mm` / `releases` sites.
- `compression_service.dart` keeps a plain-English label only if it is used for logs. If it reaches
  the UI, the UI formats it instead.
- Unit symbols (`KB`, `MB`, `mm`) stay as symbols in `ml` and `sa`, as other Indian-language apps do. They go on the `sameAsEnglishAllowed` list with this reason.

### Step 3 — G35: touch targets
- Grow the hit area to 48 × 48 dp without changing the look, using `SizedBox` or `Padding`
  around the visible dot or handle:
  - markup pen colors;
  - tag color picker;
  - mask handles;
  - compare handle.
- Give each color swatch a `Semantics` label (the color name) and a `selected` state. Today the
  selected color is shown by its border alone (§7.2).
- New widget tests run Flutter's own checks, `androidTapTargetGuideline` and
  `labeledTapTargetGuideline`, on the editor controls, the tag editor and the compare screen.
  These tests find any other small targets, which then get fixed in this step.

### Step 4 — G34: semantics for the drawing tools
- Each tool gets a `Semantics` wrapper with a localized `label`, `hint` and `value`:

  | Tool | Value |
  |---|---|
  | Crop | The crop box as percentages |
  | Curve | Number of points |
  | Markup / redaction | Number of strokes / boxes |
  | Mask | Mask type and position |

- Where a screen reader can act, add `customSemanticsActions`:
  - Crop: "reset";
  - Curve: "reset curve";
  - Mask: "move centre left / right / up / down".
- **Honest limit:** freehand drawing cannot be done with a screen reader. For markup and
  redaction, the label says so, and the hint points to the controls panel, which is accessible.
  This is recorded in `docs/known_gaps.md` as an accepted limit, not hidden.
- New ARB keys for every label and hint, in all three languages.

### Step 5 — G36: memory
- New `lib/core/lifecycle/memory_pressure_observer.dart`: a `WidgetsBindingObserver` that, on
  `didHaveMemoryPressure`:
  - clears `PaintingBinding.instance.imageCache` (`clear()` and `clearLiveImages()`);
  - logs one `info` line.
- It is registered once in `main.dart`, in one line. The Riverpod thumbnail cache is cleared too,
  if it keeps bytes in memory. I will check this before writing it.
- `cacheWidth` set from the shown size × device pixel ratio on the decode sites that show small images:
  - `media_thumbnail.dart` (the grid);
  - `vault_item_tile.dart`;
  - `pdf_image_tile.dart`;
  - `trash_screen.dart`;
  - `photo_selector_sheet.dart`;
  - `frame_grab_panel.dart`.
- The full-screen viewer, the editor, compare and the vault viewer keep full resolution, because
  the user zooms in. The reason goes in a comment and in `docs/architecture.md`.
- A widget test checks that a thumbnail is decoded at the reduced width.

### Step 6 — G33: tell the user when "open with" fails
- Kotlin `extractMediaIntentData` sends `{"refused": true}` instead of `null` when
  `IncomingUriRules` refuses a link. It still sends no URI or path back.
- Move `_initMediaIntents` / `_openIntentMedia` out of `main.dart` into a new
  `MediaIntentController` in `lib/providers/media_intent_providers.dart`. It has a typed
  `MediaRepository`, not `dynamic`. `main.dart` only starts it.
- On a refused or failed link, the app shows a `SnackBar` through a root
  `ScaffoldMessenger` key. New ARB keys: `errorOpenWithRefused` and `errorOpenWithFailed`.
- `MediaIntentService.resolveMediaItem` logs its three silent lookups (part of G31).
- Tests: controller tests for "refused", "failed" and "opened"; a Kotlin-source test like
  `test/android/provider_paths_test.dart` checks that the refusal sends no URI.

### Step 7 — G31: no silent catches in services and repositories
Rule for each of the 110 silent blocks in `services/` and `repositories/`:

1. **Changes state or loses user data when it fails** → log with `AppLogger.warning` or
   `AppLogger.error`, then:
   - rethrow as a typed `AppException`, or
   - return a result the caller turns into a message.
2. **Best-effort and truly harmless** (deleting a temp file, closing a stream already closed,
   a parse that falls back by design under hard rule 5) → keep it silent, but add a one-line
   `// Safe to ignore: <reason>` comment.
3. Log lines never contain a path, file name, URI, note text or metadata value. They contain only
   the operation name and the error type. `AppLogger` already reduces errors to their type
   outside the dev flavor.

- A new test, `test/tool/catch_policy_test.dart`, scans `lib/services/` and `lib/repositories/`.
  It fails if a `catch` block has none of these: a rethrow/throw, an `AppLogger` call, or a
  `// Safe to ignore:` comment. This stops the problem from coming back.
- The providers (4 empty catches), `core/` (2) and `models/` (3) are read and fixed with the same
  rule. The test covers only services and repositories, because UI-layer catches usually set state.
- **Risk:** this touches about 60 files. Each change is small, and no behavior changes except
  extra logging and typed errors. Tests run after every folder.

### Step 8 — docs and close
- Update `docs/known_gaps.md`: move G31–G37 to resolved, and record the accepted freehand-drawing
  limit.
- Update `docs/architecture.md` (error handling and image memory) and `docs/security.md` §9 (what
  the new log lines may contain).
- Write the change log.

---

## 3. Files to change

| Area | Files |
|---|---|
| Errors | `lib/core/errors/app_exception.dart`, `lib/services/batch/gallery_batch_handler.dart`, `lib/services/vault/vault_import_service.dart`, `lib/services/duplicates/perceptual_hash_service.dart` |
| Formatting | new `lib/core/formatting/unit_format.dart`; `lib/screens/trash/trash_screen.dart`, `lib/widgets/pdf/pdf_image_tile.dart`, `lib/widgets/sync/transfer_progress_view.dart`, `lib/widgets/viewer/media_details_sheet.dart`, `lib/widgets/compare/compare_metadata_sheet.dart`, `lib/widgets/privacy/forensic_inspector_sheet.dart`, `lib/services/convert/compression_service.dart` |
| Touch / semantics | `lib/widgets/editor/{crop_overlay,curve_editor,markup_canvas,redaction_panel,selective_mask_overlay}.dart`, `lib/widgets/tags/tag_color_picker.dart`, `lib/widgets/compare/curtain_comparison_view.dart`, plus anything the guideline tests find |
| Memory | new `lib/core/lifecycle/memory_pressure_observer.dart`; `lib/main.dart` (one line); `lib/widgets/media/media_thumbnail.dart`, `lib/widgets/vault/vault_item_tile.dart`, `lib/widgets/pdf/pdf_image_tile.dart`, `lib/screens/trash/trash_screen.dart`, `lib/widgets/compare/photo_selector_sheet.dart`, `lib/widgets/video/frame_grab_panel.dart` |
| Open with | `lib/main.dart`, `lib/providers/media_intent_providers.dart`, `lib/services/intent/media_intent_service.dart`, `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt` |
| Silent catches | about 60 files in `lib/services/` and `lib/repositories/`, plus a few in `lib/providers/`, `lib/core/`, `lib/models/` |
| Localization | `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ `flutter gen-l10n`); `test/l10n/translation_parity_test.dart` (allow-list for unit symbols) |
| Tests | new tests listed in each step; existing tests updated where messages or types change |
| Docs | `docs/known_gaps.md`, `docs/architecture.md`, `docs/security.md` |

---

## 4. How it will be checked

- After each step: `flutter gen-l10n` (when ARB files changed), `dart format`, `flutter analyze`,
  `flutter test`.
- New tests:
  - catch policy;
  - unit formatter in `en` / `ml` / `sa`;
  - tap-target and label guidelines;
  - semantics labels on the five tools;
  - thumbnail decode width;
  - memory observer;
  - "open with" controller;
  - Kotlin refusal source check.
- **Not checked without a device:**
  - TalkBack on the drawing tools;
  - real memory pressure;
  - an "open with" link from a real file manager.
- An Android build is needed for the Kotlin change. I'll give you the command; after it,
  `android\gradlew --stop`.

## 5. Risks

- **Size:** this batch is bigger than Batch 2, mostly because of G31. If you prefer, Steps 1–6 can
  ship first and Step 7 later, as its own change log.
- **New Sanskrit and Malayalam text** (about 30 keys) will not be reviewed by a fluent reader yet. G9 stays open.
- **`sealed`** may break a `switch` somewhere that relies on a default branch. The analyzer finds these.
