# CLAUDE.md — SreerajP Image Video Gallery

This file is read by Claude Code at the start of every session in this repository.
Read it before making any change. See the docs table below for full detail.

---

## Project identity

| Field | Value |
|-------|-------|
| App name | SreerajP Image Video Gallery |
| Type | Offline-first image and video gallery application for viewing, organizing, and managing local media |
| Platform(s) | Android only (minSdk 24, targetSdk 35) |
| Package / org id | in.sreerajp.imgvidgal |
| Flutter SDK | ^3.41.0 or higher |
| Dart SDK | ^3.11.0 or higher |
| State management | Riverpod |
| Navigation | go_router |
| Database | sqflite |
| Orientation | both |
| Connectivity | no remote network — local Wi-Fi transfer only |

---

## Read these docs before working

| Document | Read when |
|----------|-----------|
| docs/guidelines/architecture.md | Changing structure, screens, state, services, models, repositories |
| docs/guidelines/security.md | Touching permissions, logging, storage, crypto, manifest |
| docs/guidelines/release_process.md | Building a release, versioning, release checklist |
| docs/guidelines/flutter_build_flavors_guide.md | Build config, signing, flavors, Gradle, ProGuard |
| docs/guidelines/flutter_project_engineering_standard.md | Any code change — layers, naming, testing |
| docs/guidelines/guideline.md | Common folder structure, About-screen config, keystore rules |
| docs/GUIDELINES_MANIFEST.md | The shared Flutter guidelines index |

> If a doc is copied into this project's own `docs/`, the local copy wins over the submodule.

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
- Request only necessary media permissions (`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`), plus `CAMERA` for the pairing QR scan only.
- `CHANGE_WIFI_STATE` exists for one thing: offering a scanned Wi-Fi code to Android as a network suggestion, on the in-image scanner screen. The app never joins a network itself; the user still picks it in the Wi-Fi settings.
- A scanned code is untrusted input. The app launches an intent only for `http`, `https`, `tel`, `mailto`, `sms` and `geo`, checked in Dart and again in Kotlin. Never add a scheme without a reason written down. See `docs/security.md` §12.
- `android.permission.INTERNET` exists for the local transfer feature alone. Never open a socket to an address `LocalAddressRules` rejects, never add an HTTP client, and never start a listener outside the transfer screen's lifetime.
- Never send media, metadata, or diagnostics anywhere the user did not pair with by hand.
- Keep `android:allowBackup="false"` in the manifest.

---

## Localization rules

- All user-visible text comes from `lib/l10n/*.arb` via `AppLocalizations` — never a raw string literal in a widget. This applies even though the app ships only English (`en`).
- `l10n.yaml` (project root) and `lib/l10n/app_en.arb` must exist. Run `flutter gen-l10n` after editing any `.arb` file.
- Every ARB key needs an `@key` description entry.
- Literals are allowed only for logs, non-UI exception messages, asset paths, route names, and map/JSON keys.

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
AGENTS.md            # project rules for AI agents / LLMs
CLAUDE.md            # this file — Claude Code native project rules
docs/                # design docs & guidelines submodule
plans/               # one plan per change (see workflow rules)
change_log/          # one log per implemented change
lib/                 # app source
test/                # tests
```

---

## Workflow rules (mandatory — from global rules)

Every change follows plan-before-changing and log-after-changing:

1. **Plan before changing.** Write a full plan to `plans/` named `yyyymmdd_hhMMss_<short-slug>.md` with a `**Status:**` line, the files to change, the issue, and the fix. Then **STOP and get explicit approval** before editing/creating/deleting any project file (other than the plan). A question or ambiguous reply is not approval.
2. **Log after changing.** After implementing, write a change log to `change_log/` named `yyyymmdd_hhMMss_<short-slug>.md` describing what changed and referencing its plan.
3. **Relative paths & privacy only.** `plans/` and `change_log/` files are committed and may become public on the internet. They MUST use relative repository paths only (never absolute system paths like `C:\...`, `l:\...`, or `file:///...`). They MUST NOT contain any **local system details** — OS user name, computer/host name, home or drive-letter paths, network share names, LAN/internal IP addresses, local server URLs with ports, device serial numbers, personal email addresses — or any secret (API keys, tokens, passwords, keystore passphrases, credentials, PII). Write them as if a stranger will read them; nothing should reveal the machine they came from.

Create `plans/` and `change_log/` if they do not exist.

---

## Communication rules

- **Always use simple English.** Write all responses, plans, change logs, and explanations in plain, simple English. Short sentences, common words. Explain any jargon you must use.

---

## What Claude must always / never do

**Always:** read this file first; state the target layer before adding a class; run analyze + test after changes; keep main.dart thin; use `AppLocalizations` for user-visible strings.

**Never:** put business logic or database queries in a widget; call a DAO/repository directly from a UI widget; edit generated files directly; add a blocked dependency; log secrets or private metadata.
