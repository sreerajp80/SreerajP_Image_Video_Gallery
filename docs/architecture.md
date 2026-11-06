# Architecture — SreerajP Image Video Gallery

This document describes how the SreerajP Image Video Gallery app is built: its layers, start-up
order, state, data, navigation and build model. Read it before you add or change a model,
service, repository, provider or screen. It follows the section order of the shared blueprint.
A section marked `N/A` says why.

### Read first
- [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md)
- [Project_Idea.md](Project_Idea.md)
- [security.md](security.md)
- [known_gaps.md](known_gaps.md)
- [guidelines/architecture.md](guidelines/architecture.md) (the blank template)
- [guidelines/flutter_project_engineering_standard.md](guidelines/flutter_project_engineering_standard.md)

---

## 1. Scope

- **Product:** SreerajP Image Video Gallery (`in.sreerajp.imgvidgal`)
- **Repository type:** application
- **Engineering standard profiles in force:** `Core Baseline` + `Production App Extension` +
  `Sensitive Data Extension`
- **App-specific rule on top of the profiles:** local network only, never the internet
  (hard rule 2 in `CLAUDE.md`).
- **Platforms:** Android only (minSdk 24, targetSdk 36)

---

## 2. Goals And Non-Goals

### Goals

- View, organize, edit, convert and protect local photos and videos with no account and no
  server.
- Never lose or damage an original file: every write is staged and swapped atomically.
- Keep private media private: an encrypted vault, no telemetry, and network use limited to a
  hand-paired phone on the same Wi-Fi.
- Stay smooth on large libraries and low-RAM phones.
- Never crash on a bad or hostile file.

### Non-Goals

- Cloud sync, accounts, sharing links or any remote server.
- iOS, desktop or web builds.
- Editing that changes an original file without the user's explicit confirmation.

---

## 3. Architecture Summary

The app uses a **Tier 1 layer-first** Flutter structure with **Riverpod** for state and
dependency injection and **go_router** for navigation. Screens and widgets only draw and
forward user actions. Providers hold state and call services and repositories. Services hold
pure logic, or wrap one Android method channel each. Repositories hide `sqflite` and the
Android MediaStore. Heavy work (decoding, hashing, filters) runs in isolates or in Kotlin. The
app has no HTTP client. Its only socket use is the local Wi-Fi transfer screen, which
`LocalAddressRules` limits to private addresses.

---

## 4. Repository Structure

### Current Structure Tier

- **Tier 1 (layer-first).**
- Why this tier fits now:
  - One developer, one app, one platform. Layer folders keep the dependency direction easy to
    check.
  - Features share many services (MediaStore, thumbnails, vault, hashing), so feature folders
    would mostly import each other.
- Do not move to Tier 2 without a plan and approval.

### Top-Level Source Layout

