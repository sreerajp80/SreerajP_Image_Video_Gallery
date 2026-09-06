# Change Log: Phase 4 — Chronological Timeline, Dynamic Grid & Flashback Memories

**Date:** 2026-08-29
**Implements:** [plans/20260829_102129_phase_4_timeline_grid_and_flashbacks.md](../plans/20260829_102129_phase_4_timeline_grid_and_flashbacks.md)
**Status:** Completed

## What changed

Phase 3 gave the app a media scanner, an index, and a thumbnail cache, but no gallery
screen. This change adds the main screen: a chronological timeline of every indexed
photo and video, grouped by day.

The app now opens on the timeline instead of the old demo home screen.

## Files created

### Models
- `lib/models/timeline_group.dart` — `TimelineHeaderKind`, `TimelineGroup` (one day of
  media), `TimelineRow` (a header row or one line of tiles), and `TimelineData` (the
  whole flattened list). All immutable with `const` constructors, `copyWith`, `==`, and
  `hashCode`.
- `lib/models/flashback_memory.dart` — `FlashbackMemory`: one earlier year's media for
  today's date.

### Services (pure Dart, no `BuildContext`, no I/O)
- `lib/services/timeline/timeline_grouping_service.dart` — sorts media newest first,
  buckets it by calendar day, picks each day's header kind, and flattens the buckets
  into fixed-height rows for a given column count. The same file holds `TimelineMetrics`,
  which turns row heights into cumulative scroll offsets and maps a scroll offset back
  onto a row using a binary search.
- `lib/services/timeline/flashback_service.dart` — picks media captured on today's month
  and day in earlier years, groups it by year newest first, and caps both the number of
  years and the items per year.

### Providers
- `lib/providers/timeline_providers.dart` — `gridColumnCountProvider` (clamped to 1–5),
  `timelineFilterProvider`, `timelineItemsProvider`, `timelineDataProvider`,
  `flashbackMemoriesProvider`, and `timelineNowProvider`.

### Screen
- `lib/screens/timeline/timeline_screen.dart` — permission gate, empty state,
  pull-to-refresh incremental scan, the scrolling list, the pinch handler, and the
  scrubber overlay.

### Widgets
- `lib/widgets/media/media_grid_tile.dart` — one square tile: thumbnail, badges, tap target.
- `lib/widgets/media/media_badges.dart` — duration pill, GIF / RAW / HD chips, plus the
  `formatMediaDuration` and `isHighResolution` helpers.
- `lib/widgets/media/timeline_date_header.dart` — the date header, and
  `formatTimelineDate`, which turns a header kind into localized text.
- `lib/widgets/media/fast_scroll_scrubber.dart` — draggable scroll handle with a floating
  date bubble; hides itself on short lists and fades out when idle.
- `lib/widgets/media/flashback_carousel.dart` — the "On This Day" strip.
- `lib/core/routing/app_router.dart` — minimal `go_router` config.

### Tests
- `test/services/timeline/timeline_grouping_service_test.dart` (grouping, labels, row
  flattening at all five densities, and the scroll metrics)
- `test/services/timeline/flashback_service_test.dart`
- `test/models/timeline_group_test.dart`
- `test/providers/timeline_providers_test.dart`
- `test/widgets/media/media_badges_test.dart`

## Files changed

- `lib/main.dart` — now uses `MaterialApp.router` with `appRouter`.
- `lib/screens/home_screen.dart` — the app bar title is now "Settings", since this screen
  is reached from the timeline rather than being the launch screen.
- `lib/widgets/dev/media_scan_panel.dart` — comment updated; the panel still exists for
  the `dev` flavor on the settings screen.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — 15 new keys, each with an `@`
  description in the English template. `flutter gen-l10n` was re-run.
- `docs/implementation_progress.md` — Phase 4 marked Completed at 100%.

## How the main pieces work

**Date headers.** Each day is labelled Today, Yesterday, the day inside the current year,
or the day plus the year. The service returns only the kind and the raw date; the widget
formats it with `intl` for the active locale. That keeps the service free of
`BuildContext` and makes Malayalam formatting work without touching the logic.

**Flat rows instead of nested grids.** A list of per-day grids has an unknown total
height until every child is built, which scrolls badly and makes a scrubber guess. The
grouping service instead flattens each day into one header row plus `ceil(n / columns)`
tile rows. Every row's height is known, so a scroll offset maps exactly onto a date.

**Pinch to zoom.** A two-finger pinch changes the column count between 1 and 5. The
screen records which day was at the top of the view before the change and scrolls back to
that same day afterwards, so the view does not jump. Changing density only regroups
items that are already loaded — it does not re-query the database.

**Flashbacks.** Computed from the loaded items, not stored, so this phase needed no
database or schema change. The carousel is not built at all when there are no memories,
so there is no empty gap on ordinary days.

**Scroll offset correction.** The flashback carousel is a separate sliver above the rows,
so it shifts every scroll offset. The screen measures the carousel's real height and
subtracts it before mapping an offset onto a row, for both the scrubber label and the
pinch re-anchoring. It measures zero when no carousel is shown.

## Rules followed

- No new package was added. The app stays fully offline with no network dependency.
- No SQL, file I/O, or platform call was added to any widget. Grouping, flashback
  selection, and scroll-offset maths all live in the service layer.
- Every new model is immutable with a `const` constructor and `copyWith`.
- Every user-visible string comes from an ARB key in both English and Malayalam.
- Thumbnails that cannot be produced still fall back to a placeholder, so a corrupt file
  cannot break the grid.

## One difference from the plan

The plan said in one place to remove the dev media scan panel from the home screen, and
in another to keep it reachable from the dev-flavour settings route. The panel was kept
on the settings screen for the `dev` flavour, since it is still useful for testing the
scanner on a real device and removing it would have left the widget unused.

## Verification

- `flutter pub get` — succeeded.
- `flutter gen-l10n` — succeeded; both locales regenerated.
- `dart format .` — applied.
- `flutter analyze` — **No issues found.**
- `flutter test` — **All 171 tests passed** (128 existing plus 43 new).

## Not included (later phases)

Tapping a tile is wired to an empty handler that Phase 5 fills in with the fullscreen
viewer. Multi-select, albums, search, filter sheets, and the real Settings and About
screens remain in their own phases.
