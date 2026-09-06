# Change Log: Fix SQLite FTS Module Error Causing Media Scan Failure

**Plan:** [plans/20260906_140000_fix_sqlite_fts_media_scan_failure.md](plans/20260906_140000_fix_sqlite_fts_media_scan_failure.md)

## Summary of Changes
Fixed the media scan failure where opening the app or scanning media resulted in "Media scan failed" ("മീഡിയ സ്കാൻ പരാജയപ്പെട്ടു").

### Root Cause
Android's platform SQLite build does not compile the `fts5` extension module. When `DatabaseHelper` executed `CREATE VIRTUAL TABLE media_search_fts USING fts5(...)`, SQLite threw `DatabaseException(no such module: fts5 (code 1 SQLITE_ERROR))`, which prevented the database from opening. This caused media scanning and timeline loading to fail.

### Changes Implemented
1. **Database Helper (`lib/repositories/database/database_helper.dart`)**:
   - Extracted full-text search table creation and triggers into `_createFtsTableAndTriggers`.
   - Added progressive fallback: attempts `fts5`, then falls back to `fts4` (with `notindexed=media_id` and `tokenize=unicode61` supported natively on Android), then basic `fts4`, and finally a standard table.
   - Added v3 database migration in `_onUpgrade` to ensure existing installations automatically recover and create the search table.
2. **Database Constants (`lib/repositories/database/database_constants.dart`)**:
   - Bumped `schemaVersion` from 2 to 3.
3. **Media DAO (`lib/repositories/database/media_dao.dart`)**:
   - Updated `searchMediaFts` to order results by `date_taken` and `date_added` instead of the FTS5-only `rank` column.
4. **Fast Scroll Scrubber (`lib/widgets/media/fast_scroll_scrubber.dart`)**:
   - Added `hasContentDimensions` check before reading `maxScrollExtent` to prevent null-check exceptions on unlaid-out scroll positions.
   - Provided bounded width constraints to the scrubber Stack widget.

## Verification
- `flutter analyze` completed with 0 issues.
- `flutter test` passed all 1,824 automated unit and widget tests.
- Tested on Android device: verified database creation succeeded with FTS fallback, media scan completed without errors, and media items populated the timeline.
