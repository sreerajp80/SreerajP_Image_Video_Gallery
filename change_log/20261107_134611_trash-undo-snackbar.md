# Change log — Undo bar that cannot be pressed by mistake, and Undo for selection trash

Implements: `plans/20261107_133128_trash-undo-snackbar.md`

## What changed for the user

- **Viewer "Moved to trash · Undo" bar** now hides itself after the usual 4 seconds. Before, it
  stayed until tapped (Flutter keeps a snackbar with an action on screen by default).
- **Opening a photo clears any leftover bar.** The old bar used to follow into the next viewer and
  sit over its Delete button, so a tap meant for Delete could press Undo.
- **Trash from the selection bar** now shows "N items moved to trash · Undo" instead of the
  "Finished" sheet, when every item was trashed without a problem. Undo puts back exactly those
  items. If anything failed or was skipped, the "Finished" sheet still shows.
- The delete choice sheet says "restore **it**" for one item and "restore **them**" for several.

## Security impact

None. No permission, storage, network or dependency change.

## Files

- `lib/screens/viewer/media_viewer_screen.dart` — `initState` hides a leftover snackbar after the
  first frame; the trash snackbar has `persist: false`.
- `lib/widgets/batch/batch_action_bar.dart` — Undo snackbar after a clean trash batch. The Undo
  callback uses the provider container, because the bar itself unmounts once the selection is
  cleared.
- `lib/providers/trash_providers.dart` — new `TrashController.restoreItems(ids)`.
- `lib/widgets/common/delete_choice_sheet.dart` — passes the count to the trash line.
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ generated) — new `bodyBatchTrashSuccess`
  (plural); `bodyDeleteChoiceTrash` now takes `count` (Malayalam and Sanskrit keep their text in
  both forms, as they do not name the item).
- Tests: `test/screens/viewer/media_viewer_screen_test.dart` (leftover bar cleared on open),
  `test/widgets/batch/batch_action_bar_test.dart` (clean trash shows Undo bar that does not
  persist, and Undo restores the ids; a failed trash shows no bar),
  `test/providers/trash_providers_test.dart` (`restoreItems` restores only the given ids),
  `test/widgets/common/delete_choice_sheet_test.dart` ("it" / "them").

## Checks

- `flutter gen-l10n`, `dart format`, `flutter analyze` — no issues.
- `flutter test` — all 2293 tests pass.
- Dev build installed on the emulator (Android API 37):
  - Viewer trash: bar shows, then hides by itself within 6 seconds. Pass.
  - Viewer trash, then open the next photo at once: the bar is cleared; Delete is not covered.
    Pass.
  - Selection trash: "1 item moved to trash · Undo" instead of the "Finished" sheet; Undo brings
    the photo back. Pass.
- Gradle daemons stopped afterwards; none left.

## Note

- In one emulator run, Undo was tapped about 4 seconds after the bar appeared, just as it was
  closing, and the tap did nothing. That is the expected cost of a bar that hides itself. The
  item stays in the trash and can be restored from the Trash screen.
- New Malayalam and Sanskrit text (`bodyBatchTrashSuccess`) needs the owner's review.
