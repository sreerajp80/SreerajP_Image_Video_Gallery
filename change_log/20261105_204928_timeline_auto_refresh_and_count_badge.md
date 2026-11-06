# Timeline auto-refresh and readable day counts

Implements plan: `plans/20261105_203106_timeline_auto_refresh_and_count_badge.md`

## What changed

### Quick scan now notices deletions and old-dated files
- `lib/services/media/media_scanner_service.dart`
  - The page-by-page reading loop moved into a private `_indexPass(...)` method so it can
    run twice in one scan.
  - After a quick (`incremental: true`) pass with full permission, the scanner compares the
    device count with the number of indexed rows. If they differ, it runs a full pass, which
    also removes rows for files that are gone.
  - It remembers how many unreadable rows the last full pass skipped, so a few bad files do
    not force a full pass on every resume.
  - With partial ("selected photos") access the check is skipped and nothing is removed, as
    before.
- `lib/repositories/database/media_dao.dart`
  - New `getMediaStoreBackedCount()`: counts every non-vaulted row (trashed or not), which
    is what should still be in MediaStore.

### Refresh when returning to the Timeline tab
- `lib/screens/home/home_shell_screen.dart`
  - Tapping Timeline from another tab starts a quick scan. The scan controller already
    ignores a call while a scan runs.

### Readable day count
- `lib/widgets/media/timeline_date_header.dart`
  - The count is now a rounded pill: `labelMedium`, semi-bold, `onSecondaryContainer` text on
    a `secondaryContainer` background.

### Tests
- `test/services/media/media_scanner_service_test.dart`: the old "incremental scan keeps
  rows" test now expects the new behaviour. Added cases for matching counts (no full pass),
  deletion, an old-dated file, skipped rows, and partial access.
- `test/widgets/media/timeline_date_header_test.dart` (new): checks the pill colours.

## Not done from the plan
- `lib/screens/timeline/timeline_screen.dart` was not changed. Its existing resume and
  first-frame refresh already call the quick scan, which now does the count check, so no
  shared entry point was needed.

## Checks
- `flutter analyze`: no issues.
- `flutter test`: all tests pass.
- Not yet checked on a real device.

## Security impact
None. No new permission, network use or package. Only index rows are removed, never media
files.
