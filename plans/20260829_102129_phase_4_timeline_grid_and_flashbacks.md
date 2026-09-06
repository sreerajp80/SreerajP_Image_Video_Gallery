# Plan: Phase 4 — Chronological Timeline, Dynamic Grid & Flashback Memories

**Status:** completed

## 1. Issue & Objective

Phases 1–3 are done. The app can read the device MediaStore, index media into SQLite,
and build thumbnails with a RAM-aware multi-tier cache. But there is still no gallery
screen. The only place media shows up is a small dev-only test panel on the home screen.

Phase 4 builds the main screen of the app — the chronological timeline. It must:

1. Show all indexed media grouped by date, with sticky date headers
   (Today, Yesterday, a month name, or a year).
2. Let the user pinch to change the grid density between 1 and 5 columns.
3. Give a fast scroll scrubber with a floating date label, so a large library can be
   crossed quickly.
4. Show an "On This Day" / Flashback Memories carousel at the top, built from media
   taken on today's calendar date in earlier years.
5. Draw badges on tiles: video duration, GIF, RAW, and high resolution.

This phase is UI plus the grouping logic behind it. It adds no new package, no new
database table, and no new native code. All data still comes through
`MediaRepository` and the existing providers.

## 2. Key Design Decisions

**a. Grouping runs in a pure Dart service, not in the widget.**
The rule in [CLAUDE.md](../CLAUDE.md) is that widgets hold no business logic. So the
date bucketing, header labelling, and flat-index maths live in a new
`TimelineGroupingService` under `lib/services/timeline/`. It takes a `List<MediaItem>`
and returns an immutable `TimelineData` model. This keeps the whole thing unit-testable
with no widget test and no device.

**b. One flat sliver list, not a nested list of grids.**
A naive `ListView` of per-day `GridView`s scrolls badly and breaks the scrubber, because
the total scroll height is unknown until every child is built. Instead
`TimelineGroupingService` flattens the groups into a single list of rows
(`TimelineRow`), where a row is either a header or one line of up to N tiles. Every row
has a known height, so the list gets a fixed `itemExtent`-style layout, scroll position
maps directly to a date, and the scrubber is exact rather than approximate.

Because the number of columns changes on pinch, the rows are rebuilt when the column
count changes. That work is memoised in the provider so a pinch does not re-query SQLite.

**c. Flashbacks are computed, not stored.**
"On This Day" needs no table. It is a filter over the already-loaded items: same month
and same day-of-month as today, in an earlier year. Grouped by how many years ago.
This keeps Phase 4 free of schema changes.

**d. The timeline becomes the app home; the old home screen becomes a temporary
settings entry.**
[architecture.md](../docs/architecture.md) §4 puts the Timeline at route `/`. `go_router`
is already a dependency but is not wired up yet. This plan wires a minimal router with
two routes (`/` and `/settings`) so the timeline is the launch screen and the existing
theme/about content stays reachable from an app bar icon. The full settings and About
screens are Phase 13; nothing existing is deleted.

**e. Badges read only from `MediaItem`.**
Duration comes from `durationMs`, GIF and RAW from `mediaType`, and "HD" from
`width`/`height`. No extra decode, no extra I/O.

## 3. Dependencies

**No new packages.** Everything needed is already in `pubspec.yaml`
(`flutter_riverpod`, `go_router`, `intl`). This keeps the offline hard rule trivially
satisfied.

## 4. Files to Create

### Models
| File | Purpose |
|---|---|
| `lib/models/timeline_group.dart` | Immutable `TimelineGroup` (a date bucket with its items), `TimelineRow` (header row or tile row), `TimelineData` (the flattened rows plus the group index), and the `TimelineHeaderKind` enum (`today`, `yesterday`, `month`, `year`). |
| `lib/models/flashback_memory.dart` | Immutable `FlashbackMemory` — the year, how many years ago, and the items taken on today's date in that year. |

