# Plan — Hide photos the app is not allowed to see

**Status:** completed

## The issue

Tested on an Android 17 emulator with build 2.6.4: after the user picks **Allow limited access**
and chooses 3 photos, the app shows its "Only selected media is visible" banner, but the timeline
still shows every photo it indexed while it had full access. A photo the user did not pick opened
in the viewer.

Cause: the scan removes old rows only with full access (`MediaScannerService.scan`), on purpose,
so tags, favourites and notes are not lost when access is only limited. Nothing hides those rows
instead. The same happens if access is taken away completely: the folders and albums tabs can
still list old rows.

This builds on `plans/20261107_112011_scan-save-keeps-user-data.md` (done): a scan no longer
resets a row, so a flag set on it now survives rescans.

## The fix

Keep every row and its data, and **hide** the rows Android does not currently allow.

**New column** `media_items.is_out_of_reach` (0/1, default 0). Database version 6 → 7:
`ALTER TABLE ... ADD COLUMN is_out_of_reach INTEGER NOT NULL DEFAULT 0` with the same `0,1` rule
as the other flags (a new `ColumnValueRule.mediaIsOutOfReach`, `CHECK` on a new database,
triggers on an upgraded one).

**Set by the scan** (`MediaScannerService.scan`):

| Access | What the scan does |
| --- | --- |
| Limited | Always a full pass (the list is short, so this is cheap). Rows it saw → `0`. Every other row → `1`. Nothing is deleted |
| Full | As today, plus: if any row is out of reach, run a full pass even when a quick one was asked for. After it, delete rows whose files are gone (as today) and set every remaining row back to `0` |
| None | Before failing as today, set every row to `1`, so no tab can list them |

**Hidden from every list** — the filter `is_out_of_reach = 0` is added next to the existing
`is_vaulted = 0` filter in:

| Method | Used by |
| --- | --- |
| `MediaDao.getMediaItems` | Timeline, search, and every other list built from a filter (4 callers) |
| `MediaDao.searchMediaFts` | Full-text search helper |
| `MediaDao.restoreAllFromTrash`, `deleteAllTrashed` | Trash "Restore all" and "Empty trash": they must act only on what the user can see, not on hidden rows |
| `MediaDao.getMediaItemsByIds` | Album contents, tag contents, folder covers, selection and batch actions |
| `MediaDao.getFolderSummaries` | Folders tab (counts and covers) |
| `MediaDao.getTotalCount`, `getTrashCount` | Counts, trash badge |
| `MediaDao.getHashCandidates` | Duplicate finder |
| `AlbumDao.getMediaForAlbum` | Album contents |

**Single-item lookups for the screens:**
- `MediaItem` gains `isOutOfReach` (read in `fromMap`, written in `toMap`, `copyWith`, `==`).
- `mediaItemProvider` (viewer, compare, OCR, scanner screens) returns null for an out-of-reach
  item, so the screen shows its normal "not found" state.
- `AlbumRepository._resolveCover` skips an out-of-reach chosen cover and falls back to the newest
  visible member, as it already does for a removed cover.

**Left as they are, on purpose:**
- `getMediaItemById/ByPath/ByUri` in the DAO stay unfiltered: the vault restore, notes service and
  "open with" intents need the real row. Only the screen-facing provider above filters.
- `hasMediaWithHash` (transfer de-duplication), `getMediaStoreBackedCount`,
  `getNewestDateModifiedMs`: scan and transfer bookkeeping, not lists.
- Backup (`getBackupRecords`): includes hidden rows. It is the user's own encrypted archive, and
  leaving them out would lose their tags in a restore.
- Cached thumbnails on disk stay. They are app-private and never shown for a hidden row. Deleting
  them would make switching back to full access slow.

**Known limit (not fixed here):** the stored album and tag counts (`item_count`) still include
hidden photos, so a tile may say 12 and open with 3. It shows a number, not a photo. It can be
fixed later by counting at read time.

## Files to change

| File | Change |
| --- | --- |
| `lib/repositories/database/database_constants.dart` | `colMediaIsOutOfReach`; `schemaVersion` 6 → 7 |
| `lib/repositories/database/column_value_rules.dart` | `mediaIsOutOfReach` rule, added to `all` |
| `lib/repositories/database/database_helper.dart` | Column in `CREATE TABLE`; v7 migration (add column, its triggers) |
| `lib/repositories/database/media_dao.dart` | Filter in the 9 methods above; new `markOutOfReachExcept(seenIds)`, `markAllOutOfReach()`, `clearOutOfReach()`, `hasOutOfReach()` |
| `lib/repositories/database/album_dao.dart` | Filter in `getMediaForAlbum` |
| `lib/models/media_item.dart` | `isOutOfReach` field |
| `lib/services/media/media_scanner_service.dart` | The three access cases above |
| `lib/repositories/album_repository.dart` | `_resolveCover` skips an out-of-reach cover |
| `lib/providers/media_providers.dart` | `mediaItemProvider` returns null for an out-of-reach item |
| `test/services/media/media_scanner_service_test.dart` | Limited → unseen rows hidden, seen rows visible, nothing deleted; full again → all visible and data intact; quick scan with hidden rows runs a full pass; no access → all hidden |
| `test/repositories/database/media_dao_test.dart` (and `media_dao_phase9_test.dart` where the method lives) | Each of the 9 filtered methods leaves out (or does not touch) a hidden row; mark/clear methods; favourite and tags survive hide → unhide |
| `test/repositories/database/album_dao_test.dart` | `getMediaForAlbum` leaves out a hidden row |
| `test/repositories/database/database_migration_test.dart` | v6 → v7 adds the column with 0 for old rows; upgraded and fresh columns still match |
| `test/repositories/database/column_value_rules_test.dart` | New rule refuses a value other than 0/1 |
| `test/repositories/album_repository_test.dart` (or the existing album repository test) | Hidden chosen cover falls back to a visible member |
| `test/providers/` (media providers test) | `mediaItemProvider` gives null for a hidden item |
| `docs/architecture.md` | Schema version 7 and migration row; one line on limited access |
| `docs/security.md` | Limited photo access: what is hidden, what is kept, and why |

No UI text, ARB, Kotlin, manifest, permission, dependency or submodule changes.

## Checks

`dart format`, `flutter analyze`, `flutter test`. Then on the emulator with a dev build: full
access → star and tag a photo → choose **Allow limited access** with 3 other photos → only those
3 show in Timeline, Folders, Albums and Search → **Allow all** again → everything is back, and the
star and tag are still there.

## Security impact

Storage and permission behaviour. No new permission and no network change. The app now honours a
limited or removed media permission in every list, instead of showing rows indexed earlier.
Hidden rows and their thumbnails stay in app-private storage so the user's data is not lost; the
encrypted backup still contains their metadata.
