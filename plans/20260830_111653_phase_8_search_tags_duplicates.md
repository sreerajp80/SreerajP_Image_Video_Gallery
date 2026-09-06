# Plan — Phase 8: Search, Multi-Tag Filtering & Duplicate Detection (pHash)

**Status:** completed

**Date:** 2026-08-30
**Phase:** 8 of 13 (see [docs/implementation_plan.md](../docs/implementation_plan.md))

---

## 1. What this phase must deliver

From the implementation plan, Phase 8 has four action steps:

1. An FTS5 search interface over filenames, tags, notes, EXIF data, and places.
2. Custom tag creation, colour coding, and multi-tag filtering (`AND` / `OR`).
3. A visual duplicate and similar photo finder using SHA-256 and perceptual
   hashing (`pHash` / `dHash`).
4. A side-by-side comparison screen with a "Keep Best Photo / Delete Rest"
   assistant.

## 2. The issue / gap today

The database already has most of the plumbing, but nothing uses it:

- The FTS5 virtual table and its insert/update/delete triggers exist, and
  `MediaDao.searchMediaFts` works, but no screen calls it. The route `/search`
  named in [docs/architecture.md](../docs/architecture.md) is not wired.
- `FilterOptions` already carries `tagIds` and `tagFilterMode`, and
  `MediaDao.getMediaItems` already builds the `AND` / `OR` SQL for them, but
  there is no way for a user to make a tag, colour it, put it on a photo, or
  pick tags to filter by. The route `/tags` is not wired.
- The `tags_content` column of the FTS table is written as an empty string by
  the insert trigger and never filled in. `MediaDao` has a private
  `_syncFtsTags` helper that nothing calls, so tag names are not searchable.
- `media_items` has `sha256_hash` and `p_hash` columns and
  `MediaDao.updateHashes` to write them, but nothing ever computes a hash.
  There is no duplicate finder and the route `/cleaner` is not wired.

## 3. Design decisions

**Nothing is deleted from disk.** Hard rule 4 stands. The "Delete Rest"
assistant moves the losing copies to the app's trash (`is_trash = 1`) after an
explicit confirmation that names the count. The files stay on the device and
can be restored. The screen says this in plain words, so nobody expects the
button to erase a photo. Removing files for good is a later phase's job.

**Pure maths split from pixels and from SQL.** The query parser, the tag name
rules, the colour palette, the perceptual hash maths, the Hamming distance,
the grouping, and the best-photo scoring are all pure functions in their own
services. They are unit tested with no device, no files, and no database.

**Search is one pass, not two.** A search mixes free text (FTS5) with
structured filters (type, tags, dates, favourite, has-GPS). Running FTS first
and filtering the list in Dart would be wrong once a library is large, so the
FTS `MATCH` becomes an `id IN (...)` sub-query inside the existing
`getMediaItems` builder. One SQL statement, one sort, one page of results.

**The search box understands simple prefixes.** Typing `tag:beach sunset`
searches the text `sunset` and narrows to the tag `beach`. Supported prefixes
are `tag:`, `type:` (photo, video, gif, raw), `place:`, `camera:`, and
`before:` / `after:` with a `YYYY-MM-DD` date. Anything else is free text.
Parsing is a pure function, so it is fully tested. Unknown prefixes fall back
to free text rather than failing.

**FTS input is always escaped.** A raw user string is never handed to `MATCH`.
Every word is quoted, inner quotes are doubled, and a `*` is appended for
prefix matching, exactly as the existing `searchMediaFts` does. This is moved
into the parser so there is one place that builds a match expression, and one
place to test that `"` and `*` and `AND` typed by a user cannot break the
query.

**Tag names are unique, case-insensitively.** `Beach` and `beach` are the same
tag. The service trims, collapses inner whitespace, caps the length, rejects
an empty name, and checks for an existing tag before it makes a new one.
Renaming follows the same rules.

**Tag colours come from a fixed palette.** Twelve Material-friendly colours
that read well on both light and dark themes. A new tag gets a colour picked
from the palette by a stable hash of its name, so two tags rarely clash and
the user can still change it. The palette is pure data with its own test.

**Tag changes keep FTS in step.** Every add, remove, rename, and delete goes
through `TagRepository`, which rewrites the `tags_content` cell for each
affected media row. The private `_syncFtsTags` becomes public, and it now
writes an empty string when the last tag is removed instead of returning
early — otherwise a removed tag would stay searchable.

