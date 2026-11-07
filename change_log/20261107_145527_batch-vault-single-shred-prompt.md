# Change log — One Android prompt for a batch "Move to vault" with shred

Implements `plans/20261107_145031_batch-vault-single-shred-prompt.md`.

## What was wrong

A batch "Move to vault" with "Shred the originals" called the vault import service once per
photo, each time with a one-item list. So each photo made its own shred request, and Android 11+
showed its "Allow this app to modify…" prompt once per photo.

## What changed

- `lib/services/batch/batch_runner_service.dart`
  - `BatchItemHandler` has a new `finish(action, succeeded)` hook. It does nothing by default.
  - The runner calls it once after the per-item loop, with only the items that succeeded. It
    also runs after Cancel, for the items already done. It is skipped when nothing succeeded.
  - If `finish` throws, the error is logged and shown as the batch's `firstError`. The items
    already done stay counted as done.
- `lib/services/vault/vault_import_service.dart`
  - The shred step is now public: `shredOriginals(items, {passes})`. It returns 0 at once for an
    empty list. `importItems` uses it as before, so the vault screen path does not change.
- `lib/services/batch/gallery_batch_handler.dart`
  - `moveToVault` imports each photo with no shred.
  - `finish` shreds every original the vault took, in one call, when the user chose shred.
    Only items whose encrypted copy and vault row are saved reach it.

## Tests

- `test/services/batch/batch_runner_service_test.dart`: new "the end step" group. `finish` runs
  once with only the succeeded items, still runs after Cancel, does not run when nothing
  succeeded, and a failure in it is reported without losing the done items.
- `test/services/vault/vault_import_service_test.dart`: photos imported one by one are shredded
  in a single MediaStore call with the given passes; an empty list makes no call.

## Checks

- `dart format`: no changes needed.
- `flutter analyze`: no issues.
- `flutter test`: all 2299 pass. In the first full run, one older test failed once
  (`vault_crypto_service_test.dart`, "the payload on disk is not the plain bytes"). It passed 3
  times out of 3 on its own and in a second full run. This change does not touch that code, so
  it looks flaky. Worth a look later.
- Not yet checked on a device. To check: on Android 11+, select 3 or more photos, Move to vault
  with shred on, and expect one prompt.

## Not changed

- Android 10 still asks once per file. Android 10 has no batch prompt.
- The batch path still ignores the user's "Shred passes" setting and uses the default of 2.
  This was left out of the plan on purpose.
