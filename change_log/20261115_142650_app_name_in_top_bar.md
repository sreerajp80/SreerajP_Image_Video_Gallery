# Change log — App name in the top bar of the main tabs

Implements plan: `plans/20261115_142307_app_name_in_top_bar.md`

## What changed

The top bar of the three main tabs now shows the app name instead of the tab
name. The text comes from the existing `titleApp` key:
English "Drishya Gallery", Malayalam "ദൃശ്യ", Sanskrit "दृश्य".

| File | Change |
|------|--------|
| `lib/screens/timeline/timeline_screen.dart` | Title `l10n.titleTimeline` → `l10n.titleApp` |
| `lib/screens/home/folders_tab.dart` | Title `l10n.titleFolders` → `l10n.titleApp` |
| `lib/screens/home/albums_tab.dart` | Title `l10n.titleAlbums` → `l10n.titleApp` |

The tab name stays visible in the bottom navigation bar. Inner screens and the
Timeline selection bar are unchanged. No ARB keys were added or removed.

## Checks

- `dart format`: no changes needed.
- `flutter analyze`: no issues.
- `flutter test`: all tests passed.
- Not yet checked by hand on a device: the title fitting next to the action
  icons in all three languages, in portrait and landscape.

## Security impact

None. UI text only.
