# Change Log: Phase 2 — Core Domain Models & Database (sqflite + SQLite FTS5)

**Date:** 2026-08-29  
**Plan Reference:** `plans/20260829_085600_phase_2_core_domain_models_and_database.md`  
**Status:** Completed

---

## 1. Summary of Changes

Phase 2 builds the complete local data layer and persistence foundation for the SreerajP Image Video Gallery application.

### Key Deliverables Implemented:
1. **Domain Models (`lib/models/`):**
   - `MediaItem` and `MediaType` (`image`, `video`, `gif`, `rawImage`, `svg`): Immutable domain entity representing photos and videos, supporting EXIF metadata, custom tags, user notes, GPS coordinates, and hashes.
   - `Album` and `AlbumType` (`physicalFolder`, `virtualAlbum`, `smartFavorites`, `smartVideos`, `smartGifs`, `smartRaw`, `smartTrash`): Immutable model for physical directories and virtual collections.
   - `Tag`: Immutable model for custom color-coded organization tags with item counters.
   - `ExifData`: Immutable metadata model for camera make/model, lens, aperture, shutter speed, ISO, GPS coordinates, and date/time.
   - `VaultItem`: Immutable model representing encrypted private vault media with initialization vectors (IV) and authentication tags.
   - `FilterOptions`: Immutable query criteria model supporting tag filtering (`AND`/`OR`), media types, date ranges, favorites, trash status, GPS filtering, and sorting.

2. **Error Handling Hierarchy (`lib/core/errors/app_exception.dart`):**
   - Implemented `AppException` base hierarchy including `StorageException`, `AtomicSaveException`, `DatabaseMigrationException`, and `ModelParseException`.

3. **Crash-Resilient File Operations (`lib/core/storage/atomic_saver.dart`):**
   - Implemented `AtomicSaver` for safe staging writes (`.tmp` -> verification -> atomic swap) and atomic file copies, preventing file corruption on unexpected crashes.

4. **Local Database Backbone (`lib/repositories/database/`):**
   - Configured `sqflite` with SQLite WAL mode and enabled foreign key constraints (`PRAGMA foreign_keys = ON;`).
   - Created tables: `media_items`, `albums`, `album_media_entries` (many-to-many junction), `tags`, `media_tag_entries` (many-to-many junction), and `vault_items`.
   - Built full-text search virtual table `media_search_fts` using SQLite FTS5 with automatic insert/update/delete triggers.
   - Implemented Data Access Objects:
     - `MediaDao`: CRUD, filtering with `FilterOptions`, batch upsert, favorite toggling, trash management, and FTS5 search queries.
     - `AlbumDao`: CRUD for virtual/physical albums, item membership, and cascade cleanup.
     - `TagDao`: CRUD for tags, media-tag associations, and item counters.
     - `VaultDao`: Index management for encrypted vault items.

5. **Testing & Quality Assurance (`test/`):**
   - Added 49 unit and integration tests across domain models, `AtomicSaver`, `DatabaseHelper` schema lifecycle, and all DAOs.
   - All tests pass with zero warnings in `flutter analyze`.

---

## 2. Files Added & Modified

### Modified
- `pubspec.yaml`
- `docs/implementation_progress.md`
- `plans/20260829_085600_phase_2_core_domain_models_and_database.md`

### Added
- `lib/core/errors/app_exception.dart`
- `lib/core/storage/atomic_saver.dart`
- `lib/models/exif_data.dart`
- `lib/models/media_item.dart`
- `lib/models/album.dart`
- `lib/models/tag.dart`
- `lib/models/vault_item.dart`
- `lib/models/filter_options.dart`
- `lib/repositories/database/database_constants.dart`
- `lib/repositories/database/database_helper.dart`
- `lib/repositories/database/media_dao.dart`
- `lib/repositories/database/album_dao.dart`
- `lib/repositories/database/tag_dao.dart`
- `lib/repositories/database/vault_dao.dart`
- `test/models/exif_data_test.dart`
- `test/models/media_item_test.dart`
- `test/models/album_test.dart`
- `test/models/tag_test.dart`
- `test/models/vault_item_test.dart`
- `test/models/filter_options_test.dart`
- `test/core/storage/atomic_saver_test.dart`
- `test/repositories/database/database_helper_test.dart`
- `test/repositories/database/media_dao_test.dart`
- `test/repositories/database/album_dao_test.dart`
- `test/repositories/database/tag_dao_test.dart`
- `test/repositories/database/vault_dao_test.dart`

---

## 3. Verification

- `flutter pub get`: Resolved all dependencies cleanly.
- `flutter analyze`: 0 errors, 0 warnings.
- `flutter test`: 49/49 tests passed.
