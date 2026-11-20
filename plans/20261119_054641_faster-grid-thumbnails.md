# Plan — Faster thumbnails when scrolling large grids

**Status:** completed

## The issue

When you scroll the Timeline, or open a folder with many photos, a lot of tiles show
a spinning loader for a long time before the picture appears.

The 9 Nov fix (`plans/20261109_190215_timeline-load-speed.md`) made the *list* of
items load fast. It did not touch how each tile's *picture* (thumbnail) is made.
That path has three problems:

1. **One thread, first-come-first-served.**
   `MediaStoreChannelHandler.kt` makes every thumbnail on one shared thread
   (`worker`, a single-thread executor). The same thread also runs delete jobs.
   Requests are served in arrival order. After a fast fling, hundreds of requests for
   tiles you have already scrolled past are in the queue *ahead of* the tiles now on
   screen. The visible tiles wait for all of them.

2. **Off-screen requests are never cancelled.**
   `thumbnailProvider` (`lib/providers/media_providers.dart`) is a plain
   `FutureProvider.family`. It is never disposed, so a request keeps running after
   its tile leaves the screen. Nothing tells the queue "this one is no longer needed".
   Its results are also kept in memory for every item ever shown, until a
   memory-pressure event clears them.

3. **A full cache scan after every new thumbnail.**
   `ThumbnailDiskCache.write()` calls `evictIfOverBudget()` after each save. That
   lists the whole cache folder and reads the size and date of every file. With
   20,000 cached thumbnails, each new thumbnail costs 20,000 file checks, and the
   tile waits for this to finish (`ThumbnailService._store` awaits the write).
   This gets worse as the library grows, so big folders feel the slowest.
   Smaller: every disk-cache *read* also changes the file's date (`_touch`) and checks
   `exists()` first, which is two extra file-system calls per tile.

## The fix

### Step 1 — A request queue in Dart that serves visible tiles first

New class `ThumbnailRequestQueue` in `lib/services/thumbnail/` (service layer,
no Flutter or `BuildContext`).

- At most N native thumbnail calls run at once (N = 4; 3 on low-RAM devices,
  taken from `ThumbnailCacheConfig`).
- Waiting requests are served **newest first** (last in, first out). The tiles the
  user just scrolled to are the newest requests, so they go first.
- Each request can be cancelled. A cancelled request that has not started is
  dropped and never reaches Android. One that has already started finishes, and its
  result still goes into the caches (it is not wasted).

`ThumbnailService` uses this queue only for the slow steps (Android thumbnail and the
Dart decode fallback). Memory-cache and disk-cache hits skip the queue.
Requests for the same item still share one future, as today. A shared request is
cancelled only when *every* caller has cancelled it.

### Step 2 — Dispose and cancel off-screen requests

- `thumbnailProvider` becomes `FutureProvider.autoDispose.family`. When the tile
  leaves the screen, `ref.onDispose` cancels its request.
- The bytes stay in the RAM cache (`ThumbnailMemoryCache`, already size-limited), so
  scrolling back is still instant.
- `lib/providers/memory_providers.dart`: its comment says Riverpod keeps every
  entry for the app's life. That is no longer true. Keep the `invalidate` call (it is
  harmless) and fix the comment.
- `lib/screens/trash/trash_screen.dart:103` uses `ref.read` on the provider. With
  auto-dispose a bare `read` can start and then drop the request at once. Check that
  code and change it to read the future safely (or `watch` inside the build).
- Test overrides in `test/` that use `thumbnailProvider(...).overrideWith(...)`
  should still compile; fix any that do not.

### Step 3 — Several native threads, kept apart from other jobs

`MediaStoreChannelHandler.kt`:

- Add a separate `thumbnailWorker` with a small fixed pool (4 threads) used only by
  `loadThumbnail`. Deletes and other jobs stay on `worker`, so a long delete no
  longer blocks thumbnails, and thumbnails no longer delay deletes.
- Shut it down in `dispose()` as `worker` is today.
- The Dart queue (Step 1) already limits how many calls are sent, so this pool never
  gets a big backlog.

### Step 4 — Stop scanning the whole cache on every write

`ThumbnailDiskCache`:

- Keep a running total of bytes in memory. Measure it once with a full scan, the first
  time it is needed, then add each write's size.
- Run `evictIfOverBudget()` only when the running total goes over `maxBytes`. After
  eviction, the total is set from the real scan again. Only one eviction runs at a
  time.
- `read()`: drop the separate `exists()` check (a missing file is caught as a miss),
  and do the date "touch" without waiting for it.

`ThumbnailService._store`: put the bytes in the RAM cache and return them to the
tile at once. The disk write runs after, without the tile waiting for it. Errors are
still caught and logged, as today.

## Files to change

- `lib/services/thumbnail/thumbnail_request_queue.dart` (new)
- `lib/services/thumbnail/thumbnail_service.dart`
- `lib/services/thumbnail/thumbnail_disk_cache.dart`
- `lib/services/device/device_memory_service.dart` (add the concurrency number to
  `ThumbnailCacheConfig`)
- `lib/core/constants/app_constants.dart` (concurrency numbers per RAM tier)
- `lib/providers/media_providers.dart`
- `lib/providers/memory_providers.dart` (comment only)
- `lib/screens/trash/trash_screen.dart` (only if the `ref.read` needs a change)
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- Tests:
  - `test/services/thumbnail/thumbnail_request_queue_test.dart` (new): limit on running
    calls, newest-first order, cancel before start drops the call, cancel after start
    still caches, a shared request stays alive while one caller still wants it.
  - `test/services/thumbnail/thumbnail_service_test.dart`: cache hits skip the queue;
    the result is returned before the disk write ends.
  - `test/services/thumbnail/thumbnail_disk_cache_test.dart`: no eviction scan while
    under budget; eviction still trims to the budget when over it.
  - `test/providers/memory_providers_test.dart` and other tests that override
    `thumbnailProvider`: update if auto-dispose changes them.

No new packages. No changes to `docs/guidelines/` (submodule).

## What this does not change

- Thumbnail size and quality stay the same.
- The first time a photo is ever shown, Android still has to make its thumbnail. That
  first pass will still show some loaders on a very fast fling, but the tiles you
  stop on should fill first and quickly.
- No prefetching of tiles ahead of the scroll. That could be a later step once this is
  measured on a real device.

## How to check

- `flutter analyze` clean, `flutter test` all pass, `dart format .`.
- On a real phone: clear the app cache, open a folder with several thousand photos,
  fling down, stop, and watch how fast the tiles on screen fill. Compare with today's
  build.
- Gradle daemons stopped after the build (global rule).

## Security impact

None. No new permissions, network, or storage location. Thumbnails stay in the app's
own cache folder. A new background thread pool on the Android side reads only
MediaStore thumbnails, with the same `IncomingUriRules` check as today.
