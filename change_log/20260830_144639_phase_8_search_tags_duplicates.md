# Change Log — Phase 8: Search, Multi-Tag Filtering & Duplicate Detection (pHash)

**Date:** 2026-08-30
**Implements:** [plans/20260830_111653_phase_8_search_tags_duplicates.md](../plans/20260830_111653_phase_8_search_tags_duplicates.md)
**Phase:** 8 of 13 (see [docs/implementation_plan.md](../docs/implementation_plan.md))

---

## What was built

Phase 8 turns on three things the database was already prepared for but nothing
used: full-text search, custom tags, and a duplicate finder.

### 1. Search, at `/search`

- A pure `SearchQueryParser` turns typed text into a `SearchQuery`. It
  understands `tag:`, `type:`, `place:`, `camera:`, `before:` and `after:`, and
  treats anything else as plain search text. An unknown prefix, or a prefix
  with nothing after it, falls back to plain text rather than failing.
- The same parser builds the FTS5 `MATCH` expression. Every user word is
  quoted, inner quotes are doubled, and the only wildcard is the prefix `*` the
  parser adds itself. A user typing `"`, `*`, `AND` or `NEAR(` searches for
  those characters instead of changing the query.
- `MediaDao.getMediaItems` now takes an optional match expression and folds it
  in as an `id IN (...)` sub-query. Text and filters therefore run as one
  statement with one sort, instead of searching first and filtering in Dart.
- The screen has a debounced search box, a filter sheet (kind, favourites,
  place, date range, tags with `AND` / `OR`), a result grid, and recent
  searches. Recent searches live in a small JSON file written through
  `AtomicSaver`; a missing or corrupt file simply reads as no history.

### 2. Tags, at `/tags`

- `TagRepository` is now the only way tags change. It applies `TagNameRules`
  (trim, collapse inner spaces, length cap, case-insensitive uniqueness) before
  anything is written, and it rewrites the FTS tag words for every affected
  photo after every change.
- The private `_syncFtsTags` became public `syncFtsTags` and now writes an
  empty cell when the last tag is removed. Before this it returned early, so a
  removed tag would have stayed searchable.
- Colours come from a fixed twelve-colour palette. A new tag takes the colour
  its name maps to through a stable hash, so the colour does not change between
  runs, and the user can still pick another.
- The tag screen creates, renames, recolours and deletes. A tag sheet in the
  viewer ticks tags on and off for one photo and writes the whole set at once.

### 3. Duplicate cleaner, at `/cleaner`

- A new Kotlin `HashToolsChannelHandler` does the two jobs Dart should not:
  it streams SHA-256 in 64 KB blocks, and it returns a 32x32 grayscale grid
  decoded with `inSampleSize`. Neither ever holds a whole file in memory, and
  anything Android can decode is covered.
- `PerceptualHashService` computes both 64-bit hashes from that grid as pure
  maths: `pHash` from a 32x32 DCT keeping the top-left 8x8 block and splitting
  on the median, and `dHash` from a 9x8 neighbour comparison.
- Both hashes share the existing `p_hash` column as `<phash>:<dhash>`, so there
  was no schema change and no migration.
- The scan is paged, cancellable, and resumable: every fingerprint is written
  back as it is worked out, so a second scan reads no files it has already seen.
  A file it cannot read is counted and skipped, never fatal.
- Exact copies are grouped by SHA-256. Similar copies are found by bucketing
  the pHash into four 16-bit bands and only comparing photos that share a band,
  then merging matches with a union-find, so a burst of five shots becomes one
  group of five rather than ten pairs. Both hashes have to agree before two
  photos are called similar.
- The comparison screen shows the copies side by side with the facts the
  suggestion is scored on, and the user can override the choice.

**Nothing is deleted from disk.** "Keep Best Photo" moves the other copies to
the app's trash after a confirmation that names the count. The screen says in
plain words that the files stay on the device and can be brought back.

---

## Two real defects found and fixed while testing

**A nonsense date silently became a real one.** `before:2026-13-99` parsed
without complaint, because both `DateTime.parse` and the `DateTime`
constructor roll an out-of-range value over — it became a date in 2027 and
would have quietly filtered out most of the library. The parser now checks the
parts against the date that comes back and ignores anything that does not
match.

**A flat picture hashed to noise.** A blank wall, a plain screenshot, or any
picture with little detail produces DCT coefficients that are all
mathematically zero, leaving the median sitting in floating-point noise around
1e-15. Which side of it each value fell on was decided by rounding error, so
two photos of the same blank wall could hash completely differently while two
unrelated ones happened to agree. A tolerance scaled to the largest coefficient
now makes such a picture hash to a stable zero; it is far too small to affect a
normal photo, whose coefficients are in the hundreds.

Both are covered by tests.

---

## Files added

### Models
- `lib/models/search/search_query.dart`
- `lib/models/search/search_result.dart`
- `lib/models/search/search_history_entry.dart`
- `lib/models/duplicate/media_hashes.dart`
- `lib/models/duplicate/duplicate_group.dart`
- `lib/models/duplicate/duplicate_scan_state.dart`

