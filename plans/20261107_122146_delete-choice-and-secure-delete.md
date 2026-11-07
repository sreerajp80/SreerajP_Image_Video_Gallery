# Plan — Delete choice (trash or permanent) and secure delete

**Status:** completed

## What the user asked for

1. Deleting should offer a choice: **move to trash** or **delete permanently**.
2. A setting, **Secure delete**. When it is on, every permanent delete and every delete
   from the trash writes over the file before removing it, so undelete tools cannot get it back.
3. Every delete from the vault is always permanent and secure. No setting can change this.

Design agreed with the user: **one Delete button that opens a choice** (not two buttons, not a
default in Settings).

## How it works today

- Gallery viewer and batch bar: the only delete is **Move to trash**. Trash is a database
  flag (`is_trash`); the file stays on the device.
- **Delete permanently** exists only inside the trash (one item, or Empty trash). It calls
  `MediaStoreChannel.deleteMedia`, which on Android 11+ shows Android's own delete dialog
  (`MediaStore.createDeleteRequest`).
- The vault's "delete forever" (`VaultExportService.deleteForever`) already shreds the
  encrypted file and its thumbnail every time, using `VaultShredderService`. There is no switch
  to turn this off. Pass count comes from vault settings (1 to 5).

## Problems found while reading the code

1. **Android 11+ (API 30+):** the app can read photos it did not create, but cannot write to
   them. Writing over a file first needs `MediaStore.createWriteRequest`: one system dialog,
   "Allow this app to modify these items?".
2. **Android 10 (API 29):** writing to a file the app did not create throws
   `RecoverableSecurityException`, and Android asks **once per file**. A batch of 20 photos
   means 20 dialogs. Android gives no batch option on this version.
3. **Android 7 to 9 (API 24–28):** writing to (and deleting) another app's file needs
   `WRITE_EXTERNAL_STORAGE`, which the manifest currently removes. So today's
   "Delete permanently" probably fails there without saying so: the native code returns
   `true` whatever happened. **Decision (user):** declare `WRITE_EXTERNAL_STORAGE` with
   `android:maxSdkVersion="28"`.
