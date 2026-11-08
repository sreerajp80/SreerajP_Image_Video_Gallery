# Dependencies — Drishya Gallery

This document lists every package in `pubspec.yaml`, its license and whether the code uses it,
plus the packages that are blocked and the checklist for adding a new one. Read it before you
add, remove or upgrade any package.

### Read first
- [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md)
- [security.md](security.md)
- [architecture.md](architecture.md)

---

## 1. Dependency Management Principles

1. **Open source only.** Every package must have an OSI-approved license (MIT, Apache-2.0,
   BSD-2-Clause, BSD-3-Clause, MPL-2.0). No commercial or closed-source SDKs.
2. **No remote network.** Any package that contacts a remote server, makes background network
   requests, or bundles an HTTP client is blocked. The app's only networking is `dart:io`
   sockets on the local transfer screen, refused unless the peer is on the local network.
3. **Small footprint.** Keep direct and transitive dependencies few, for build speed, APK size
   and a smaller supply-chain risk.

---

## 2. Declared Packages

"Integrated" means the package is imported in `lib/`. Licenses were read from each package's
`LICENSE` file at the version in `pubspec.lock`.

### 2.1 Runtime dependencies

| Package | Purpose | License | Integrated |
|---|---|---|---|
| `flutter_localizations` (SDK) | Framework localizations | BSD-3-Clause | Yes |
| `intl` | Date and number formatting; ARB messages | BSD-3-Clause | Yes |
| `flutter_riverpod` | State management and dependency injection. 3.x since 2026-11-02; the `StateNotifier`/`StateProvider` classes come from `package:flutter_riverpod/legacy.dart`, and automatic retry is off app-wide (`noProviderRetry`) | MIT | Yes |
| `go_router` | Declarative navigation. 18.x, which builds its pages with `material_ui` (the reason the app moved to `material_ui`, G22). URLs are case-sensitive since 15 | BSD-3-Clause | Yes |
| `material_ui` | Material widgets as a package, replacing the frozen SDK copy (engineering standard §6.1) | BSD-3-Clause | Yes |
| `cupertino_ui` | Cupertino as a package; used by the Sanskrit fallback delegates | BSD-3-Clause | Yes |
| `sqflite` | Local SQLite database (index, tags, albums, notes, FTS search) | BSD-2-Clause | Yes |
| `path` | Path joining and parsing | BSD-3-Clause | Yes |
| `path_provider` | App-private folders (support, cache, temp) | BSD-3-Clause | Yes |
| `shared_preferences` | Holds the language choice under `app_language`, as engineering standard §8.4 names it. Nothing else, and never a secret. Its tree adds only the `shared_preferences` platform packages; no HTTP client | BSD-3-Clause | Yes |
| `system_info2` | Device RAM, to size the thumbnail cache | BSD-3-Clause | Yes |
| `crypto` | SHA-256 and HMAC-SHA256 (hashing, transfer keys) | BSD-3-Clause | Yes |
| `image` | Pure Dart decode, resize, filters, encode | MIT | Yes |
| `video_player` | Local video playback (ExoPlayer on Android) | BSD-3-Clause | Yes |
| `pdf` | Build a PDF from photos | Apache-2.0 | Yes |
| `local_auth` | Biometric unlock for the vault. 3.x: errors arrive as `LocalAuthException` codes, mapped in `LocalAuthBiometricService.resultForCode`; the plugin shows no error dialogs, the gate screen does | BSD-3-Clause | Yes |
| `local_auth_android` | Android implementation of `local_auth`, pinned directly | BSD-3-Clause | Declared only — no direct import; used through `local_auth` |
| `flutter_secure_storage` | Vault PIN hash, salt, iterations and settings. **Pinned to 10.3.4 on purpose.** Version 11 cannot read data that version 9 wrote; 10 moves it across on first use. Options: `migrateOnAlgorithmChange`, `migrateWithBackup`, `resetOnError: false`, tested in `vault_credential_store_test.dart`. Move to 11 only under G49 | BSD-3-Clause | Yes |
| `qr_flutter` | Draws the transfer pairing QR code. Pure Dart, no network | BSD-3-Clause | Yes |
| `camera` | Live preview and frames for the pairing QR scan (`PairingQrScanner`). Android side is `camera_android_camerax`: AndroidX CameraX and Guava only — no Play Services, no ML Kit, no network library. Its full tree (`camera_platform_interface`, `cross_file`, `stream_transform`, `web`) has no `http`. Pinned exactly. `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE`, which it asks for, are removed in the manifest; `enableAudio` is off | BSD-3-Clause (CameraX Apache-2.0) | Yes |
| `flutter_tesseract_ocr` | Offline OCR, English and Malayalam. Wraps Tesseract4Android; Dart deps are only `flutter`, `path`, `path_provider`; no HTTP client. Language data ships in `assets/tessdata/` and is never downloaded. Taken from a `dependency_overrides` git entry pinned to one commit: the published 0.4.31 calls `jcenter()`, which Gradle 9 removed, and that commit changes only `jcenter()` to `mavenCentral()`. Move back to pub.dev once a release has the fix | BSD-3-Clause (Tesseract itself Apache-2.0) | Yes |

### 2.1A Android (Gradle) libraries added by the app

| Library | Purpose | License |
|---|---|---|
| `com.google.zxing:core` 3.5.3 | Reads barcodes and QR codes, in still photos and camera frames (`BarcodeChannelHandler`). The original ZXing library: plain Java, no dependencies, no network code | Apache-2.0 |

### 2.2 Dev dependencies

