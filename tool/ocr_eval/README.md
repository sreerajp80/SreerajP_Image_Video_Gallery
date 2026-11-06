# OCR accuracy tool

A developer-only tool that measures how well OCR reads a fixed set of test pictures. It is
**not part of the app**: nothing here is bundled into the APK, and the tool makes no network
calls.

Use it to compare settings and models with numbers instead of by eye: today's setup, image
preparation, `tessdata_fast` against `tessdata_best`, page modes, and a future fine-tuned
Malayalam model.

## What it measures

- **CER** (character error rate): edits needed to turn the OCR result into the correct text,
  divided by the length of the correct text. 0% is perfect.
- **WER** (word error rate): the same on words.

Characters are counted as the units a reader sees (grapheme clusters). A Malayalam conjunct
such as `ക്ഷ` counts as one character, so one misread conjunct is one mistake.

Before comparing, both texts are normalised the same way: spaces and line breaks are
collapsed, old chillu spellings become the single chillu letter, two-part vowel signs are
composed, and leftover zero-width joiners are dropped. So the numbers count reading mistakes,
not spacing or invisible Unicode differences.

## The privacy rule for samples

**Only add pictures you made yourself for this purpose, or that are public domain or openly
licensed.** Never add personal photos, bills, IDs, prescriptions, or screenshots that show
names, phone numbers, or messages.

Everything in `samples/` is ignored by git except the three made-up `*_example_*` pairs.
Results in `results/` are ignored too. Numbers worth keeping go into a change log.

## Adding samples

Put each picture in `samples/` with its correct text next to it:

```
samples/ml_newspaper_03.png
samples/ml_newspaper_03.gt.txt
```

- The `.gt.txt` file is UTF-8 and holds exactly the text in the picture, typed and checked by
  hand. Line breaks do not matter.
- The name starts with a **group tag**. The first part picks the language:
  `en_` → `eng`, `ml_` → `mal`, `mixed_` → `eng+mal`. The first two parts form the group in
  the report.

| Group | Use for |
|---|---|
| `en_screenshot` | Phone screenshots, light theme |
| `en_dark` | Phone screenshots, dark theme |
| `en_photo` | Camera photos of printed English |
| `en_doc` | Scans or clean pages |
| `ml_print` | Clean printed Malayalam, modern script |
| `ml_newspaper` | Newspaper photos |
| `ml_screenshot` | Malayalam screenshots |
| `ml_oldlipi` | Old script (പഴയ ലിപി) print |
| `mixed_...` | Pages that mix both languages |

Aim for 100–200 samples in total, at least 15 per group. Once a sample is in the set, do not
change it. Otherwise results from different days cannot be compared.

## Installing Tesseract

The tool runs the desktop Tesseract program with the app's own language files from
`assets/tessdata/`.

- **Windows:** install the UB Mannheim build of Tesseract 5, for example
  `winget install UB-Mannheim.TesseractOCR`. Then either add its folder to `PATH`, set the
  `TESSERACT` environment variable to `tesseract.exe`, or pass `--tesseract <path>`.
- **Linux:** `sudo apt install tesseract-ocr`.
- **macOS:** `brew install tesseract`.

You do not need to install any language packs. The tool always uses `--tessdata-dir`.

## Running

From the project root:

```bash
dart run tool/ocr_eval/bin/ocr_eval.dart --label baseline
```

Options:

| Option | Default | Meaning |
|---|---|---|
| `--samples <folder>` | `tool/ocr_eval/samples` | Where the pictures are |
| `--tessdata <folder>` | `assets/tessdata` | Language files to test |
| `--tesseract <path>` | `$TESSERACT` or `tesseract` | The Tesseract program |
| `--lang <code>` | from the name | Force one language for every sample |
| `--psm <n>` | `3` | Page segmentation mode (the app uses 3 today) |
| `--dpi <n>` | not set | DPI hint (the app sets none today) |
| `--label <text>` | `run` | Name for the results file |

The table is printed and also saved as `results/<date>_<time>_<label>.md`. The report lists
sample names and scores only, never the recognised text.

## Limits

- The phone uses Tesseract4Android through the `flutter_tesseract_ocr` plugin; the desktop
  program may be a slightly different Tesseract version. Use the numbers to **compare**
  settings and models, not as an exact promise of phone accuracy. Keep a small on-device spot
  check in each change.
- The app does not prepare images yet. When it does, this tool should run the same
  preparation step, so both see the same picture.
