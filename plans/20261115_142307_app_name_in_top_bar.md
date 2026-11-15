# Show the app name in the top bar of the main tabs

**Status:** completed

## The issue

Inside the app, nothing on screen shows the app name. The three main tabs
(Timeline, Folders, Albums) show only the tab name in the top bar, such as
"Timeline". The name "Drishya Gallery" appears only on the About screen, which
is several taps deep. A user who opens the app from a share sheet, the recent
apps list or a screenshot cannot tell which app it is.

The tab name in the top bar repeats what the bottom navigation bar already
shows, because the selected tab is highlighted there with its label.

## The fix

On the three main tabs, show the app name as the top bar title instead of the
tab name. The text comes from the existing `titleApp` key, which already has a
real value in all three languages:

| Language | `titleApp` |
|----------|------------|
| English | Drishya Gallery |
| Malayalam | ദൃശ്യ |
| Sanskrit | दृश्य |

- No new ARB keys and no new translations.
- The top bar keeps the same height, so it takes no extra space.
- The tab name stays visible in the bottom navigation bar.
- While items are selected, the Timeline tab still swaps in its selection bar,
  as it does today.
- Inner screens (viewer, Settings, Search, the pushed Albums screen at
  `lib/screens/albums/albums_screen.dart`, and the rest) are not changed. They
  keep their own titles and back arrows.

## Files to change

| File | Change |
|------|--------|
| `lib/screens/timeline/timeline_screen.dart` | Top bar title `l10n.titleTimeline` → `l10n.titleApp` |
| `lib/screens/home/folders_tab.dart` | Top bar title `l10n.titleFolders` → `l10n.titleApp` |
| `lib/screens/home/albums_tab.dart` | Top bar title `l10n.titleAlbums` → `l10n.titleApp` |

The `titleTimeline`, `titleFolders` and `titleAlbums` keys stay, because the
bottom navigation bar and other screens still use them.

## Checks

- `dart format .`, `flutter analyze` (zero issues), `flutter test`.
- No existing test looks for the tab names in the top bar, so no test needs to
  change. No new test is added: this is a one-word UI text swap with no logic.
- By hand: open each tab in English, Malayalam and Sanskrit, in portrait and
  landscape, and check that the title fits next to the action icons.

## Security impact

None. Only UI text changes. No permissions, storage, network or dependencies
are touched.
