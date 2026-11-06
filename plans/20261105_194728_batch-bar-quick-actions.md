# Batch action bar: quick actions first, the rest under "More"

**Status:** completed

## The issue

When items are selected, the bottom bar shows all 11 actions in one long row that
scrolls sideways. The order comes straight from the `BatchAction` enum, so the
heavy tools (Convert, Watermark, PDF, Tags) come first and the actions people use
most (Transfer, Move to trash) are last, off screen. The user has to scroll to reach
Delete, which is the most common reason to select a photo.

## The fix

Show a short, fixed bar with the common actions, plus a "More" button. This is the
same pattern most gallery apps use.

**Bar (no scrolling), left to right:**

1. Transfer (send to another device)
2. Favourite
3. Add to album
4. Move to trash
5. More

**"More" opens a bottom sheet** with the rest, in two groups split by a divider:

- Organise: Add tags, Remove tags, Remove from favourites, Move to vault
- Create new files: Convert, Watermark, Make PDF

Rules that stay the same:

- A blocked action is still shown greyed out, in the bar and in the sheet, and
  tapping it still says why.
- Every action still runs through the same `_start` path, so all confirm dialogs
  (trash, vault, new files) are unchanged.
- The groups use a divider, not headings, so no extra headings need translating.

Where the order lives: a new small list in the domain layer
(`batch_action_rules.dart`) names which actions are "quick" and the order of the
rest. The widget only reads it. This keeps the decision in one tested place.

## Files to change

- `lib/core/domain/batch/batch_action_rules.dart` — add the quick list and the
  "more" list (in display order), plus a helper that splits `evaluateAll` results
  into the two lists.
- `lib/widgets/batch/batch_action_bar.dart` — draw the 4 quick buttons and a More
  button in a fixed `Row` (each `Expanded`) instead of the scrolling list; add the
  More bottom sheet.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, `lib/l10n/app_sa.arb` — one new key
  `labelBatchActionMore` ("More" / "കൂടുതൽ" / "अधिकम्"), with its `@` description in
  the English file. Then run `flutter gen-l10n`.
- `test/core/domain/batch/batch_action_rules_test.dart` — test that every action
  appears exactly once across the two lists, and that the quick list is in the
  expected order.

## Notes

- The new Sanskrit word "अधिकम्" needs the owner's review, like all new Sanskrit.
- Downside: the less-used actions now take one more tap. That is the trade-off for
  making Delete and Transfer one tap away.
- Security impact: none. No permissions, storage, network or platform files change.
