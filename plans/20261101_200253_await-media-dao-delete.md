# Await the delete in deleteMediaItemsMissingFrom

**Status:** completed

## Files to change

- `lib/repositories/database/media_dao.dart`

## The issue

`flutter analyze` gives one warning at `media_dao.dart:923`, and the project rule is zero warnings.

Line 923 is `return db.delete(...)` inside a `try` block, with no `await`. The function leaves the
`try` before the delete finishes. If the delete fails, the `catch` does not run, so the caller gets
a raw database error and not a `StorageException`.

This path runs only when `seenIds` is empty. The other path in the same function uses
`await db.transaction(...)` and is not affected.

## The fix

Change line 923 to `return await db.delete(`. Nothing else changes.

## Checks

The user runs `flutter analyze` (expected: no issues) and `flutter test` (expected: all pass).

No new test is planned. The analyzer warning itself guards this line, and forcing a database
failure in a test would need more setup than this one-word fix is worth.
