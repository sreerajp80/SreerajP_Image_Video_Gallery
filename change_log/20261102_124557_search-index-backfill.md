# Search index backfill (G45)

Implements [plans/20261102_124557_search-index-backfill.md](../plans/20261102_124557_search-index-backfill.md).

## What changed

- `lib/repositories/database/database_constants.dart`: `schemaVersion` 3 → 4.
- `lib/repositories/database/database_helper.dart`: new v4 step `_backfillSearchIndex`. It adds a
  search row, with the item's tag names, for every media item that has none. v3 is unchanged,
  because it has shipped.
- `test/repositories/database/database_migration_test.dart`: two new tests.
  - v1 with no search table: the old photo is indexed with its name, notes and tag. This test was
    run before the fix and **failed** (no row found), which proved the bug.
  - v3 with a full index: no rows are added, and the existing row is unchanged.
- `docs/architecture.md`: schema version 4 and its history row.
- `README.md` §6: corrected the test file path and added the rule that shipped migrations are never
  changed.
- `docs/known_gaps.md`: G45 moved to resolved.

## Checked

- Backups store the schema version but never compare it on restore, so older backups still restore.

## Test results

- `dart format`: no changes needed.
- `flutter analyze`: clean.
- `flutter test`: all 1,992 pass.

## Not verified

- Not run on a phone. Most phones will show no difference, because they already had a search table.
