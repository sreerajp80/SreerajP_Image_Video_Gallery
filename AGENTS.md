# AGENTS.md — SreerajP Image Video Gallery

This file is read by AI agents and LLM coding assistants (Gemini, Antigravity, Cursor, Windsurf, Codex, etc.) at the start of every session in this repository.
Read it before making any change. See the docs table below for full detail.

---

## Project identity

| Field | Value |
|-------|-------|
| App name | SreerajP Image Video Gallery |
| Type | Offline-first image and video gallery application for viewing, organizing, and managing local media |
| Platform(s) | Android only (minSdk 24, targetSdk 36, compileSdk 36) |
| Package / org id | in.sreerajp.imgvidgal |
| Flutter SDK | **3.47.6** (stable) — the exact version this project builds with; CI uses the same (`.github/workflows/ci.yml`). Lowest allowed in `pubspec.yaml`: 3.41.0 |
| Dart SDK | **3.13.5** (ships with Flutter 3.47.6). Lowest allowed in `pubspec.yaml`: 3.11.0 |
| State management | Riverpod |
| Navigation | go_router |
| Database | sqflite |
| Orientation | both |
| Connectivity | no remote network — local Wi-Fi transfer only |
| Distribution | Google Play and direct split APKs (Android only) — store rules in `docs/guidelines/platform_store_readiness.md` |

---

## Read these docs before working

| Document | Read when |
|----------|-----------|
| docs/architecture.md | Changing structure, screens, state, services, models, repositories |
| docs/security.md | Touching permissions, logging, storage, crypto, manifest |
| docs/release_process.md | Building a release, versioning, release checklist |
| docs/dependencies.md | Adding, removing or upgrading a package |
| docs/PROJECT_PROFILE.md | Declared platforms, stores, languages and About options — read first |
| docs/known_gaps.md | Guideline rules the app does not meet yet |
| docs/workflow_rules.md | Writing a plan or a change log |
| docs/guidelines/flutter_build_flavors_guide.md | Build config, signing, flavors, Gradle, ProGuard |
| docs/guidelines/flutter_project_engineering_standard.md | Any code change — layers, naming, testing |
| docs/guidelines/guideline.md | Common folder structure, About-screen config, keystore rules |
| docs/guidelines/language_packs/sanskrit_malayalam.md | Adding or changing Malayalam or Sanskrit text (mandatory for this app) |
| docs/guidelines/DOCS_FOLDER_GUIDELINE.md | Adding or changing any file in `docs/` |
| docs/GUIDELINES_MANIFEST.md | The shared Flutter guidelines index |
| docs/guidelines/platform_store_readiness.md | Anything about Google Play or direct APK release |

> If a doc is copied into this project's own `docs/`, the local copy wins over the submodule.
> `architecture.md`, `security.md` and `release_process.md` have local copies, so read those,
> not the templates in `docs/guidelines/`.

---

## Hard rules (must follow — these override convenience)

1. Open source only. No commercial or proprietary SDKs. Verify package licenses before adding.
2. **Local network only, never the internet.** The app never talks to a remote server: no HTTP client, no cloud backend, no analytics, no telemetry, no update check. `android.permission.INTERNET` is declared for exactly one feature — the device-to-device transfer screen — because Android demands it for *any* socket, including one that only ever reaches another phone on the same Wi-Fi router. Every connection is refused unless the peer's address is private (`10/8`, `172.16/12`, `192.168/16`, `169.254/16`), the listener binds to the device's own Wi-Fi address rather than `0.0.0.0`, and it runs only while the transfer screen is open. `LocalAddressRules` enforces this in code; see `docs/security.md`.
3. Scoped storage & MediaStore APIs only. Use system photo picker and granular media permissions without broad legacy storage permissions.
4. Safe & non-destructive operations. Never overwrite or delete original media files without explicit user confirmation and atomic safeguards.
5. Never crash on bad input or corrupted media. Every metadata parser and image/video decoder must have a graceful fallback path with user-friendly handling.

---

## Architecture rules

- Layout: Tier 1 layer-first under `lib/` (`core/`, `models/`, `repositories/`, `services/`, `providers/`, `screens/`, `widgets/`, `theme/`, `l10n/`, `main.dart`). Do not restructure without instruction.
- Layer boundaries: Widgets must not contain raw SQL/database queries, direct file I/O, or intent parsing. Services/repositories must not depend on `BuildContext` or UI elements.
- Dependency direction: `screens` → `providers` → `repositories`/`services` → `database`/`platform` → `models`.
- Models are immutable (`const` constructors, `copyWith`). Never mutate state or model objects in place.
- No direct storage or database access from widgets — route all operations through provider/repository layers.
- About screen metadata MUST follow `docs/guidelines/guideline.md §1`: source of truth is `assets/config/app_config.json`, loaded via `ConfigService` (`lib/core/config/config_service.dart`) into `AppConfig` (`lib/core/config/app_config.dart`), dynamically rendering `details`.

