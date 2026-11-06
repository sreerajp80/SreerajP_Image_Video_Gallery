# Search index backfill (G45)

**Status:** completed

## What the issue is

The v3 migration creates the search table `media_search_fts` when it is missing, but it does not
add the photos already in `media_items`. New photos get a search row through the insert trigger.
Old photos never do, because every later change (notes, tags, address) is an `UPDATE` that only
changes rows already in the index. So on a phone that upgraded without a search table, old photos
never appear in search.

This was found by reading the code (`docs/known_gaps.md` G45). Step 1 below proves it with a test
before anything is fixed.

Only phones whose database had no search table before v3 are affected. Nobody knows how many that
is; it is likely few, but the harm is silent.

## Files to be changed

- `lib/repositories/database/database_constants.dart` — `schemaVersion` 3 → 4
- `lib/repositories/database/database_helper.dart` — new v4 step in `_onUpgrade`
- `test/repositories/database/database_migration_test.dart` — new tests
- `docs/architecture.md` — schema version and migration history
- `README.md` — §6 names a test file path that does not exist; correct it
- `docs/known_gaps.md` — move G45 to resolved

## The plan for the fix

### 1. Prove the bug first

Add a test that seeds a v1 database with no search table, one photo, one tag and some notes, then
upgrades it and searches the index for that photo. Run it before the fix and confirm it fails. If it
passes, the bug is not real: I will stop and tell you, and change nothing else.

### 2. Add a v4 migration, not a change to v3

The app is at version 2.5.2, so v3 has shipped. Shipped migrations are append-only (standard
§13.1). Changing v3 would also not help: phones already on v3 would never run it again.

The v4 step runs one SQL statement. It adds a search row for every photo that has none, filled the
same way the insert trigger fills it, plus its tag names:

```sql
INSERT INTO media_search_fts (media_id, display_name, user_notes, tags_content,
                              exif_search_text, address)
SELECT m.id, m.display_name, COALESCE(m.user_notes, ''),
       COALESCE((SELECT group_concat(t.name, ' ')
                 FROM tags t JOIN media_tag_entries mt ON t.id = mt.tag_id
                 WHERE mt.media_id = m.id), ''),
       COALESCE(m.exif_json, ''), COALESCE(m.address, '')
FROM media_items m
WHERE m.id NOT IN (SELECT media_id FROM media_search_fts);
```

- It is written with `DatabaseConstants` names in the code, like the rest of the helper.
- It is safe to run on a healthy database: every photo already has a row, so it adds nothing.
- It runs inside sqflite's upgrade transaction, so it either all happens or none of it does.
- Tag words may come out in a different order than `syncFtsTags` writes them. Search does not care
  about order. The next tag change on that photo rewrites the cell in the usual order anyway.

**Cost:** every upgrading phone scans the search table once. The `NOT IN` check is a single pass,
fine for a gallery-sized table.

**Other options I rejected:**
- *Rebuild the whole index on every upgrade:* more work, and it throws away good rows.
- *Check for missing rows on every app start:* hides any future bug of the same kind instead of
  fixing it once, and costs time on every launch.

### 3. Tests

In `database_migration_test.dart`:
- The step 1 test, which must pass after the fix: the old photo is found, with its tags and notes.
- v3 to v4 on a healthy database: no rows are added twice, and existing rows are unchanged.
- The existing tests now expect version 4 (they already read `DatabaseConstants.schemaVersion`).

### 4. Docs

- `docs/architecture.md`: schema version 4, and a history row for v4.
- `README.md` §6: correct the test file path to `test/repositories/database/`, and name
  `database_migration_test.dart`.
- `docs/known_gaps.md`: move G45 to resolved, with a link to this plan.

## How it will be tested

Claude runs: the step 1 test before the fix (it must fail), then `dart format`, `flutter analyze`
and `flutter test`.

You may also check on a phone, but most phones will show no difference, because they had a search
table. The test is the real proof.

## Not in this plan

- The case where the search table exists but its triggers are missing. That is a different gap and
  was not seen in the code paths checked.
- Git commits, unless you ask.
