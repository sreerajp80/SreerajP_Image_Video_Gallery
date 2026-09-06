# Plan: Connect Trash Navigation and Ensure Correct Album Filtering

**Status:** Approved

## Issues
1. **Trash Navigation from Albums Tab**: Tapping the "Trash" smart album card on the Albums screen currently routes to generic `SmartAlbumScreen` (`/albums/auto/trash`) instead of the dedicated `TrashScreen` (`/trash`), preventing users from accessing the "Empty trash" and "Restore all" controls.
2. **Missing Quick Access from Timeline**: There is no direct shortcut to Trash from the main timeline's 3-dot overflow menu (which has Tags, Cleaner, Vault, Sync, PDF, and Settings).
3. **Filter Merging Bug in Smart Albums**: In `AlbumRepository._mergeFilters`, when applying active filters to a smart album, `base.isTrash` and `base.folderPaths` are not preserved. As a result, when an album filter is active, the Trash smart album accidentally searches with `is_trash = 0`, causing it to display normal non-trashed photos instead of trashed items.

## Fix
1. **Connect Trash Card in Albums Screen**:
   - In `lib/screens/albums/albums_screen.dart`, update the `onTap` handler for smart albums so that `album.albumType == AlbumType.smartTrash` routes to `kRouteTrash` (`/trash`).
2. **App Router Fallback**:
   - In `lib/core/routing/app_router.dart`, handle `type == 'trash'` under `auto/:type` so that any navigation to `/albums/auto/trash` renders `TrashScreen()`.
3. **Timeline Overflow Menu Shortcut**:
   - In `lib/screens/timeline/timeline_screen.dart`, add a "Trash" entry with `Icons.delete_outline` to the 3-dot overflow menu between Cleaner and Vault, navigating directly to `kRouteTrash`.
4. **Preserve Base Filters in Album Repository**:
   - In `lib/repositories/album_repository.dart`, update `_mergeFilters` to preserve `isTrash: base.isTrash || (extra.isTrash)` and `folderPaths: base.folderPaths.isNotEmpty ? base.folderPaths : extra.folderPaths`.
   - Ensure all smart albums, virtual albums, and device folders consistently return their designated items and exclude trashed or vaulted media.
5. **Testing**:
   - Add unit tests in `test/repositories/album_repository_test.dart` verifying filter merging retains `isTrash` and that albums return correct images.
   - Run `flutter analyze` and `flutter test`.

## Files to Change
- `lib/screens/albums/albums_screen.dart`
- `lib/core/routing/app_router.dart`
- `lib/screens/timeline/timeline_screen.dart`
- `lib/repositories/album_repository.dart`
- `test/repositories/album_repository_test.dart`
