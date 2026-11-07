# Plan — One Android prompt for a batch "Move to vault" with shred

**Status:** completed

## The issue

When several photos are selected and moved to the vault with "Shred the originals" on,
Android 11+ shows its "Allow this app to modify…" prompt once per photo.

The lower layers already batch correctly:

- `VaultImportService.importItems` collects every original and shreds them in one call at the end.
- On Android 11+, `MediaStoreChannelHandler.startWriteRequest` asks for all URIs in one
  `MediaStore.createWriteRequest`.

The problem is the caller. `GalleryBatchHandler.handle` runs once per item (the batch runner
drives it one file at a time for progress and Cancel), and for `moveToVault` it calls
`importItems([item], shredOriginals: ...)` with a one-item list. So every photo makes its own
shred call, and Android asks every time.

The prompt is Android's own system dialog, not ours. The app cannot hide or merge it after the
fact. The only way to get one prompt is to send all the files in **one** request.

## The fix

Keep the per-item import (so progress and Cancel still work), but move the shredding to the
end of the batch, in one call.

1. **`BatchItemHandler` gets an end hook.** Add
   `Future<void> finish(BatchAction action, List<MediaItem> succeeded)` with an empty default.
   `BatchRunnerService.run` calls it once after the per-item loop, with the items that succeeded
   (also when the user pressed Cancel — the items already moved still had shred chosen). A
   failure inside `finish` is logged and does not undo the import; it is reported in
   `firstError` so the user sees that the shred did not finish.
2. **`VaultImportService` exposes the shred step.** Make the private `_shredOriginals` a public
   `shredOriginals(List<MediaItem> items, {int? passes})`. `importItems` keeps using it, so the
   single-screen path does not change.
3. **`GalleryBatchHandler` uses both.** In `moveToVault`, call `importItems([item],
   shredOriginals: false)`. In `finish`, when the action is `moveToVault` and
   `options.shredOriginals` is true, call `shredOriginals(succeededItems)` once.

Safety order is kept: an original is only shredded after its encrypted copy and vault row are
saved, because only items that succeeded are passed to `finish`.

Android 10 still asks once per file. That is a limit of Android 10 itself (it has no batch
prompt), and the Kotlin code already says so.

## Files to change

- `lib/services/batch/batch_runner_service.dart` — add `finish` hook and call it after the loop.
- `lib/services/batch/gallery_batch_handler.dart` — import without shred per item, shred all in `finish`.
- `lib/services/vault/vault_import_service.dart` — make the shred step public.
- `test/services/batch/batch_runner_service_test.dart` — `finish` is called once, with only the
  succeeded items, and also after Cancel.
- `test/services/vault/vault_import_service_test.dart` — `shredOriginals` sends all items in one
  MediaStore call.
- `change_log/<timestamp>_batch-vault-single-shred-prompt.md` — new change log.

No ARB, Kotlin, manifest or dependency changes.

## Security impact

Touches the shred of public originals (storage). No new permission, no new prompt type. The
originals are still only shredded after a successful import and after the user's own confirm.

## Not in this plan (found while reading)

The batch path does not pass the user's "Shred passes" setting, so a batch shred always uses the
default of 2 passes. Fixing that needs the setting passed through `BatchOptions`. Kept out unless
the owner asks for it.

## Checks

- `dart format .`, `flutter analyze`, `flutter test`.
- On a device with Android 11+: select 3+ photos, Move to vault, shred on → one prompt.