### Services
- `lib/services/search/search_query_parser.dart`
- `lib/services/search/search_history_service.dart`
- `lib/services/tags/tag_name_rules.dart`
- `lib/services/tags/tag_color_palette.dart`
- `lib/services/duplicates/hash_tools_channel.dart`
- `lib/services/duplicates/perceptual_hash_service.dart`
- `lib/services/duplicates/content_hash_service.dart`
- `lib/services/duplicates/duplicate_group_service.dart`
- `lib/services/duplicates/best_photo_service.dart`
- `lib/services/duplicates/duplicate_scan_service.dart`

### Repositories and providers
- `lib/repositories/tag_repository.dart`
- `lib/repositories/search_repository.dart`
- `lib/providers/search_providers.dart`
- `lib/providers/tag_providers.dart`
- `lib/providers/duplicate_providers.dart`

### Screens and widgets
- `lib/screens/search/search_screen.dart`
- `lib/screens/tags/tags_screen.dart`
- `lib/screens/cleaner/duplicate_cleaner_screen.dart`
- `lib/screens/cleaner/duplicate_compare_screen.dart`
- `lib/widgets/search/search_field_bar.dart`
- `lib/widgets/search/search_filter_sheet.dart`
- `lib/widgets/search/recent_search_list.dart`
- `lib/widgets/tags/tag_chip.dart`
- `lib/widgets/tags/tag_color_picker.dart`
- `lib/widgets/tags/tag_edit_dialog.dart`
- `lib/widgets/tags/tag_filter_bar.dart`
- `lib/widgets/tags/media_tag_sheet.dart`
- `lib/widgets/cleaner/duplicate_group_card.dart`
- `lib/widgets/cleaner/comparison_pane.dart`
- `lib/widgets/cleaner/keep_best_bar.dart`

### Native
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/HashToolsChannelHandler.kt`

### Tests
- `test/models/search/search_query_test.dart`
- `test/models/duplicate/media_hashes_test.dart`
- `test/models/duplicate/duplicate_group_test.dart`
- `test/services/search/search_query_parser_test.dart`
- `test/services/search/search_history_service_test.dart`
- `test/services/tags/tag_name_rules_test.dart`
- `test/services/tags/tag_color_palette_test.dart`
- `test/services/duplicates/perceptual_hash_service_test.dart`
- `test/services/duplicates/duplicate_group_service_test.dart`
- `test/services/duplicates/best_photo_service_test.dart`
- `test/services/duplicates/duplicate_scan_service_test.dart`
- `test/services/duplicates/fake_hash_tools_channel.dart`
- `test/repositories/tag_repository_test.dart`
- `test/repositories/search_repository_test.dart`

## Files changed

- `lib/repositories/database/media_dao.dart` — `syncFtsTags` made public and
  made to write an empty cell; a full-text sub-query branch added to
  `getMediaItems`; `getHashCandidates` added as a light projection for the
  duplicate scan, which needs no tags and would otherwise cost one extra query
  per row.
- `lib/repositories/database/tag_dao.dart` — added `renameTag`,
  `getMediaIdsForTag`, `setTagsForMedia` (one transaction), and `recountTag`.
- `lib/models/filter_options.dart` — `copyWith` gained `clearFavorite`,
  `clearDates`, `clearGps` and `clearSearchQuery`, because passing null means
  "leave alone" and the filter sheet has to be able to switch a filter back off.
- `lib/core/routing/app_router.dart` — wired `/search`, `/tags`, `/cleaner`,
  and `/cleaner/compare/:groupId`, with their path helpers.
- `lib/core/constants/app_constants.dart` — the Phase 8 block.
- `lib/screens/timeline/timeline_screen.dart` — a search action, and an
  overflow menu holding tags, the cleaner, and settings.
- `lib/screens/viewer/media_viewer_screen.dart` — a tags action opening the
  tag sheet.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` —
  registers and disposes the new hash channel.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` — a string for every new label,
  each with its `@key` description. Regenerated with `flutter gen-l10n`.
- `docs/implementation_progress.md` — Phase 8 marked complete.

## What was planned but not built

- `getHashRows` and `getItemsMissingHashes` were replaced by the single
  `getHashCandidates`, which is what the scan actually needs. Adding the other
  two would have left unused public API.
- `FilterOptions.clearedSearch` was replaced by the four `clear...` flags on
  `copyWith`, which cover the same need and more.

No new package was added, no permission was added, and no schema change was
needed.

## Verification

- `flutter analyze` — clean, no issues.
- `flutter test` — 806 tests pass, including the new ones listed above.
- `flutter gen-l10n` — clean; both language files carry every key.
- `dart format .` — applied.
- `flutter build apk --flavor dev --debug` — builds, so the new Kotlin handler
  compiles. The Android SDK and Kotlin version warnings it prints are
  pre-existing and unrelated to this phase.
