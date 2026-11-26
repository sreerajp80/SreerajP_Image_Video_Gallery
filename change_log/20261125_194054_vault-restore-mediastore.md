# Change log — Make vault Restore work on Android 10+ (through MediaStore)

Implements: [plans/20261125_192432_vault-restore-mediastore.md](../plans/20261125_192432_vault-restore-mediastore.md)

## What changed

### Kotlin

- **New** `media/MediaStoreWriter.kt`: the pending-row code moved out of
  `MediaStoreChannelHandler`, namely:
  - insert with Android 10 ghost recovery;
  - rescan of missing files;
  - path lookup.

  It also adds `insertPending`, `finish`, `abort` and `isAllowedRelativePath` (photos: DCIM
  or Pictures; videos: also Movies; at most 4 plain levels).
- `MediaStoreChannelHandler.kt`: its `insertWithGhostRecovery`, `rescanMissing` and
  `resolvePath` now call the shared writer. `publishFile` and the ghost clean-up behave as
  before.
- `vault/VaultChannelHandler.kt`:
  - New `restoreToGallery`. On Android 10+ it inserts a pending MediaStore row in the checked
    folder, and decrypts the payload straight into it (format 1 or 2) while hashing. It then
    reads the new file back and compares SHA-256 and length, and only then sets
    `IS_PENDING = 0`. On any failure it deletes the row. On Android 9 and older it answers
    `supported: false` and writes nothing.
  - New `canRestoreToGallery`.

### Dart

- **New** `lib/core/domain/vault/restore_target_rules.dart`. It keeps the original folder
  when MediaStore allows it, and otherwise uses `Pictures/Drishya Restored`.
- `vault_channel.dart` and `vault_crypto_service.dart`: `canRestoreToGallery()` and
  `restoreToGallery()`.
- `vault_export_service.dart`:
  - On Android 10+ every item goes through MediaStore, and the vault copy is shredded only
    after that succeeds.
  - Items that went to the fallback folder are counted.
  - `itemsWithMissingFolder` is now async, and empty on Android 10+, so the folder question
    is no longer asked there.
  - The restored name is `<original>_vault.<ext>`.
  - Android 9 and older: unchanged route.
- `vault_import_result.dart`: `VaultBatchResult.fallbackCount`.
- `vault_repository.dart` and `vault_providers.dart`: the async `itemsWithMissingFolder`.
- `vault_screen.dart`:
  - It remembers which batch it started (import, restore or delete) and shows that action's
    message.
  - A restore adds "N went to Pictures/Drishya Restored." when it applies.
- Strings in en, ml and sa: `bodyVaultRestoreDone`, `bodyVaultRestorePartial`,
  `errorVaultRestoreFailed`, `bodyVaultRestoredElsewhere`, `bodyVaultDeleteDone`,
  `errorVaultDeleteFailed`, plus **`bodyVaultDeletePartial`**. The last one is not in the
  plan: without it, a partly failed delete would have been reported as a full success. **New
  Sanskrit text needs the owner's review.**

### Tests

- **New** `restore_target_rules_test.dart` (11 tests).
- Export service, new group "on Android 10+":
  - an item goes back to `DCIM/Camera` with the same bytes, and the vault copy is gone;
  - a `Download/` original goes to the fallback and is counted;
  - a failed restore keeps the item and its payload;
  - no folder question is asked.
- **New** `vault_screen_messages_test.dart`: restore, restore with fallback, failed restore,
  and delete each show their own message.
- The test helper now joins Android-style paths with `/`, so tests behave the same on Windows.
- Existing tests updated for the async folder check.

### Docs

`docs/security.md`: new §6.4 "Restoring out of the vault".

## Checks

- `dart format`: no changes.
- `flutter analyze`: no issues.
- `flutter test`: all 2599 passed.

### Phone test (2026-11-25)

Dev build on the test phone (Android 10). Commands targeted it by serial: two other phones
were connected during the test, and they were not touched.

1. Multi-select "Move to vault" with the vault locked showed the PIN gate. After unlocking it
   came back to "1 photo will be moved into the vault" and finished. The test phone was
   unplugged once mid-test; after reconnecting, the interrupted move had not happened, and it
   was repeated.
2. The vault held 3 items:
   - two photos whose original folder `Pictures/DrishyaVaultTest` had been deleted;
   - one photo from `Download/`.
3. Selected all 3 and restored them. **No folder question** was asked. The message read: "3
   items restored to the gallery 1 went to Pictures/Drishya Restored." The vault was then
   empty.
4. Files on the phone:
   - `Pictures/DrishyaVaultTest/vault_small_vault.jpg` and `vault_test_1_vault.jpg` (folder
     re-created);
   - `Pictures/Drishya Restored/dl_test_vault.jpg`.

   **All three SHA-256 values equal the original files.** MediaStore lists all three with
   `is_pending=0`.
5. Test files removed through MediaStore (no Android 10 ghost rows left), and folders deleted.

The exact exception the old route threw on Android 10 was not captured (the app logs to the
Dart developer log, not logcat). The new route works on the same phone, which supports the
scoped-storage explanation.

## Security impact

- Restores write through MediaStore. No storage permission was added.
- The decrypted bytes go straight into a pending entry that other apps cannot see. They are
  read back before the entry is made visible and before the vault copy is shredded.
- On Android 10+ no decrypted working file is made for a restore any more.
- Folder names from stored records are checked in Dart and in Kotlin, and can only point into
  DCIM, Pictures or Movies.
