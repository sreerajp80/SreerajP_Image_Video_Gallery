# Change log — the owner's Sanskrit review applied (G9)

**Plan:** [plans/20261105_073420_apply-sanskrit-review.md](../plans/20261105_073420_apply-sanskrit-review.md)
**Date:** 2026-11-05
**Gaps:** G9 closed; G50 narrowed to four Malayalam labels.

## What changed

- **Sanskrit text.** The owner reviewed all 1,078 Sanskrit strings and corrected 145:
  - 144 values in `lib/l10n/app_sa.arb`;
  - `details.license.sa` in `assets/config/app_config.json`;
  - for `errorPdfFailed` the owner chose `PDF स्रष्टुं नाशक्यत`.

  Spaces at the start or end of each line were trimmed, and runs of spaces made single.
  `flutter gen-l10n` regenerated the Sanskrit localizations.
- **Checks on the corrections:** no placeholder or plural structure changed, every short label
  fits 22 letters, and no real Hindi marker.
- **Length review list** (`test/l10n/translation_parity_test.dart`): the two Sanskrit keys left
  `overBudgetAwaitingReview`, because the owner's shorter wording fits. The four Malayalam keys
  stay (G50).
- **Hindi-marker gate** (`test/l10n/sanskrit_hindi_marker_test.dart`):
  - Eight corrected strings are correct Sanskrit that contains `क्या` or `रहा` inside a word
    (`अशक्या…`, `सङ्ग्रहान्वेषणम्`). The language pack's gate matches those tokens anywhere.
  - With the owner's choice (b), each key and its one token is listed in
    `sanskritInsideMarker`. Any other marker in those lines still fails.
  - A new test fails if an entry is no longer needed.
  - The test now reports every match on a line, not only the first.
- **Docs.**
  - `docs/known_gaps.md`: G9 moved to fixed; G50 lists only Malayalam; a new accepted exception
    for the eight words.
  - `CLAUDE.md`, `AGENTS.md`, `README.md`, `docs/release_process.md` and
    `docs/implementation_progress.md`: the Sanskrit is now reviewed; new or changed Sanskrit
    needs the same review.
- **Note for the guideline owner** in the plan, §8: in `language_packs/sanskrit_malayalam.md`
  §4.1, match `क्या`, `रहा` and similar verb forms only as whole words.

## Results

`dart format`: no changes. `flutter analyze`: no issues. `flutter test`: 2,205 tests pass.

## Still open

- G50: four Malayalam labels over 22 letters.
- The guideline change in the plan's §8 (owner, in the guidelines repository).
- The owner's build after `targetSdk` 36 and the phone checks.
