# Change log — Make the Timeline load fast on large libraries

Implements plan: `plans/20261109_190215_timeline-load-speed.md`

## What changed

### Step 1 — Tags read in one query

- `lib/repositories/database/media_dao.dart`
  - New `_rowsToItems` and `_getTagsForMediaIds`: tags for a whole result are
    read in one query (an `IN (...)` list for 500 ids or fewer, otherwise every
    tag link at once, filtered in Dart).
  - `getMediaItems`, `searchMediaFts` and `getMediaItemsByIds` use it. Before,
    each made one extra query per row, so a 30,000-photo library meant 30,001
    database trips. Now it is 2.
  - The list order now has the id as a tie-breaker
    (`<sort column> <dir>, id <dir>`), so a first page read with `LIMIT` is
    always the exact start of the full list.

### Step 2 — Reload only when the library changed

- `lib/services/media/media_scanner_service.dart`
  - `ScanResult` has `fullPass` (default `true`) and `changed` (rows that were
    really new or changed), plus `libraryChanged`.
- `lib/repositories/database/media_dao.dart`
  - `batchUpsertMediaItems` now returns how many rows were new or had an
    Android-owned column changed (it was `void`). New helper
    `_countMissingIds` counts new rows in chunks of 500 ids.
- `lib/providers/media_providers.dart`
  - New `mediaLibraryVersionProvider`, a counter bumped by
    `MediaScanController` when a scan reports `libraryChanged`, when a scan
    fails, or when permission is missing (safe side).
  - `mediaItemsProvider` and `indexedMediaCountProvider` watch this counter
    instead of the scan state, so a quick scan that finds nothing new no
    longer reloads the library, and a normal scan reloads once, not twice.

### Step 3 — Progressive first load

- `lib/providers/timeline_providers.dart`
  - `timelineItemsProvider` is now a `StreamProvider`. On a cold load with the
    newest-first sort it sends the newest 300 items (`kTimelineFirstPageSize`)
    first, then the full list. If the full list is already loaded (reload after
    delete or scan), or the sort is different, it sends the full list in one
    step.

## Difference from the plan

- The plan's first idea for Step 2 was `libraryChanged = fullPass ||
  indexed > 0 || removed > 0`. While building it I found that a quick scan
  always re-reads the newest row ("modified at or after"), so `indexed` is
  never 0 and the list would still reload every time. To fix this,
  `batchUpsertMediaItems` now reports real changes and `ScanResult` carries
  them in `changed`. Same files as planned; no new files in `lib/`.
- The id tie-breaker in the sort order was not in the plan. Without it the
  first page and the full list could order same-date photos differently.

## Tests

- New `test/repositories/database/media_dao_load_speed_test.dart`: tags on
  lists (none, one, many, more than 500 items, a `LIMIT` page, by-ids order),
  the upsert change count, and the stable order on ties.
- New `test/providers/media_library_reload_test.dart`: first page then full
  list; no first page on reload or other sorts; no reload after an empty quick
  scan; one reload after a scan with changes; `libraryChanged` rules.
- `test/providers/timeline_providers_test.dart` and
  `test/screens/viewer/media_viewer_screen_test.dart`: overrides now return a
  stream; the timeline test listens to the stream (Riverpod pauses a stream
  nobody listens to; on screen the timeline always listens).
- `test/repositories/media_repository_test.dart`: one test picked "the first
  item" of two photos with the same date, which depended on an undefined
  order. It now picks the photo by id.
- `flutter analyze`: no issues. `flutter test`: all 2,334 tests pass.

## Not done / not checked

- Not measured on a real device yet.
- The albums, search and trash providers still watch the scan state directly
  and reload on every scan. They were out of scope for this plan.

## Security impact

None. Local database reads and provider wiring only.
