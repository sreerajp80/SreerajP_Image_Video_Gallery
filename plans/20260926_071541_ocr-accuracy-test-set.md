# OCR: a fixed test set and a script to measure accuracy

**Status:** partial_completion

> The tool is built and tested. The baseline numbers wait for Tesseract to be installed.
> See [the change log](../change_log/20260926_072625_ocr-accuracy-test-set.md).

Part 4 of 4 in the OCR accuracy work. The other plans:
`20260926_071538_ocr-image-preparation-and-crop.md`,
`20260926_071539_ocr-best-data-dpi-and-layout.md`, `20260926_071540_ocr-share-text.md`.

> **Suggested order:** do this plan **first**. Then plans 1 and 2 can each show real numbers
> before and after, instead of "it looks better".

## The issue

We have no way to measure OCR accuracy. Every change (image preparation, `best` data, layout
modes, and later a fine-tuned Malayalam model) is judged by eye on a few images. That is
unreliable, especially for Malayalam, where one wrong conjunct is easy to miss.

## The fix

A developer-only tool that runs outside the app. It is **not** part of the shipped APK and
adds nothing to the app's `dependencies`.

### A. The test set

- Folder: `tool/ocr_eval/samples/`. Each sample is a pair:
  `name.png` (or `.jpg`) and `name.gt.txt`, the correct text typed and checked by hand.
- Sample names start with a group tag, so results can be grouped:
  `en_screenshot_`, `en_dark_`, `en_photo_`, `en_doc_`, `ml_print_`, `ml_newspaper_`,
  `ml_screenshot_`, `ml_oldlipi_`, `mixed_`.
- Aim: 100–200 samples in total, at least 15 per group.
- **Privacy rule:** only images the user made themselves for this purpose, or public-domain
  or openly licensed images. No personal photos, bills, IDs, or screenshots with names or
  numbers. The README says this clearly.
- The images are **not committed by default**: `tool/ocr_eval/samples/` goes into
  `.gitignore`, with only a README and three tiny made-up example pairs committed. If the
  user later wants the full set in git, that is a separate decision.

### B. The error rate code

Target: `tool/ocr_eval/lib/` (developer tool, not `lib/`).

- `error_rate.dart`: pure functions.
  - **CER** (character error rate): edit distance between result and truth, divided by the
    truth length. Counted on Unicode grapheme clusters, so a Malayalam conjunct counts as one
    unit, not three or four code points.
  - **WER** (word error rate): the same on words.
- Before comparing, both texts go through the same light normalisation: trim, collapse
  spaces, unify line endings, and the same chillu cleanup as plan 2. So we measure reading
  mistakes, not spacing.

### C. The runner script

`tool/ocr_eval/bin/ocr_eval.dart`, run with `dart run`:

- For each sample, it:
  1. optionally runs the same `OcrImagePreparer` as the app (after plan 1), since it is pure
     Dart;
  2. calls the **desktop Tesseract command line** with the same `traineddata` files from
     `assets/tessdata/` and the same settings (language, `psm`, DPI, interword spaces);
  3. computes CER and WER.
- Options: `--lang eng|mal|eng+mal`, `--psm 3|6|11`, `--prepare on|off`,
  `--tessdata <folder>` (to compare fast, best, and a future fine-tuned model).
- Output: a table per group (sample count, mean CER, mean WER, worst three samples), printed
  to the terminal and written to `tool/ocr_eval/results/<date>_<label>.md`. The results folder
  is gitignored; numbers worth keeping go into change logs.
- It needs Tesseract installed on the developer's machine. The README gives install steps.
  The script makes no network calls.

**Honest limit:** desktop Tesseract and the phone plugin (Tesseract4Android) may differ
slightly in version. The results are for **comparing** settings and models, not a promise of
exact phone accuracy. A small on-device spot check stays part of each change.

## Files to change

| File | Change |
|---|---|
| `tool/ocr_eval/README.md` | **New.** How to add samples, the privacy rule, how to install Tesseract and run |
| `tool/ocr_eval/lib/error_rate.dart` | **New.** CER and WER |
| `tool/ocr_eval/lib/text_normaliser.dart` | **New.** Comparison normalisation |
| `tool/ocr_eval/bin/ocr_eval.dart` | **New.** The runner |
| `tool/ocr_eval/samples/example_*` | **New.** Three tiny made-up pairs (English, Malayalam, mixed) |
| `test/tool/ocr_eval/error_rate_test.dart` | **New.** Known cases, including Malayalam conjuncts counted as one unit |
| `.gitignore` | Ignore `tool/ocr_eval/samples/*` (except examples and README) and `tool/ocr_eval/results/` |
| `pubspec.yaml` | Only if needed: `characters` is already available through Flutter; `args` as a **dev_dependency** for the command-line options (BSD-3, no network). Checked against the blocked list before adding |
| `docs/dependencies.md` | Note `args` as dev-only, if added |
| `docs/project_structure.md` | Add `tool/ocr_eval/` |

Before adding the `tool/` folder, check `docs/guidelines/guideline.md` and
`docs/guidelines/flutter_project_engineering_standard.md` for where dev tools belong, and follow
them if they say otherwise.

## How it will be checked

- Unit tests for CER and WER: identical text gives 0; one wrong letter gives the expected
  value; a Malayalam conjunct counts as one unit; empty truth is handled without dividing by
  zero.
- `dart format .`, `flutter analyze` (zero issues), `flutter test` (all pass).
- Run the script on the example pairs and check the table prints and the result file is
  written.
- Then record the **baseline** numbers for today's setup (fast data, `psm 3`, no preparation)
  in the change log. Plans 1 and 2 compare against these.

## After this plan

With the baseline in place, the Malayalam fine-tuning (from `mal` best with `tesstrain`) can
be measured the same way, using `--tessdata` to point at the new model. That training is its
own future plan.
