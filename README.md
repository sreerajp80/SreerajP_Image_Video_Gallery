# SreerajP Image Video Gallery

An offline-first image and video gallery application for Android designed for viewing, organizing, editing, and managing local media with high privacy, performance, and security.

---

## 1. Features & Architecture Highlights

- **Offline-First & Privacy-Centric**: Zero remote servers, zero cloud backends, zero analytics, and no telemetry. Network connectivity is restricted exclusively to private peer-to-peer Wi-Fi file transfers between devices.
- **Scoped Storage & Modern MediaStore**: Full Android 14+ granular permission support (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, and `READ_MEDIA_VISUAL_USER_SELECTED`) with no broad legacy storage permissions required.
- **Chronological Timeline & Fluid Grid**: Smooth multi-column grid with pinch-to-zoom, fast date-scrubber, and flashback memories.
- **Secure Private Vault**: Hardware-backed biometrics and AES-256-GCM authenticated encryption for private media items.
- **In-App Media Editor**: Non-destructive image adjustments, crops, rotation, filters, and markup drawings.
- **Local Media Intelligence**: On-device QR/barcode reading and offline OCR text extraction using bundled Tesseract language data (English and Malayalam).
- **Format Conversion & Compression**: Convert and compress images/videos locally to standard formats (JPEG, PNG, WebP).
- **Internationalization**: Dual-language support in English (`en`) and Malayalam (`ml`).

---

## 2. Prerequisites

| Component | Requirement |
|---|---|
| Flutter SDK | `^3.41.0` or higher |
| Dart SDK | `^3.11.0` or higher |
| Platform Target | Android only |
| Android Min SDK | `24` (Android 7.0 Nougat) |
| Android Target SDK | `35` (Android 15) |
| Java Development Kit | JDK 17 |

---

## 3. Getting Started & Setup

### 3.1 Clone and Install Dependencies

```bash
# Fetch pub packages
flutter pub get

# Generate localization files (AppLocalizations)
flutter gen-l10n
```

### 3.2 Running the Application

The project uses Android build flavors (`dev` and `prod`). Always pass the `--flavor` flag when executing:

```bash
# Development flavor (with debug tooling and .dev package suffix)
flutter run --flavor dev

# Production flavor
flutter run --flavor prod
```

---

## 4. Code Quality & Testing

All code changes must pass static analysis and the automated test suite before committing:

```bash
# Run static analysis (must report zero warnings/errors)
flutter analyze

# Run all unit, service, repository, and widget tests
flutter test

# Format all Dart files according to repository conventions
dart format .
```

---

## 5. Building for Production (Android)

Production artifacts must be hardened using `--release`, `--obfuscate`, and `--split-debug-info`:

### 5.1 Split APKs (Direct Distribution / Sideloading)

Generates separate APKs per CPU architecture (`arm64-v8a`, `armeabi-v7a`, `x86_64`):

**Bash / macOS / Linux:**
```bash
flutter build apk --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod/ \
  --split-per-abi
```

**PowerShell (Windows):**
```powershell
flutter build apk `
  --flavor prod `
  --release `
  --obfuscate `
  --split-debug-info=build/symbols/android-prod/ `
  --split-per-abi
```

### 5.2 App Bundle (Google Play Store)

Generates a signed Android App Bundle (`.aab`):

**Bash / macOS / Linux:**
```bash
flutter build appbundle --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod/
```

**PowerShell (Windows):**
```powershell
flutter build appbundle `
  --flavor prod `
  --release `
  --obfuscate `
  --split-debug-info=build/symbols/android-prod/
```

> **Note**: Release signing properties are read from `android/key.properties`, which points to the keystore at `android/gallery-release.jks`. These files are git-ignored and never committed.

---

## 6. Database Migrations

The local cache and indexing database is powered by SQLite via `sqflite`.

- Database configuration and table constants are in `lib/repositories/database/database_constants.dart`.
- The database connection, lifecycle, and migration executor are in `lib/repositories/database/database_helper.dart`.

### Steps to add a migration:
1. Increment `DatabaseConstants.schemaVersion` in `lib/repositories/database/database_constants.dart`.
2. Add a new migration handler method in `DatabaseHelper` (e.g. `_migrateToV3(Database db)`).
3. Call the migration in `_onUpgrade` inside `DatabaseHelper` within the version transition switch.
4. Add corresponding unit tests in `test/repositories/database_helper_test.dart` to verify schema progression from the previous version.

---

## 7. Documentation & Architecture Reference

| Document | Purpose |
|---|---|
| [AGENTS.md](AGENTS.md) | Mandatory AI agent guidelines, constraints, and workflow rules |
| [CLAUDE.md](CLAUDE.md) | Claude Code workflow configuration and commands |
| [docs/architecture.md](docs/architecture.md) | Layer boundaries, state management, models, and services |
| [docs/security.md](docs/security.md) | Threat model, offline networking boundaries, and vault crypto |
| [docs/release_process.md](docs/release_process.md) | Production release runbook and checklist |
| [docs/dependencies.md](docs/dependencies.md) | Dependency inventory and blocked library policy |
| [docs/project_structure.md](docs/project_structure.md) | Detailed directory layout and responsibility index |
| [docs/workflow_rules.md](docs/workflow_rules.md) | Plan-before-changing and log-after-changing protocol |
