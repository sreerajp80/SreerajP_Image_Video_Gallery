# Phase 9 — Virtual Albums, Device Folders & Smart Auto-Albums

**Status:** completed

**Date:** 2026-08-30
**Implements:** `docs/implementation_plan.md` → Phase 9
**Follows:** `plans/20260830_111653_phase_8_search_tags_duplicates.md`

---

## 1. What this phase must deliver

From the implementation plan, Phase 9 has four action steps:

1. Virtual album management — create, rename, delete, reorder items, custom cover.
2. Group media by physical device folders (Camera, Screenshots, Downloads, …).
3. Smart dynamic auto-albums — Favorites, Videos, GIFs, RAW, Panoramas, Recently Added.
4. Smart multi-dimensional filter sheets.

The route tree in `docs/architecture.md` already names the screens this phase adds:

```
/albums              (Albums grid)
/albums/:id          (Album media grid)
/albums/auto/:type   (Smart dynamic albums)
```

---

## 2. What already exists (and what is missing)

**Already there:**

- `lib/models/album.dart` — the immutable `Album` model with `AlbumType`, cover,
  item count, pin flag, and sort order. `toMap` / `fromMap` / `copyWith` are done.
- `lib/repositories/database/album_dao.dart` — insert, update, delete, get by id,
  get all, add media, remove media, get media for album.
- The `albums` and `album_media_entries` tables in `database_helper.dart`.
- `lib/models/filter_options.dart` — media types, tags, favourites, date range,
  folder paths, sort field and direction, GPS flag, trash flag.
- `test/models/album_test.dart` and `test/repositories/database/album_dao_test.dart`.

**Missing — this is the actual work:**

| Gap | Why it matters |
|-----|----------------|
| No repository over `AlbumDao` | Widgets have nothing to talk to; the album layer stops at the DAO. |
| No album providers | Nothing wires albums into Riverpod. |
| No album screens or route entries | `/albums` does not exist in `app_router.dart`. |
| No device-folder grouping query | Nothing reads the parent directory out of `media_items`. |
| `AlbumType` has no panorama or recently-added member | Two of the six required smart albums cannot be named. |
| No reorder support in `AlbumDao` | `position` is written but never rewritten, so ordering cannot change. |
| No cover chooser | `cover_media_id` is never set by anything. |
| `FilterOptions` has no size range and no "has tags" flag | The plan asks for filtering by file size and by presence of tags. |
| `MediaDao.getMediaItems` cannot filter by folder | Folder filtering is done in Dart inside `MediaRepository`, which loads the whole table first. |
| No smart-album rule engine | Nothing turns "Panoramas" into a query. |

---

## 3. Design decisions (and the reasons)

**a. Smart albums are rules, not rows.**
A smart album is computed on the fly from `FilterOptions`. Nothing about a smart
album is stored in the `albums` table. This keeps a smart album always correct:
star a photo and Favourites is right immediately, with no bookkeeping to drift.
The rules live in a pure service, `SmartAlbumService`, so they are testable
without a database.

**b. Device folders are derived from `media_items.path`, not stored.**
A folder album is just "every indexed item whose parent directory is X". A new
SQL `GROUP BY` on the directory part of the path gives the folder list, its
count, and its newest item (used as the cover) in one statement. Storing folder
rows would mean keeping them in step with every scan; deriving them cannot drift.

**c. Only virtual albums are rows in the `albums` table.**
This matches what the table was built for and keeps `AlbumType` values other than
`virtualAlbum` out of the database entirely.

**d. Panorama is a shape rule, not a tag.**
A photo counts as a panorama when its longest side is at least 2.5x its shortest
side and its longest side is at least 2000 pixels. Both parts are needed: the
ratio alone would catch a thin crop, the pixel floor alone would catch any big
photo. The numbers become named constants so they can be tuned in one place.
Items with no width or height recorded are never panoramas.

**e. "Recently added" is a rolling window, not a fixed list.**
Anything added in the last 30 days. The window becomes a named constant.

**f. Filtering by folder moves into SQL.**
Today `MediaRepository.getMediaItems` loads every matching row and then keeps the
ones whose path starts with a chosen folder. On a large library that reads the
whole table to show one folder. The folder test moves into `MediaDao` as a
`path LIKE ? ESCAPE` prefix match, with `%`, `_`, and the escape character itself
escaped so a folder name containing one of them cannot widen the match.
The Dart-side filter in `MediaRepository` is then removed, because keeping both
would be doing the same job twice.