```text
lib/
|-- core/          # config, constants, device, errors, routing, storage (AtomicSaver), text
|-- models/        # immutable entities, grouped by feature subfolder
|-- repositories/  # MediaStore + sqflite access (database/ holds helper, DAOs, constants)
|-- services/      # pure logic and one wrapper per method channel, grouped by feature
|-- providers/     # Riverpod providers, one file per feature area
|-- screens/       # route destinations, grouped by feature
|-- widgets/       # reusable UI, grouped by feature
|-- theme/         # Material 3 themes and color schemes
|-- l10n/          # ARB files and generated AppLocalizations
`-- main.dart      # start-up and the root MaterialApp
```

The full folder list is in [project_structure.md](project_structure.md).

### Ownership Rules

| Path | Responsibility | May depend on | Must not depend on |
|---|---|---|---|
| `lib/models/` | Immutable entities (`const` constructors, `copyWith`) | Pure Dart | Flutter UI, DB, services |
| `lib/services/` | Crypto, OCR, hashing, image work, channel wrappers | `models/`, Dart SDK, low-level packages | `BuildContext`, widgets, routes |
| `lib/repositories/` | SQLite and MediaStore reads and writes | `models/`, `services/`, `sqflite` | `BuildContext`, widgets, navigation |
| `lib/providers/` | State and user-action orchestration | `repositories/`, `services/`, `models/` | Raw SQL, raw file writes |
| `lib/screens/`, `lib/widgets/` | Drawing, gestures, animation | `providers/`, `models/`, Flutter | SQL, file I/O, crypto, intent parsing |
| `lib/core/` | App-wide helpers used by every layer | Dart SDK, Flutter where needed | Feature code |
| `lib/core/domain/` | Pure rules with no I/O (name checks, geometry, grouping, address rules), usable from any layer, UI included | Dart SDK, `models/` | Services, repositories, platform code |

Dependency direction: `screens` → `providers` → `repositories` / `services` → `database` /
`platform` → `models`.

### Files Over 500 Lines

Engineering standard §16.2 says a file of about 500 lines should be split, or the reason
written down. On 2026-11-03 the viewer, the timeline and the privacy sheet were split,
and so was the photo compare screen. Their bars, dialogs, body and cards moved to
`lib/widgets/viewer/`, `lib/widgets/timeline/`, `lib/widgets/privacy/` and `lib/widgets/compare/`. These files stay large on purpose:

| File | Lines | Why it stays one file |
|---|---|---|
| `lib/repositories/database/media_dao.dart` | ~1,060 | The one DAO for the `media` table. Its queries share private helpers (tag loading, the FTS sync). Splitting it would need `part` files or would make those helpers public. |
| `lib/core/constants/app_constants.dart` | ~660 | A flat list of named constants, each with its reason. No logic to split. |
| `lib/widgets/privacy/media_privacy_sheet.dart` | ~650 | One state object owns the strip and fuzz options and the export call both tabs use. The audit card is already its own file. |
| `lib/services/pdf/pdf_lexer.dart` | ~630 | One tokenizer state machine. Its states only make sense read together. |
| `lib/screens/viewer/media_viewer_screen.dart` | ~630 | The page view, the chrome timer and the swipe-to-dismiss tracking share one state. Its bars and dialogs are already split out. |
| `lib/providers/editor_providers.dart` | ~565 | The wiring for every editor service plus the editor's own state. Could be split by tool later. |
| `lib/screens/editor/image_editor_screen.dart` | ~530 | Just over the limit. One state object drives every tool; the tool panels are already their own widgets. |
| `lib/providers/vault_providers.dart` | ~515 | Just over the limit. The wiring for every vault service plus the lock and batch controllers. |

A new file over 500 lines needs a split or a row here.

---

## 5. App Initialization Sequence

| Step | Code / Call | Notes |
|---|---|---|
| 1 | `WidgetsFlutterBinding.ensureInitialized()` | Always first. |
| 2 | FFI / platform binding init | `N/A` — Android only; `sqflite` needs no FFI there. `sqflite_common_ffi` is a dev dependency for tests. |
| 3 | `AppFlavorConfig.initialize()` | Reads `FLUTTER_APP_FLAVOR` (`dev` / `prod`). The logger reads the flavor, so this comes before any log call. |
| 3a | `_installErrorHandlers()` | `FlutterError.onError` and `PlatformDispatcher.instance.onError` log through `AppLogger`; in release, `ErrorWidget.builder` shows `SafeErrorFallback`. |
| 4 | `_loadSettings()` | Reads the settings JSON file from the app-support folder **before the first frame**, so the app opens in the right theme and language. Falls back to `AppSettings.defaults` on any error, so start-up never depends on it. |
| 5 | `runApp(ProviderScope(...))` | Overrides `appSettingsProvider` with the loaded settings. |
| 6 | Post-frame: `_initMediaIntents()` | Checks for a launch "open with" intent, then listens for new ones, and opens the viewer. |
| 7 | Logging init | None needed. `AppLogger` writes through `dart:developer` and has no async set-up. |

**Deferred (lazy) work:**

- **Database open and migration** happen on first use through the repository providers, not in
  `main()`. This keeps the first frame fast. `DatabaseHelper` runs `_onUpgrade` when it opens.
- **Secure storage** (`flutter_secure_storage`) is read only when the vault is opened.
- **Vault key** is created in the Android Keystore the first time the vault is set up.
- **Lifecycle observers** are registered per screen (vault, transfer), not globally. See §6.

---

## 6. App Lifecycle Behavior

The app has no global lifecycle observer. Three widgets observe the lifecycle for their own
screens.

| Lifecycle State | App Behavior |
|---|---|
| `resumed` | The vault stays as it was. It never unlocks by itself. |
| `inactive` / `hidden` / `paused` / `detached` | `VaultAutoLockScope` locks the vault at once (rules in the pure `VaultLockPolicy`). `SyncReceiveScreen` stops the socket listener on `paused`. `SyncSendScreen` also reacts to the change. |
| Idle while in the vault | The vault locks after the timeout the user chose (one timer, re-armed on each touch). |
| Memory pressure | `MemoryPressureObserver` (`lib/core/lifecycle/`) clears Flutter's image cache, the thumbnail service's memory cache and the `thumbnailProvider` / `vaultThumbnailProvider` entries (`memoryReliefProvider`). Tiles on screen load again from the disk cache. The cache size is still set at start from device RAM (§14). |

---

## 7. Offline Behavior

- **Connectivity requirement:** no remote network. Every feature works with no internet.
- **Network permission:** `INTERNET` is **present**, for one feature only: device-to-device
  transfer over the same Wi-Fi. Android needs it for any socket, even a LAN-only one.
- **What bounds it:** `LocalAddressRules` refuses any peer that is not in `10/8`, `172.16/12`,
  `192.168/16` or `169.254/16`. The listener binds to the phone's own Wi-Fi address (never
  `0.0.0.0`) and runs only while the transfer screen is open. Full detail:
  [security.md](security.md) §19.
- **No HTTP client** and no network-status package. The blocked list is in
  [dependencies.md](dependencies.md).
- **Offline data source:** `sqflite` plus the Android MediaStore.
- **Release check:** the merged manifest must list exactly the 11 permissions in
  [security.md](security.md) §11, including `INTERNET`, plus AndroidX's private
  `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. See
  [release_process.md](release_process.md).