| Package | Purpose | License |
|---|---|---|
| `flutter_test` (SDK) | Unit and widget tests | BSD-3-Clause |
| `flutter_lints` | Lint rules for `flutter analyze` (6.x since 2026-11-02) | BSD-3-Clause |
| `sqflite_common_ffi` | Real SQLite in unit tests on the host | BSD-2-Clause |
| `characters` | OCR accuracy tool (`tool/ocr_eval/`): counts Malayalam conjuncts as one character. Already a transitive dependency through Flutter; no dependencies of its own, no networking | BSD-3-Clause |

> **Note on `video_player`:** its Android side wraps ExoPlayer, which declares `INTERNET`,
> `ACCESS_NETWORK_STATE` and `WAKE_LOCK` for streaming. The app plays local files only.
> `WAKE_LOCK` is removed from the merged manifest with `tools:node="remove"`. `INTERNET` and
> `ACCESS_NETWORK_STATE` stay, because the app declares them itself for the local transfer
> feature ([security.md](security.md) §11). After any dependency change, build the APK and
> compare its permissions with the list of 12 in
> [release_process.md](release_process.md) §6.4.

---

## 3. Strictly Prohibited & Blocked Packages

These packages, and anything that pulls them in as a transitive dependency, are **permanently
blocked**:

| Prohibited Category | Examples | Reason |
|---|---|---|
| HTTP / networking clients | `http`, `dio`, `retrofit`, `chopper` | The app never contacts a remote server. Allowing local transfer did not unblock these |
| Cloud BaaS and remote sync | `firebase_*`, `supabase_flutter`, `amplify` | No cloud; all data stays on the device |
| Crash and telemetry SDKs | `sentry_flutter`, `datadog`, `bugsnag` | No remote telemetry |
| Analytics and trackers | `google_analytics`, `mixpanel`, `amplitude` | No tracking |
| Ads and monetization | `google_mobile_ads`, `unity_ads`, `applovin` | Ad-free app |
| Network status checkers | `connectivity_plus`, `internet_connection_checker` | The app never needs to know if the internet is up |

---

## 4. Packages Considered and Not Used

| Package | Why it was not used |
|---|---|
| `chewie` | Its control bar ships its own strings and gestures. That clashes with the rule that every visible label comes from `AppLocalizations`, and with the brightness, volume and seek gestures the app defines itself. The controls are built directly on `video_player` instead. |
| `photo_view` | Flutter's built-in `InteractiveViewer` already gives pinch, pan and inertia. The rest (double-tap zoom target, rotation, swipe-down dismiss) is small pure logic, unit tested in `ViewerTransformService`. |
| `screen_brightness` | Brightness, media volume and keep-awake are a few dozen lines of Kotlin on the app's own `playback` channel, with no extra Android permission. |
| `google_mlkit_text_recognition` | Planned at first, then dropped in Phase 12 before it was ever added. **It has no Malayalam model.** ML Kit's on-device text recognition covers Latin, Chinese, Devanagari, Japanese and Korean only. It is also a closed-source Google binary, which breaks hard rule 1. `flutter_tesseract_ocr` replaced it: Tesseract is open source and has a Malayalam model. Do not re-add ML Kit for OCR. |
| `url_launcher` | The scanner must hand a scanned code to another app. That is four short Android intents, done by `IntentChannelHandler` on the app's own `intents` channel. Owning it keeps the list of launchable schemes in one place, checked in both Dart and Kotlin, so a scanned code cannot reach `intent:` or `content:`. |
| `riverpod_annotation`, `cryptography`, `flutter_svg` | Listed in early planning; never added. Crypto is done in Kotlin (Keystore + `javax.crypto`) and with `crypto` for hashes. |
| `build_runner`, `freezed`, `json_serializable` | Not used. Models are hand-written with `const` constructors and `copyWith`. |
| `mobile_scanner` | **Removed on 2026-11-02 (G47).** On Android it reads codes with Google ML Kit, a closed-source binary (hard rule 1), in both its bundled and unbundled modes, up to at least 7.5.0. Replaced by ZXing core in Kotlin plus the `camera` plugin. |
| `flutter_zxing` | **Tried and rejected on 2026-11-02.** Open source (MIT, zxing-cpp Apache-2.0), but it depends on `image_picker`, whose platform interfaces pull in `http` (blocked even as a transitive dependency). It also has a `readBarcodeImageUrl` function that fetches over the network, which the app does not need. |
| `package_info_plus` | **Removed on 2026-09-26.** It depends on the `http` package (for its web build), so `http` sat in `pubspec.lock` even though the app never used it. HTTP clients are blocked even as transitive dependencies. The app's own `app_info` channel (`AppInfoChannelHandler` in Kotlin, `AppInfoService` in Dart) reads the version name and build number from `PackageManager` instead. |
| `logger` | The engineering standard's reference logger uses it. Not needed: `AppLogger` writes through `dart:developer`, and the app writes no log files. |

---

## 5. New Dependency Approval Checklist

Before adding any package:

1. [ ] Confirm the license is OSI-approved (read its `LICENSE` file).
2. [ ] Read its `pubspec.yaml` and transitive dependencies: no HTTP client, cloud SDK,
       analytics or anything in §3.
3. [ ] Read its Android manifest: list every permission it adds. Any permission not in the 12
       in [security.md](security.md) §11 must be removed with `tools:node="remove"` or approved
       and documented.
4. [ ] Write the reason for the package in the plan.
5. [ ] Build a release APK and run the permission check in
       [release_process.md](release_process.md) §6.4.
6. [ ] Run `flutter analyze` and `flutter test`.
7. [ ] Add the package to §2 of this file.