**g. Album membership never touches the file system.**
Adding a photo to an album writes one junction row. No file is copied, moved, or
renamed. This is what "virtual" means here, and it keeps hard rule 4
(safe, non-destructive operations) satisfied without any special care.

**h. Reorder writes a whole new position list in one transaction.**
Rewriting every affected row's `position` from the new order is simpler to reason
about than trying to shuffle single values, and one transaction means a
half-applied order cannot be left behind.

---

## 4. Files to change

### 4.1 Models

| File | Change |
|------|--------|
| `lib/models/album.dart` | Add `smartPanoramas` and `smartRecentlyAdded` to `AlbumType`; include them in `isSmartAlbum`. Additive only — `fromString` already falls back safely, and no stored row uses these values. |
| `lib/models/album_summary.dart` | **New.** Immutable `AlbumSummary`: `id`, `name`, `albumType`, `folderPath`, `itemCount`, `coverItem` (a `MediaItem?`). One shape the album grid can draw, whether the row came from the album table, a folder scan, or a smart rule. |
| `lib/models/smart_album.dart` | **New.** Immutable `SmartAlbum`: the `AlbumType`, a stable string key used in the `/albums/auto/:type` route, and the `FilterOptions` that define it. |
| `lib/models/filter_options.dart` | Add `minSizeBytes`, `maxSizeBytes`, and `hasTagsOnly`. Extend `copyWith` (with `clearSizeRange` and `clearHasTags` flags, matching the existing `clear…` pattern), `hasActiveFilters`, `==`, and `hashCode`. |

### 4.2 Services

| File | Change |
|------|--------|
| `lib/services/albums/smart_album_service.dart` | **New.** Pure. Builds the six smart albums, maps a route key to a `SmartAlbum` and back, holds the panorama ratio/pixel constants and the recently-added window, and exposes `isPanorama(MediaItem)`. Panoramas and "recently added" need a post-filter pass in Dart because neither is a plain column test; the rest are pure `FilterOptions`. |
| `lib/services/albums/album_name_rules.dart` | **New.** Pure. Trims, collapses inner whitespace, enforces a 1–60 character length, and rejects a name already used by another album. Mirrors `TagNameRules` so both behave the same way. |
| `lib/services/albums/folder_path_rules.dart` | **New.** Pure. Splits a file path into its parent directory and gives a folder a display name (the last path segment). Handles both separators and a trailing separator, so a device that reports either style groups the same. Also builds the escaped `LIKE` prefix pattern used by the folder filter. |

### 4.3 Database

| File | Change |
|------|--------|
| `lib/repositories/database/album_dao.dart` | Add `getAlbumsByType`, `getMediaIdsForAlbum`, `addMediaToAlbums` (one media into several albums in one transaction), `setMediaOrder` (rewrite `position` for a whole album in one transaction), `setCover`, `setPinned`, `getAlbumIdsForMedia`, and `nextPosition`. Fix the existing `addMediaToAlbum` so it appends at the end by default instead of always writing `position = 0`, which today makes every added item tie at zero. |
| `lib/repositories/database/media_dao.dart` | Add folder support to `getMediaItems` as a SQL `LIKE … ESCAPE` prefix test over `path`. Add `getFolderSummaries()` — one `GROUP BY` over the directory part of the path returning folder path, item count, and newest item id. Add `getMediaItemsByIds`. Add size-range and has-tags clauses for the new filter fields. |
| `lib/repositories/database/database_constants.dart` | No schema change. Add an index name constant if the folder query needs one; the plan expects the existing `path` index to serve the prefix match. |

> No schema version bump: nothing in this phase adds a table or a column.

### 4.4 Repository

| File | Change |
|------|--------|
| `lib/repositories/album_repository.dart` | **New.** The only way the app changes albums. Validates names through `AlbumNameRules`, generates ids the same way `TagRepository` does, keeps `item_count` correct, resolves covers (explicit cover, else newest member), builds `AlbumSummary` lists for virtual albums, device folders, and smart albums, and applies the panorama and recently-added post-filters. Throws `AlbumValidationException` for a refused name, mirroring `TagValidationException`. |
| `lib/repositories/media_repository.dart` | Remove the Dart-side folder filter now that `MediaDao` does it in SQL. Add `getMediaItemsByIds`. |

