# Change log: OCR accuracy test set and measuring tool

Implements plan: [plans/20260926_131141_ocr-accuracy-test-set.md](../plans/20260926_131141_ocr-accuracy-test-set.md)

## What changed and why

We had no way to measure OCR accuracy, so every OCR change was judged by eye. This adds a
developer-only tool that runs desktop Tesseract on a fixed set of test pictures. It uses the
app's own language files and settings, and reports character and word error rates (CER and
WER) per group of samples. It is not part of the app and adds nothing to the APK.

- **Error rates** (`tool/ocr_eval/src/error_rate.dart`): Levenshtein edit distance on
  characters and on words. Characters are grapheme clusters, so a Malayalam conjunct such as
  `ക്ഷ` counts as one. An empty correct text never causes a division by zero.
- **Normalisation** (`tool/ocr_eval/src/text_normaliser.dart`): collapses spaces and line
  breaks, turns old chillu spellings into the single chillu letters, composes two-part vowel
  signs, and drops leftover zero-width joiners. It is used for comparison only. It never
  changes one letter into another.
- **Samples** (`tool/ocr_eval/src/sample.dart`): pairs `name.png|jpg` with `name.gt.txt`. The
  first part of the name picks the language (`en_`, `ml_`, `mixed_`); the first two parts
  form the report group.
- **Runner** (`tool/ocr_eval/bin/ocr_eval.dart`): runs Tesseract with a 120-second limit per
  picture (the same as the app). It prints a table (samples, failed, mean CER, mean WER,
  three worst samples) and saves it to `tool/ocr_eval/results/`. The report lists sample
  names and scores only, never the recognised text. If Tesseract is missing, it exits with a
  clear message.
- **Three made-up example pairs** (English, Malayalam, mixed), drawn with Windows fonts. They
  contain no personal data.
- **Git:** everything in `tool/ocr_eval/samples/` except the `*_example_*` files is ignored,
  and so is `tool/ocr_eval/results/`. This keeps personal pictures out of the repository by
  default.

## Differences from the plan

- The shared code folder is `tool/ocr_eval/src/`, not `tool/ocr_eval/lib/`. A folder called
  `lib` outside the package root can confuse the relative-import lint rules.
- `args` was **not** added. The tool reads its few `--name value` options by hand, so no new
  package was needed for this.
- `characters` was added as a **dev dependency** (BSD-3-Clause, Dart team, no dependencies of
  its own, no networking). It was already in `pubspec.lock` through Flutter. Listing it lets
  the tool import it without a lint warning.
- Two extra options: `--tesseract <path>` (Tesseract is often not on `PATH` on Windows) and
  `--dpi <n>` (needed later for plan 2).
- `--prepare` was **not** added, because the image preparation from plan 1 does not exist
  yet. Plan 1 should add it, so the tool sees the same picture as the app.
- **The baseline was not recorded.** Tesseract is not installed on the development machine
  yet. See "Still to do".

## Files

| File | Change |
|---|---|
| `tool/ocr_eval/README.md` | New: purpose, privacy rule, sample naming, install and run steps, limits |
| `tool/ocr_eval/bin/ocr_eval.dart` | New: the runner |
| `tool/ocr_eval/src/error_rate.dart` | New: CER and WER |
| `tool/ocr_eval/src/text_normaliser.dart` | New: comparison normalisation |
| `tool/ocr_eval/src/sample.dart` | New: finding and naming samples |
| `tool/ocr_eval/samples/en_example_01.png`, `.gt.txt` | New: made-up English example |
| `tool/ocr_eval/samples/ml_example_01.png`, `.gt.txt` | New: made-up Malayalam example |
| `tool/ocr_eval/samples/mixed_example_01.png`, `.gt.txt` | New: made-up mixed example |
| `test/tool/ocr_eval/error_rate_test.dart` | New: 11 tests (edit distance, conjunct counted once, empty text) |
| `test/tool/ocr_eval/text_normaliser_test.dart` | New: 7 tests (spacing, all six chillus, vowel signs, joiners, English untouched) |
| `test/tool/ocr_eval/sample_test.dart` | New: 5 tests (group, language, pairing, missing truth, other files ignored) |
| `pubspec.yaml` | `characters: ^1.4.1` under `dev_dependencies` |
| `.gitignore` | Ignore local samples and results; keep examples |
| `docs/dependencies.md` | `characters` added to the dev dependency table |
| `docs/project_structure.md` | `tool/ocr_eval/` added |

## Checks

- `dart format`: clean (0 files changed on the final check).
- `flutter analyze`: no issues found.
- `flutter test`: all 1,982 tests passed, including the 23 new ones.
- Runner without Tesseract: exits with code 69 and the install message.
- Runner with an unknown option: prints usage and exits with code 64.
- `git check-ignore`: a new local sample and a results file are ignored; the example files
  are not.

## Still to do

1. Install Tesseract 5 on the development machine (see `tool/ocr_eval/README.md`).
2. Add real samples, 100–200 in total, following the privacy rule.
3. Run `dart run tool/ocr_eval/bin/ocr_eval.dart --label baseline-fast-psm3` and record the
   baseline numbers (today's fast data, psm 3, no preparation) here or in a follow-up log.
   Plans 1 and 2 compare against them.