---

## Build & run commands

```bash
flutter pub get                        # install dependencies
flutter run --flavor dev               # daily development
flutter run --flavor prod              # production build with debug tooling
flutter analyze                        # static analysis (must be clean)
flutter test                           # run all tests
dart format .                          # format before committing

# Production release APK (split per ABI)
flutter build apk --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod-<version>/ --split-per-abi

# Production Play Store bundle
flutter build appbundle --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod-<version>/
```

> If the app defines flavors, a bare `flutter run` fails — always pass `--flavor`.

---

## Build flavors

| Flavor | App ID | Display name | Signing |
|--------|--------|--------------|---------|
| dev | in.sreerajp.imgvidgal.dev | SreerajP Gallery Dev | Debug keystore (automatic) |
| prod | in.sreerajp.imgvidgal | SreerajP Image Video Gallery | Release keystore (android/key.properties) |

> Flutter ≥ 3.19 sets `FLUTTER_APP_FLAVOR` automatically; read it with `String.fromEnvironment('FLUTTER_APP_FLAVOR')`.

---

## Signing / keystore

- Keystore file: `android/gallery-release.jks`. Alias: `gallery_key`. Keep at least one offline backup.
- Create `android/key.properties` (gitignored — never commit).
- `.gitignore` must include: `key.properties`, `*.jks`, `*.keystore`, `build/symbols/`.

---

## Security rules

