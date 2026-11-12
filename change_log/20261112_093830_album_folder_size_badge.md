# Change log: Show total size on folder and album cards

Implements plan `plans/20261112_093330_album_folder_size_badge.md`.

## What changed

- `lib/models/album_summary.dart` — new `totalBytes` field (default 0), also in
  `copyWith`, `==` and `hashCode`.
- `lib/repositories/database/media_dao.dart` — the folder summary query now
  also returns `COALESCE(SUM(size_bytes), 0)` per folder, in the same single
  query. `FolderSummaryRow` carries it as `totalBytes`.
- `lib/repositories/database/album_dao.dart` — new `getAlbumSizes({albumId})`:
  one grouped query that sums the sizes of each album's visible members, using
  the same visibility rule as the item count.
- `lib/repositories/album_repository.dart` — fills `totalBytes` for device
  folders, user albums (list and single, one size query for the whole list),
  and smart albums (sum of the items already loaded).
- `lib/widgets/albums/album_card.dart` — when `totalBytes > 0`, a small dark
  see-through pill with white text (for example `1.4 GB`) sits 6 px in from
  the top-start corner of the cover. It uses the existing `context.units.bytes`
  formatter, so the unit is translated in all three languages. It moves to the
  top-right in a right-to-left layout. The card's screen-reader label now ends
  with the size; the pill itself is hidden from screen readers so the size is
  not read twice. Empty albums show no pill.

## Tests

- `test/repositories/album_repository_test.dart` — checks the totals for
  folders, user albums (hidden items left out), smart albums, and empty albums.
- `test/widgets/albums/album_card_test.dart` (new) — the badge shows, sits in
  the top-left, works for grid cards, is hidden when empty, is read once by
  screen readers, and draws in Malayalam and Sanskrit.

`dart format` (no changes), `flutter analyze` (no issues) and `flutter test`
(all passed) were run.

## Not done

- Not checked on a real device yet.
- No ARB, schema or permission change.
