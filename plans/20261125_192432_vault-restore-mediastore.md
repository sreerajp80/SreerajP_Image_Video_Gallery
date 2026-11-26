# Plan — Make vault Restore work on Android 10+ (through MediaStore)

**Status:** completed

## The issue

On the test phone (Android 10) on 2026-11-25, restoring two vault items wrote nothing, and
both stayed in the vault. The message said "Nothing could be moved to the vault".

**Cause.** `VaultExportService._exportOne` writes the decrypted file straight to its old path
with plain file I/O (`OutputNamingService.saveBytes`, or `_copyStreamed` for videos), e.g.
`/storage/emulated/0/Pictures/…`. The app targets SDK 36 and does not ask for legacy storage;
`appops` on the phone shows `LEGACY_STORAGE: ignore`. On Android 10 that means scoped storage:
an app cannot create files in shared folders with file paths, only through MediaStore. So
every restore fails on Android 10. On Android 11 and later, path writes into Pictures and DCIM
are sometimes allowed, but MediaStore is the supported route there too. (I am confident about
the Android 10 rule; the exact exception will be checked on the phone after the fix.)

This matters now: **the owner's real vault is on an Android 10 phone**, and Restore is the only
way to take a second copy out before updating (the app's Backup does not include the vault).

Two smaller problems in the same flow:

1. **Wrong messages.** `VaultScreen` uses the *import* strings for every vault batch result. A
   restore or delete-for-good is reported as "… moved to the vault" or "Nothing could be moved
   to the vault".
2. **The folder question is mostly unneeded.** When the original folder is gone, the app asks
   the user to pick one (Storage Access Framework). MediaStore can simply re-create an allowed
   folder such as `DCIM/Camera`.

## The fix

### 1. Restore through MediaStore on Android 10+ (Kotlin)

New vault channel method `restoreToGallery(sourcePath, iv, format, keysetPath, displayName,
mimeType, isVideo, relativePath)`:

1. Insert a MediaStore row in `relativePath`, with `IS_PENDING = 1`, so no other app sees a
   half-written file. MediaStore gives the file a new name if one is taken; nothing is ever
   overwritten.
2. Decrypt the payload **straight into that row's output stream** (format 1 or 2). The
   plaintext never lands in the app's own storage, not even as a working file. SHA-256 runs
   over it on the way.
3. **Read back:** open the new file, hash it, and compare. This follows the read-back rule from
   [plans/20261125_115802_vault-write-verification.md](20261125_115802_vault-write-verification.md):
   the vault copy is only shredded after the restored copy is proven.
4. Set `IS_PENDING = 0` and return `{uri, path}`.
5. On any failure, delete the pending row and throw. The item stays in the vault.

On Android 9 and older (no `RELATIVE_PATH`), the method answers "not supported" without
writing anything, and Dart keeps today's path-based route, which those versions allow.

The pending-row code that `publishFile` already uses (insert with ghost recovery, resolve the
path) is moved into a small shared Kotlin helper (`MediaStoreWriter`) used by both handlers.
`publishFile` behaves exactly as before.

### 2. Where the file goes (pure Dart rule, checked again in Kotlin)

New `RestoreTargetRules.relativePathFor(originalPath, isVideo)` in
`lib/core/domain/vault/`:

- Take the original folder relative to the primary storage root
  (`/storage/emulated/0/` or `/sdcard/`).
- Keep it when MediaStore allows it: photos under `DCIM/` or `Pictures/`; videos under `DCIM/`,
  `Movies/` or `Pictures/`. Every folder name must be plain (not empty, not `.` or `..`, no
  hidden name), with at most 4 levels.
- Otherwise (for example `Download/…`, another app's `Android/media/…`, an SD card, or no
  original path at all, as with items from a phone move) use **`Pictures/Drishya Restored`**.

On Android 10+ the "original folder is missing, pick a folder" question is no longer asked: an
allowed folder is re-created, and anything else goes to `Pictures/Drishya Restored`. The
message says when that happened. On Android 9 and older the question stays as it is.

### 3. Messages

`VaultScreen` remembers which batch it started (restore or delete-for-good) and picks that
action's strings. New strings in en, ml and sa:

| Key | English |
|---|---|
| `bodyVaultRestoreDone` | "{count} restored to the gallery" (plural) |
| `bodyVaultRestorePartial` | "{done} restored, {failed} could not be restored" |
| `errorVaultRestoreFailed` | "Nothing could be restored" |
| `bodyVaultRestoredElsewhere` | "{count} went to Pictures/Drishya Restored" (plural), added when some did |
| `bodyVaultDeleteDone` | "{count} deleted for good" (plural) |
| `errorVaultDeleteFailed` | "Nothing could be deleted" |

The import messages stay for imports. New Sanskrit text needs the owner's review.

## Files to change

| File | Change |
|------|--------|
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreWriter.kt` | **New.** Shared pending-row helper (insert with ghost recovery, open, finish, abort, resolve path), moved out of `MediaStoreChannelHandler` |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt` | `publishThroughMediaStore` uses the helper; same behaviour |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt` | New `restoreToGallery` (decrypt into the pending row, hash, read back, finish); re-checks the relative path |
| `lib/core/domain/vault/restore_target_rules.dart` | **New.** Pure rule above |
| `lib/services/vault/vault_channel.dart` | `restoreToGallery()`; result `{uri, path}` or "not supported" |
| `lib/services/vault/vault_crypto_service.dart` | `restoreToGallery(item, displayName, relativePath)` |
| `lib/services/vault/vault_export_service.dart` | Android 10+: MediaStore route and target rule, no folder question; Android 9-: today's route; result counts how many went to the fallback folder |
| `lib/models/vault/vault_import_result.dart` | `VaultBatchResult.fallbackCount` |
| `lib/providers/vault_providers.dart` | `findItemsWithMissingFolder` returns nothing on Android 10+ (decided by the export service) |
| `lib/screens/vault/vault_screen.dart` | Per-action messages; "went to Pictures/Drishya Restored" line |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ `flutter gen-l10n`) | 6 new keys |
| `test/core/domain/vault/restore_target_rules_test.dart` | **New.** DCIM/Pictures kept; Movies kept for video only; Download, Android/media, SD card, `..`, hidden, too deep and empty paths fall back |
| `test/services/vault/fake_vault_channel.dart` | Fake `restoreToGallery`, plus a "not supported" switch |
| `test/services/vault/vault_export_service_test.dart` | MediaStore route used and the vault copy shredded only after success; a failed restore keeps the item; the fallback is counted; old route when not supported |
| `test/screens/vault/…` | Restore and delete show their own messages |
| `docs/security.md` | §5 / §6.3: restore writes through MediaStore with `IS_PENDING` and read-back; no plaintext working file for restores on Android 10+ |

No new permission, package or database change.

## Security impact

Touches storage and the platform folder. Restore now writes through MediaStore, the supported
scoped-storage route; no broad storage permission is added. The decrypted file is streamed into
a pending MediaStore entry that other apps cannot see until it is complete and checked. Before,
videos and picked-folder restores first went through a decrypted working file in app-private
storage; on Android 10+ that no longer happens. Folder names come from the item's own stored
path and are checked in both Dart and Kotlin, so nothing can be written outside DCIM, Pictures
or Movies.

## Checks after the change

- `dart format .`, `flutter gen-l10n`, `flutter analyze` (zero issues), `flutter test`.
- On the test phone (dev build): move two test photos in, then:
  - Restore both → they appear in their original folder, with SHA-256 equal to the files on
    the computer;
  - they leave the vault;
  - the message says "2 restored to the gallery".
- Restore an item whose folder is gone → it is re-created.
- Restore an item from an unusual folder → it goes to `Pictures/Drishya Restored`, and the
  message says so.
- Stop the Gradle daemons afterwards.
