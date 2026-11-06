# Await the delete in deleteMediaItemsMissingFrom

Implements [plans/20261101_200253_await-media-dao-delete.md](../plans/20261101_200253_await-media-dao-delete.md).

## What changed

- `lib/repositories/database/media_dao.dart`: `return db.delete(` is now `return await db.delete(`
  in `deleteMediaItemsMissingFrom`, on the path used when `seenIds` is empty.

## Why

Without `await`, the function left the `try` block before the delete finished. A failed delete
skipped the `catch` and reached the caller as a raw database error, not a `StorageException`.
This also removes the one `flutter analyze` warning at this line.

## Checks

`flutter analyze` found no issues, and `flutter test` passed all 1985 tests.

## Not tested

No new test was added, as the plan says, so no test proves the `catch` now runs for this path.