### Services
| File | Purpose |
|---|---|
| `lib/services/timeline/timeline_grouping_service.dart` | Pure Dart. Buckets a sorted `List<MediaItem>` by day, labels each bucket, and flattens into rows for a given column count. |
| `lib/services/timeline/flashback_service.dart` | Pure Dart. Picks items whose `effectiveDate` shares today's month and day but falls in an earlier year, groups them by year, newest first, and caps each group. |

### Providers
| File | Purpose |
|---|---|
| `lib/providers/timeline_providers.dart` | `gridColumnCountProvider` (a `StateNotifier` clamped to 1–5), `timelineFilterProvider`, `timelineDataProvider` (grouping over `mediaItemsProvider` for the current column count), and `flashbackMemoriesProvider`. |

### Screens
| File | Purpose |
|---|---|
| `lib/screens/timeline/timeline_screen.dart` | The main screen. Permission gate, empty state, pull-to-refresh scan, the sliver list, the pinch handler, the scrubber, and the flashback carousel header. |

### Widgets
| File | Purpose |
|---|---|
| `lib/widgets/media/media_grid_tile.dart` | One square tile: `MediaThumbnail` plus the badge overlay and a tap target. |
| `lib/widgets/media/media_badges.dart` | The badge row — duration pill, GIF chip, RAW chip, HD chip. |
| `lib/widgets/media/timeline_date_header.dart` | The sticky-looking date header row. |
| `lib/widgets/media/fast_scroll_scrubber.dart` | Draggable scroll thumb with a floating date bubble. |
| `lib/widgets/media/flashback_carousel.dart` | Horizontal "On This Day" strip shown above the first header. |
| `lib/core/routing/app_router.dart` | Minimal `go_router` config: `/` → `TimelineScreen`, `/settings` → the existing `HomeScreen`. |

### Tests
| File | Purpose |
|---|---|
| `test/services/timeline/timeline_grouping_service_test.dart` | Bucketing, Today/Yesterday/month/year labels, row flattening at 1–5 columns, empty input, unsorted input, items sharing a day across a month boundary. |
| `test/services/timeline/flashback_service_test.dart` | Same-day-earlier-year matching, exclusion of today's own items and of other days, leap-day handling, year grouping order, per-group cap. |
| `test/models/timeline_group_test.dart` | `copyWith`, equality, and `hashCode` for the new models. |
| `test/providers/timeline_providers_test.dart` | Column count clamping to 1–5 and the grouping provider reacting to a column change. |

## 5. Files to Change

| File | Change |
|---|---|
| `lib/main.dart` | Switch `MaterialApp` to `MaterialApp.router` using `appRouter`. |
| `lib/screens/home_screen.dart` | Add a back-safe app bar (it is now a pushed `/settings` route) and drop the dev scan panel block, since the timeline replaces it. Theme and About content is untouched. |
| `lib/widgets/dev/media_scan_panel.dart` | Keep the file but remove the "Phase 4 replaces it" comment; it is now reachable only from the dev flavor settings route. |
| `lib/l10n/app_en.arb` | Add keys with `@` descriptions: `timelineToday`, `timelineYesterday`, `flashbackTitle`, `flashbackYearsAgo`, `flashbackOneYearAgo`, `gridColumns`, `badgeGif`, `badgeRaw`, `badgeHd`, `badgeVideoDuration`, `noMediaInTimeline`, `pullToScan`, `settings` (exists). |
| `lib/l10n/app_ml.arb` | Malayalam values for every new key. |
| `docs/implementation_progress.md` | Flip Phase 4 to Completed / 100% and tick its five checklist items. |

## 6. Detailed Approach

### 6.1 Date bucketing and header labels
- Sort items by `effectiveDate` descending (`dateTaken ?? dateModified`).
- Bucket by local calendar day (`year`, `month`, `day`).
- Label each bucket:
  - same day as now → `timelineToday`
  - the day before now → `timelineYesterday`
  - same calendar year → month + day, via `intl` `DateFormat.MMMMd`
  - earlier year → month + day + year, via `DateFormat.yMMMMd`