### 4.5 Providers

| File | Change |
|------|--------|
| `lib/providers/album_providers.dart` | **New.** `albumDaoProvider`, `albumRepositoryProvider`, `albumRevisionProvider` (the same refresh dial as `tagRevisionProvider`), `virtualAlbumsProvider`, `deviceFolderAlbumsProvider`, `smartAlbumsProvider`, `albumSummaryProvider(id)`, `albumMediaProvider(id)`, `smartAlbumMediaProvider(key)`, `albumsForMediaProvider(mediaId)`, and an `AlbumEditController` (create, rename, delete, add/remove media, reorder, set cover, set pinned) exposed as `albumEditControllerProvider`. |
| `lib/providers/media_providers.dart` | No change expected; the album providers reuse `mediaDaoProvider`. |

### 4.6 Screens and widgets

| File | Change |
|------|--------|
| `lib/screens/albums/albums_screen.dart` | **New.** `/albums`. Three sections in one scroll view: virtual albums (with a New Album button), smart albums, device folders. Each section is a grid of album cards. Empty and error states follow the timeline's `_MessageState` pattern. |
| `lib/screens/albums/album_media_screen.dart` | **New.** `/albums/:id`. The media grid of one virtual album, with an overflow menu for rename, choose cover, reorder, and delete, plus an Add Media action. |
| `lib/screens/albums/smart_album_screen.dart` | **New.** `/albums/auto/:type`. The media grid of one smart album, read only apart from the filter sheet. |
| `lib/screens/albums/album_reorder_screen.dart` | **New.** A `ReorderableListView` of the album's items; on save it writes the whole new order in one call. A separate screen rather than a drag mode on the grid, because a reorderable grid plus a scrolling grid in one widget is where this kind of screen usually goes wrong. |
| `lib/widgets/albums/album_card.dart` | **New.** Cover thumbnail, name, item count, and a type badge. Reuses `MediaThumbnail` so the existing cache and corrupt-file fallback apply. |
| `lib/widgets/albums/album_edit_dialog.dart` | **New.** Create and rename, with live name validation. Modelled on `TagEditDialog`. |
| `lib/widgets/albums/album_picker_sheet.dart` | **New.** "Add to album" — a checklist of virtual albums plus a create-new row. Opened from the viewer. |
| `lib/widgets/albums/album_cover_picker.dart` | **New.** A grid of the album's own items; tapping one sets it as the cover. |
| `lib/widgets/albums/smart_filter_sheet.dart` | **New.** The multi-dimensional filter sheet: media type, favourites, has location, has tags, date range, file size range, and sort field and direction. Built on the same "write straight to the provider" approach as `SearchFilterSheet`, so there is no unsaved state. |
| `lib/screens/search/search_screen.dart` | Point the existing filter button at the shared sheet so search and albums offer the same filters, rather than two sheets drifting apart. |
| `lib/screens/timeline/timeline_screen.dart` | Add an Albums action to the app bar. |
| `lib/screens/viewer/media_viewer_screen.dart` | Add an "Add to album" action that opens `AlbumPickerSheet`. |
| `lib/core/routing/app_router.dart` | Add `kRouteAlbums`, `albumPath(id)`, `smartAlbumPath(key)`, and the three route entries under the timeline route. Update the doc comment. |

### 4.7 Localization

| File | Change |
|------|--------|
| `lib/l10n/app_en.arb` | New keys for every user-visible string added here: screen titles, section headings, the six smart album names, empty states, album actions, name errors, the picker, the cover chooser, reorder, and the new filter rows. Each with an `@key` description. |
| `lib/l10n/app_ml.arb` | The same keys in Malayalam. |
| Generated files | Refreshed by `flutter gen-l10n`; never hand edited. |

### 4.8 Tests

