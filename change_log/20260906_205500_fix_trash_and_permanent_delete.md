# Change Log: Fix Trash Sync and Implement Permanent File Deletion

**Date:** 2026-09-06
**Reference Plan:** `plans/20260906_205500_fix_trash_and_permanent_delete.md`

## Summary of Changes

1. **Native MediaStore File Deletion**:
   - Updated `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt` with a `deleteMedia` channel method.
   - On Android 11+ (API 30+), it uses `MediaStore.createDeleteRequest` to trigger the native Android deletion consent dialog, cleanly deleting files from device storage.
   - On Android 10 (API 29), it handles scoped storage deletion and catches `RecoverableSecurityException` to launch the user action intent.
   - On Android 9 and below, it deletes via `ContentResolver.delete` and file unlinking.
   - Updated `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` to route delete activity results to the media handler.

2. **Channel & Repository Deletion API**:
   - Added `deleteMedia` to `MediaStoreChannel` and `PlatformMediaStoreChannel` in `lib/services/media/media_store_channel.dart`.
   - Added `deleteMediaItems` to `lib/repositories/database/media_dao.dart`.
   - Added `deletePermanently` to `lib/repositories/media_repository.dart` to handle channel file deletion followed by database removal.

3. **Riverpod State Invalidation & Synchronization**:
   - Updated `lib/providers/trash_providers.dart`:
     - `TrashController.emptyTrash()` now permanently deletes all trashed files from the device storage via `MediaRepository.deletePermanently()`.
     - Added `TrashController.deletePermanently()` to support single-item permanent deletion.
     - Updated `restoreItem`, `restoreAll`, `emptyTrash`, and `deletePermanently` to bump both `trashRevisionProvider` and `albumRevisionProvider`.
   - Updated `lib/providers/album_providers.dart` so `smartAlbumsProvider` and `smartAlbumMediaProvider` watch `trashRevisionProvider`. The Trash album card ("ചവറ്റുകുട്ട") now updates its count and cover thumbnail immediately when trash changes.
   - Updated `lib/providers/batch_providers.dart` so batch "Move to trash" bumps both `trashRevisionProvider` and `albumRevisionProvider`.
   - Updated `lib/providers/duplicate_providers.dart` so keeping the best duplicate bumps both `trashRevisionProvider` and `albumRevisionProvider`.
   - Updated `lib/screens/viewer/media_viewer_screen.dart` so moving an image to trash or undoing it bumps both `trashRevisionProvider` and `albumRevisionProvider`.

4. **UI & Localization**:
   - Updated `lib/widgets/albums/album_media_grid.dart` to support an optional `onItemTap` callback.
   - Updated `lib/screens/trash/trash_screen.dart`:
     - Tapping or long-pressing an item in Trash opens an options sheet with:
       - **View fullscreen**
       - **Restore to gallery**
       - **Delete permanently** (with confirmation dialog)
     - Empty trash dialog now clearly explains that files will be permanently deleted from phone storage.
   - Updated `lib/screens/viewer/media_viewer_screen.dart`:
     - Trashed images and videos display dedicated "Restore" and "Delete permanently" action buttons in the bottom bar.
     - Trashed items hide normal editing and favorite options in the top bar.
   - Updated `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` with localized strings for permanent deletion titles, bodies, and snackbars.

5. **Tests**:
   - Updated `test/services/media/fake_media_store_channel.dart` with `deleteMedia` mock implementation.
   - Added unit tests in `test/repositories/media_repository_test.dart` for `deletePermanently`.
   - Verified that all 1,837 tests pass and static analysis is clean.

## Verification
- Ran `flutter analyze`: 0 warnings, 0 errors.
- Ran `flutter test`: all 1,837 tests passed.
- Formatted code using `dart format .`.