---

## 8. State Management

- **Primary pattern:** Riverpod (`flutter_riverpod` 3.x since 2026-11-02). The code uses
  `StateNotifierProvider` (about 30), `FutureProvider` (about 45), plain `Provider`, and
  `StreamProvider`. `StateNotifier`, `StateNotifierProvider` and `StateProvider` now come from
  `package:flutter_riverpod/legacy.dart`; moving them to `Notifier` is optional later work.
- **Retry:** Riverpod 3 retries a failing provider by default. The app turns that off
  (`ProviderScope(retry: noProviderRetry)`, `lib/providers/provider_retry.dart`), because a
  corrupt file or a refused permission does not get better by itself (hard rule 5).
- **Pause:** Riverpod 3 pauses listeners in widgets hidden by `TickerMode`. Nothing in the app
  relies on updates while hidden (all tests pass).
- **Why:** compile-safe dependency injection, easy overrides in tests, and fine-grained rebuilds
  with `ref.watch(... .select(...))`.
- **State boundaries:**
  - Widgets own: scroll position, text controllers, animation, gesture state.
  - Providers own: screen and app state (timeline, selection, vault lock, editor session,
    settings, transfer session).
  - Services own: business rules (lock policy, scan actions, backup merge plan, hashing).

---

## 9. Data Flow

```text
Widget -> Provider (StateNotifier / FutureProvider) -> Service or Repository -> sqflite / MediaStore / method channel
```

Some pure services are called by providers without a repository (for example
`VaultLockPolicy`, `ScanActionResolver`, `BarcodePayloadParser`). That is intended: they touch
no storage.

### Rules

- Widgets must not know: SQL, file paths, crypto, method channel names, intent parsing.
- Services must not know: `BuildContext`, routes, or UI strings.
- Repositories hide: the `sqflite` schema, the FTS table and the MediaStore query builder.

---

## 10. Error Handling Architecture

- **Global error handler:** set in `main()` before `runApp` (engineering standard §11.1).
  `FlutterError.onError` and `PlatformDispatcher.instance.onError` only log. In release builds
  `ErrorWidget.builder` returns `SafeErrorFallback` (`lib/widgets/common/`), a context-free icon,
  instead of the grey error box. No handler navigates.
