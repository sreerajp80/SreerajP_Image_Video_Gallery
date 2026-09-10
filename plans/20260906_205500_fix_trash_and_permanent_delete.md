# Plan: Fix Trash Sync and Implement Permanent File Deletion

**Status:** Approved

## Overview
This plan addresses two related issues:
1. **Trash and Album Out-of-Sync Glitches**:
   - Moving photos to trash (from single viewer, batch bar, or cleaner) does not notify `trashRevisionProvider`. Consequently, newly deleted items do not show up in the Trash screen until an app restart.
   - Emptying trash or changing trash status does not notify `albumRevisionProvider` or `smartAlbumsProvider`. As a result, the Albums screen continues showing the old cached count and thumbnail (e.g. "Trash 1 item") even after emptying.
2. **Permanent Storage Deletion**:
   - The app currently only removes SQLite rows when "Empty trash" is called, leaving the physical files on the device storage. A subsequent scan re-indexes them.
   - There is currently no native method to permanently delete files from Android storage via `MediaStore`.
   - We will implement native MediaStore file deletion (using `MediaStore.createDeleteRequest` on Android 11+ and `ContentResolver.delete` on older versions) with system confirmation, and provide a true "Delete permanently" option both per-item and when emptying trash.

---

## Issues

1. **Trash screen does not receive update signals on Move-to-Trash**:
   - `MediaViewerScreen._moveToTrash` and `BatchController` (`BatchAction.moveToTrash`) and `DuplicateKeepController.keepOnly` modify the database via `MediaRepository.setTrash()`, but do not increment `trashRevisionProvider` or `albumRevisionProvider`.
   - Therefore, `trashMediaProvider` and `trashCountProvider` remain stale, and items moved to trash do not appear on the Trash screen.

2. **Albums screen does not refresh when trash changes**:
   - `smartAlbumsProvider` watches `mediaScanControllerProvider` and `albumRevisionProvider`, but does not watch `trashRevisionProvider`.
   - Operations that alter trash (`TrashController.emptyTrash`, `restoreItem`, `restoreAll`, etc.) do not bump `albumRevisionProvider`.
   - Therefore, the "Trash" smart album card on the Albums screen retains stale counts and thumbnail images.

3. **No real permanent deletion from device storage**:
   - "Empty Trash" previously called `deleteAllTrashed()` in SQLite, leaving the physical files untouched on the device storage.
   - When the media scanner next runs, it detects the files and re-inserts them into the gallery.
   - Users have no way to permanently remove a file from their device storage from within the gallery app.

---

## Proposed Changes

### 1. Native Android Platform Channel
- **`android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`**:
  - Add method `deleteMedia` taking `uris: List<String>` and `paths: List<String>`.
  - For Android 11+ (API 30+): use `MediaStore.createDeleteRequest(activity.contentResolver, uris.map { Uri.parse(it) })` and start the sender via `activity.startIntentSenderForResult`.
  - For Android 10 (API 29): handle via `ContentResolver.delete()` and catch `RecoverableSecurityException` to launch the consent dialog.
  - For Android 9 and below: delete via `ContentResolver.delete()` and fallback to `File(path).delete()`.
  - Implement `onActivityResult` to return `true` on `Activity.RESULT_OK` and `false` otherwise.
- **`android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt`**:
  - Forward `onActivityResult` to `mediaStoreHandler`.

### 2. Media Store Service & Repository Layer
- **`lib/services/media/media_store_channel.dart`**:
  - Add `Future<bool> deleteMedia({required List<String> uris, required List<String> paths})` to `MediaStoreChannel` and `PlatformMediaStoreChannel`.
- **`lib/repositories/database/media_dao.dart`**:
  - Add `deleteMediaItem(String id)` and `deleteMediaItems(List<String> ids)` to remove specific rows from the media table and search index.
- **`lib/repositories/media_repository.dart`**:
  - Add `Future<bool> deletePermanently(List<MediaItem> items)`:
    - Calls `channel.deleteMedia(...)`.
    - Upon success, removes the corresponding rows from `_mediaDao`.
    - Bumps revision providers.

### 3. State & Providers
- **`lib/providers/trash_providers.dart`**:
  - Update `TrashController.emptyTrash` to permanently delete trashed items from storage using `mediaRepository.deletePermanently()`.
  - Add `TrashController.deletePermanently(MediaItem item)` for single-item permanent deletion.
  - Bump both `trashRevisionProvider` and `albumRevisionProvider` on any trash modification.
- **`lib/providers/album_providers.dart`**:
  - Add `ref.watch(trashRevisionProvider)` to `smartAlbumsProvider` so any trash change immediately invalidates the Trash album card.
- **`lib/providers/batch_providers.dart`**:
  - Bump `trashRevisionProvider` and `albumRevisionProvider` when `BatchAction.moveToTrash` runs.
- **`lib/providers/duplicate_providers.dart`**:
  - Bump `trashRevisionProvider` and `albumRevisionProvider` when duplicates are moved to trash.

### 4. UI Layer
- **`lib/screens/viewer/media_viewer_screen.dart`**:
  - Bump `trashRevisionProvider` and `albumRevisionProvider` when moving an item to trash or undoing it.
  - If the item is in trash (opened from Trash screen), present "Restore" and "Delete permanently" actions instead of normal viewer actions.
- **`lib/screens/trash/trash_screen.dart`**:
  - Update empty trash confirmation dialog to explain that files will be permanently deleted from device storage.
  - Add tile interaction: tapping or long-pressing an item in the trash grid displays a bottom sheet or dialog offering:
    - **Restore** (moves back to gallery)
    - **Delete permanently** (deletes from device storage with confirmation)
- **`lib/l10n/app_en.arb` & `lib/l10n/app_ml.arb`**:
  - Add localized strings for "Delete permanently", confirmation titles, warnings, and snackbars.

---

## Files to Change
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt`
- `lib/services/media/media_store_channel.dart`
- `lib/repositories/database/media_dao.dart`
- `lib/repositories/media_repository.dart`
- `lib/providers/trash_providers.dart`
- `lib/providers/album_providers.dart`
- `lib/providers/batch_providers.dart`
- `lib/providers/duplicate_providers.dart`
- `lib/screens/trash/trash_screen.dart`
- `lib/screens/viewer/media_viewer_screen.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ml.arb`

---

## Verification Plan
1. **Static Analysis & Tests**:
   - Run `flutter analyze` to ensure zero errors and zero warnings.
   - Run `flutter test` to verify existing repository, DAO, and provider tests pass.
   - Add unit tests for `MediaDao.deleteMediaItems` and `MediaRepository.deletePermanently`.
2. **Behavior Verification**:
   - Moving an item to trash immediately updates the Trash count on the Albums screen and displays the item in the Trash screen.
   - Emptying trash triggers the MediaStore deletion and clears the Trash album count to 0 and removes the thumbnail.
   - Tapping an item in Trash allows restoring or deleting permanently.
