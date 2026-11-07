# Plan — Make the media scan keep the user's data

**Status:** completed

## The issue

`MediaDao.batchUpsertMediaItems` (`lib/repositories/database/media_dao.dart`) saves every scanned
photo with `ConflictAlgorithm.replace`. In SQLite, "replace" **deletes** the old row and inserts a
new one. The new row is built only from Android's media list (`mapEntryToMediaItem` in
`lib/services/media/media_scanner_service.dart`), so it has none of the user's data.

A throwaway test against the real DAO (outside the project) showed what one rescan does to a photo
that was starred and tagged:

- favourite: **lost** (true → false)
- tag links: **lost** (1 → 0), because the delete cascades (`ON DELETE CASCADE`)
- search index rows: **2 for 1 photo**, and a search returns the photo **twice**. The delete
  trigger does not fire for "replace", but the insert trigger does, so every rescan adds a copy.

By the same logic, user notes, trash flag, vault flag (a vaulted photo can come back in the
timeline), album links, EXIF, place and hashes are reset too.

Only the quick scan's *new* rows are re-saved, which is why it is not seen every day. A **full**
scan re-saves every row. It runs when media access is first granted, and when the photo count no
longer matches (for example, after a photo is deleted in another app).

## The fix

Replace the "replace" save with two steps per photo, in the same transaction:

1. `INSERT OR IGNORE` the full row. A **new** photo is added as today. An existing one is left
   alone.
2. `UPDATE` only the columns Android owns, and only when one of them changed:
   `path`, `uri`, `display_name`, `media_type`, `mime_type`, `size_bytes`, `date_added`,
   `date_modified`, `date_taken`, `duration_ms`, `width`, `height`, `orientation`.
   `WHERE id = ? AND (path IS NOT ? OR ... )`, so an unchanged photo is not written at all (keeps
   scans fast and does not wake the search trigger for nothing).
3. If `size_bytes` or `date_modified` changed, the file itself changed, so the values worked out
   from the file are cleared to be worked out again: `sha256_hash`, `p_hash`, `exif_json`. This
   matches what happens today, but only for files that really changed. Favourite, notes, trash,
   vault flag, place, tags and album links are never touched.

Two steps (not SQLite's `ON CONFLICT DO UPDATE`) because that syntax needs SQLite 3.24, and the
app runs from Android 7 (API 24), whose built-in SQLite is older.

**One-time clean-up of the search index (database version 5 → 6):** delete the extra copies the old
save left, keeping one row per photo:
`DELETE FROM media_search_fts WHERE rowid NOT IN (SELECT MIN(rowid) FROM media_search_fts GROUP BY media_id)`.
Data the user already lost to past rescans cannot be brought back.

## Files to change

| File | Change |
| --- | --- |
| `lib/repositories/database/media_dao.dart` | `batchUpsertMediaItems`: insert-or-ignore, then update Android-owned columns only when changed; clear hashes and EXIF when the file changed |
| `lib/repositories/database/database_helper.dart` | v6 migration: remove duplicate search-index rows |
| `lib/repositories/database/database_constants.dart` | `schemaVersion` 5 → 6 |
| `test/repositories/database/media_dao_test.dart` | New tests (below) |
| `test/repositories/database/database_migration_test.dart` | v5 → v6 removes duplicates and keeps one row per photo |
| `test/services/media/media_scanner_service_test.dart` | A full rescan keeps a favourite |
| `docs/architecture.md` | Schema version line, and one line on the scan save rule |

No UI, ARB, Kotlin, manifest, dependency or submodule changes.

## Tests

A rescan of the same photo (same data from Android):
- keeps favourite, notes, trash flag, vault flag, place, tag links and album links;
- leaves exactly one search-index row, and search returns the photo once.

A rescan where Android reports a new name / size / date:
- the new values are saved;
- with a new size or date, hashes and EXIF are cleared; with only a new name, they are kept.

A new photo is still inserted with every field it was given (the current tests rely on this).

Scanner: a full scan after starring a photo keeps the star.

Migration: a v5 database with duplicate search rows opens as v6 with one row per photo.

Then `dart format`, `flutter analyze`, `flutter test`.

## Security impact

Storage only (local database). No permission, network, or platform change. It stops a vaulted
photo's hidden flag from being reset by a rescan, which today could show a vaulted photo's row in
the timeline again.

## Not in this plan

- Hiding out-of-reach photos with limited access: next plan, built on this one.
- The viewer title showing a different photo's file name: noted, not looked into yet.
