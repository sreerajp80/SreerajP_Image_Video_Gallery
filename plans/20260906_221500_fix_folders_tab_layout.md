# Fix Blank Folders Tab Due to Infinite Layout Size

**Status:** Implemented

## Problem
When opening the Folders tab, the screen is blank.

In `lib/screens/home/folders_tab.dart`, the grid builds each folder item with:
```dart
AlbumCard(
  summary: folder,
  size: double.infinity,
  onTap: () => context.push(folderAlbumPath(folder.id)),
)
```

Inside `lib/widgets/albums/album_card.dart`, `AlbumCard` places a `SizedBox(width: size, height: size)` inside a vertical `Column`.
In Flutter, a `Column` gives its children unbounded vertical constraints. When `size: double.infinity` is passed:
1. `SizedBox(height: double.infinity)` tries to take infinite height.
2. In `_EmptyCover`, `Icon(size: size * 0.35)` passes `double.infinity` to the icon.
3. Flutter throws a fatal layout error: `RenderConstrainedBox object was given an infinite size during layout`.
4. In release mode, Flutter replaces the failed widget with a blank box, making the Folders tab completely blank.

## Solution

1. **`lib/widgets/albums/album_card.dart`**:
   - Make `size` nullable (`final double? size;`).
   - If `size != null`, use a fixed `SizedBox(width: size, height: size)`.
   - If `size == null`, use an `AspectRatio(aspectRatio: 1.0)` cover that matches the cell width.
   - Update `_EmptyCover` to support adaptive sizing via `LayoutBuilder` instead of multiplying by infinity.

2. **`lib/widgets/media/media_thumbnail.dart`**:
   - Make `size` nullable (`final double? size;`).
   - When `size` is specified, wrap in `SizedBox(width: size, height: size)`.
   - When `size` is null, allow the image to fill the parent container (like `AspectRatio`).

3. **`lib/screens/home/folders_tab.dart`**:
   - Remove `size: double.infinity` when instantiating `AlbumCard`.

4. **`test/widgets/folders_tab_test.dart`**:
   - Add widget tests for `FoldersTab` verifying it renders folder cards and empty states without layout errors.

## Files to Change
- `lib/widgets/albums/album_card.dart`
- `lib/widgets/media/media_thumbnail.dart`
- `lib/screens/home/folders_tab.dart`
- `test/widgets/folders_tab_test.dart` (new test file)

## Verification
- Run `flutter analyze` to ensure zero static warnings.
- Run `flutter test` including the new `folders_tab_test.dart` to verify all tests pass.
