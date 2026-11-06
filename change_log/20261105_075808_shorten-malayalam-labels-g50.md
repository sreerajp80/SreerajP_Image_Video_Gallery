# Change log — four Malayalam labels shortened (G50)

**Plan:** [plans/20261105_075808_shorten-malayalam-labels-g50.md](../plans/20261105_075808_shorten-malayalam-labels-g50.md)
**Date:** 2026-11-05
**Gap closed:** G50. No gap is open in `docs/known_gaps.md`.

## What changed

- `lib/l10n/app_ml.arb`: the owner's shorter text.

  | Key | New text | Letters |
  |---|---|---|
  | `actionForensicInspector` | ലെൻസ്-സെൻസർ പരിശോധന | 14 |
  | `titlePrivacyOptionAuthor` | നിർമ്മാണവിവരം നീക്കുക | 11 |
  | `titlePrivacyOptionSerials` | സീരിയൽ നമ്പർ നീക്കുക | 12 |
  | `titlePrivacyOptionTimestamps` | തീയതി-സമയം നീക്കുക | 11 |

  The limit is 22. `flutter gen-l10n` regenerated the Malayalam localizations.
- `test/l10n/translation_parity_test.dart`: the `overBudgetAwaitingReview` list and its stale-entry
  test are gone. The length test now has no exceptions in any language.
- `docs/known_gaps.md`: G50 moved to fixed; §2 says no gap is open.
- `docs/release_process.md`, `docs/implementation_progress.md`: the G50 mentions updated.

## Results

`dart format`: no changes. `flutter analyze`: no issues. `flutter test`: 2,204 tests pass (one
fewer than before, because the review-list check was removed with the list).

## Still open

- The owner's build after `targetSdk` 36 and the phone checks.
- The guideline-pack note in `plans/20261105_073420_apply-sanskrit-review.md` §8.
