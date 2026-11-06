# Change log — guideline Batch 3: errors, accessibility, memory, units

**Plan:** [plans/20261102_133537_guideline-batch-3-errors-a11y-memory.md](../plans/20261102_133537_guideline-batch-3-errors-a11y-memory.md)
**Part of:** [plans/20261102_131432_strict-guideline-adherence.md](../plans/20261102_131432_strict-guideline-adherence.md)
**Date:** 2026-11-02

Closes G31–G37 in [docs/known_gaps.md](../docs/known_gaps.md). It also found and fixed a privacy
bug, and it adds two new gaps: G48, and the freehand-drawing limit, recorded as an accepted
exception.

---

## Step 1 — G32: typed exceptions

- `AppException` is now `sealed`, and every direct subclass is `final`.
- New `ValidationException` (names the refused field) and `BatchItemException` (never names the item).
- **Changed during work, with the owner's choice:** 19 feature exceptions (`ConversionException`,
  `RestoreException`, `TransferSessionException` and others) implemented `Exception` directly.
  They now extend a new open branch, `FeatureException`, and stay in their own files. This keeps
  `core/` from importing services.
- The 9 raw throws are gone. These are the 6 in the plan, plus 3 that the first search missed
  (`ArgumentError.value` in `smart_album_service.dart` and `vault_pin_service.dart`). Three of the
  old messages contained the photo's file name.
- Seven messages that joined a raw error into their text (`'... $error'`) now pass it as `cause`
  instead.

## Step 2 — G37: units and number format

- New `UnitFormat` (`lib/core/formatting/unit_format.dart`) for bytes, mm, m, ISO and crop factor.
  It formats numbers with `formattingLocale`.
- New `context.units` helper (`lib/widgets/common/unit_format_context.dart`).
- The five byte formatters are gone, including `CompressionService.formatBytes`. Its tests moved
  to `test/core/formatting/unit_format_test.dart`.
- `mm`, `m`, `ISO`, `x` and `'... releases'` now come from ARB keys. `releases` is a plural.
- Two strings that joined text in Dart (`a / b` progress and `JPG · 245 KB`) are ARB keys now.
- New unit keys keep their symbols in `ml` and `sa`, so they are on the parity test's
  `sameAsEnglishAllowed` list, with the reason given.

## Step 3 — G35: touch targets

- New `ColorSwatchButton`:
  - 48 × 48 dp hit area;
  - screen-reader label with the colour's name;
  - a `selected` state, so the selected colour is not shown by its border alone (§7.2).
- It is used by the markup pen colours and the tag colour picker. 15 colour names were added in
  all three languages.
- Mask handles grew from 28 to 48 dp, and the compare handle from 44 to 48 dp. Both look the same
  as before.
- **Found by the new test, not in the plan:** the crop aspect chips were squeezed to 40 dp by a
  52 dp row. The row is now 60 dp.
- `test/widgets/accessibility/tap_target_guideline_test.dart` runs Flutter's
  `androidTapTargetGuideline` and `labeledTapTargetGuideline` on these four controls:
  - the tag picker;
  - the markup panel;
  - the redaction panel;
  - the crop panel.

## Step 4 — G34: drawing tools and screen readers

| Tool | What a screen reader gets |
|---|---|
| Crop box | Label, value (position in %), hint, and actions: move left/right/up/down, make smaller/larger |
| Curve graph | Label, point count, and the existing hint. The Reset button next to it was already accessible |
| Markup and hide surfaces | Label, mark/area count, and a hint that drawing needs touch and the panel below is the way in. Recorded as an accepted exception |
| Selected mask | Label, value (shape and centre in %), and move actions |
| Compare divider | A slider, with increase/decrease |

- 21 new ARB keys.
- Tested in `test/widgets/accessibility/drawing_tools_semantics_test.dart`, which includes a
  Sanskrit label check.

## Step 5 — G36: memory

- New `MemoryPressureObserver` (`lib/core/lifecycle/`) and `memoryReliefProvider`
  (`lib/providers/memory_providers.dart`). On memory pressure they clear:
  - the image cache;
  - the thumbnail service's memory cache;
  - every `thumbnailProvider` and `vaultThumbnailProvider` entry.

  `thumbnailProvider` never disposes its entries, so before this they stayed for the whole
  session.
- New `SizedMemoryImage` decodes at the shown size × pixel ratio (twice that for a cover fit). It
  is used in 6 places: grid thumbnail, vault tile, PDF picture tile, trash, compare picker and
  video frame.
- The biggest win is a PDF picture of up to 80 megapixels shown in a 64 dp tile.
- The full-screen viewer, editor, compare views and vault viewer keep full resolution, because the
  user zooms in.

## Step 6 — G33: "open with" feedback

- Kotlin `extractMediaIntentData` returns `{"refused": true}` when `IncomingUriRules` refuses a
  link. It sends no URI, name or size.
- New `MediaIntentController` in `lib/providers/media_intent_providers.dart`, with a typed
  `MediaRepository`. It replaces the intent code and the `dynamic` parameter in `main.dart`.
