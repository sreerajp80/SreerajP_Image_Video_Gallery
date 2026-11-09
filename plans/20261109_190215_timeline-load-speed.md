# Make the Timeline load fast on large libraries

**Status:** completed

## The issue

With a large library (for example 30,000 photos) the Timeline takes a very long
time to show anything. Three causes, biggest first:

1. **One extra database call per photo (the "N+1" problem).**
   `MediaDao.getMediaItems` runs one query for the list, then, inside a loop,
   one more query per row to read that row's tags (`_getTagsForMedia`).
   30,000 photos means 30,001 trips from Dart to the Android SQLite side.
   Each trip costs a fraction of a millisecond, so together they cost many
   seconds. The same loop is in `searchMediaItems` and `getMediaItemsByIds`.
2. **The whole list is loaded twice on every app open and resume.**
   `mediaItemsProvider` watches `mediaScanControllerProvider`. A scan starts on
   every open and resume, and the controller's state changes twice (loading,
   then done). Each change throws the list away and loads all of it again,
   even when the scan found nothing new.
3. **Nothing shows until every row is loaded.** The first screen needs only
   about a hundred photos, but the user waits for all 30,000.

## The fix

### Step 1 — Read tags in one query, not one per photo (biggest win)

- Add a private helper `_getTagsForMediaIds(List<String> ids)` in `MediaDao`
  that returns `Map<String, List<String>>` (media id → tag names) using one
  query:
  - for a short list (500 ids or fewer): `WHERE media_id IN (...)`;
  - for a longer list: read all tag links in one go (the tag link table is
    small next to the media table) and keep only the ids asked for.
- Use it in `getMediaItems`, `searchMediaItems` and `getMediaItemsByIds`.
  The single-item methods keep `_getTagsForMedia` (one row, one query is fine).
- Result: 30,001 database trips become 2.

### Step 2 — Reload only when the library really changed

- Add `fullPass` (bool, default `true`) to `ScanResult`, set by the scanner,
  and a getter `libraryChanged` = `indexed > 0 || removed > 0 || fullPass`.
  A full pass can hide or show rows without counting them, so it always
  counts as a change, which keeps this safe.
- Add `mediaLibraryVersionProvider` (a simple counter) in `media_providers.dart`.
  `MediaScanController` bumps it when a scan finishes with `libraryChanged`,
  or when a scan fails (safe side: reload).
- `mediaItemsProvider` and `indexedMediaCountProvider` watch this counter
  instead of the scan controller's state.
- Result: a quick scan that finds nothing new causes no reload at all. The
  existing `ref.invalidate(mediaItemsProvider)` calls after delete, move,
  restore and so on keep working as before.

### Step 3 — Show the newest photos first, then the rest (progressive load)

- `timelineItemsProvider` becomes a `StreamProvider`. It first loads the
  newest 300 items (`limit: 300`), sends them out so the Timeline draws at
  once, then loads the full list and sends it out.
- `timelineDataProvider` and `flashbackMemoriesProvider` keep working on
  whatever list is current, so they regroup when the full list arrives.
- Only for the default newest-first sort, which is what the Timeline uses.
  For any other filter or sort it loads the full list in one step as today.

### Why not true page-by-page loading while scrolling?

I considered it and do not recommend it now. The fast-scroll scrubber needs
every date to place its label, "select all" needs every id, the "On This Day"
row needs every year, and the viewer swipes through the same list. Paging
would mean rewriting all four. After Steps 1–3 the full list of 30,000 small
rows should load in about a second or two in the background, while the first
screen shows almost at once. If that is still too slow on a real device, page
loading can be a later plan.

**Known small side effect of Step 3:** for the short moment before the full
list arrives, the scrubber covers only the first 300 items, and the photo count
on the oldest day header in that first page may be low. Both correct
themselves when the full list lands.

## Files to change

- `lib/repositories/database/media_dao.dart` — batched tag helper; use it in
  the three list methods.
- `lib/services/media/media_scanner_service.dart` — `ScanResult.fullPass`
  and `libraryChanged`.
- `lib/providers/media_providers.dart` — `mediaLibraryVersionProvider`;
  scan controller bumps it; list and count providers watch it.
- `lib/providers/timeline_providers.dart` — progressive `timelineItemsProvider`.
- `test/repositories/database/media_dao_test.dart` — tags still correct for
  lists (no tags, one tag, many tags, list longer than 500).
- `test/providers/timeline_providers_test.dart` — first page arrives, then
  the full list.
- `test/providers/` (new or existing scan test) — a quick scan with no
  changes does not reload; a scan with changes does.
- `docs/architecture.md` — only if it describes how the list reloads after a
  scan (will check, and update the line if so).

## Security impact

None. Read path of the local database and provider wiring only. No change to
network, permissions, storage locations or dependencies.

## How to check

- `flutter analyze` clean, `flutter test` passes.
- On a device with a large library: open the app and time how long until the
  first photos show, before and after. Pull to refresh with no new photos
  should not make the grid flash or reload.
