# Change log: ⋮ menu inside folders and albums

Implements plan `plans/20261111_101028_overflow-menu-inside-albums.md`.

## What was wrong

The shared ⋮ menu was on the three home tabs only. Inside a folder or a smart album there was
no ⋮ menu. Inside a user album the ⋮ menu held only the album actions. So Settings and the
other tools could not be reached from those screens.

## What changed

- `lib/widgets/home/home_overflow_menu.dart`: `HomeOverflowMenu` takes two optional inputs,
  `extraItems` and `onExtraSelected`. Extra items are shown first, then a divider, then the
  eight shared items. Picking a shared item opens its route; picking an extra item calls
  `onExtraSelected`. With no extra items the menu is the same as before (no divider).
- `lib/screens/albums/smart_album_screen.dart`: the folder screen and the smart album screen
  show `HomeOverflowMenu` after the filter button.
- `lib/screens/albums/album_media_screen.dart`: the album's own `PopupMenuButton` is replaced
  by `HomeOverflowMenu`. Rename, Choose cover, Reorder and Delete are passed as extra items,
  so the album has one ⋮ menu: album actions on top, then the shared items.
- `test/widgets/home/home_overflow_menu_test.dart`: two new tests. Extra items show above a
  divider and call back instead of navigating; with no extra items there is no divider.

No ARB changes.

## Checks

- `dart format`: clean. `flutter analyze`: no issues. `flutter test`: all 2341 tests pass.
- Not yet checked by hand on a device.
