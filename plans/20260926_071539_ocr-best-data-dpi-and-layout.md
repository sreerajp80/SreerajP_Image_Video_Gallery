# OCR: more accurate language data, a DPI hint, a layout choice, and Malayalam output cleanup

**Status:** dropped

> Never built: no DPI hint, no layout choice (`ocr_layout.dart` does not exist), and `assets/tessdata/` still holds the standard data; `ocr_text_cleaner.dart` predates this plan (checked 2026-11-02). Closed with no code change. See [plans/20261102_201827_finish-all-pending-guideline-work.md](20261102_201827_finish-all-pending-guideline-work.md), step 9.

Part 2 of 4 in the OCR accuracy work. The other plans:
`20260926_071538_ocr-image-preparation-and-crop.md`, `20260926_071540_ocr-share-text.md`,
`20260926_071541_ocr-accuracy-test-set.md`.

## The issue

1. **The bundled language files look like the "fast" set.** `assets/tessdata/eng.traineddata`
   is about 4.1 MB and `mal.traineddata` is about 5.3 MB. Those sizes match Tesseract's
   `tessdata_fast` models, which trade accuracy for speed. The `tessdata_best` models are
   more accurate. They are also the only ones that can be fine-tuned, which matters for the
   planned Malayalam training.
2. **No DPI hint.** PNG screenshots carry no DPI, so Tesseract guesses. A wrong guess hurts
   its size estimates.
3. **One layout mode for everything.** Tesseract always uses page segmentation mode 3 (full
   automatic page). It works for pages, but it handles scattered screenshot text and
   signboards badly.
4. **Malayalam chillu letters come out in two forms.** Tesseract can output a chillu either as
   the old three-part sequence (consonant + virama + zero-width joiner) or as the single
   atomic letter (for example `ൻ`, U+0D7B). The text looks the same on screen, but search,
   notes and copy-paste treat the two forms as different words.

## The fix

### A. Switch to `tessdata_best` files

- The developer downloads `eng.traineddata` and `mal.traineddata` from the official
  `tesseract-ocr/tessdata_best` repository (Apache-2.0) **on the development machine**. The
  app itself still never downloads anything (hard rule 2).
- First, check the current files' SHA-256 against `tessdata_fast` to confirm what we ship
  today. Write both hashes down in `docs/dependencies.md` (source, version tag, SHA-256,
  licence).
- Measure the effect on the release APK size per ABI, and write it in the change log.
  Expected: about +10 MB for English. We confirm the Malayalam size when downloading.
- `best` models are slower (roughly 2–3×). The existing 120-second timeout stays. If plan 4
  shows it is too tight on low-end phones, raise it then.

### B. DPI hint

- Pass `user_defined_dpi: '300'` in the Tesseract arguments in `TesseractOcrEngine`. After
  plan 1, images are scaled so that text size is close to what 300 DPI means.
- Check during implementation that the plugin passes this variable through to Tesseract. If it
  does not, record that in the change log and drop this step.

### C. Layout choice

Target layer: `models/` (enum), `providers/`, `screens/`.

- Add enum `OcrLayout` in `lib/models/ocr/ocr_layout.dart`:

  | Value | Tesseract `psm` | Use for |
  |---|---|---|
  | `document` | `3` (auto page) | Pages, letters, newspaper photos. **Default** — today's behaviour |
  | `block` | `6` (single block) | One paragraph, a cropped area |
  | `scattered` | `11` (sparse text) | Screenshots of apps, signboards, posters |

- `OcrEngine.readText` gains a `layout` argument. `TesseractOcrEngine` sends `psm`.
- `ocrLayoutProvider` holds the choice. The screen shows it as a second row of chips under
  the language chips. Changing it reads the picture again, the same way the language chips
  do.
- The choice lasts only while the screen is open, like the language choice today.

### D. Malayalam output cleanup

Target layer: `services/` (pure).

- In `OcrTextCleaner`, add one step that turns the old chillu sequences into the atomic chillu
  letters (ൺ ൻ ർ ൽ ൾ ൿ). It is a small fixed table in code, so no Unicode package is added.
- It also removes stray zero-width joiners and non-joiners that are left over and do nothing.
- This does **not** change any letter, fix spelling or reorder text. The cleaner's existing
  rule ("never corrects a word") still holds.

## Files to change

| File | Change |
|---|---|
| `assets/tessdata/eng.traineddata`, `mal.traineddata` | Replaced with the `tessdata_best` files |
| `lib/models/ocr/ocr_layout.dart` | **New.** `OcrLayout` enum with its `psm` value |
| `lib/services/ocr/ocr_engine.dart` | `layout` argument; send `psm` and `user_defined_dpi` |
| `lib/services/ocr/ocr_service.dart` | Pass `layout` through |
| `lib/services/ocr/ocr_text_cleaner.dart` | Chillu and stray-joiner cleanup |
| `lib/models/ocr/ocr_result.dart` | Record the layout used, like `language` today |
| `lib/providers/ocr_providers.dart` | `ocrLayoutProvider`; controller passes it |
| `lib/screens/ocr/extracted_text_screen.dart` | Layout chip row |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` | New short keys, e.g. `ocrLayout`, `ocrLayoutDocument`, `ocrLayoutBlock`, `ocrLayoutScattered`, with real translations and `@` descriptions |
| `lib/l10n/generated/*` | Regenerated by `flutter gen-l10n` |
| `test/services/ocr/ocr_text_cleaner_test.dart` | Chillu cases, joiner cases, and "English text is untouched" |
| `test/services/ocr/ocr_service_test.dart` | Layout is passed to the engine |
| `test/models/ocr/ocr_layout_test.dart` | **New.** Each value maps to the right `psm` |
| `docs/dependencies.md` | Language data source, tag, SHA-256, licence, size |
| `docs/architecture.md` | Update the OCR row: best data, trade-off is size and speed |
| `docs/release_process.md` | Checklist item: confirm the traineddata hashes before release |

## How it will be checked

- Unit tests as listed above.
- `dart format .`, `flutter analyze` (zero issues), `flutter test` (all pass).
- Build a prod release APK and record the size per ABI, before and after.
- On a device: the same four sample images as plan 1, in each layout. Note the time taken on
  the slowest phone available.
- If plan 4 is in place: run the test set with `fast` and with `best` data, and record the
  error rates in the change log.

## Out of scope

- Training or fine-tuning a Malayalam model. That comes after plan 4, so we can measure it.
- Guessing the layout automatically. We can add that later if plan 4 shows a clear rule.
