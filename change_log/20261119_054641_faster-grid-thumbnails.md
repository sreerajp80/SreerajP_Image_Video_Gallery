# Change log — Faster thumbnails when scrolling large grids

Implements plan: `plans/20261119_054641_faster-grid-thumbnails.md`

## What changed

### Step 1 — Request queue, newest first

- New `lib/services/thumbnail/thumbnail_request_queue.dart`:
  `ThumbnailRequestQueue` runs at most N jobs at once and starts the newest
  waiting job first. A waiting job can be cancelled; it then never runs and
  completes with null. A job that has started always finishes.
- `lib/services/device/device_memory_service.dart`: `ThumbnailCacheConfig` has a
  new `maxConcurrentThumbnails`.
- `lib/core/constants/app_constants.dart`: 3 on low-RAM devices, 4 on medium and
  high, plus `nativeThumbnailThreads = 4` for reference.

### Step 1 and 4 — Thumbnail service

- `lib/services/thumbnail/thumbnail_service.dart`:
  - New `requestThumbnail()` returns a `ThumbnailRequest` with `future` and
    `cancel()`. `getThumbnail()` still works and is not cancellable.
  - RAM and disk-cache hits skip the queue. Only the Android thumbnail and the
    Dart decode fallback go through it.
  - Callers asking for the same item share one job. The job is dropped only
    when every caller has cancelled. A request after that starts fresh work.
  - A new thumbnail is returned as soon as it is in RAM. The disk write runs in
    the background. `clearAll()` waits for started writes first.
    `flushDiskWrites()` (marked for tests) waits for them.

### Step 2 — Dispose and cancel off-screen tiles

- `lib/providers/media_providers.dart`: `thumbnailProvider` is now
  `FutureProvider.autoDispose.family`. On dispose it cancels its request.
- `lib/providers/memory_providers.dart`: comment updated. Off-screen tiles no
  longer hold thumbnail bytes in Riverpod.
- `lib/screens/trash/trash_screen.dart`: not changed. Its `ref.read` runs while
  the list tile is on screen and watching the same provider, so the value is
  still there.

### Step 3 — Android thread pool

- `MediaStoreChannelHandler.kt`: new `thumbnailWorker`, a fixed pool of 4
  threads (`THUMBNAIL_THREADS`). `loadThumbnail` runs on it. Shut down in
  `dispose()`.

### Step 4 — Disk cache

- `lib/services/thumbnail/thumbnail_disk_cache.dart`:
  - Keeps a running byte total. It is measured once with a full scan, then each
    write adds its size. The full eviction scan runs only when the total goes
    over budget, and only one runs at a time. Eviction and `clear()` reset the
    total to the real value.
  - `read()` no longer calls `exists()` first, and does not wait for the date
    "touch".

## Difference from the plan

- `readBytes` also moved to the new `thumbnailWorker`. While building, I found
  that the library scan (`queryMedia`) runs on the same single `worker` thread,
  so the thumbnail fallback (which uses `readBytes`) would wait behind a scan.
  `readBytes` only reads, so it is safe on the pool. Same file as planned.
- `test/services/media/fake_media_store_channel.dart` was not in the plan's file
  list. It got a `thumbnailGate` (to hold device calls "in progress") and
  `thumbnailUris` (call order), needed by the new service tests.

## Tests

- New `test/services/thumbnail/thumbnail_request_queue_test.dart`: the limit,
  newest-first order, cancel before start, cancel after start, a failing job
  frees its slot.
- `test/services/thumbnail/thumbnail_service_test.dart`: newest first, a
  cancelled request never reaches the device, shared work survives one cancel,
  a request after a cancel starts fresh, RAM hits skip the queue. Two existing
  tests now wait for the background disk write. tearDown waits for writes before
  deleting the temp folder.
- `test/services/thumbnail/thumbnail_disk_cache_test.dart`: no folder scan per
  write while under budget; `clear()` resets the total.
- `flutter analyze`: no issues. `flutter test`: all 2,491 tests pass. The
  thumbnail tests passed 5 runs in a row.

## Not done / not checked

- The Kotlin change has not been compiled yet. No Android build was run.
- Not measured on a real phone yet.

## Security impact

None. No new permissions, network or storage location. The new Android thread
pool runs the same `IncomingUriRules` check as before.
