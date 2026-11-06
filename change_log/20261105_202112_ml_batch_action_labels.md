# Shorter Malayalam labels for the batch action bar

Implements plan: `plans/20261105_201735_ml_batch_action_labels.md`

## What changed

In `lib/l10n/app_ml.arb`, five values were made shorter so they fit the action bar:

| Key | New text |
|-----|----------|
| `bodyBatchActionTransfer` | ഉപകരണത്തിലേക്ക് അയക്കുക |
| `labelBatchActionFavourite` | പ്രിയപ്പെട്ടതാക്കുക |
| `labelBatchActionAddToAlbum` | ആൽബത്തിലാക്കുക |
| `titleBatchActionMoveToTrash` | കളയുക |
| `bodyBatchActionUnfavourite` | പ്രിയപ്പെട്ടതല്ലാതാക്കുക |

`lib/l10n/generated/app_localizations_ml.dart` was regenerated with `flutter gen-l10n`.

`titleBatchActionMoveToTrash` is also used in the photo viewer (bottom bar, top menu, and the
confirm button of the move-to-trash dialog), so those now show "കളയുക" too.

No English or Sanskrit text changed. No keys were added or removed.

## Checks

- `flutter analyze`: no issues.
- `flutter test`: all tests passed.
