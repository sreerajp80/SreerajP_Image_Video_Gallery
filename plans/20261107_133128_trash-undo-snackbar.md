# Plan — Undo bar that cannot be pressed by mistake, and Undo for selection trash

**Status:** completed

Follows `plans/20261107_122146_delete-choice-and-secure-delete.md`. Found during the emulator
check written up in `change_log/20261107_124324_delete-choice-and-secure-delete.md`.

## The issues

1. **The viewer's "Moved to trash · Undo" bar never goes away by itself.** In the Flutter version
   this project uses, a `SnackBar` with an action button has `persist` on by default, so it stays
   until it is tapped or swiped. After "Move to trash" the viewer closes and the bar stays on the
   timeline. When the next photo is opened, the bar follows into the viewer and its **Undo** sits
   exactly over the viewer's **Delete** button. A tap meant for Delete presses Undo, and the
   previous photo quietly comes back out of the trash. This happened during testing.
2. **Trash from the selection bar has no Undo.** It runs as a batch and ends with the
   "Finished · 1 file done" sheet. The viewer offers Undo for the same action, so the two paths
   behave differently.
3. **Wording.** The delete choice sheet says "You can restore **it** from the trash" even when
   several items are selected.

There is only one `SnackBarAction` in the app (the viewer's), so issue 1 has one source.

## The fix

### 1. Viewer Undo bar (`lib/screens/viewer/media_viewer_screen.dart`)

- Give the "Moved to trash" snackbar `persist: false`, so it hides itself after the normal
  4 seconds, like any other snackbar. Long enough to change your mind; not long enough to get in
  the way.
- When the viewer opens, hide any snackbar still showing
  (`ScaffoldMessenger.of(context).hideCurrentSnackBar()`, after the first frame). Even 4 seconds
  is enough to open the next photo and tap Delete; this makes sure no leftover bar can ever sit
  over the viewer's buttons.

Both are needed: hiding by time alone leaves a short window; clearing on open alone leaves the bar
stuck on the timeline forever.

### 2. Undo for trash from the selection bar (`lib/widgets/batch/batch_action_bar.dart`)

- After a "Move to trash" batch, when every item succeeded (none failed, none skipped, not
  cancelled), skip the "Finished" sheet and show a snackbar instead:
  "{count} moved to trash" with **Undo**, `persist: false`.
- **Undo** puts exactly the items that were trashed back (`succeededIds`).
- If anything failed or was skipped, keep showing the "Finished" sheet as today, so a problem is
  never hidden behind a short snackbar.
- New `TrashController.restoreItems(List<String> ids)` in `lib/providers/trash_providers.dart`:
  restores each, then refreshes the trash, album and timeline lists once.

### 3. Wording (`bodyDeleteChoiceTrash`)

- Make it count-aware: "You can restore it from the trash." for one item, "You can restore them
  from the trash." for several. The sheet already knows the count.
- Malayalam and Sanskrit lines do not name the item today, so both forms keep their current text.

### New and changed strings (all three languages)

- `bodyBatchTrashSuccess(count)` — new: "{count, plural, =1{1 item moved to trash} other{{count}
  items moved to trash}}", with Malayalam and Sanskrit.
- `bodyDeleteChoiceTrash` — gains a `count` placeholder (see 3).
- Reuses the existing `actionViewerTrashUndo` ("Undo").

## Files to change

| File | Change |
|------|--------|
| `lib/screens/viewer/media_viewer_screen.dart` | `persist: false`; hide leftover snackbar when the viewer opens |
| `lib/widgets/batch/batch_action_bar.dart` | Snackbar with Undo after a clean trash batch |
| `lib/providers/trash_providers.dart` | `restoreItems(ids)` |
| `lib/widgets/common/delete_choice_sheet.dart` | Pass the count to `bodyDeleteChoiceTrash` |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ `flutter gen-l10n`) | Strings above |
| `test/providers/trash_providers_test.dart` | `restoreItems` restores only the given ids |
| `test/widgets/common/delete_choice_sheet_test.dart` | "it" / "them" wording |
| `test/widgets/batch/batch_action_bar_test.dart` | Clean trash batch shows Undo snackbar, not the sheet (if the existing test setup allows; otherwise noted) |
| `test/screens/viewer/media_viewer_screen_test.dart` | A leftover snackbar is hidden when the viewer opens |

## Security impact

None. No permissions, storage, network or dependency change. Undo only clears the trash flag on
rows the user just trashed.

## Check after implementing

`flutter gen-l10n`, `dart format .`, `flutter analyze`, `flutter test`. Then a build and an
emulator re-check of: viewer trash → open next photo → the bar is gone; selection trash → Undo
bar → Undo brings the items back.