- **Domain exception hierarchy:** `sealed class AppException` in
  `lib/core/errors/app_exception.dart` (engineering standard §11.3). Every direct subclass is
  `final` and lives in that file, so a `switch` over an `AppException` must name each kind.
  Errors that belong to one feature extend the open branch `FeatureException` in the feature's
  own file (19 of them, such as `ConversionException`, `RestoreException`,
  `TransferSessionException` and `PrivacyProcessingException`), so `core/` never imports a
  service. Services never throw raw `StateError` / `ArgumentError`. A message never names a file,
  path or URI; the underlying error goes in `cause`.

| Exception Class | Thrown By | Meaning |
|---|---|---|
| `StorageException` | Repositories, storage helpers | A read or write failed |
| `AtomicSaveException` | `AtomicSaver` | A staged write could not be verified or swapped |
| `DatabaseMigrationException` | `DatabaseHelper._onUpgrade` | A schema upgrade failed (carries the from-version) |
| `ModelParseException` | Model `fromMap` / `fromJson` | Stored or received data could not be parsed |
| `MediaScanException` | MediaStore scanning | The media query failed |
| `PermissionDeniedException` | Permission flows | The user refused media access |
| `ThumbnailException` | Thumbnail service | A thumbnail could not be made |
| `VaultException` | Vault services | A vault operation failed |
| `VaultAuthException` | Vault auth | Wrong PIN, lockout, or biometric failure |
| `ValidationException` | Services | A value handed in is not valid (names the field) |
| `BatchItemException` | Batch handler | One item of a batch could not be handled (never names it) |
| `FeatureException` | Feature services | Open branch for feature errors (see above) |

- **Error escalation policy:** errors are caught in the service or provider that can explain
  them and shown as a friendly message. A bad file becomes a fallback icon or a "skipped, with
  reason" row, never a crash (hard rule 5). The screen never shows an exception's own text
  (§11.2): the duplicate cleaner and the batch result sheet show translated messages, and the
  detail goes to the log.
- **No silent catches:** every `catch` in `lib/services/` and `lib/repositories/` rethrows, logs
  through `AppLogger`, or carries a `// Safe to ignore: <reason>` comment.
  `test/tool/catch_policy_test.dart` fails the build if one does none of these.
- **"Open with" failures:** `MediaIntentController` (`lib/providers/media_intent_providers.dart`)
  handles links from other apps. A refused or unreadable link shows a SnackBar through
  `rootScaffoldMessengerKey`. Kotlin reports a refusal as `{"refused": true}` and sends nothing
  else about the link.
- **Fatal error screen:** none. There is no app-wide fatal screen yet (tied to G7).

---

## 11. Domain Model

### Current Schema Version

SQLite schema version: **5** (`DatabaseConstants.schemaVersion` in
`lib/repositories/database/database_constants.dart`). Database file: `gallery_database.db`.

Migration history:

| Version | Change Summary |
|---|---|
| 1 | Initial schema: `media_items`, `albums`, `album_media_entries`, `tags`, `media_tag_entries`, `vault_items`, plus the `media_search_fts` search table and its triggers |
| 2 | `vault_items` gains a thumbnail IV column, because every encrypted file has its own IV |
| 3 | Re-creates `media_search_fts` and its triggers if missing, with an FTS5 → FTS4 fallback for devices whose SQLite has no FTS5 |
| 4 | Adds a `media_search_fts` row, with tag names, for every media item that has none. v3 could create the table empty, so older photos were never searchable |
| 5 | Enum and flag columns are checked (`ColumnValueRule`): `CHECK` constraints on a new database, `BEFORE INSERT/UPDATE` triggers on an upgraded one. No table rebuild, because that would cascade-delete album and tag links |

Upgrade paths are tested in `test/repositories/database/database_migration_test.dart`.

How to add a migration is described in [../README.md](../README.md) §6.

### Core Models Or Entities

| Type | Purpose | Mutable? | Notes |
|---|---|---|---|
| `MediaItem` | One photo or video | No | Mirrors a MediaStore row plus app data (favorite, notes, vault, trash) |
| `Album` / `AlbumSummary` / `SmartAlbum` | Virtual, folder and smart albums | No | |
| `Tag` | A user tag | No | |
| `VaultItem` | One encrypted file | No | |
| `ExifData` | Camera metadata | No | |
| `TimelineGroup` / `FlashbackMemory` | Timeline sections and "on this day" | No | |
| Feature models in `lib/models/<feature>/` | Backup, batch, convert, duplicates, editor, help, notes, OCR, PDF, privacy, scan, search, settings, sync, vault, video | No | All `const` + `copyWith` |

