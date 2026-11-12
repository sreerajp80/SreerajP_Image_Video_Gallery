# Change log: ⋮ menu on all three home tabs

Implements plan `plans/20261110_213503_overflow-menu-on-all-tabs.md`.

## What was wrong

Only the Timeline tab had the ⋮ menu in its top bar. Folders and Albums had only the search
button, so Settings, Tags, Cleaner, Trash, Vault, Transfer, PDF images and Backup could not
be reached from those tabs.

## What changed

- `lib/widgets/home/home_overflow_menu.dart` (new): `HomeOverflowMenu`, the one shared ⋮ menu.
  Same eight items, order, icons and labels as before. Items are built from one list, so the
  repeated `PopupMenuItem` code is gone.
- `lib/screens/timeline/timeline_screen.dart`: the inline menu is replaced by
  `HomeOverflowMenu`. Search and PDF-export buttons are unchanged. The selection bar is
  unchanged.
- `lib/screens/home/folders_tab.dart`, `lib/screens/home/albums_tab.dart`: `HomeOverflowMenu`
  added after the search button.
- `test/widgets/home/home_overflow_menu_test.dart` (new): checks the menu shows eight items,
  that tapping Settings opens the settings route, and that the open menu renders cleanly in
  en, ml and sa.
- `test/screens/home/folders_tab_test.dart`: checks the Folders tab shows the menu.

No ARB changes; all labels already existed in all three languages.

## Checks

- `dart format` on the changed files: clean.
- `flutter analyze`: no issues.
- `flutter test`: all 2339 tests pass.
- Not yet checked by hand on a device.