- Never log secrets, private media metadata, or encryption keys — even in debug builds.
- Store sensitive configuration or secure preferences in `flutter_secure_storage`; never in plain `SharedPreferences`.
- Request only the permissions the app needs. The manifest declares exactly 12 Android permissions, each with its reason in `docs/security.md` §11: media access (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`, `READ_EXTERNAL_STORAGE` up to API 32), vault unlock (`USE_BIOMETRIC`, `USE_FINGERPRINT` up to API 28), `CAMERA` for the pairing QR scan only, the local transfer set (`INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE`, `CHANGE_WIFI_STATE`), and `WRITE_EXTERNAL_STORAGE` up to API 28 for "Delete permanently" and "Secure delete" on Android 9 and older. AndroidX adds one more to the merged manifest, the app's own private `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`, so the merged manifest holds 13. Never add one without updating that table.
- `CHANGE_WIFI_STATE` exists for one thing: offering a scanned Wi-Fi code to Android as a network suggestion, on the in-image scanner screen. The app never joins a network itself; the user still picks it in the Wi-Fi settings.
- A scanned code is untrusted input. The app launches an intent only for `http`, `https`, `tel`, `mailto`, `sms` and `geo`, checked in Dart and again in Kotlin. Never add a scheme without a reason written down. See `docs/security.md` §20.
- `android.permission.INTERNET` exists for the local transfer feature alone. Never open a socket to an address `LocalAddressRules` rejects, never add an HTTP client, and never start a listener outside the transfer screen's lifetime.
- Never send media, metadata, or diagnostics anywhere the user did not pair with by hand.
- Keep `android:allowBackup="false"` and `android:dataExtractionRules` in the manifest. On Android 12+ the first alone does not stop device transfer.

---

## Localization rules

- This app must ship three languages: **English (`en`), Malayalam (`ml`), Sanskrit (`sa`)**. Every
  feature and every screen works in all three.
- **Current state:** all three languages ship. The owner reviewed the Sanskrit text on
  2026-11-05 (G9 closed); new or changed Sanskrit needs the same review. `test/l10n/` fails the
  build if a key is missing from any ARB file or if a Hindi marker appears in Sanskrit text.
- All user-visible text comes from `lib/l10n/*.arb` via `AppLocalizations` — never a raw string
  literal in a widget.
- `l10n.yaml` (project root) and all three ARB files (`app_en.arb`, `app_ml.arb`, `app_sa.arb`)
  must exist. Run `flutter gen-l10n` after editing any `.arb` file.
- Every new key goes into **all** ARB files with a real translation. Never leave the English
  value sitting in `app_ml.arb` or `app_sa.arb`.
- Every ARB key needs an `@key` description entry in the template file (`app_en.arb`).
- **Sanskrit means Sanskrit, not Hindi in Devanagari.** No Hindi copulas/postpositions/verb endings
  (`है`, `करें`, `नहीं`, `सेटिंग्स`), no nukta letters. Use the glossary in
  `docs/guidelines/language_packs/sanskrit_malayalam.md` §4.4 and flag anything you are unsure of for human review.
- `supportedLocales` is `en`, `ml`, `sa`, and the Sanskrit Material/Cupertino fallback delegates are
  registered (§8.3.1) — Flutter ships no Sanskrit framework translation. Format dates and numbers
  with the `formattingLocale(...)` helper, never `DateFormat(..., 'sa')`.
- The language is user-selectable in Settings (System default / English / മലയാളം / संस्कृतम्),
  persisted, and applied without restarting the app.
- Menu, button, label, tab and tooltip strings stay short in all three languages (§8.6); only
  `desc…`/`help…`/`empty…`/`error…`/`body…` keys may be long prose.
- Every icon-only control has a localized `tooltip:` (§7.8).
- The About screen is data-driven, localized, and ends with the "Made with ❤️ from India" badge.
- Literals are allowed only for logs, non-UI exception messages, asset paths, route names, and
  map/JSON keys.
- Log through `AppLogger` (`lib/core/logging/app_logger.dart`), never `print` or `debugPrint`.

---

## Code style / naming

- Files `snake_case.dart`; classes `PascalCase`; variables/methods `camelCase`; providers `camelCase` + `Provider` suffix.
- Use `package:` imports, not relative. Prefer `const` constructors, `final` locals, single quotes.
- Run `dart format .` and keep `flutter analyze` at zero warnings before every commit.

---

## Testing rules

- Mirror `lib/` structure in `test/` (e.g. `test/services/`, `test/repositories/`, `test/providers/`).
- Critical areas that must be covered before release: media scanner/indexer, thumbnail caching logic, album grouping, metadata parsers, and DB migrations.
- Add or update a test whenever you add or change a service/DAO/repository/provider.

---

## Dependency constraints

- Blocked (never add, never accept as transitive dep): HTTP clients (`dio`, `http`), cloud/BaaS (`firebase`, `supabase`), analytics, crash reporting, ads, network-status packages.
- Networking is limited to `dart:io` sockets used by the local transfer feature. Relaxing hard rule 2 did not unblock any package above.
- Before adding any new package: check its `pubspec.yaml` for networking deps, state why it is needed, and confirm it fits the hard rules.

---

## Where things live

```
AGENTS.md            # this file — project rules for AI agents / LLMs
CLAUDE.md            # Claude Code native project rules
docs/                # design docs & guidelines submodule
plans/               # one plan per change (see workflow rules)
change_log/          # one log per implemented change
lib/                 # app source
test/                # tests
```

---

## Workflow rules (mandatory — from global rules)

Every change follows plan-before-changing and log-after-changing:

1. **Plan before changing.** Write a full plan to `plans/` named `yyyymmdd_hhMMss_<short-slug>.md` with a `**Status:**` line, the files to change, the issue, and the fix. Then **STOP and get explicit approval** before editing/creating/deleting any project file (other than the plan). A question or ambiguous reply is not approval. A plan that touches network, storage, sign-in, permissions, deep links, WebViews, platform folders or dependencies has a short **"Security impact"** line (engineering standard §22.2).
2. **Log after changing.** After implementing, write a change log to `change_log/` named `yyyymmdd_hhMMss_<short-slug>.md` describing what changed and referencing its plan.
3. **Relative paths & privacy only.** `plans/` and `change_log/` files are committed and may become public on the internet. They MUST use relative repository paths only (never absolute system paths like `C:\...`, `l:\...`, or `file:///...`). They MUST NOT contain any **local system details** — OS user name, computer/host name, home or drive-letter paths, network share names, LAN/internal IP addresses, local server URLs with ports, device serial numbers, personal email addresses — or any secret (API keys, tokens, passwords, keystore passphrases, credentials, PII). Write them as if a stranger will read them; nothing should reveal the machine they came from.
4. **The guidelines submodule is read-only.** `docs/guidelines/` is read-only. Never edit, pull, check out or commit the submodule or its version. If a guideline needs a change, write a note for the user instead (`docs/guidelines/DOCS_FOLDER_GUIDELINE.md` §1.1). If the folder is empty or missing, stop and ask the user.
5. **CI is checks only.** GitHub CI runs only `flutter pub get`, code generation (`flutter gen-l10n`), the format check, `flutter analyze`, `flutter test`, and other pass/fail check scripts. No Dependabot or other update bot: dependencies are updated by hand. CI never builds release artifacts, signs, holds signing secrets, uploads, or publishes. Release builds are done locally (`docs/guidelines/flutter_project_engineering_standard.md` §19).

Create `plans/` and `change_log/` if they do not exist.

---

## Communication rules

- **Always use simple English.** Write all responses, plans, change logs, and explanations in plain, simple English. Short sentences, common words. Explain any jargon you must use.

---

## What AI agents must always / never do

**Always:** read this file first; state the target layer before adding a class; run analyze + test after changes; keep main.dart thin; use `AppLocalizations` for user-visible strings.

**Never:** put business logic or database queries in a widget; call a DAO/repository directly from a UI widget; edit generated files directly; add a blocked dependency; log secrets or private metadata.
