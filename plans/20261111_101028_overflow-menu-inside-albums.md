# Show the ⋮ menu inside folders and albums

**Status:** completed

## Issue

The earlier fix (`plans/20261110_213503_overflow-menu-on-all-tabs.md`) added the shared ⋮ menu
(`HomeOverflowMenu`) to the three home tabs. The screens opened from those tabs still lack it:

- Folder screen (`FolderAlbumScreen`): only a filter button.
- Smart album screen (`SmartAlbumScreen`): only a filter button.
- User album screen (`AlbumMediaScreen`): has its own ⋮ menu, but it holds only the album
  actions (Rename, Choose cover, Reorder, Delete).

So from inside a folder or album the user must go back to reach Settings and the other tools.

## Fix

1. `HomeOverflowMenu` gets two optional inputs:
   - `extraItems`: menu items shown **first**, above the shared ones, with a divider between.
   - `onExtraSelected`: called when one of the extra items is picked.
   A shared item still opens its route. An extra item's value is passed to `onExtraSelected`.
   With no extra items the menu is exactly as it is today.
2. Folder screen and smart album screen: add `HomeOverflowMenu()` after the filter button.
3. User album screen: replace its own `PopupMenuButton` with `HomeOverflowMenu`, passing the
   four album actions as `extraItems` and `_onAction` as `onExtraSelected`. The user gets one
   ⋮ menu: album actions on top, a divider, then the eight shared items (as the owner asked).

No new text, so no ARB changes.

### Downsides (said honestly)

- The album menu grows from 4 to 12 items. On a small phone in landscape it will scroll.
- "Delete album" and "Trash" both use a bin icon. The divider keeps them apart, and the album
  actions stay on top, so the risk of a wrong tap is low but not zero.

## Files to change

- `lib/widgets/home/home_overflow_menu.dart` — add `extraItems` and `onExtraSelected`.
- `lib/screens/albums/smart_album_screen.dart` — add the menu to the folder and smart album bars.
- `lib/screens/albums/album_media_screen.dart` — use the shared menu with album actions on top.
- `test/widgets/home/home_overflow_menu_test.dart` — new test: extra items show first, with a
  divider, and picking one calls `onExtraSelected` and does not navigate.

## Checks

- `dart format`, `flutter analyze` (clean), `flutter test` (all pass).
- By hand: open a folder, a smart album and a user album; tap ⋮; open Settings; rename an album.

## Security impact

None. No new permission, route, storage or network use.
