# Timeline auto-refresh and readable day counts

**Status:** completed

## The issue

1. **Refresh on open / return to the app.** `lib/screens/timeline/timeline_screen.dart`
   already runs a scan on start and on resume (`AppLifecycleListener.onResume`). But it is an
   *incremental* scan: it only reads MediaStore rows whose `date_modified` is newer than the
   newest row already in the database. So it misses:
   - photos deleted or moved to trash in another app (they stay on the timeline),
   - files that arrive with an old modified time (restored from trash, copied with the
     original timestamp, some downloads).
   To the user this looks like "the timeline did not refresh".
2. **Refresh when switching to the Timeline tab.** `lib/screens/home/home_shell_screen.dart`
   keeps all three tabs alive in an `IndexedStack`. Tapping the Timeline tab only changes the
   index, so nothing reloads.
3. **Day counts are hard to read.** `lib/widgets/media/timeline_date_header.dart` draws the
   count with `labelSmall` (about 11 sp) in `onSurfaceVariant` grey. On the black background
   it is tiny and dim.

## Files to change

- `lib/services/media/media_scanner_service.dart`
- `lib/repositories/database/media_dao.dart` (only if a count helper is missing — `getTotalCount` already exists)
- `lib/screens/home/home_shell_screen.dart`
- `lib/screens/timeline/timeline_screen.dart` (small: share one refresh entry point)
- `lib/widgets/media/timeline_date_header.dart`
- `test/services/media/media_scanner_service_test.dart` (new or updated cases)
- `test/widgets/media/timeline_date_header_test.dart` (if present; otherwise a small new one)

## The fix

### A. Make the quick scan notice deletions and old-dated files
In `MediaScannerService.scan(incremental: true)`:
- After the incremental pass, compare the device count (`getMediaCount()`, already read at
  the start of the scan) with the number of rows in the database.
- If the numbers differ, something was added with an old date or was removed. Then run the
  full pass (same code path as `incremental: false`), which also removes stale rows.
- Keep the existing safety rule: stale rows are removed only with full permission, never with
  partial ("selected photos") access. With partial access the count check is skipped,
  because hidden items make the numbers differ on purpose.
- When the numbers match (the common case), nothing extra runs, so resume stays cheap.

### B. Refresh when the Timeline tab is tapped
In `HomeShellScreen.onDestinationSelected`: when the user moves **to** tab 0 from another
tab, call `mediaScanControllerProvider.notifier.scan(incremental: true)`. The controller
already ignores a call while a scan is running, so fast tab taps cannot start two scans.
Tapping the tab while already on it does nothing new (no change).

### C. Readable count
In `TimelineDateHeader`, draw the count as a small rounded "pill":
- text style `labelMedium`, `FontWeight.w600`, colour `onSecondaryContainer`,
- background `secondaryContainer`, padding 8 × 2, fully rounded corners.
This uses theme colours, so it has good contrast in both light and dark themes.
Add a `Semantics` label is not needed — the number is read as text already.

## Tests
- Scanner: incremental scan with matching counts does not run a full pass; with a lower
  device count it runs the full pass and removes the stale row; with partial permission it
  never removes rows.
- Header: the count text is shown inside the pill.
- Run `flutter analyze` and `flutter test`.

## Security impact
None. No new permission, no network, no new package. The full pass only reads MediaStore,
as it already does today, and removes only database index rows — never real media files.

## Not in scope
- Listening to MediaStore change events live (a `ContentObserver` in Kotlin). It would update
  even while the app is open, but adds native code; can be a later change.
