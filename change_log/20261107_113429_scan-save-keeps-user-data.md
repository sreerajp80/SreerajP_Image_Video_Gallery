# Change log — Make the media scan keep the user's data

Implements plan: `plans/20261107_112011_scan-save-keeps-user-data.md`

## What changed

The scan saved every photo with SQLite `REPLACE`, which deletes the old row first. On a full
rescan this reset the favourite, notes, trash and vault flags, EXIF, place and hashes, deleted the
photo's tag and album links (`ON DELETE CASCADE`), and added another search-index row each time.
The scan now keeps all of that.

| File | Change |
| --- | --- |
| `lib/repositories/database/media_dao.dart` | `batchUpsertMediaItems`: `INSERT OR IGNORE` the full row, then `UPDATE` only the 13 Android-owned columns, and only when one of them changed. A changed size or `date_modified` also clears `sha256_hash`, `p_hash` and `exif_json`. Two statements, because `ON CONFLICT DO UPDATE` needs SQLite 3.24 and Android 7 ships an older one |
| `lib/repositories/database/database_helper.dart` | v6 migration `_removeDuplicateSearchRows`: keeps one `media_search_fts` row per photo; skipped if the search table does not exist |
| `lib/repositories/database/database_constants.dart` | `schemaVersion` 5 → 6 |
| `test/repositories/database/media_dao_test.dart` | 5 new tests: unchanged rescan keeps favourite, notes, hashes, EXIF, place, tag and album links; keeps trash and vault flags; one search row and one search hit; a rename keeps hashes and EXIF; a changed file clears hashes and EXIF but keeps the rest |
| `test/repositories/database/database_migration_test.dart` | v5 → v6 keeps one search row per photo |
| `test/services/media/media_scanner_service_test.dart` | A full rescan keeps a favourite |
| `test/providers/trash_providers_test.dart` | **Not in the plan.** Added a `tearDown` that closes the database. The tests shared one in-memory database, and the old `REPLACE` save hid that by resetting every row to "in trash". With the fix, two tests failed until each got its own database |
| `docs/architecture.md` | Schema version 6, migration row 6, and the scan save rule under Local Storage |

## Checks

- `dart format` (0 changed), `flutter analyze` (no issues).
- `flutter test`: all 2,241 tests pass.
- Before the fix, a throwaway test (kept outside the project) showed one rescan turn favourite
  true → false, tag links 1 → 0, and search rows 1 → 2.

## Not done

- Not yet run on a phone or emulator. Suggested check: star and tag a photo, delete a different
  photo in another app (this forces a full scan), reopen the gallery, and check the star and tag
  are still there.
- Favourites and tags already lost to past full scans cannot be brought back.
- Next: the limited-access hiding plan, which builds on this.