| File | Covers |
|------|--------|
| `test/models/album_test.dart` | Extend: the two new `AlbumType` values, `isSmartAlbum`, `fromString` fallback. |
| `test/models/album_summary_test.dart` | **New.** Equality and `copyWith`. |
| `test/models/filter_options_test.dart` | Extend: size range, has-tags, the new `clear…` flags, `hasActiveFilters`. |
| `test/services/albums/smart_album_service_test.dart` | **New.** All six rules, the panorama ratio and pixel floor (including the boundary and a missing-dimension item), the recently-added window boundary, and route-key round tripping. |
| `test/services/albums/album_name_rules_test.dart` | **New.** Trimming, whitespace collapsing, length limits, duplicate detection, and the rename-ignores-itself case. |
| `test/services/albums/folder_path_rules_test.dart` | **New.** Both separators, trailing separators, root paths, display names, and `LIKE` escaping of `%`, `_`, and the escape character. |
| `test/repositories/database/album_dao_test.dart` | Extend against a real in-memory database: append position, reorder, cover, pin, multi-album add, ids-for-media, and item-count upkeep. |
| `test/repositories/database/media_dao_test.dart` | Extend: folder prefix filter (including a folder name containing `%`), folder summaries, size range, has-tags, and get-by-ids. |
| `test/repositories/album_repository_test.dart` | **New.** Create, rename, delete, membership, name validation errors, cover fallback to newest member, folder summaries, and smart album contents. |

Roughly 20 new files and 12 edited files.

---

## 5. Order of work

1. Models — `AlbumType` additions, `AlbumSummary`, `SmartAlbum`, `FilterOptions` fields.
2. Pure services — `AlbumNameRules`, `FolderPathRules`, `SmartAlbumService`, and their tests.
3. Database — `AlbumDao` additions and the `MediaDao` folder, size, has-tags, and summary queries, with tests.
4. `AlbumRepository` and its tests; drop the Dart-side folder filter from `MediaRepository`.
5. Providers.
6. ARB strings for English and Malayalam, then `flutter gen-l10n`.
7. Widgets, then screens, then routes and the entry points in the timeline and viewer.
8. `dart format .`, `flutter analyze` (must be clean), `flutter test` (all must pass).
9. Tick the Phase 9 boxes in `docs/implementation_progress.md`.
10. Write the change log to `change_log/`.

---

## 6. Rules this phase must respect

- **Offline.** No new package of any kind. Everything here is SQLite and Flutter.
- **Layers.** Widgets read providers only. No SQL and no file I/O in a widget.
  `AlbumRepository` and the three services take no `BuildContext`.
- **Immutable models.** `const` constructors and `copyWith` throughout; nothing
  is mutated in place.
- **Non-destructive.** Album membership is database only. Deleting an album
  deletes junction rows, never a file. The delete confirmation says so.
- **Never crash on bad input.** An item with no dimensions, a path with no
  parent directory, a cover whose media has since gone, and an album whose id is
  no longer in the database all resolve to a safe fallback, not a throw.
- **Localization.** Every user-visible string comes from `AppLocalizations`.
- **Naming.** `snake_case.dart` files, `PascalCase` classes, `camelCase` +
  `Provider` for providers, `package:` imports only.

---

## 7. Risks

| Risk | Handling |
|------|----------|
| Moving the folder filter into SQL could change results. | The prefix test is written to match today's `startsWith`, and the `LIKE` wildcards are escaped so it cannot match more than before. Covered by a test with a folder name containing `%`. |
| Two `AlbumType` values added to a stored enum. | Nothing writes them to the database — only virtual albums are stored — and `fromString` already falls back, so an old row cannot break. |
| Panorama thresholds may not suit every device. | They are named constants in one service, tuned in one place, and directly tested. |
| The albums screen runs three separate queries. | Each is a single indexed statement, and each section is its own provider, so a slow one cannot block the others. |

---

## 8. Definition of done

- `/albums`, `/albums/:id`, `/albums/auto/:type`, and the reorder screen all work.
- Virtual albums can be created, renamed, deleted, reordered, given a cover, and
  have media added and removed.
- Device folders appear with correct counts and covers.
- All six smart albums list the right items.
- The shared filter sheet works on both the search screen and the album screens.
- English and Malayalam strings exist for every new label.
- `flutter analyze` is clean; `flutter test` is green.
- `docs/implementation_progress.md` Phase 9 is ticked and the change log is written.
