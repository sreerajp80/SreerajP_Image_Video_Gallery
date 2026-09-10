# Fix Blank Folders Tab Due to Infinite Layout Size

**Plan:** `plans/20260906_221500_fix_folders_tab_layout.md`

## What Changed

### Modified Files
- `lib/widgets/media/media_thumbnail.dart` — Made `size` nullable (`final double? size;`). When `size` is specified, it wraps the thumbnail with a `SizedBox(width: size, height: size)`. When `size` is null, it allows the thumbnail to adaptively fill its parent container (such as an `AspectRatio` box).
- `lib/widgets/albums/album_card.dart` — Made `size` nullable (`final double? size;`). When `size` is finite, it uses `SizedBox(width: size, height: size)`. When `size` is null or non-finite, it uses `AspectRatio(aspectRatio: 1.0)` to keep a square cover that dynamically fills grid cells. Updated `_EmptyCover` to scale icons cleanly via `LayoutBuilder` when size is null or non-finite.
- `lib/screens/home/folders_tab.dart` — Changed `size: double.infinity` to `size: null` on `AlbumCard` so the folder items adaptively fill their grid columns without causing infinite height layout errors in Flutter.

### New Test Files
- `test/widgets/folders_tab_test.dart` — Added widget tests covering `FoldersTab` rendering folder cards in a grid and rendering the empty state when no folders exist.

## What Was Tested

- `flutter analyze` — 0 issues found.
- `flutter test test/widgets/folders_tab_test.dart` — All 2 tests passed.
- `flutter test` — All 1847 tests passed.