- Labels are produced at build time from a `Locale`, so Malayalam formats correctly.
  The service returns the `TimelineHeaderKind` and the raw `DateTime`; the widget does
  the `intl` formatting. That keeps the service free of `BuildContext` and localization.

### 6.2 Flattening into rows
For a column count `n`, each group becomes:
1. one `TimelineRow.header`,
2. `ceil(items.length / n)` `TimelineRow.tiles` rows, each holding up to `n` items.

`TimelineData` keeps the row list plus, for each row, the group's date. The scrubber
uses that map to turn a scroll offset into a date label without touching the item list.

### 6.3 Pinch-to-zoom density
`TimelineScreen` wraps the scroll view in a `GestureDetector` handling
`onScaleStart` / `onScaleUpdate` / `onScaleEnd`. A scale above ~1.25 steps the column
count down (bigger tiles), below ~0.8 steps it up, then the gesture resets so one pinch
moves one step. The count is clamped 1–5 and stored in `gridColumnCountProvider`.
Before rebuilding, the screen records the first visible group's date and re-anchors the
scroll position to that same group afterwards, so the view does not jump.

### 6.4 Fast scroll scrubber
A thin draggable thumb pinned to the trailing edge, visible while scrolling or dragging
and fading out after a short idle delay. Dragging maps the vertical fraction onto
`ScrollController.jumpTo`, and a bubble shows the date of the row at that offset.
It is hidden when the library is small enough not to need it.

### 6.5 Flashback carousel
Shown as the first sliver, above the first date header, and only when there is at least
one memory. Each entry is a horizontally scrolling strip of tiles with a "1 year ago" /
"N years ago" caption. Empty means the sliver is not built at all — no blank space.

### 6.6 Badges
- Video: a duration pill (`m:ss`, or `h:mm:ss` past an hour) in the bottom-right.
- GIF / RAW: a small text chip in the top-left.
- HD: shown when the smaller pixel edge is 1080 or more and the item is not a video
  already showing a duration pill in that corner.
- All badge labels come from ARB keys; none are raw literals.

### 6.7 Empty, loading, and permission states
- Permission not granted → the existing permission copy plus an "Allow access" button
  that calls `MediaScanController.scan()`.
- Granted but nothing indexed → `noMediaInTimeline` plus a scan button.
- Pull-to-refresh anywhere on the timeline triggers an incremental scan.
- A thumbnail that cannot be produced still shows the existing placeholder, so a corrupt
  file never breaks the grid — this is already handled inside `MediaThumbnail`.

## 7. Rules This Plan Follows

- **Layer boundaries.** No SQL, file I/O, or platform call in any widget. Grouping and
  flashback logic sit in `services/`, state in `providers/`, rendering in
  `screens/` and `widgets/`.
- **Immutability.** Every new model is `@immutable`, has a `const` constructor,
  `copyWith`, `==`, and `hashCode`.
- **Localization.** Every user-visible string is an ARB key with an `@` description, in
  both `app_en.arb` and `app_ml.arb`. `flutter gen-l10n` is run after editing.
- **Offline.** No package added; no network code.
- **Naming.** `snake_case.dart` files, `PascalCase` classes, `camelCase` + `Provider`
  suffix for providers, `package:` imports only.
- **Testing.** New tests mirror the `lib/` layout under `test/`.

## 8. Verification

1. `flutter pub get`
2. `flutter gen-l10n`
3. `dart format .`
4. `flutter analyze` — must report zero issues.
5. `flutter test` — the full suite, existing and new, must pass.

## 9. Out of Scope (later phases)

- Tapping a tile opening a fullscreen viewer — that is Phase 5. In this phase a tap
  is wired to a no-op handler that Phase 5 will fill in.
- Multi-select batch mode — Phase 11.
- Albums, folders, and smart albums — Phase 9.
- Search and filter sheets — Phases 8 and 9.
- The real Settings and About screens — Phase 13.
