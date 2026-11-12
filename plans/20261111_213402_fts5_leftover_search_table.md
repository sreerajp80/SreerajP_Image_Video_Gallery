# Plan: Broken FTS5 search table on old Android SQLite

**Status:** completed

## The problem

On an Android 10 phone (SQLite 3.22.0) a fresh install of the app indexes no
photos. Every insert into `media_items` fails with
`DatabaseException(no such module: fts5)`.

The database holds `CREATE VIRTUAL TABLE media_search_fts USING fts5(...)`, and
the triggers `trg_media_insert`, `trg_media_update` and `trg_media_delete`
write to it. That SQLite has no FTS5 module, so every insert, update and delete
on `media_items` fails, because the trigger cannot compile.

## Root cause (proven on the phone)

`DatabaseHelper._createFtsTableAndTriggers` tries FTS5 first, catches the
error, then tries FTS4 with `CREATE VIRTUAL TABLE IF NOT EXISTS`.

I ran a small test program on the phones through `adb` (`app_process`, using
Android's own SQLite). Results:

| Test | SQLite 3.22 (Android 10) | SQLite 3.50 (Android API 37) | SQLite 3.54 (PC tests) |
|------|------|------|------|
| Failed FTS5 create, no transaction | nothing left behind | nothing left behind | nothing left behind |
| Failed FTS5 create **inside a transaction** | **the FTS5 row stays in `sqlite_master`** | nothing left behind | nothing left behind |
| Then FTS4 `CREATE ... IF NOT EXISTS` | does nothing, the name already exists | creates FTS4 | creates FTS5 |
| `DROP TABLE media_search_fts` on the broken table | fails: `no such module: fts5` | — | — |

So the cause is a bug in old SQLite: when `CREATE VIRTUAL TABLE` fails because
the module is missing, it has already written the table's row into the schema,
and inside a transaction nothing undoes that write. sqflite always runs
`onCreate` inside a transaction. Then `IF NOT EXISTS` sees the name and skips
FTS4, and the transaction commits the useless FTS5 row. Newer SQLite (3.50,
3.54) cleans up correctly, which is why the PC tests and the newer phone never
showed it.

Two more facts from the phone that shape the repair:

1. `DROP TABLE` cannot remove the broken table (it needs the missing module).
   The only way is `PRAGMA writable_schema = ON` and deleting that one row from
   `sqlite_master`. This worked on the phone; `PRAGMA integrity_check` stayed
   `ok`.
2. After that delete, **the same connection still remembers the old table**,
   even after commit and even after changing `schema_version`. A new
   `CREATE ... IF NOT EXISTS` is silently skipped. Only closing and reopening
   the database clears it. So the repair cannot finish inside one
   `onUpgrade` transaction.

Raw probe output is kept outside the repository (session notes); it is not
needed to review this plan.

## The fix

### 1. Fresh install: decide the module before creating (fixes new databases)

- Add a small probe that runs on a **separate in-memory database** (its own
  connection, not inside any transaction), once per app process. It tries, in
  order: FTS5, FTS4 with `unicode61`, plain FTS4, and remembers the first one
  that works. It creates the test table in `temp`, then drops it.
- `_createFtsTableAndTriggers` uses the probed choice directly. It no longer
  "tries and catches" inside the transaction, so a failed `CREATE` can never
  leave a row behind. If nothing works, it still makes the plain table.
- The order stays FTS5 first, because the PC test SQLite has FTS5 but no FTS4.
  On Android the probe will pick FTS4.

### 2. Existing broken database: repair on open (fixes the phone already hit)

Because the repair needs a close and reopen, it cannot be a normal numbered
step in `onUpgrade`. Instead:

- **Before the normal open** (in `_initDatabase`, only when the database file
  already exists): open the file briefly with no version (so no transaction),
  check `media_search_fts`. If it exists but `SELECT ... FROM media_search_fts
  LIMIT 0` fails with `no such module`, then in one transaction: drop the three
  search triggers, and with `writable_schema` delete exactly that one
  `sqlite_master` row (only if it is a `CREATE VIRTUAL TABLE` row with
  `rootpage = 0`). Close the file. When the table is fine, this only reads.
- **The normal open** then starts with a fresh connection that knows the table
  is gone. `onUpgrade` steps are made safe for a missing search table (the v4
  backfill skips it, like the v6 clean-up already does).
- **Add an `onOpen` step**: if `media_search_fts` is missing, create it with the
  probed module, create the triggers, and fill it from `media_items` (with tag
  names) using the existing `_backfillSearchIndex`. This runs in one
  transaction. On a healthy database it is one cheap `sqlite_master` lookup.

Why not a "version 10" migration: the repair cannot finish inside the upgrade
transaction on SQLite 3.22 (proven above), and a broken database is already at
version 9. A check on every open also covers a database file that comes back
in a broken state some other way. The cost on a healthy database is one short
extra open and two small reads at app start. The schema version stays 9.

### 3. Tests (sqflite_common_ffi)

PC SQLite 3.54 does not have this bug, so the tests copy the broken state by
hand:

- **Fallback test:** give the helper a module list whose first entry is a
  module that does not exist (test-only constructor parameter). Check that the
  fresh database gets the next working module, that inserting into
  `media_items` works, and that search finds the item.
- **Probe test:** the probe picks the first working module and skips a
  missing one, without leaving any table behind.
- **Repair test:** create a normal database file with media and tags, then
  replace the search table's row with exactly what SQLite 3.22 leaves
  (`CREATE VIRTUAL TABLE media_search_fts USING <missing module>(...)`,
  `rootpage 0`) plus the three triggers. Confirm inserts now fail. Then open it
  with `DatabaseHelper`: the table must be usable, inserts must work, every
  `media_items` row must have one search row (tag names included), and
  `PRAGMA integrity_check` must be `ok`.
- **Healthy database test:** opening a good database changes nothing
  (same search rows, same schema).

### 4. Check on the phone

Build the dev flavor, install it on the Android 10 phone over the current
broken database (repair case), check that photos are indexed. Then clear the
app data (fresh install case) and check again. Stop the Gradle daemons after
the build.

## Files to change

- `lib/repositories/database/database_helper.dart` — probe, creation without
  try-and-catch, pre-open repair, `onOpen` rebuild, safe v4 step.
- `lib/repositories/database/fts_support.dart` (new) — the module list and the
  probe, so the helper stays readable. Layer: repositories/database.
- `test/repositories/database/fts_support_test.dart` (new).
- `test/repositories/database/database_fts_repair_test.dart` (new).
- `docs/architecture.md` — a short note on how the search table is created and
  repaired (only if it already describes the FTS fallback).
- `change_log/<timestamp>_fts5_leftover_search_table.md` (new, after the work).

`database_helper.dart` already has uncommitted changes from other work. I will
only add to it and not touch those lines. Nothing is committed.

## Security impact

Storage only. The repair writes to the app's own database schema with
`writable_schema`, limited to one row chosen by exact name, type and
`rootpage = 0`, and only when SQLite itself reports the module missing. No new
permission, no network, no new package.

## Risks

- `writable_schema` is a sharp tool. The delete is limited to one exact row,
  and the phone test showed `integrity_check` stays `ok`.
- If the app is killed between the clean-up and the rebuild, the next open
  finds the table missing and rebuilds it. No data in `media_items` is touched.
- The probe adds one in-memory database open per app start (a few
  milliseconds).