### Serialization Strategy

- JSON models: yes — settings, backup body, app config, transfer manifest.
- Database models: yes — `toMap` / `fromMap` on the stored entities.
- Separate domain entities from transport models: partly. Backup and transfer use their own
  record types, so a format change does not change the domain model.

### Database Indexes

| Table | Indexed Columns | Reason |
|---|---|---|
| `media_items` | `date_taken DESC`, `date_added DESC` | Timeline order |
| `media_items` | `media_type` | Photo / video filters |
| `media_items` | `is_favorite`, `is_vaulted`, `is_trash` (one index each) | Smart albums and hiding vaulted/trashed rows |
| `album_media_entries` | `album_id` | Album contents |
| `media_tag_entries` | `tag_id`, `media_id` (one index each) | Tag filter and a photo's tags |

The index list lives in `DatabaseHelper`. Update this table when you add one.

---

## 12. Dependency Management And Injection

- **DI approach:** Riverpod providers. There is no service locator.
- **App-root dependencies:** `ProviderScope` in `main.dart`, with `appSettingsProvider`
  overridden by the settings read before the first frame.
- **Test replacement strategy:** provider overrides; services take their channel or store in the
  constructor (for example `VaultCredentialStore` is abstract), so tests use in-memory fakes.
  `sqflite_common_ffi` runs real SQLite in unit tests.

---

## 13. Navigation

- **Navigation approach:** `go_router` (declarative).
- **Route definition location:** `lib/core/routing/app_router.dart`. The initial location is the
  timeline.
- **Protected-route strategy:** `/vault` opens `VaultGateScreen`, which asks for biometrics or
  the PIN before showing anything. Vault screens are wrapped in `SecureScreen` (`FLAG_SECURE`)
  and `VaultAutoLockScope`. The "Hide content" setting adds `FLAG_SECURE` to every screen
  through `AppScreenProtection` in `MaterialApp.builder`.
- **Deep-link support:** no web deep links. The app does accept "open with" intents for images
  and videos from other apps, and routes them to the viewer.

```text
/ (Home shell: timeline, albums, and the rest of the main tabs)
|-- media-viewer/:id            (image / video viewer)
|   |-- editor | convert | video-tools | scan | text | notes
|-- search
|-- tags
|-- albums
|   |-- auto/:type              (smart albums; "trash" opens the trash screen)
|   |-- folder/:path            (device folder)
|   `-- :id                     (virtual album)
|       `-- reorder
|-- vault                       (gate: biometrics / PIN)
|   |-- settings
|   `-- viewer/:id
|-- cleaner                     (duplicates and similar photos)
|   `-- compare/:groupId
|-- compare                     (compare chosen photos)
|-- trash
|-- pdf-export | pdf-images
|-- backup
|-- sync                        (local Wi-Fi transfer; owns the socket listener)
|   |-- receive | send
`-- settings
    |-- about | appearance | language | safety | default-app | privacy | developer
    `-- help
        `-- :topicId
