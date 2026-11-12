# Show the ⋮ menu on all three home tabs

**Status:** completed

## Issue

The home screen has three bottom tabs: Timeline, Folders and Albums.
`HomeShellScreen` only switches between them. Each tab builds its **own** top bar.

Only the Timeline top bar has the ⋮ (overflow) menu. That menu is the only way to reach
Settings, Tags, Cleaner, Trash, Vault, Transfer, PDF images and Backup. The Folders and
Albums top bars have only the search button. So on those two tabs the user cannot reach
Settings or any of the other menu items.

## Fix

1. Move the menu out of `timeline_screen.dart` into a new shared widget,
   `HomeOverflowMenu` (layer: `widgets/`). It holds the same eight items in the same order,
   with the same icons and labels. It opens the chosen route with `context.push`.
2. Use `HomeOverflowMenu` in the top bar of all three tabs, after the existing buttons.
3. The Timeline keeps its PDF-export icon button. Folders and Albums do not get it (no change
   to them other than the menu).
4. While a selection is running, the Timeline still shows its selection bar instead. No change
   there.

No new text, so no ARB changes. All labels already exist in all three languages.

Why a shared widget and not one top bar in `HomeShellScreen`: each tab has its own title,
and the Timeline swaps its bar for the selection bar. A shared widget fixes the bug with the
smallest change and keeps one copy of the menu, so the tabs cannot drift apart again.

## Files to change

- `lib/widgets/home/home_overflow_menu.dart` — new shared menu widget.
- `lib/screens/timeline/timeline_screen.dart` — use the shared widget instead of the inline menu.
- `lib/screens/home/folders_tab.dart` — add the menu to the top bar.
- `lib/screens/home/albums_tab.dart` — add the menu to the top bar.
- `test/widgets/home/home_overflow_menu_test.dart` — new test: the menu shows all eight items,
  including Settings, in en, ml and sa.
- `test/screens/home/folders_tab_test.dart` — check the ⋮ menu is shown.

## Checks

- `dart format .`, `flutter analyze` (clean), `flutter test` (all pass).
- By hand: open each tab, tap ⋮, open Settings.

## Security impact

None. No new permission, route, storage or network use. Same routes as before.