- A refused or failed link shows a SnackBar through `rootScaffoldMessengerKey`. New keys:
  `errorOpenWithRefused` and `errorOpenWithFailed`.
- `MediaIntentService` logs its three lookups that used to be silent.

## Step 7 — G31: no silent catches

- **Services and repositories (109 blocks):**
  - **Logged (about 60):** for state changes or user data at `warning` or `error`; for frequent,
    expected per-item failures at `debug` (dev flavor only). Every message names the operation
    only.
  - **Safe to ignore (about 50):** best-effort clean-up, cache misses, and decode fallbacks under
    hard rule 5. Each now says why in a `// Safe to ignore:` comment.
- **Providers, core and models (12 more blocks):** the same rule. Models get comments only, so
  they do not depend on logging.
- Old comments that only repeated the new reason were removed. Ones that add detail were kept.
- `test/tool/catch_policy_test.dart` fails if a bare catch comes back in services or repositories.
- **Privacy bug found and fixed:**
  - `ExifScrubberService` and `GpsGeofenceService` returned the original bytes when they failed,
    or when the picture would not decode.
  - `PrivacyExportService` then shared or saved that original, GPS included, as `scrubbed_…`,
    `clean_…` or `geofuzzed_…`.
  - Both now throw the new `PrivacyProcessingException`, so the export reports `failed` and
    nothing goes out.
  - The old export tests used 8 junk bytes and expected `done`, so they encoded the bug. They now
    use a real tiny JPEG.
  - New tests prove that a copy which could not be cleaned is never shared or saved.
- **Raw error text on screen, found and fixed (§11.2):**
  - The duplicate cleaner showed `e.toString()`. It now shows a translated message
    (`cleanerFailedBody`), and the unused `errorMessage` field was removed.
  - The batch result sheet showed the raw first error. It now shows only its translated count; the
    detail is logged.

## Step 8 — docs

- `docs/architecture.md`: §10 error handling, the memory-pressure lifecycle row, and decode size.
- `docs/security.md` §9: what the new log lines may contain, and the G48 note.
- `docs/known_gaps.md`:
  - G31–G37 resolved;
  - new G48: dev-flavor logs keep the full error text, which can quote a path. The owner decides;
  - freehand drawing added to the accepted exceptions.

---

## Files

**Created:**
- Code: `lib/core/formatting/unit_format.dart`, `lib/core/lifecycle/memory_pressure_observer.dart`,
  `lib/providers/memory_providers.dart`
- Widgets: `lib/widgets/common/unit_format_context.dart`,
  `lib/widgets/common/color_swatch_button.dart`, `lib/widgets/common/sized_memory_image.dart`
- Tests:
  - `test/core/errors/app_exception_hierarchy_test.dart`
  - `test/core/formatting/unit_format_test.dart`
  - `test/core/lifecycle/memory_pressure_observer_test.dart`
  - `test/widgets/common/sized_memory_image_test.dart`
  - `test/widgets/accessibility/tap_target_guideline_test.dart`
  - `test/widgets/accessibility/drawing_tools_semantics_test.dart`
  - `test/providers/media_intent_controller_test.dart`
  - `test/android/incoming_link_refusal_test.dart`
  - `test/tool/catch_policy_test.dart`

**Changed (main ones):**
- Core: `lib/core/errors/app_exception.dart`, `lib/core/routing/app_router.dart`, `lib/main.dart`,
  `lib/providers/media_intent_providers.dart`
- Services:
  - the 19 files holding feature exceptions;
  - `lib/services/privacy/exif_scrubber_service.dart`,
    `lib/services/privacy/gps_geofence_service.dart`;
  - `lib/services/intent/media_intent_service.dart`,
    `lib/services/duplicates/duplicate_scan_service.dart`;
  - about 50 files in `lib/services/` and `lib/repositories/` for the catch blocks.
- Widgets and screens: the five editor tool widgets, `tag_color_picker.dart`,
  `curtain_comparison_view.dart`, the six tile widgets, the unit formatting sites,
  `batch_result_sheet.dart`, `duplicate_cleaner_screen.dart`
- Model: `lib/models/duplicate/duplicate_scan_state.dart`
- Android: `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt`
- Localization: `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (51 new keys), plus the generated files
- Tests and docs: `test/l10n/translation_parity_test.dart`, the privacy tests, the exception tests,
  `test/services/convert/compression_service_test.dart`, `docs/architecture.md`,
  `docs/security.md`, `docs/known_gaps.md`

---

## Check results

- `flutter gen-l10n`: clean.
- `dart format --set-exit-if-changed lib test`: 548 files, 0 changed.
- `flutter analyze`: no issues.
- `flutter test`: all 2,042 tests pass (2,003 after Batch 2; 39 new).
- `test/tool/catch_policy_test.dart`: 0 silent catch blocks (113 at the start of Step 7).

**Not checked:**
- No Android build was run, so the Kotlin change has not been compiled.
- TalkBack on a phone.
- Real memory pressure.
- An "open with" link from a real file manager.
- The new Malayalam and Sanskrit text (51 keys) has not been read by a fluent reader (G9).
