# Plan: Fix SQLite FTS Module Error Causing Media Scan Failure

**Status:** Completed

## Problem
When opening the app or tapping "Scan media on device", the media scan fails with "Media scan failed" ("മീഡിയ സ്കാൻ പരാജയപ്പെട്ടു").
Logcat inspection shows that Android's built-in SQLite engine throws:
`DatabaseException(no such module: fts5 (code 1 SQLITE_ERROR))` when trying to create virtual table `media_search_fts USING fts5`.
Because this table creation is run inside the initial database creation batch, the database fails to open. Since the database cannot open, the media scanner and timeline cannot read or save any media items.

## Proposed Solution
Android OS SQLite includes `fts4` instead of `fts5`.
We will make the database initialization resilient:
1. Attempt creating `media_search_fts` using `fts5` (supported in desktop test environments).
2. If `fts5` is unavailable (as on Android), fall back to `fts4` with `notindexed=media_id` and `tokenize=unicode61`.
3. If `fts4` with tokenizer is unavailable, fall back to basic `fts4`.
4. If no FTS module exists, fall back to a standard table so the database opens safely without crashing.
5. Create synchronization triggers (`trg_media_insert`, `trg_media_update`, `trg_media_delete`).
6. Update `searchMediaFts` query in `MediaDao` to avoid referencing `rank`, which is only available in FTS5.
7. Bump database version to 3 and add migration logic in `_onUpgrade`.
8. Guard `ScrollPosition.maxScrollExtent` and bounded layout in `FastScrollScrubber`.

## Files to Change
- `lib/repositories/database/database_constants.dart`
- `lib/repositories/database/database_helper.dart`
- `lib/repositories/database/media_dao.dart`
- `lib/widgets/media/fast_scroll_scrubber.dart`

## Verification
- Run `flutter analyze` (must have zero warnings).
- Run `flutter test` (all unit and repository tests must pass).
- Test on the connected Android device to confirm the database opens, media scanning succeeds, and photos load in the timeline.
