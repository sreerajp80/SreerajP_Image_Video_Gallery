# Project Structure — Image & Video Gallery

This document outlines the directory structure, file naming conventions, and layer ownership rules for the Image & Video Gallery repository.

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [architecture.md](architecture.md)

---

## 1. Top-Level Project Layout

```text
.
|-- .agents/              # Agent customizations and workspace rules
|-- android/              # Native Android project configuration and Gradle scripts
|-- assets/               # Static assets (icons, config files)
|   `-- config/           # App configuration (app_config.json)
|-- change_log/           # Historical change logs for every completed plan
|-- docs/                 # Project documentation and architectural guidelines
|   `-- guidelines/       # Shared Flutter guidelines Git submodule
|-- lib/                  # Application source code (Tier 1 layer-first)
|-- plans/                # Dated implementation plans requiring user approval
|-- test/                 # Automated unit, widget, and integration test suite
|-- AGENTS.md             # Project rules and architectural guidelines for AI agents
|-- CLAUDE.md             # Claude Code workflow instructions
|-- README.md             # Project overview, setup, build, and test guide
|-- l10n.yaml             # Localization generator configuration
`-- pubspec.yaml          # Project dependencies, assets, and metadata
```

---

## 2. Source Code Architecture (`lib/`)

```text
lib/
|-- core/                                # App-wide utilities, error handling, config
|   |-- config/                          # AppFlavorConfig and ConfigService
|   |-- errors/                          # Domain exceptions and failure types
|   |-- storage/                         # AtomicSaver and file safety utilities
|   `-- utils/                           # RAM policy, date formatters, directionality
|-- models/                              # Immutable data entities
|   |-- album.dart                       # Virtual and physical album models
|   |-- exif_data.dart                   # Camera metadata and EXIF properties
|   |-- media_filter.dart                # Filtering and query parameter models
|   |-- media_item.dart                  # Image and Video core domain entity
|   |-- tag.dart                         # User-defined custom tag model
|   `-- vault_item.dart                  # Encrypted vault file model
|-- repositories/                        # Persistence and MediaStore queries
|   |-- album_repository.dart
|   |-- database/                        # sqflite connection, migrations, FTS5
|   |-- media_repository.dart            # Android MediaStore query abstraction
|   |-- tag_repository.dart
|   `-- vault_repository.dart            # Encrypted file persistence
|-- services/                            # Pure computational and native services
|   |-- crypto/                          # AES-256-GCM and Android Keystore wrapper
|   |-- editor/                          # Image transformations, filters, markup
|   |-- hash/                            # SHA-256 and pHash perceptual hashing
|   |-- intelligence/                    # In-Image QR scanner and offline OCR
|   |-- metadata/                        # EXIF parser and privacy stripper
|   `-- video/                           # Video frame grabber and trimming
|-- providers/                           # Riverpod state notifiers and providers
|   |-- album_providers.dart
|   |-- cleaner_providers.dart           # Duplicate finder state
|   |-- editor_providers.dart            # Active image editing session state
|   |-- media_providers.dart             # Timeline and thumbnail loading state
|   |-- search_providers.dart            # FTS5 search query state
|   `-- vault_providers.dart             # Vault lock/unlock and media state
|-- screens/                             # App navigation destinations
|   |-- albums/                          # Albums grid and album detail views
|   |-- cleaner/                         # Duplicate and similar photo cleanup screen
|   |-- editor/                          # Fullscreen non-destructive image editor
|   |-- search/                          # Multi-criteria FTS5 search screen
|   |-- settings/                        # App settings and About screen
|   |-- timeline/                        # Main chronological timeline & flashback
|   |-- vault/                           # Biometric unlock & private vault gallery
|   `-- viewer/                          # Fullscreen image viewer and video player
|-- widgets/                             # Reusable visual components
|   |-- common/                          # Adaptive directionality, buttons, badges
|   |-- editor/                          # Markup canvas, crop overlays, tone sliders
|   |-- media/                           # Dynamic grid, thumbnail tile, fast scrubber
|   `-- viewer/                          # Video controls, gesture zoom, EXIF drawer
|-- theme/                               # Material 3 themes and palettes
|   |-- app_theme.dart
|   `-- color_schemes.dart
|-- l10n/                                # ARB localization templates
|   |-- app_en.arb                       # English translations (source of truth)
|   `-- app_ml.arb                       # Malayalam translations
`-- main.dart                            # Application entry point and ProviderScope
```

---

## 3. Directory Responsibility & Boundary Rules

1. **`models/`**:
   - Must contain only pure Dart immutable classes with `const` constructors and `copyWith`.
   - Never import Flutter widgets, UI packages, or databases in `models/`.
2. **`services/`**:
   - Perform specific computations (e.g. image filtering, hashing, cryptography).
   - Never reference `BuildContext` or navigation logic in `services/`.
3. **`repositories/`**:
   - Abstract the underlying storage mechanism (`sqflite`, Android MediaStore, encrypted vault files).
   - Return domain models or Result/Either types.
4. **`providers/`**:
   - Riverpod StateNotifiers coordinate data loading from repositories and invoke services.
   - Expose immutable state objects to screens.
5. **`screens/` & `widgets/`**:
   - Render UI and capture user interactions.
   - All user-visible strings must use `AppLocalizations.of(context)!`.
   - No direct database queries or raw file writes from widgets.
