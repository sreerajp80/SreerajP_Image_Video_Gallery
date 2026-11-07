# Plan — Album and tag tiles count only photos the user can see

**Status:** completed

## The issue

Album and tag tiles show a number that can be bigger than what opens. Example: a tile says 12,
the album opens with 3.

Cause: the number is a saved column, `item_count`, on the `albums` and `tags` tables. It is
worked out by a plain `COUNT(*)` over the link table (`album_media` or `media_tags`):

- `AlbumDao._refreshCount`
- `TagDao.addTagToMedia`, `TagDao.removeTagFromMedia`, `TagDao._recountTagIn`

That `COUNT(*)` counts every linked photo. But the screens that open an album or tag
(`AlbumDao.getMediaForAlbum`, `MediaDao.getMediaItemsByIds`, `MediaDao.getMediaItems`) leave out
three kinds of photo:

- hidden (`is_out_of_reach = 1`) — the known limit from
  `plans/20261107_113934_hide-media-out-of-reach.md`,
- in the trash (`is_trash = 1`),
- in the vault (`is_vaulted = 1`).

So the tile count is wrong for all three, not only for hidden photos.

There is a second problem. The saved count only changes when a photo is added to or removed
from an album or tag. A scan that hides a photo, or moving a photo to the trash or the vault,
does not touch it. So even a better `COUNT` would go out of date.

Folder tiles are already right: `MediaDao.getFolderSummaries` counts at read time with all three
filters.

## The fix

**Count at read time**, the same way folder tiles already do. Do not trust the saved column for
display any more.

1. In `AlbumDao` and `TagDao`, every method that returns an `Album` or a `Tag` reads it with a
   live count of visible linked photos:

   ```sql
   SELECT a.*,
     (SELECT COUNT(*)
        FROM album_media am
        JOIN media_items m ON m.id = am.media_id
       WHERE am.album_id = a.id
         AND m.is_vaulted = 0
         AND m.is_trash = 0
         AND m.is_out_of_reach = 0) AS visible_count
   FROM albums a ...
   ```

   The row is turned into a model with `item_count` replaced by `visible_count`. The model
   classes do not change. The existing indexes `idx_album_media_album_id` and
   `idx_media_tags_tag_id` keep the sub-query fast; the user has tens of albums and tags, not
   thousands.

   Methods: `AlbumDao.getAlbumById`, `getAllAlbums`, `getAlbumsByType`;
   `TagDao.getTagById`, `getTagByName`, `getAllTags`, `getTagsForMedia`.

2. The "visible photo" rule (`is_vaulted = 0 AND is_trash = 0 AND is_out_of_reach = 0`) is
   written once, as a shared SQL snippet in `DatabaseConstants`, and used by both DAOs. This
   keeps the album, tag and folder counts from drifting apart again.

3. **The saved `item_count` column stays**, and is still written as today. No schema change and
   no migration. It is just no longer what the tiles show. Removing it would need a migration
   for no real gain.

**Left as is, on purpose:**
- Backup: it already leaves `itemCount` out (`backup_payload.dart`), so nothing changes there.
- `TagDao.recountTag` and `AlbumDao._refreshCount` keep working; they only feed the saved
  column.

## Other way, not chosen

Keep the saved count, make its `COUNT` use the visible rule, and recount every album and tag
after each scan, trash, restore, vault and unvault. This is faster to read, but it needs a
recount in at least six places, and any place that is missed brings the bug back. Counting at
read time cannot go stale.

## Files to change

| File | Change |
| --- | --- |
| `lib/repositories/database/database_constants.dart` | Shared "visible media" SQL snippet |
| `lib/repositories/database/album_dao.dart` | Live visible count in `getAlbumById`, `getAllAlbums`, `getAlbumsByType` |
| `lib/repositories/database/tag_dao.dart` | Live visible count in `getTagById`, `getTagByName`, `getAllTags`, `getTagsForMedia` |
| `lib/repositories/database/media_dao.dart` | Use the shared snippet in `getFolderSummaries` (same SQL, no change in result) |
| `test/repositories/database/album_dao_test.dart` | Album with visible, hidden, trashed and vaulted members → count is only the visible ones; hiding a member after adding it lowers the count with no recount call |
| `test/repositories/database/tag_dao_test.dart` | Same cases for tags, in `getAllTags` and `getTagsForMedia` |
| `test/repositories/album_repository_test.dart` | `getVirtualAlbumSummaries` passes the visible count to the tile |
| `docs/architecture.md` | One line: album and tag counts are worked out at read time; `item_count` is a saved value only |

Existing tests that check `itemCount` will be run and fixed only where they assumed hidden,
trashed or vaulted photos are counted.

No UI text, ARB, Kotlin, manifest, permission, dependency, schema or submodule changes.

## Checks

`dart format .`, `flutter analyze`, `flutter test`. Then on the emulator with a dev build: put
some photos in an album and give them a tag → choose **Allow limited access** without them →
the album and tag tiles show the smaller number → **Allow all** again → the numbers go back up.
Also: move one album photo to the trash → its tile count drops by one.

## Security impact

None. Read-only change to how a number is counted. No storage, permission or network change.
