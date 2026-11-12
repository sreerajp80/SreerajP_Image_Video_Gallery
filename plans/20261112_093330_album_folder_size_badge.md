# Plan: Show total size on folder and album cards

**Status:** completed

## The issue

The Folders tab and the Albums tab show each folder or album as an
`AlbumCard`: a square cover, the name, and "N items". The user also wants to
see how much space the folder or album takes. It should sit in the top-left
corner of the cover and be easy to read on any photo, light or dark.

Today no size reaches the card. `AlbumSummary` (the one shape the card draws)
has `itemCount` but no byte total. Each kind of album gets its data a
different way:

- **Device folder:** `MediaDao.getFolderSummaries()` groups media rows by
  directory in one SQL query. It counts rows but does not add up sizes.
- **Virtual (user-made) album:** `AlbumDao` reads each album with a live
  count of visible members. No size.
- **Smart album:** `AlbumRepository.getSmartAlbums()` already loads every
  item of each smart album, so the sizes are already in memory.

The `media` table already stores each file's size in `size_bytes`, so no
schema change or migration is needed.

## Files to change

- `lib/models/album_summary.dart` — add `totalBytes`.
- `lib/repositories/database/media_dao.dart` — folder query adds
  `SUM(size_bytes)`; `FolderSummaryRow` gets `totalBytes`.
- `lib/repositories/database/album_dao.dart` — new method
  `getVirtualAlbumSizes()`: one grouped query, album id → total bytes of
  visible members.
- `lib/repositories/album_repository.dart` — fill `totalBytes` for folders,
  virtual albums (list and single), and smart albums.
- `lib/widgets/albums/album_card.dart` — draw the size badge over the cover.
- `test/repositories/album_repository_test.dart` — check the totals.
- `test/repositories/database/` (the existing DAO test for folders/albums,
  if present) — check the new SUM.
- `test/widgets/albums/album_card_test.dart` — new: badge shows, and is
  hidden for an empty album.

No ARB changes. The size text comes from the existing `context.units.bytes()`
helper, which already uses translated unit names (KB / MB / GB) for English,
Malayalam and Sanskrit.

## The fix

1. **Model.** Add `final int totalBytes` (default `0`) to `AlbumSummary`,
   with `copyWith`, `==` and `hashCode` updated.
2. **Folders.** In `getFolderSummaries()` add
   `COALESCE(SUM(size), 0) AS total_bytes` to the grouped query (the inner
   select also picks `size_bytes`). Same single query, so no extra cost.
3. **Virtual albums.** Add `AlbumDao.getVirtualAlbumSizes()`:
   `SELECT am.album_id, SUM(m.size_bytes) FROM album_media am JOIN media m …
   WHERE <visible rule> GROUP BY am.album_id`. Same visibility rule as the
   item count, so size and count always agree. The repository calls it once
   for the whole list (not once per album). The single-album read uses the
   same query filtered to one id.
4. **Smart albums.** Sum `item.size` over the items that are already loaded.
   No new query.
5. **Badge on the card.** Wrap the cover in a `Stack`. In the top-left corner
   (6 px inset) draw a small rounded pill:
   - background: black at about 55 % opacity, so white text stays readable
     on both bright and dark photos (the same idea as video-length badges);
   - text: white, `labelSmall`, one line, e.g. `1.4 GB`;
   - corner radius 8, padding 6 × 2.
   It uses `AlignmentDirectional.topStart`, so in a right-to-left language it
   moves to the top-right, which is correct.
   Hidden when `totalBytes == 0` (an empty album shows nothing extra).
   The `Semantics` label of the card adds the size, so screen readers hear it.
6. **Tests** as listed above. Then run `flutter gen-l10n` (no change
   expected), `dart format .`, `flutter analyze`, `flutter test`.

## Notes

- A file whose size is unknown is stored as `0`, so it simply adds nothing.
- Folder sizes count only files directly in that folder, the same as the item
  count. Sub-folders are not included.
- Sizes are what the last scan found. After a scan or refresh they update
  together with the item count.

**Security impact:** none. Read-only sums over data already in the local
database. No new permission, network, storage or dependency.