```

---

## 14. Persistence And External Systems

### Local Storage

- **Database:** `sqflite`, file `gallery_database.db`, foreign keys on.
- **WAL mode:** enabled (`PRAGMA journal_mode = WAL`), except for in-memory test databases.
- **Key-value storage:** a small JSON settings file in the app-support folder
  (`AppSettingsService`). It holds only non-secret preferences (theme, grid density, switches).
  The one exception is the language: engineering standard §8.4 names its place, so it is kept in
  `shared_preferences` under `app_language` (`system` or a language code). An old `localeCode`
  in the JSON file is moved across once.
- **Secure storage:** `flutter_secure_storage` holds the vault PIN hash, salt, iteration count
  and vault settings. The vault encryption key lives in the Android Keystore.
- **Files:** edits and conversions go through `AtomicSaver` (write to a `.tmp` file, verify,
  swap). New media is published through MediaStore.
- **Memory:** `system_info2` reads device RAM at start. Low-RAM phones (< 4 GB) keep about 100
  thumbnails at 256 px. Phones with 6 GB or more keep 500+ at 512 px.
- **Decode size:** small tiles (grid, trash, vault, PDF pictures, compare picker, video frame)
  use `SizedMemoryImage` (`lib/widgets/common/`), which decodes at the shown size × pixel ratio
  (twice that for a cover fit). The biggest win is a PDF picture of up to 80 megapixels shown in
  a 64 dp tile. The full-screen viewer, editor, compare views and vault viewer keep full
  resolution on purpose, because the user zooms in.

### Network

- **Network client:** none. No HTTP client exists in the dependency tree.
- **Sockets:** `dart:io` sockets on the transfer screen only, bound by `LocalAddressRules`.
- **Offline behavior:** fully usable offline; see §7.

### Platform Channels Or Native Integrations

Each channel has one Kotlin handler in `android/app/src/main/kotlin/…` and one Dart wrapper
service. Channel names live in `AppConstants`.

| Channel (`in.sreerajp.imgvidgal/…`) | Purpose |
|---|---|
| `mediastore` | Query, insert, update and delete MediaStore rows |
| `playback` | Screen brightness, media volume and keep-awake for the video player |
| `imagetools` | Native image encode/decode for conversion |
| `videotools` | Trim, frame grab and GIF export |
| `hashtools` | Fast SHA-256 and perceptual hashes |
| `vault` | Keystore key, AES-256-GCM cipher, shredder, `FLAG_SECURE` |
| `backup` | PBKDF2 + AES-256-GCM for `.gallerybak` archives |
| `documents` | Storage Access Framework pickers |
| `intents` | Incoming "open with" intents, and outgoing intents for the allowed scan schemes only |
| `app_info` | The app's own version name and build number from `PackageManager` (replaced `package_info_plus`, which pulled in `http`) |
| `barcode` | ZXing core reads codes from a still file (`decodeImageFile`) or from one camera frame's brightness plane (`decodeLuminance`). Replaced `mobile_scanner` and its ML Kit (G47) |

Plugins used: `camera` (preview and frames for the pairing QR scan; decoding is ZXing core on the
app's own `barcode` channel),
`flutter_tesseract_ocr` (offline OCR), `local_auth` (biometrics), `video_player` (ExoPlayer).

---

## 15. Environment And Build Model

- **Flavors used:** `dev` (`in.sreerajp.imgvidgal.dev`, debug keystore) and `prod`
  (`in.sreerajp.imgvidgal`, release keystore).
- **Runtime config mechanism:** native flavor. `FLUTTER_APP_FLAVOR` is set by `--flavor` and read
  by `AppFlavorConfig`. No `--dart-define` values are needed. About-screen data comes from
  `assets/config/app_config.json` through `ConfigService`.
- **Toolchain:** Flutter 3.47.6 / Dart 3.13.5, AGP 9.4.1, Kotlin 2.4.10, Gradle 9.8.0,
  `compileSdk` and `targetSdk` 36. These are the owner's chosen versions and are newer than the
  standard's 2026-10-15 snapshot (AGP 9.1.0, KGP 2.4.0, Gradle 9.3.1); that is a deliberate
  choice, not a gap. `android.builtInKotlin=false` and `android.newDsl=false` stay set until
  every plugin supports AGP 9's defaults.
- **Build outputs supported:** debug APK, release APK split per ABI, App Bundle.
- **Obfuscation:** on for every prod release, with symbols at
  `build/symbols/android-prod-<version>/`. R8 minify and resource shrinking are on. Full steps
  in [release_process.md](release_process.md).

---

## 16. UI System

- **Theme source of truth:** `lib/theme/app_theme.dart` (light, dark, AMOLED true black).
- **Design tokens location:** `lib/theme/color_schemes.dart`.
- **Shared widget strategy:** `lib/widgets/<feature>/` for feature widgets, `lib/widgets/common/`
  for app-wide ones (for example `AdaptiveDirectionality`).
- **Localization:** all text from `AppLocalizations`, in English (`en`), Malayalam (`ml`) and
  Sanskrit (`sa`). The language picker (System default / English / മലയാളം / संस्कृतम्) applies at
  once, with no restart. Flutter has no framework text for `sa`, so
  `lib/core/l10n/sanskrit_fallback_delegates.dart` serves English framework text for it; the app
  builds `MaterialApp` with `appLocalizationsDelegates` from that file. Dates go through
  `formattingLocale(...)` (`lib/core/l10n/formatting_locale.dart`) because `intl` has no `sa`
  data. Text direction is detected per field with `detectTextDirection` for mixed input. The
  Sanskrit still needs a fluent reader's review — [known_gaps.md](known_gaps.md) G9.
- **Fonts:** none bundled. `AppTheme.fontFamilyFallback` names Noto Sans Malayalam and Noto Sans
  Devanagari, which Android ships.
- **About screen:** config-driven from `assets/config/app_config.json` via `ConfigService`.
  Display values are `{"en","ml","sa"}` maps read through `LocalizedText`; row labels come from
  the `aboutDetail<Key>` ARB keys. The screen ends with the `MadeWithLove` badge
  (`lib/widgets/made_with_love.dart`).
- **Accessibility expectations:**
  - Minimum touch target: 48 × 48 dp.
  - Color contrast: WCAG AA (4.5:1 normal text, 3:1 large text).
  - Screen reader: TalkBack checked before each release.
  - Text scale: layouts checked at 1.0×, 1.5× and 2.0×.

---

## 17. Logging

- **Logger implementation:** `AppLogger` in `lib/core/logging/app_logger.dart`, with the six
  levels of engineering standard §14.1. It writes through `dart:developer` `log`, so it needs no
  package. `print` and `debugPrint` are not used anywhere in `lib/`.
- **Log file location:** `N/A` — nothing is written to a log file, on purpose (privacy).
- **Log rotation policy:** `N/A` — no log files.
- **Verbose logging gate:** `trace` and `debug` produce output only in the dev flavor
  (`AppFlavorConfig.current.isDev`). Outside the dev flavor an `error` object is reduced to its
  type name, so an exception message that quotes a file path cannot reach the log.
- **Sensitive data policy:** never log secrets, keys, PINs, passwords, OCR text, notes, Wi-Fi
  passwords or media bytes — in any build. Model `toString()` methods hide these on purpose.
  See [security.md](security.md) §9.

---

## 18. Testing Strategy

| Test Type | Scope | Notes |
|---|---|---|
| Unit | Services, repositories, models, providers, `core/` | Most of the ~150 test files. SQLite runs through `sqflite_common_ffi`. |
| Widget | Custom widgets and some screens | `test/widgets/`, `test/screens/` |
| Integration | `N/A` — there is no `integration_test/` folder yet | |
| Performance | `N/A` — manual profiling on a device before release | |

### Test Layout

```text
test/
|-- core/          # AtomicSaver, text direction, config, logger, formatting locale
|-- l10n/          # ARB parity, label length, About config parity, Sanskrit Hindi-marker gate, sa widgets
|-- models/        # copyWith, equality, serialization
|-- repositories/  # database helper, DAOs, migrations
|-- services/      # crypto, hashing, parsers, sync, backup, scan, OCR, PDF
|-- providers/     # state notifier behavior
|-- screens/       # screen widget tests
|-- widgets/       # custom component tests
|-- theme/         # theme tests
`-- helpers/       # fakes, fixtures, sample media
```