**Hashing is native, streamed, and never loads a whole file.** SHA-256 over a
video read fully into Dart memory would be reckless. A small Kotlin handler
streams the file from its MediaStore URI in 64 KB blocks and returns the hex
digest. The same handler returns a 32x32 grayscale byte array decoded with
`BitmapFactory` and `inSampleSize`, which is the only input the perceptual
hashes need. This also means HEIC, RAW, and anything else Android can decode
is covered for free, and a corrupt file returns an error result instead of
crashing.

**Both hashes, because they answer different questions.**

- *dHash* (64-bit): compares each pixel with its right neighbour on a 9x8
  grayscale grid. Cheap, and very good at catching resizes and re-saves.
- *pHash* (64-bit): a 32x32 DCT, keep the top-left 8x8 block, drop the DC
  term, compare each value against the median. Slower but far steadier
  against brightness and contrast changes, and the better burst detector.

Both are computed from the same grayscale array in one pass. The stored
`p_hash` column keeps them as `<phash>:<dhash>`, so no schema change is needed
and the second hash is not lost. Two photos are "similar" when the Hamming
distance of the pHash is at most the chosen threshold **and** the dHash agrees
within a looser bound. Requiring both cuts the false pairs that either hash
alone produces.

**Exact duplicates are grouped by SHA-256 only.** Byte-identical files are a
certainty, not a guess, so they get their own group kind and their own,
stronger wording in the UI.

**The scan is resumable and cancellable.** Hashes are written to the database
as they are computed, so a second run only hashes what is new. The scan
reports progress, can be stopped, and never blocks the UI thread. Videos are
hashed with SHA-256 only; perceptual hashing a video frame is out of scope for
this phase.

**Similarity grouping is near-linear in practice.** Comparing every photo with
every other is quadratic. Instead the pHash is split into four 16-bit bands,
and only photos sharing a band are compared in full. This is a standard
locality-sensitive bucket trick, it is pure Dart, and it is unit tested.
Groups are built with a union-find so a burst of five photos becomes one
group, not ten pairs.

**"Best photo" is scored, and the user can override it.** The score prefers,
in order: more pixels, larger file, a real capture date, EXIF present, marked
favourite, and finally the older file as a tie-break. The suggestion is
pre-ticked; every tick is the user's to change, and the confirm button always
says how many copies will be moved.

**Layering.** `screens/search`, `screens/tags`, `screens/cleaner` →
`providers` → `repositories` (`SearchRepository`, `TagRepository`) and
`services/search`, `services/tags`, `services/duplicates` → DAOs and the
platform channel → `models`. No widget writes SQL or touches a file; no
service imports `BuildContext`.

**No new package.** `crypto` is already a dependency and is used for the Dart
fallback digest; the native path needs nothing. Search history is a small JSON
file written through `AtomicSaver` into the app support directory, so no
preferences package is added.

## 4. Files to be added

### Dart models (immutable, `const` constructors + `copyWith`)

- `lib/models/search/search_query.dart` — `SearchQuery`: free text, tag names,
  media types, place text, camera text, `before` / `after` dates, and whether
  it is empty.
- `lib/models/search/search_result.dart` — `SearchResult`: the `MediaItem`
  plus which field matched, for the "matched in notes" hint under a tile.
- `lib/models/search/search_history_entry.dart` — the raw text and when it was
  last run.
- `lib/models/duplicate/media_hashes.dart` — `MediaHashes`: media id, SHA-256
  hex, pHash, dHash, with the combined encode and decode helpers.
- `lib/models/duplicate/duplicate_group.dart` — `DuplicateGroup`: kind
  (`exact` or `similar`), the member items, the suggested keeper id, and the
  bytes that would be reclaimed.
- `lib/models/duplicate/duplicate_scan_state.dart` — scanned count, total,
  groups found, running / stopped / done, and any per-file failure count.

### Dart services

- `lib/services/search/search_query_parser.dart` — pure. Raw text →
  `SearchQuery`; and `SearchQuery` → a safe FTS5 `MATCH` expression.
- `lib/services/search/search_history_service.dart` — reads and writes the
  recent-search JSON file through `AtomicSaver`, newest first, capped, with a
  clear-all. A missing or corrupt file gives an empty list, never an error.
- `lib/services/tags/tag_name_rules.dart` — pure. Trim, collapse whitespace,
  length cap, empty and duplicate checks, and the case-insensitive compare.
- `lib/services/tags/tag_color_palette.dart` — pure. The twelve palette
  colours and the stable default colour for a name.
