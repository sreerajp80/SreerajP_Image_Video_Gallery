# Change log — Phase 9: Virtual Albums, Device Folders & Smart Auto-Albums

**Date:** 2026-08-30
**Implements:** `plans/20260830_145010_phase_9_albums_folders_smart_albums.md`
**Covers:** `docs/implementation_plan.md` → Phase 9

---

## What was done

All four Phase 9 action steps are complete: virtual album management, device
folder grouping, smart auto-albums, and the multi-dimensional filter sheet.

The `Album` model, `AlbumDao`, and the album tables already existed from
Phase 2, but nothing sat above them. This phase built that layer and the
screens on top.

---

## Design decisions worth knowing

**Smart albums are rules, not stored rows.** A smart album is a `FilterOptions`
evaluated fresh each time it is opened. Star a photo and Favourites is right at
once, with no stored membership that could drift.

**Device folders are derived from file paths.** One `GROUP BY` gives the folder
list, its count, and its newest item. Storing folder rows would have meant
keeping them in step with every scan.

**Only virtual albums are rows in the `albums` table.** No schema change and no
version bump were needed.

**A panorama is a shape rule:** the longest side is at least 2.5 times the
shortest *and* at least 2000 pixels. The ratio alone would catch a thin crop;
the pixel floor alone would catch any large photo. An item with no recorded
dimensions is never a panorama.

**"Recently added" is a rolling 30-day window,** applied against the clock at
read time rather than baked into a stored filter.

**A smart album's own rule beats the user's filter where the two overlap.**
A filter can narrow "Videos" but cannot widen it back to every media type,
which would leave the user in an album that no longer matches its name.

---

## Bug found and fixed

`AlbumDao.addMediaToAlbum` defaulted `position` to `0`, so every item added to
an album tied at position zero and the stored order meant nothing. It now
appends at the end. Reordering would not have worked at all without this.

---

## Performance change

Folder filtering used to run in Dart inside `MediaRepository`: it read every
matching row out of the database and then dropped the ones in other folders.
Showing one folder therefore read the whole table.

It now runs inside the query as a `LIKE ... ESCAPE` prefix test plus a "no
further separator" test, which together mean "directly inside this folder". The
Dart-side filter was removed so the two cannot disagree.

Two correctness points came with the move:

- `%`, `_`, and the escape character are escaped in the pattern, so a real
  folder called `100%` matches only itself.
- The pattern includes the trailing separator, so `/DCIM/Camera` no longer
  picks up `/DCIM/CameraRoll`. The old `startsWith` check did pick it up.

---

## Files added

**Models**
- `lib/models/album_summary.dart` — one shape the album grid can draw, whether
  the row came from the album table, a folder scan, or a smart rule.
- `lib/models/smart_album.dart` — a smart album's type, route key, and filter.

**Services (all pure, no database and no `BuildContext`)**
- `lib/services/albums/album_name_rules.dart`
- `lib/services/albums/folder_path_rules.dart`
- `lib/services/albums/smart_album_service.dart`

**Repository and providers**
- `lib/repositories/album_repository.dart`
- `lib/providers/album_providers.dart`

**Screens**
- `lib/screens/albums/albums_screen.dart`
- `lib/screens/albums/album_media_screen.dart`
- `lib/screens/albums/smart_album_screen.dart` — holds both the smart album and
  the device folder screens, which differ only in where their list comes from.
- `lib/screens/albums/album_reorder_screen.dart`

**Widgets**
- `lib/widgets/albums/album_card.dart`
- `lib/widgets/albums/album_edit_dialog.dart`
- `lib/widgets/albums/album_picker_sheet.dart`
- `lib/widgets/albums/album_cover_picker.dart`
- `lib/widgets/albums/album_media_grid.dart`
- `lib/widgets/albums/smart_filter_sheet.dart`

**Tests**
- `test/models/album_summary_test.dart`
- `test/services/albums/album_name_rules_test.dart`
- `test/services/albums/folder_path_rules_test.dart`
- `test/services/albums/smart_album_service_test.dart`
- `test/repositories/album_repository_test.dart`
- `test/repositories/database/album_dao_phase9_test.dart`
- `test/repositories/database/media_dao_phase9_test.dart`
- `test/core/routing/album_routes_test.dart`

---

## Files changed

- `lib/models/album.dart` — added `smartPanoramas` and `smartRecentlyAdded`.
  Additive only; nothing writes these to the database and `fromString` already
  falls back safely.
- `lib/models/filter_options.dart` — added `minSizeBytes`, `maxSizeBytes`, and
  `hasTagsOnly`, with `clearSizeRange` and `clearHasTags` flags matching the
  existing pattern.
- `lib/repositories/database/album_dao.dart` — the position fix plus
  `getAlbumsByType`, `getMediaIdsForAlbum`, `getAlbumIdsForMedia`,
  `addMediaToAlbums`, `setMediaOrder`, `setCover`, and `setPinned`. The item
  count is now recounted in one shared helper.
- `lib/repositories/database/media_dao.dart` — the folder, size, and tag
  filters, plus `getFolderSummaries` and `getMediaItemsByIds`.
- `lib/repositories/media_repository.dart` — dropped the Dart folder filter,
  added `getMediaItemsByIds`.
- `lib/core/routing/app_router.dart` — the album routes and path builders.
- `lib/screens/timeline/timeline_screen.dart` — the Albums action.
- `lib/screens/viewer/media_viewer_screen.dart` — the "add to album" action.
- `lib/screens/search/search_screen.dart` — now opens the shared filter sheet.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` — 71 new keys each, every one
  with an `@key` description. Generated files refreshed with `flutter gen-l10n`.
- `test/models/album_test.dart`, `test/models/filter_options_test.dart` —
  extended for the new values and fields.
- `docs/implementation_progress.md` — Phase 9 ticked.

---

## File removed

- `lib/widgets/search/search_filter_sheet.dart` — fully replaced by
  `smart_filter_sheet.dart`, which search and the album screens now share. It
  had no remaining references. Keeping two sheets would have meant they drifted
  apart the first time either grew a row.

---

## Rules kept

- **Offline:** no new package of any kind was added.
- **Layers:** widgets read providers only; no SQL or file I/O in a widget, and
  the repository and services take no `BuildContext`.
- **Non-destructive:** album membership is database-only. Deleting an album
  removes the album row and its membership rows and touches no file, and the
  confirmation dialog says so. A test asserts the media item survives.
- **Never crash on bad input:** an item with no dimensions, a path with no
  parent, a cover whose media has gone, an album id that no longer resolves,
  and an unknown smart album key all fall back to a safe state rather than
  throwing.
- **Localization:** every user-visible string comes from `AppLocalizations`.

---

## Verification

- `dart format .` — 13 files reformatted.
- `flutter analyze` — **No issues found.**
- `flutter test` — **961 tests, all passed.**

The route test is worth calling out. A device folder path contains separators,
so it is URL-encoded into the route and decoded on the way out. That round trip
is easy to break silently — the wrong folder would open rather than an error —
so it is pinned by tests covering spaces, a `%` in the folder name, the root
path, and the fact that a smart album or folder is never matched as an album id.

---

## Not done

`docs/architecture.md` still lists the older route tree and does not mention
`/albums/folder/:path` or `/albums/:id/reorder`. Updating that design document
was not part of the approved plan, so it was left alone and is noted here as a
small follow-up.
