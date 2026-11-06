# OCR: prepare the image and let the user crop before reading

**Status:** dropped

> Never built: `ocr_crop.dart` and `ocr_image_preparer.dart` do not exist (checked 2026-11-02). Closed with no code change; it can be proposed again as a new plan. See [plans/20261102_201827_finish-all-pending-guideline-work.md](20261102_201827_finish-all-pending-guideline-work.md), step 9.

Part 1 of 4 in the OCR accuracy work. The other plans:
`20260926_071539_ocr-best-data-dpi-and-layout.md`, `20260926_071540_ocr-share-text.md`,
`20260926_071541_ocr-accuracy-test-set.md`.

## The issue

`TesseractOcrEngine.readText` (`lib/services/ocr/ocr_engine.dart`) gives Tesseract the
original file with no preparation. Tesseract was built for page scans at about 300 DPI with
dark text on a white background. Our real inputs are different:

- **Screenshots**: text is often only 10–15 px tall. Tesseract works best when letters are
  about 20–30 px tall. Dark mode gives light text on a dark background.
- **Camera photos**: uneven light, shadows, coloured paper, and a lot of non-text area
  (table, hand, background) that Tesseract tries to read as text.

This is the main reason both English and Malayalam results are poor today.

## The fix

### A. Image preparation (new pure service)

Target layer: `services/` (pure Dart, no `BuildContext`).

Add `OcrImagePreparer` in `lib/services/ocr/ocr_image_preparer.dart`. It uses the `image`
package, which is already a dependency. So no new package is needed. Steps, in order:

1. **Decode** safely. If decoding fails, return a failure reason; never throw (hard rule 5).
2. **Apply EXIF rotation** (`bakeOrientation`), so sideways phone photos read upright.
3. **Crop** to the area the user chose (see part B), if any.
4. **Convert to grayscale.**
5. **Invert if the image is mostly dark.** Measure the average brightness. If it is below a
   set threshold, invert, so dark-mode screenshots become dark text on light.
6. **Scale.** If the image is small (short side under a set size), upscale 2× or 3× with a
   smooth filter. If it is very large, downscale to a set maximum long side. This keeps
   memory and time bounded.
7. **Light contrast stretch** (normalise). **No hard black-and-white threshold by default**:
   Tesseract already thresholds internally, and a bad threshold destroys thin Malayalam
   strokes. We decide on adaptive thresholding later, using numbers from plan 4.
8. **Encode as PNG** into a temporary file in the app's private cache folder,
   `ocr_work/`.

The heavy work runs in a background isolate (`Isolate.run`) so the screen does not freeze.

All limits (dark threshold, small and large size, scale factors) go into `AppConstants` with
a comment explaining each.

`OcrImagePreparer` returns a small result: the prepared file path, or a failure reason.

### B. Crop before reading

Target layer: `screens/` and `widgets/`.

- On `ExtractedTextScreen`, add a **"Choose area"** action. It opens the picture with the
  existing `CropOverlay` widget (`lib/widgets/editor/crop_overlay.dart`) and its
  `NormalizedRect`. We reuse that widget; we do not write a new one.
- The chosen rectangle is held in a new `ocrCropProvider` (null means "whole picture"). After
  a new area is chosen, the text is read again.
- A **"Whole picture"** action clears the crop.
- Reading still starts automatically on the whole picture, as today, so nothing gets slower
  for simple screenshots.

### C. Wiring

- `OcrService.readImage` gains an optional `crop` argument. It runs the preparer first, then
  the engine on the prepared file, then **always deletes the temporary file** in a `finally`
  block. The existing checks (size cap, timeout, never throw) stay as they are.
- A new `OcrFailure.unreadableImage` path covers decode failure. No new failure value is
  needed.
- The service also deletes any leftover files in `ocr_work/` when it starts, in case the app
  was killed mid-read.

### Privacy

- The prepared file is a copy of a user photo. It is written only to app-private cache, never
  to shared storage or MediaStore, and it is deleted right after reading.
- Vault items stay unsupported, as today. No decrypted vault image is ever written to disk.
- Nothing about the image or its text is logged. Only sizes and timings may be logged, as
  `docs/security.md` allows.

## Files to change

| File | Change |
|---|---|
| `lib/services/ocr/ocr_image_preparer.dart` | **New.** The preparation steps above |
| `lib/services/ocr/ocr_service.dart` | Run the preparer, pass the prepared file, clean up |
| `lib/models/ocr/ocr_crop.dart` | **New** only if `NormalizedRect` cannot be reused directly; otherwise not created |
| `lib/providers/ocr_providers.dart` | `ocrImagePreparerProvider`, `ocrCropProvider`; controller passes the crop |
| `lib/screens/ocr/extracted_text_screen.dart` | "Choose area" and "Whole picture" actions, crop view |
| `lib/core/constants/app_constants.dart` | Preparation limits and the `ocr_work` folder name |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` | New keys, e.g. `ocrChooseArea`, `ocrWholePicture`, `ocrCropHint`, with real translations and `@` descriptions |
| `lib/l10n/generated/*` | Regenerated by `flutter gen-l10n` (not edited by hand) |
| `test/services/ocr/ocr_image_preparer_test.dart` | **New.** Tests for each step |
| `test/services/ocr/ocr_service_test.dart` | Crop is passed through; temp file is always deleted, also on failure and timeout |
| `docs/security.md` | §20: the temporary prepared file and when it is deleted |
| `docs/architecture.md` | Mention `OcrImagePreparer` in the OCR flow |

## How it will be checked

- Unit tests, using small images made in the test itself:
  - a dark image is inverted, a light one is not;
  - a small image is upscaled, a huge one is downscaled, both within limits;
  - EXIF rotation is applied;
  - the crop gives the expected size;
  - a corrupt file gives a failure result, not an exception;
  - the temporary file is gone after success, failure and timeout.
- `dart format .`, `flutter analyze` (zero issues), `flutter test` (all pass, including the
  `test/l10n/` checks).
- By hand on a device (dev flavor): a light screenshot, a dark-mode screenshot, a Malayalam
  newspaper photo, and a cropped photo. Compare with the text before the change.
- If plan 4 is done first, run the test set before and after, and record the numbers in the
  change log.

## Out of scope

- Straightening tilted photos (perspective correction). It needs corner detection; the crop
  covers most of the need for now.
- Hard black-and-white thresholding. We decide on it later using plan 4's numbers.
