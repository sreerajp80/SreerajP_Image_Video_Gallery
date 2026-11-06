# Batch action bar: quick actions first, the rest under "More"

Implements plan: `plans/20261105_194728_batch-bar-quick-actions.md`

## What changed

- The selection bar no longer scrolls sideways through all 11 actions. It now shows
  a fixed row: Transfer, Favourite, Add to album, Move to trash, More.
- "More" opens a bottom sheet with the other 7 actions in two groups split by a
  divider: Add tags, Remove tags, Remove from favourites, Move to vault; then
  Convert, Watermark, Make PDF.
- Blocked actions in the sheet are greyed out and show the reason under the label.
  Tapping one still shows the reason, as in the bar.
- The sheet closes before the chosen action starts, so pickers and confirm dialogs
  work exactly as before.

## Files

- `lib/core/domain/batch/batch_action_rules.dart` — new `quickActions`,
  `moreActionGroups` and `pick` helper. The layout decision lives here, not in the widget.
- `lib/widgets/batch/batch_action_bar.dart` — fixed `Row` of `Expanded` buttons,
  new `_MoreButton` and the More sheet.
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` and generated files — new key
  `labelBatchActionMore` ("More" / "കൂടുതൽ" / "अधिकम्").
- `test/core/domain/batch/batch_action_rules_test.dart` — every action shows exactly
  once; quick order is fixed; `pick` keeps order and skips missing verdicts.
- `test/widgets/batch/batch_action_bar_test.dart` — tag tests now open More first;
  new test for the bar and sheet contents.

## Checks

- `flutter analyze`: no issues.
- `flutter test`: all tests pass.

## Open item

- The new Sanskrit word "अधिकम्" needs the owner's review.
