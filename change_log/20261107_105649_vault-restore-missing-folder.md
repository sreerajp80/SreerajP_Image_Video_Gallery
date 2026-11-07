# Change log — Ask for a folder when a vault item's original folder is gone

Implements plan: `plans/20261107_104651_vault-restore-missing-folder.md`

## What changed

When a vault item's original folder no longer exists, the restore no longer writes the file with
a bare name (which landed in the process's current folder: `/` on a phone, the repository root in
tests). The user is now told, and asked to pick a folder or skip. A skipped item stays in the
vault.

| File | Change |
| --- | --- |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/backup/DocumentPickerChannelHandler.kt` | New `openFolder` (`ACTION_OPEN_DOCUMENT_TREE`, grant not persisted) and `writeToFolder` (always creates a new document, deletes a half-written one, accepts only a `.dec` working file directly inside the vault folder, runs off the main thread, asks the media scanner to index files on primary storage) |
| `lib/services/backup/document_picker_channel.dart` | Dart `openFolder()` and `writeToFolder(...)` |
| `lib/services/vault/vault_export_service.dart` | Bare-name fallback removed; `_restoreSeedPath` returns null when the folder is gone. New `VaultFolderWriter` interface and `DocumentPickerFolderWriter`, `itemsWithMissingFolder`, `fallbackFolderUri` on `exportItems`, skip path, and a picked-folder path that decrypts to a working file, copies it out and shreds it |
| `lib/models/vault/vault_import_result.dart` | New `skippedCount` |
| `lib/repositories/vault_repository.dart` | `itemsWithMissingFolder`; `fallbackFolderUri` passed through |
| `lib/providers/vault_providers.dart` | Folder writer wired in; `VaultBatchController` gets `findItemsWithMissingFolder`, `pickRestoreFolder` (a device with no picker gives null, like Skip) and `restore(..., fallbackFolderUri)` |
| `lib/screens/vault/vault_screen.dart` | "Folder not found" dialog (Choose folder / Skip), then the picker, then the restore; result message shows how many stayed in the vault |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ generated files) | 6 new keys: `titleVaultFolderMissing`, `bodyVaultFolderMissing`, `actionVaultChooseFolder`, `actionVaultSkip`, `bodyVaultRestoreSkipped`, `bodyVaultRestoreSkippedFailed` |
| `test/services/vault/vault_export_service_test.dart` | Old "falls back" test replaced by 5 tests: missing-folder listing, skip (and nothing new in the current folder), picked folder, failed folder write, mixed batch |
| `test/services/vault/fake_vault_folder_writer.dart` (new) | Fake folder writer |
| `test/providers/vault_providers_test.dart` | 4 tests for the controller's new methods |
| `docs/security.md` §14.6 | Vault restore into a picked folder |
| `docs/architecture.md` | `documents` channel row; `vault_providers.dart` size row (~550 lines) |

One small change from the plan: the copy in `writeToFolder` runs on a background thread, so a
large video does not freeze the app.

## Checks

- `flutter gen-l10n`, `dart format` (0 changed), `flutter analyze` (no issues).
- `flutter test`: all 2,234 tests pass. No `photo_vault*` file appears in the repository root
  after the run.

## Not done yet

- The Kotlin code has not been compiled or run. It needs a dev build and the manual phone check
  from the plan: vault a photo from a test folder, delete that folder, restore, pick a folder,
  and check the photo shows in the gallery. Also try Skip and backing out. Check on an old
  Android (9) and a new one (14).
- The new Sanskrit strings need the owner's review.
