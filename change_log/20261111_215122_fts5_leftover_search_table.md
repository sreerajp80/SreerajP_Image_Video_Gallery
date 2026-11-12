# Change log: Broken FTS5 search table on old Android SQLite

Implements plan: `plans/20261111_213402_fts5_leftover_search_table.md`

## What was wrong

On an Android 10 phone (SQLite 3.22.0) a fresh install indexed no photos.
Every insert into `media_items` failed with `no such module: fts5`.

Root cause, proven on the phone with a small test program: on SQLite 3.22, a
`CREATE VIRTUAL TABLE ... USING fts5` that fails for a missing module **inside
a transaction** still leaves the table's row in `sqlite_master`. sqflite runs
`onCreate` in a transaction. The FTS4 fallback then used
`CREATE ... IF NOT EXISTS`, saw the name, and did nothing. The useless FTS5
table was committed, and the search triggers made every write fail. SQLite
3.50 (newer Android) and 3.54 (PC tests) clean up correctly, so tests never
showed it.

On that SQLite, `DROP TABLE` on the broken table fails too, and the connection
keeps the old table in memory until it is closed.

## What changed

- `lib/repositories/database/fts_support.dart` (new): `FtsModule` (FTS5, FTS4
  with `unicode61`, plain FTS4) and `FtsSupport.probe`, which finds the first
  working module on a separate in-memory database, outside any transaction.
- `lib/repositories/database/database_helper.dart`:
  - The module is probed once before the first open. The search table is
    created only with that module (or a plain table when none works). No more
    "try and catch" inside the `onCreate` transaction.
  - New `_removeUnusableSearchTable`: before the normal open, on its own
    private connection, it checks the search table. If SQLite reports a
    missing module, it drops the three search triggers and deletes that one
    `sqlite_master` row (only a `CREATE VIRTUAL TABLE` row with
    `rootpage = 0`) using `writable_schema`. On a healthy database it only
    reads.
  - New `onOpen` step: when the search table is missing, it creates it, its
    triggers, and fills it from `media_items` (with tag names).
  - The v4 backfill now skips a missing search table, like the v6 clean-up.
  - Callers that ask for the database at the same moment now share one open.
    Found on the phone: at app start several callers opened at once, so the
    probe ran 7 times, and the new check could have closed a connection
    another caller was using. The check now always uses its own connection.
  - `DatabaseHelper` takes an optional `ftsCandidates` list, for tests.
- `test/repositories/database/fts_support_test.dart` (new): probe picks the
  next working module, returns null when none works, SQL text of the modules.
- `test/repositories/database/database_fts_repair_test.dart` (new): fallback to
  the next module, plain-table fallback, the broken state really blocks
  inserts, opening repairs it (all rows back, tag names included, insert,
  update and delete triggers work, `integrity_check` ok), concurrent opens
  share one repaired database, the repair survives a reopen, and a healthy
  database is left exactly as it was.
- `docs/architecture.md`: a note on how the search table is created and
  repaired, and the updated FTS5 risk line.

The schema version stays 9. A numbered migration could not do this repair: on
SQLite 3.22 it needs a closed and reopened connection, which cannot happen
inside the upgrade transaction.

## Checks

- `flutter analyze`: no issues.
- `flutter test`: all 2454 tests pass.
- `dart format`: no changes needed.
- On the Android 10 phone (dev flavor, debug build):
  - Repair case: installed over the original broken database. The table became
    FTS4, all three triggers came back, the 2 photos on the phone were indexed
    with 2 search rows, and `integrity_check` was `ok`. The third MediaStore
    image is a ghost entry whose file is missing, so skipping it is correct.
  - Fresh case: the database files were deleted (the phone blocks clearing app
    data over adb). The new database got FTS4 directly, 3 triggers, 2 photos,
    2 search rows, and a `MATCH` search found both.
  - The module probe and the broken-table check each ran once per start.
- Gradle daemons were stopped after the builds; none were left running.

## Not covered

- A database file that once had a working FTS5 table (with its shadow tables)
  and is then opened on a phone without FTS5 is not repaired; the shadow
  tables could clash with FTS4's. That cannot come from the bug fixed here.
