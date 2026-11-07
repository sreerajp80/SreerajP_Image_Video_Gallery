# Plan — Ask for a folder when a vault item's original folder is gone

**Status:** completed

## The issue

When a photo or video is restored out of the vault, the app writes it back into the folder it
came from. If that folder no longer exists, `_restoreSeedPath` in
`lib/services/vault/vault_export_service.dart` returns **only the file name, with no folder**.
Dart then writes the file into the process's current folder:

- On a phone this is usually `/`, which the app cannot write to. The restore fails, and the user
  is not told why. The item stays in the vault.
- In tests it is the repository root. The test "falls back when the original folder no longer
  exists" leaves one `photo_vault*.jpg` there on every `flutter test` run (49 were found and
  deleted on 2026-11-07).
- The test passes anyway, because it checks only the success count, not where the file went.

The owner chose this fix: **tell the user, and ask them to pick a folder.** The app will not
re-create the old folder by itself, because the user may have deleted it on purpose.

## How it will work for the user

1. The user selects items in the vault and taps Restore, then confirms (as today).
2. The app checks each item's original folder. If all exist, the restore runs as today.
3. If some are missing, a dialog says: "*N* items can't go back to their old folder, because it
   no longer exists. Choose a folder for them." Buttons: **Choose folder** and **Skip these**.
4. **Choose folder** opens Android's own folder picker. The missing-folder items are written
   into the chosen folder. All other items go back to their old folders as usual.
5. **Skip these**, or backing out of the picker, restores only the items whose folder exists.
   The rest stay safely in the vault.
6. The result message says how many were restored and how many stayed in the vault.

## Design

**Android side (Kotlin), in the existing `DocumentPickerChannelHandler`:**

- `openFolder`: opens `ACTION_OPEN_DOCUMENT_TREE` and returns the folder link (a `content://`
  tree URI). The grant is **not** kept after use (no `takePersistableUriPermission`), the same
  rule the backup picker follows.
- `writeToFolder(treeUri, displayName, mimeType, sourcePath)`: creates a new document in that
  folder with `DocumentsContract.createDocument` and copies the file into it. Android gives a
  new name such as `photo (1).jpg` if one already exists, so **nothing is ever overwritten**
  (hard rule 4). If the copy fails part way, the half-written document is deleted.
- `sourcePath` is accepted only if it is inside the app's own vault working folder. This stops
  the method from being used as a general "copy any file anywhere" tool.
- After writing, the app asks Android to add the file to the media index where it can, so it shows
  up in the gallery. To check on a phone: Android 9 and Android 14.

**Dart side:**

- `VaultExportService`:
  - `_restoreSeedPath` returns `null` when the folder is gone. The bare-file-name fallback is
    removed.
  - New `itemsWithMissingFolder(items)`: a simple check, no writing.
  - `exportItems` gets an optional `fallbackFolderUri`. For an item with no folder:
    - with a folder link: decrypt into the vault working folder, call `writeToFolder`, then shred
      the working file whatever happened. Then shred the payload and drop the row, as today.
    - without one: skip the item. It stays in the vault and is counted as **skipped**.
  - The writer is injected through a small interface, so tests use a fake.
- `VaultBatchResult`: new `skippedCount` field, so "stayed in the vault on purpose" is not
  reported as a failure.
- `VaultRepository.exportToGallery` and `VaultBatchController.restore`: pass `fallbackFolderUri`
  through. The controller gets a `findItemsWithMissingFolder` method, so the screen never calls the
  repository itself.
- `DocumentPickerChannel` (Dart): new `openFolder()` and `writeToFolder(...)` methods.
- `vault_screen.dart` `_restoreSelected`: after the confirm, asks the controller for missing-folder
  items, shows the dialog, opens the picker through the provider, then calls `restore`.
- Result message: adds the "stayed in the vault" count.

## Files to change

| File | Change |
| --- | --- |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/backup/DocumentPickerChannelHandler.kt` | Add `openFolder` and `writeToFolder`, path check, media index request |
| `lib/services/backup/document_picker_channel.dart` | Add `openFolder` and `writeToFolder` |
| `lib/services/vault/vault_export_service.dart` | Remove bare-name fallback; add `itemsWithMissingFolder`, `fallbackFolderUri`, skip path, folder writer |
| `lib/models/vault/vault_import_result.dart` | Add `skippedCount` to `VaultBatchResult` |
| `lib/repositories/vault_repository.dart` | Pass `fallbackFolderUri`; add missing-folder check |
| `lib/providers/vault_providers.dart` | `restore(..., fallbackFolderUri)`, `findItemsWithMissingFolder`; wire the folder writer |
| `lib/screens/vault/vault_screen.dart` | Missing-folder dialog, picker, then restore; result message shows skipped count |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` | New keys: dialog title, dialog body (with count), "Choose folder", "Skip these", "stayed in the vault" message. `@` descriptions in `app_en.arb` |
| `test/services/vault/vault_export_service_test.dart` | Replace the fallback test (see Tests) |
| `test/providers/vault_providers_test.dart` | Missing-folder detection and `fallbackFolderUri` pass-through |
| `test/services/vault/fake_vault_folder_writer.dart` (new) | Fake folder writer for tests |
| `docs/security.md` | Add the folder picker to the Storage Access Framework section: one-time grant, source-path check, no overwrite |
| `docs/architecture.md` | One line on the restore fallback flow |

No new permission, no manifest change, no new package, no submodule change.

## Tests

- Folder gone, no folder link given: item **stays in the vault**, counted as skipped, and **no new
  file appears in the current folder** (this is the check the old test was missing).
- Folder gone, folder link given: the fake writer receives the right name and type. Payload is
  shredded, row dropped.
- Fake writer fails: item stays in the vault, working file is shredded.
- Mixed batch: items with folders restore normally, the rest go to the chosen folder.
- `itemsWithMissingFolder` returns only the right items.
- `flutter analyze` clean, `flutter test` passes, `flutter gen-l10n` run after ARB edits.
- Manual on a phone (dev flavor): vault a photo from a test folder, delete the folder, restore,
  pick a folder, and check the photo shows in the gallery. Also try "Skip these" and backing out.

## Security impact

Storage and platform folder change. Uses the Storage Access Framework only: no new permission,
the folder grant is one-time and not kept, the app sees only the folder the user picked, and
existing files are never overwritten. `writeToFolder` accepts source files only from the app's
own vault working folder. Decrypted data exists only in app-private storage until it is copied
into the folder the user chose, and the working copy is shredded afterwards. No network change.

## Language note

The new Sanskrit strings need the owner's review before release, like all new Sanskrit text.