### Critical Test Areas

- `AtomicSaver` crash recovery and atomic swap.
- AES-256-GCM round trips and Keystore failure fallbacks.
- `LocalAddressRules` — must refuse every public address (`test/services/sync/local_address_rules_test.dart`).
- Backup container: header tamper detection, wrong password, restore adds/updates only.
- Scan scheme allow-list, on both the Dart and Kotlin sides.
- PDF extractor limits on hostile files.
- Perceptual hash distance accuracy.
- FTS search query parser with multi-tag `AND` / `OR`.
- Database upgrade path from version 1 to 3.
- Vault lock on background and on idle timeout.
- Every ARB key in all three languages with its placeholders (`test/l10n/translation_parity_test.dart`).
- No Hindi markers in Sanskrit text (`test/l10n/sanskrit_hindi_marker_test.dart`).
- A date picker and a dialog open under `sa` (`test/l10n/sanskrit_locale_test.dart`).
- The logger stays silent at `trace`/`debug` outside the dev flavor and never passes an error's
  text there (`test/core/logging/app_logger_test.dart`).

---

## 19. Operational Constraints

- **Minimum supported OS:** Android 7.0 (API 24). Target API 36 (since 2026-11-02; edge-to-edge is always on, and the app never opted out).
- **Performance constraints:**
  - Cold start: under 2 seconds to first meaningful frame (release build).
  - Frame budget: 16 ms at 60 Hz; sustained jank above 5% blocks a release.
  - Size budget: see [release_process.md](release_process.md) §6.3.