- `lib/services/duplicates/hash_tools_channel.dart` — Dart side of the native
  hash channel: `sha256(uri)` and `grayscale(uri, size)`. An abstract class so
  tests can supply a fake, in the style of `MediaStoreChannel`.
- `lib/services/duplicates/perceptual_hash_service.dart` — pure. dHash and
  pHash from a grayscale byte array, plus the DCT, the median split, and
  `hammingDistance`.
- `lib/services/duplicates/content_hash_service.dart` — computes and caches
  `MediaHashes` for one item: asks the channel, falls back to the `crypto`
  package over thumbnail bytes when the platform is unavailable, and writes
  the result through `MediaDao.updateHashes`.
- `lib/services/duplicates/duplicate_group_service.dart` — pure. Takes a list
  of `MediaHashes` plus their items and returns the exact and similar groups,
  using the banded bucket index and union-find described above.
- `lib/services/duplicates/best_photo_service.dart` — pure. Scores a group and
  names the keeper.
- `lib/services/duplicates/duplicate_scan_service.dart` — drives the whole
  scan: pages through indexed media, hashes what is missing, reports progress
  on a stream, honours a cancel, and returns the groups.

### Repositories

- `lib/repositories/tag_repository.dart` — the only way the app changes tags.
  Create, rename, recolour, delete, add to media, remove from media, set the
  whole tag set of one item, read tags for an item, read all tags with counts.
  Keeps the FTS `tags_content` cell correct after every change.
- `lib/repositories/search_repository.dart` — runs a `SearchQuery` against the
  DAO, resolves tag names to ids, merges the query into `FilterOptions`, and
  returns `SearchResult`s.

### Providers

- `lib/providers/search_providers.dart` — the raw text notifier, a debounced
  parsed-query provider, the results `FutureProvider`, the active filter
  notifier, and the history controller.
- `lib/providers/tag_providers.dart` — all tags, tags for one media item, the
  tag-filter selection notifier (chosen ids plus `AND` / `OR`), and the tag
  editor controller.
- `lib/providers/duplicate_providers.dart` — the service providers, the scan
  controller with its progress state, the found groups, and the per-group
  keep/remove selection notifier.

### Screens

- `lib/screens/search/search_screen.dart` — at `/search`: the search field,
  recent searches when the box is empty, a filter button, and a result grid
  with an empty state.
- `lib/screens/tags/tags_screen.dart` — at `/tags`: the tag list with colour
  dots and counts, create / rename / recolour / delete, and a "show media"
  action that opens the search screen filtered to that tag.
- `lib/screens/cleaner/duplicate_cleaner_screen.dart` — at `/cleaner`: start
  and stop the scan, live progress, and the found groups with the bytes they
  would free.
- `lib/screens/cleaner/duplicate_compare_screen.dart` — at
  `/cleaner/compare/:groupId`: the members side by side with size, pixels,
  date and camera, the suggested keeper highlighted, and the "Keep Best Photo
  / Move Rest to Trash" confirm bar.

### Widgets

- `lib/widgets/search/search_field_bar.dart` — the text field, clear button,
  and the parsed-token chips.
- `lib/widgets/search/search_filter_sheet.dart` — type, favourite, has-GPS,
  date range, tags, and the `AND` / `OR` switch.
- `lib/widgets/search/recent_search_list.dart` — recent searches with a
  per-row remove and a clear-all.
- `lib/widgets/tags/tag_chip.dart` — one coloured tag chip, selectable.
- `lib/widgets/tags/tag_color_picker.dart` — the palette swatches.
- `lib/widgets/tags/tag_edit_dialog.dart` — make or rename a tag, with the
  name rules shown as inline errors.
- `lib/widgets/tags/tag_filter_bar.dart` — the horizontal chip row with the
  `AND` / `OR` toggle.
- `lib/widgets/tags/media_tag_sheet.dart` — tick tags on and off for one media
  item, with an inline "new tag" row. Opened from the viewer.
- `lib/widgets/cleaner/duplicate_group_card.dart` — the group preview strip,
  its kind badge, member count, and reclaimable size.
- `lib/widgets/cleaner/comparison_pane.dart` — one candidate: picture, facts,
  keep radio, and the "best" badge.
- `lib/widgets/cleaner/keep_best_bar.dart` — the count and the confirm action.

### Native Kotlin

- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/HashToolsChannelHandler.kt`
  — `sha256(uri)` streaming the content in 64 KB blocks, and
  `grayscale(uri, size)` decoding a downsampled bitmap and returning a
  `size * size` byte array. All work on a background thread, answered on the
  main thread, every call wrapped so a broken file returns an error result and
  never a crash.

### Tests (mirroring `lib/`)

- `test/models/search/search_query_test.dart`,
  `test/models/duplicate/media_hashes_test.dart`,
  `test/models/duplicate/duplicate_group_test.dart`.
- `test/services/search/search_query_parser_test.dart` — every prefix, mixed
  text, unknown prefixes, and the escaping of quotes, stars, and a bare `AND`.
- `test/services/search/search_history_service_test.dart` — add, cap, dedupe,
  clear, and a corrupt file.
- `test/services/tags/tag_name_rules_test.dart`,
  `test/services/tags/tag_color_palette_test.dart`.
- `test/services/duplicates/perceptual_hash_service_test.dart` — a known
  gradient's dHash, pHash stability when every pixel is brightened, the
  distance between an image and its shifted copy, and `hammingDistance`.
- `test/services/duplicates/duplicate_group_service_test.dart` — exact groups,
  similar groups, a five-photo burst becoming one group, and no group for
  unrelated photos.
- `test/services/duplicates/best_photo_service_test.dart` — each scoring rule
  and the tie-breaks.
- `test/services/duplicates/duplicate_scan_service_test.dart` — against a fake
  channel: skips already-hashed items, keeps going past a failing file, and
  stops on cancel.
- `test/services/duplicates/fake_hash_tools_channel.dart` — the test double.
- `test/repositories/tag_repository_test.dart` — create, duplicate name
  refused, rename, delete cascading off media, and the FTS `tags_content` cell
  after each change.
- `test/repositories/search_repository_test.dart` — text plus tag `AND`, text
  plus tag `OR`, a type filter, and a date range, on a real in-memory
  database.

## 5. Files to be changed

- `lib/repositories/database/media_dao.dart` — make `_syncFtsTags` public and
  make it write an empty string when the tag list is empty; add an FTS
  sub-query branch to `getMediaItems` so text and filters run as one
  statement; add `getHashRows` (a light projection for the duplicate scan) and
  `getItemsMissingHashes`.
- `lib/repositories/database/tag_dao.dart` — add `renameTag`,
  `getTagsForMediaBatch`, `setTagsForMedia`, `getMediaIdsForTag`, and
  `recountTag`, so the repository is not doing SQL of its own.
- `lib/models/filter_options.dart` — no field changes; add a `clearedSearch`
  helper so the search screen can drop just the text and keep the filters.
- `lib/core/routing/app_router.dart` — wire `/search`, `/tags`, `/cleaner`,
  and `/cleaner/compare/:groupId`, plus their path helpers.
- `lib/core/constants/app_constants.dart` — the Phase 8 block: the hash
  channel name, grayscale grid size, hash block size, the pHash and dHash
  distance thresholds, the band count, the scan page size, the tag name
  length cap, the search debounce, the recent-search cap and file name.
- `lib/screens/timeline/timeline_screen.dart` — a search action and an
  overflow menu reaching tags and the cleaner.
- `lib/screens/viewer/media_viewer_screen.dart` — a "tags" action opening the
  media tag sheet.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` —
  register the new hash channel handler.
- `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` — a string for every new
  user-visible label, each with its `@key` description. Then `flutter gen-l10n`.
- `docs/implementation_progress.md` — tick the Phase 8 rows and set the phase
  to Completed.

## 6. Risks and how they are handled

| Risk | Handling |
|---|---|
| A user's typed text breaks the FTS `MATCH` | One escaping function, used everywhere, with tests for quotes, stars, and operator words |
| Duplicate scan is slow on a big library | Hashes persist, so a rerun is near-instant; the scan is paged, cancellable, and reports progress |
| Comparing every pair is quadratic | Banded pHash buckets plus union-find; only photos sharing a band are compared |
| Perceptual hashing a huge or broken photo | Native decode is downsampled to 32x32 through `inSampleSize`; a failure is counted and skipped, never fatal |
| "Delete Rest" losing a photo the user wanted | Nothing is erased. Items move to trash after a confirm naming the count, and can be restored |
| Removing a tag leaves it searchable | The FTS tag cell is rewritten on every tag change, including down to empty |

## 7. Definition of done

- `flutter analyze` is clean.
- `flutter test` passes, including every new test above.
- `flutter gen-l10n` runs clean and no new widget holds a raw user-visible
  string.
- Search, tags, and the cleaner are reachable from the timeline, and the
  viewer can tag a photo.
- The change log is written to `change_log/` and this plan is marked
  `completed`.
