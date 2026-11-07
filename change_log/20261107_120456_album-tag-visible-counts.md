# Change log — Album and tag tiles count only photos the user can see

Implements `plans/20261107_120039_album-tag-visible-counts.md`.

## What was wrong

Album and tag tiles showed the saved `item_count`, which counted every linked photo: also those
in the trash, in the vault, or hidden by limited media access. A tile could say 12 and open with
3. The saved number also did not change when a scan hid a photo or a photo went to the trash or
vault.

## What changed

- `lib/repositories/database/database_constants.dart`: new `visibleMediaCondition([alias])`, the
  one shared SQL rule for "a photo the user can see" (not vaulted, not trashed, not out of reach).
- `lib/repositories/database/album_dao.dart`: `getAlbumById`, `getAllAlbums` and
  `getAlbumsByType` now read each album with a live count of visible members, and that count
  becomes the album's `itemCount`. Sort order is unchanged.
- `lib/repositories/database/tag_dao.dart`: the same for `getTagById`, `getTagByName`,
  `getAllTags` and `getTagsForMedia`.
- `lib/repositories/database/media_dao.dart`: `getFolderSummaries` uses the shared rule. Same SQL
  as before, so the folder counts do not change.
- The saved `item_count` column is still written as before. No schema change, no migration.
- `docs/architecture.md`: one note on how album and tag counts are worked out.

## Tests

- `test/repositories/database/album_dao_test.dart`: count leaves out trashed, vaulted and hidden
  members in all three read methods and matches `getMediaForAlbum`; count drops when a member
  is hidden later, with no recount call.
- `test/repositories/database/tag_dao_test.dart`: the same cases for tags, in all four read
  methods.
- `test/repositories/album_repository_test.dart`: the tile summary count matches what the album
  opens with.

## Checks

- `dart format`: clean.
- `flutter analyze`: no issues.
- `flutter test`: all 2268 tests passed.
- Not yet checked on the emulator (limited access → album and tag tiles show the smaller number;
  trash one album photo → its count drops by one).

## Security impact

None. A read-only change to how a number is counted.