4. **Existing bug:** the vault import's "shred the original" (`VaultImportService.importItems`
   → `VaultShredderService.shred(item.path)`) opens the public file by plain path with
   `RandomAccessFile`. On Android 11+ the app has no write access to that file, so the
   overwrite fails, the plain `File.delete()` also fails, and the original stays. Fixed here
   by sending it through the new secure delete path (it already has the item's content URI).

## Security impact

- Adds one permission, `WRITE_EXTERNAL_STORAGE`, **only up to Android 9**
  (`maxSdkVersion="28"`). Declared permissions go 11 → 12, merged manifest 12 → 13. No effect
  on Android 10+, where scoped storage rules still apply (hard rule 3 holds: no broad storage
  access on modern Android).
- Adds one native method, `secureDeleteMedia`, that writes to media files. It only writes to
  the content URIs the user just chose to delete, and only after the user approves Android's
  write dialog (Android 10+).
- No network, no new package.
- Secure delete is honest about its limits: on flash storage, writing over a file defeats
  undelete tools, not laboratory recovery. The setting text says so, like the vault screen.

## The fix

### A. One Delete button that opens a choice

- New widget `showDeleteChoiceSheet(context, count)` in `lib/widgets/common/delete_choice_sheet.dart`.
  A bottom sheet with two rows:
  - **Move to trash** (first, safe, normal colour) — "You can restore it from the trash."
  - **Delete permanently** (red) — "Removed from the device. Cannot be undone." When Secure
    delete is on, adds "Securely overwritten first."
  - Returns an enum `DeleteChoice { trash, permanent }` or null (cancel).
- **Viewer** (`media_viewer_screen.dart`, `viewer_app_bar.dart`, `viewer_bottom_bar.dart`): the
  "Move to trash" button becomes **Delete** and opens the sheet. Trash → existing flow with
  undo snackbar. Permanent → existing `confirmViewerDeletePermanently` dialog (when
  "Confirm destructive actions" is on), then delete. Inside the trash, the viewer keeps its
  current Restore / Delete permanently buttons.
- **Batch bar** (`batch_action_bar.dart`): the "Move to trash" entry becomes **Delete** and
  opens the same sheet. New `BatchAction.deletePermanently`; `GalleryBatchHandler` runs it
  through the repository in one call (so Android shows one dialog for the whole batch on
  Android 11+).
- The duplicate cleaner's "Keep best and trash the rest" stays trash-only. It is a review
  flow, and the trash is its safety net. Not changed.

### B. Secure delete setting

- `AppSettings` gets `secureDelete` (bool, default **false**), with `copyWith`, JSON
  (`secureDelete`), equality, and `setSecureDelete` on the settings notifier.
- `SafetySettingsScreen` gets a second switch: **Secure delete**, subtitle explaining: writes
  over files before deleting; Android may ask for permission first; on flash storage it stops
  undelete tools, not a lab.
- Pass count: a new constant `AppConstants.secureDeletePasses` = the vault default
  (`vaultDefaultShredPasses`). Not user-adjustable in this change. (The vault keeps its own
  pass setting.)

### C. Secure delete in the native layer

New method `secureDeleteMedia(uris, paths, passes)` in `MediaStoreChannelHandler.kt`, returning
a map `{deleted: Int, overwritten: Int, failed: Int}`:

- **Android 11+:** one `createWriteRequest` for all URIs. On "Allow": for each URI open
  `contentResolver.openFileDescriptor(uri, "rw")`, write zero / random passes over its length,
  `fd.sync()` after each pass, truncate to 0, then `contentResolver.delete(uri)`. Any item
  whose delete is refused is collected and sent to one `createDeleteRequest` (only shown if
  needed). On "Deny": nothing is touched, returns all failed.
- **Android 10:** per item: try the overwrite; on `RecoverableSecurityException` launch its
  dialog, wait, retry once. Then delete.
- **Android 7–9:** path-based overwrite with `RandomAccessFile("rws")` (same loop as the vault
  shredder), delete the file, then delete the MediaStore row.
- An item whose overwrite fails but delete succeeds counts as `deleted` but not
  `overwritten`, so the app can say "deleted, but not securely".
- A second request code `WRITE_REQUEST_CODE` in `onActivityResult`.
- The overwrite loop is shared with `VaultChannelHandler.shredFile` by moving it into a small
  helper `media/SecureOverwrite.kt` (works on a `FileDescriptor` or a `File`).

Also fix in the existing `handleDeleteMedia`: on Android 7–9, return the real result instead
of always `true`. And request `WRITE_EXTERNAL_STORAGE` together with `READ_EXTERNAL_STORAGE`
on Android ≤ 9 (same permission group, so the user sees no extra dialog).

### D. Dart service, repository, providers

- `MediaStoreChannel.secureDeleteMedia(...)` → new immutable model
  `lib/models/media/media_delete_result.dart` (`deleted`, `overwritten`, `failed`).
- `MediaRepository.deletePermanently(items, {bool secure = false})` returns
  `MediaDeleteResult`. Only rows whose file is really gone are removed from the database.
- `TrashController.emptyTrash` / `deletePermanently` and the new viewer/batch permanent
  delete read `appSettingsProvider.secureDelete` and pass it on.
- Snackbar after a secure delete with `overwritten < deleted`: "N deleted, but could not be
  overwritten first."
- **Vault import "shred original"**: `VaultImportService` calls
  `MediaRepository.deletePermanently(..., secure: true)`-equivalent via the channel instead of
  `VaultShredderService.shred(item.path)`, so it works on Android 11+ (one write dialog for
  the batch).

### E. Vault — always secure, cannot be changed

No behaviour change needed: `deleteForever` already shreds every time. To lock it in:
- A test in `vault_export_service_test.dart` that `deleteForever` always calls the shredder,
  even when `shredPasses` is null or 0 (the clamp keeps it at least 1).
- A line in `docs/security.md`: vault delete is always a shred and must never become optional.

## Files to change

| File | Change |
|------|--------|
| `android/app/src/main/AndroidManifest.xml` | Declare `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="28"` (replace the `tools:node="remove"` entry) |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt` | `secureDeleteMedia`, write request code, honest ≤ 9 result, WRITE permission on ≤ 9 |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/SecureOverwrite.kt` | New — shared overwrite loop |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt` | Use the shared overwrite helper |
| `lib/core/constants/app_constants.dart` | `secureDeletePasses` |
| `lib/core/constants/app_permissions.dart` (if it lists permissions) | Add the new permission |
| `lib/models/settings/app_settings.dart` | `secureDelete` field |
| `lib/models/media/media_delete_result.dart` | New result model |
| `lib/models/batch/batch_action.dart` | `deletePermanently` |
| `lib/providers/settings_providers.dart` | `setSecureDelete` |
| `lib/providers/trash_providers.dart` | Pass `secure` |
| `lib/providers/viewer_providers.dart` | Permanent delete from the viewer |
| `lib/providers/batch_providers.dart` | Refresh after batch permanent delete |
| `lib/repositories/media_repository.dart` | `deletePermanently(..., secure:)` returning a result |
| `lib/services/media/media_store_channel.dart` | `secureDeleteMedia` |
| `lib/services/batch/gallery_batch_handler.dart` | Run `deletePermanently` |
| `lib/services/vault/vault_import_service.dart` | Shred originals through the channel (bug fix) |
| `lib/widgets/common/delete_choice_sheet.dart` | New choice sheet |
| `lib/widgets/viewer/viewer_app_bar.dart`, `viewer_bottom_bar.dart` | "Delete" opens the sheet |
| `lib/widgets/batch/batch_action_bar.dart` | "Delete" opens the sheet |
| `lib/screens/viewer/media_viewer_screen.dart` | Wire the choice |
| `lib/screens/trash/trash_screen.dart` | Show "not securely" snackbar |
| `lib/screens/settings/safety_settings_screen.dart` | Secure delete switch |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ `flutter gen-l10n`) | New strings: Delete, choice sheet rows, Secure delete title/desc, "not securely" error |
| Tests: `test/models/settings/app_settings_test.dart`, `test/repositories/media_repository_test.dart`, `test/providers/trash_providers_test.dart`, `test/services/vault/vault_export_service_test.dart`, `test/services/vault/vault_import_service_test.dart`, `test/core/constants/app_permissions_test.dart`, `test/screens/viewer/media_viewer_screen_test.dart`, new `test/widgets/common/delete_choice_sheet_test.dart`, batch handler test | Cover the above |
| `docs/security.md` | §11 permission table (12 declared, 13 merged), secure delete section, vault-always-shred rule |
| `docs/architecture.md` | Delete flow and new channel method |
| `CLAUDE.md` | Permission count line (11 → 12, merged 12 → 13) |

## Risks and honest notes

- **Android 10 batches** show one dialog per file. Android has no way around this.
- I am fairly (not fully) sure that on Android 11+ a write grant also lets the app delete
  without a second dialog. The plan handles both cases: if the delete is refused, one
  `createDeleteRequest` follows.
- Large videos take time to overwrite. The batch progress UI already exists; the viewer
  shows a spinner while it runs.
- New Sanskrit text needs the owner's review before release (as with G9).
- Must be tested on a real device for Android 9, 10 and 11+; host tests cannot reach the
  native side.

## Check after implementing

`dart format .`, `flutter gen-l10n`, `flutter analyze` (clean), `flutter test` (all pass).
Then a manual run on devices (user runs it).
