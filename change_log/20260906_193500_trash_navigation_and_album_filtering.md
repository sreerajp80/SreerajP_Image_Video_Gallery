# Change Log: Connect Trash Navigation and Ensure Correct Album Filtering

**Plan:** [plans/20260906_193100_trash_navigation_and_album_filtering.md](plans/20260906_193100_trash_navigation_and_album_filtering.md)

## Summary of Changes

1. Connected the Trash card on the Albums screen so tapping it navigates directly to the dedicated `TrashScreen` (`/trash`), giving users immediate access to the "Empty trash" and "Restore all" actions.
2. Added a fallback in `app_router.dart` so navigation to `/albums/auto/trash` opens `TrashScreen`.
3. Added a "Trash" shortcut to the 3-dot overflow menu on the main timeline screen between Cleaner and Vault.
4. Fixed filter merging in `AlbumRepository._mergeFilters` so `isTrash` and `folderPaths` are preserved when active album filters are applied. This ensures the Trash smart album retains `is_trash = 1` and other albums never display trashed or vaulted items.

## Files Changed
1. **`lib/screens/albums/albums_screen.dart`**:
   - Updated smart album `onTap` callback to push `kRouteTrash` when `album.albumType == AlbumType.smartTrash`.
2. **`lib/core/routing/app_router.dart`**:
   - Updated `auto/:type` route to return `TrashScreen()` when `type == 'trash'`.
3. **`lib/screens/timeline/timeline_screen.dart`**:
   - Added `PopupMenuItem` with value `kRouteTrash`, icon `Icons.delete_outline`, and label `l10n.trashTitle` to the 3-dot overflow menu.
4. **`lib/repositories/album_repository.dart`**:
   - Updated `_mergeFilters` to preserve `isTrash: base.isTrash || extra.isTrash` and `folderPaths: base.folderPaths.isNotEmpty ? base.folderPaths : extra.folderPaths`.
5. **`test/repositories/album_repository_test.dart`**:
   - Added tests verifying `isTrash` is preserved in smart album queries when user filters are applied.

## Verification
- `flutter analyze`: Completed with 0 issues.
- `flutter test`: All 1,829 tests passed.
- `dart format .`: Verified code formatting.