- **Store constraints:** Google Play readiness gate in
  [release_process.md](release_process.md) §9A and [guidelines/platform_store_readiness.md](guidelines/platform_store_readiness.md).
- **Team constraints:** single developer.
- **Network constraints:** no remote network, no network packages; local transfer only.

---

## 20. Decisions And Tradeoffs

| Decision | Chosen Option | Why | Tradeoff |
|---|---|---|---|
| OCR engine | Tesseract (`flutter_tesseract_ocr`), bundled data | Open source, has a Malayalam model, no download | Larger APK; slower than ML Kit |
| Video controls | Own controls on `video_player` | Every label from `AppLocalizations`; own gestures | More code to own |
| Outgoing intents | Own `intents` channel, not `url_launcher` | One allow-list, checked in Dart and Kotlin | Small Kotlin handler to maintain |
| Network use | Local transfer only, with `INTERNET` declared | Android needs it for any socket | Must prove in code (`LocalAddressRules`) that no public address is reached |
| Backup contents | Metadata only, not media bytes | Small, fast archive; transfer covers media | A backup alone cannot restore photos |
| Settings storage | JSON file, plus `shared_preferences` for the language only | One small file, loaded before first frame; the language key is where §8.4 says | Two stores to read at launch |
| Crypto | Kotlin (Keystore, `javax.crypto`) over a channel | Hardware-backed keys; no Dart crypto package | Platform-specific code |

---

## 21. Known Risks And Follow-Ups

- **Risk:** the Sanskrit text has not been reviewed by a fluent reader, and a few other rules
  are only partly met.
  **Mitigation:** tracked in [known_gaps.md](known_gaps.md) (G9–G15); each needs its own plan.
- **Risk:** `test/` uses `../` imports for shared fakes, which the "`package:` imports only" rule
  forbids. Dart cannot import `test/` files by `package:` URI, so this is an accepted exception
  ([known_gaps.md](known_gaps.md) §3). `lib/` uses `package:` imports only.
- **Risk:** a dependency update adds a permission or network code.
  **Mitigation:** the release checklist compares the merged manifest with the 12 expected
  permissions; [dependencies.md](dependencies.md) has an approval checklist.
- **Risk:** some devices ship SQLite without FTS5.
  **Mitigation:** schema v3 falls back to FTS4.
- **Risk:** three packages still import the SDK's frozen Material: `qr_flutter` 4.1.0,
  `video_player` 2.14.x and `camera` 0.12.2 (checked 2026-11-02).
  **Mitigation:** `MaterialUiCompatibilityBridge` in `MaterialApp.builder` (`lib/main.dart`)
  hands them the app's theme. They use no Material localizations, so Sanskrit needs nothing
  extra. Remove the bridge once all three move to `material_ui`.
- **Risk:** the generated `AppLocalizations.localizationsDelegates` still lists the SDK's
  Material and Cupertino delegates (the file is generated, so it is not edited).
  **Mitigation:** nothing uses it; the app and the tests use `appLocalizationsDelegates`
  (`lib/core/l10n/sanskrit_fallback_delegates.dart`), which takes them from `material_ui` /
  `cupertino_ui`.

---

## 22. Related Documents

- [../README.md](../README.md)
- [security.md](security.md)
- [release_process.md](release_process.md)
- [dependencies.md](dependencies.md)
- [project_structure.md](project_structure.md)
- [known_gaps.md](known_gaps.md)
- [guidelines/flutter_project_engineering_standard.md](guidelines/flutter_project_engineering_standard.md)
- [guidelines/flutter_build_flavors_guide.md](guidelines/flutter_build_flavors_guide.md)
