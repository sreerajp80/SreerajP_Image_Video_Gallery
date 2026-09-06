# Plan: Phase 2 — Core Domain Models & Database (sqflite + SQLite FTS5)

**Status:** Implemented

## 1. Issue & Objective
Phase 2 of the SreerajP Image Video Gallery implements the entire data layer backbone for local persistence, indexing, metadata management, atomic file handling, and full-text search.

The objectives are:
1. Create all immutable core domain models (`MediaItem`, `Album`, `Tag`, `ExifData`, `VaultItem`, `FilterOptions`) with `const` constructors, copyWith, serialization (JSON/Map), and value equality.
2. Define domain exception hierarchy in `lib/core/errors/app_exception.dart`.
3. Implement `AtomicSaver` in `lib/core/storage/atomic_saver.dart` to guarantee non-destructive, crash-resilient file writes with staging files (`.tmp`) and checksum validation.
4. Implement `DatabaseHelper` and schema migrations in `lib/repositories/database/database_helper.dart` using `sqflite` with WAL mode and foreign key constraints enabled.
5. Create SQLite tables and indexes for media metadata, albums, tags, many-to-many junction tables, and private vault records.
6. Set up SQLite FTS5 virtual table (`media_search_fts`) with search indexing and sync triggers for fast full-text search across titles, tags, user notes, EXIF data, and reverse geocodes.
7. Implement DAOs (`MediaDao`, `AlbumDao`, `TagDao`, `VaultDao`) to encapsulate database queries cleanly away from UI layers.
8. Add comprehensive unit tests in `test/models/`, `test/core/storage/`, and `test/repositories/database/`.

## 2. Dependencies to Add
- `sqflite: ^2.3.3+3` (Local SQLite database)
- `path: ^1.9.0` (Path manipulation)
- `path_provider: ^2.1.4` (Platform directory access)
- `sqflite_common_ffi: ^2.3.3+1` (in `dev_dependencies` for cross-platform unit tests in `flutter test`)

All packages are strictly open-source (BSD licensed), contain zero telemetry, and require zero network permissions.

## 3. Files to Create / Modify

### Dependencies
- `pubspec.yaml` (Add `sqflite`, `path`, `path_provider`, `sqflite_common_ffi`)

### Core Utilities & Storage
- `lib/core/errors/app_exception.dart` (Domain and storage exceptions)
- `lib/core/storage/atomic_saver.dart` (Safe staging file writes and swap)

### Domain Models (`lib/models/`)
- `lib/models/media_item.dart` (`MediaItem`, `MediaType`)
- `lib/models/album.dart` (`Album`, `AlbumType`)
- `lib/models/tag.dart` (`Tag`)
- `lib/models/exif_data.dart` (`ExifData`)
- `lib/models/vault_item.dart` (`VaultItem`)
- `lib/models/filter_options.dart` (`FilterOptions`, `TagFilterMode`, `MediaSortField`, `SortDirection`)

### Database Layer (`lib/repositories/database/`)
- `lib/repositories/database/database_constants.dart` (Table, column, trigger, and index names)
- `lib/repositories/database/database_helper.dart` (Database initialization, migrations, connection management)
- `lib/repositories/database/media_dao.dart` (CRUD, FTS search, sorting, filtering for media items)
- `lib/repositories/database/album_dao.dart` (CRUD and album item membership)
- `lib/repositories/database/tag_dao.dart` (CRUD and media tagging)
- `lib/repositories/database/vault_dao.dart` (Encrypted vault item index management)

### Unit Tests (`test/`)
- `test/models/media_item_test.dart`
- `test/models/album_test.dart`
- `test/models/tag_test.dart`
- `test/models/exif_data_test.dart`
- `test/models/vault_item_test.dart`
- `test/models/filter_options_test.dart`
- `test/core/storage/atomic_saver_test.dart`
- `test/repositories/database/database_helper_test.dart`
- `test/repositories/database/media_dao_test.dart`
- `test/repositories/database/album_dao_test.dart`
- `test/repositories/database/tag_dao_test.dart`
- `test/repositories/database/vault_dao_test.dart`

### Documentation Tracker
- `docs/implementation_progress.md` (Update Phase 2 status upon completion)

## 4. Detailed Implementation Strategy

1. **Atomic File Safety (`AtomicSaver`):**
   - Staging file writes to temporary `.tmp` location.
   - Verification of file existence, non-zero size, and integrity.
   - Atomic rename/swap to destination path.
   - Automatic fallback cleanup on write failures.

2. **Database Schema & Migrations:**
   - Version 1 schema creating `media_items`, `albums`, `album_media_entries`, `tags`, `media_tag_entries`, `vault_items`, and `media_search_fts`.
   - SQLite triggers to keep `media_search_fts` synchronized on `media_items` inserts, updates, and deletes.
   - Proper indexes on `date_taken`, `media_type`, `is_favorite`, `is_vaulted`, `is_trash`, and foreign keys.

3. **DAOs & Query Isolation:**
   - Typed methods for inserting, querying with `FilterOptions`, updating favorites/tags/notes, and executing parameterized FTS5 full-text searches.

4. **Testing:**
   - Test model serialization and equality.
   - Test atomic file write success, overwrite, and failure recovery.
   - Test in-memory SQLite database lifecycle, CRUD operations, relationships, cascade deletes, and FTS5 search queries.

## 5. Verification Plan
- Run `flutter pub get`
- Run `flutter analyze` (zero warnings)
- Run `flutter test` (all tests passing)
