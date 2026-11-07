# Change log — Hide photos the app is not allowed to see

Implements plan: `plans/20261107_113934_hide-media-out-of-reach.md`

## What changed

With "Allow limited access" (or no access), the app showed every photo it had indexed while it had
full access. Now those rows are kept, with their data, but hidden from every list until access
comes back.

| File | Change |
| --- | --- |
| `lib/repositories/database/database_constants.dart` | `colMediaIsOutOfReach`; `schemaVersion` 6 → 7 |
| `lib/repositories/database/column_value_rules.dart` | `mediaIsOutOfReach` (0/1) rule in `all`; new `addedAfterV5` list so the v5 upgrade step skips a column that does not exist yet |
| `lib/repositories/database/database_helper.dart` | Column in `CREATE TABLE` with its `CHECK`; v7 migration adds the column (default 0) and its triggers; v5 step skips `addedAfterV5` rules |
| `lib/models/media_item.dart` | `isOutOfReach` field (`fromMap`, `toMap`, `copyWith`, `==`, `hashCode`) |
| `lib/repositories/database/media_dao.dart` | `is_out_of_reach = 0` added to `getMediaItems`, `searchMediaFts`, `getMediaItemsByIds`, `getFolderSummaries`, `getTotalCount`, `getTrashCount`, `getHashCandidates`, `restoreAllFromTrash`, `deleteAllTrashed`. New `markOutOfReachExcept`, `markAllOutOfReach`, `clearOutOfReach`, `hasOutOfReach`. The seen-ids temp table moved into a shared `_fillSeenIds` helper |
| `lib/repositories/database/album_dao.dart` | Filter in `getMediaForAlbum` |
| `lib/services/media/media_scanner_service.dart` | Limited access: always a full pass, unseen rows hidden, nothing deleted. Full access: hidden rows force a full pass, then all shown again. No access: every row hidden before the scan fails |
| `lib/repositories/album_repository.dart` | `_resolveCover` skips a hidden chosen cover |
| `lib/providers/media_providers.dart` | `mediaItemProvider` gives null for a hidden item |
| `test/repositories/database/media_dao_test.dart` | 12 tests: each filtered method, trash "Restore all" / "Empty trash" leave hidden rows alone, mark/clear, data survives hide → show, a rescan keeps the flag |
| `test/repositories/database/album_dao_test.dart` | `getMediaForAlbum` leaves out a hidden item |
| `test/repositories/album_repository_test.dart` | Hidden chosen cover falls back to a visible member |
| `test/services/media/media_scanner_service_test.dart` | 2 old partial-access tests now check "kept but hidden"; 4 new tests: limited, full again with data intact, quick scan with hidden rows runs a full pass, no access hides everything |
| `test/repositories/database/database_migration_test.dart` | v6 → v7 adds the flag (0) and refuses other values |
| `test/repositories/database/column_value_rules_test.dart` | New rule test |
| `test/providers/media_item_provider_test.dart` (new) | Visible item returned, hidden item gives null |
| `docs/security.md` §11 | "Limited or removed media access" paragraph |
| `docs/architecture.md` | Schema version 7, migration row 7, limited-access line |

## Checks

- `dart format`, `flutter analyze` (no issues), `flutter test`: all 2,263 tests pass.
- Emulator (Android 17), dev debug build:
  1. Full access: all photos shown. Starred one photo.
  2. Access removed: Timeline, Folders and Albums all show "Media access needed".
  3. "Allow limited access" with 2 photos picked: Timeline shows only those 2, Folders shows
     "Camera, 2 items", Favourites shows "Empty" (the starred photo was not picked).
  4. Full access again: every photo back, Favourites shows "1 item" with the starred photo.
- Gradle daemons stopped after the build; none left.

## Not done

- Search and tags were not checked by hand on the emulator (covered by unit tests).
- Known limit, as planned: stored album and tag counts still include hidden photos.
- The dev build stays installed on the emulator, with full access.
- `play_closed_testing/SUBMISSION_RECORD.md` line 21 still says "not recorded yet". The test of the
  submitted 2.6.4 build failed; this fix is not in a released build yet.
