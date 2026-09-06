# Dependencies — Image & Video Gallery

This document catalogs all approved dependencies, their licenses, and the strictly prohibited packages for the Image & Video Gallery project. Read this before adding any new package to `pubspec.yaml`.

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [Project_Idea.md](Project_Idea.md)
- [security.md](security.md)

---

## 1. Dependency Management Principles

1. **Open Source Only**: Every dependency must have an OSI-approved open-source license (MIT, Apache-2.0, BSD-3-Clause, MPL-2.0). Commercial or proprietary SDKs are strictly prohibited.
2. **No Remote Network**: Packages that make background network requests, contact a remote server, or bundle an HTTP client are strictly blocked. Networking in this app is limited to `dart:io` sockets used by the local peer-to-peer transfer feature, and every one of those is refused unless the peer is on the local network.
3. **Minimal Footprint**: Keep transitive dependencies minimal to maintain fast compilation and small binary sizes.

---

## 2. Approved Baseline Packages

| Package | Purpose | License | Category |
|---|---|---|---|
| **`flutter_riverpod`** / **`riverpod_annotation`** | State management and dependency injection | MIT | State Management |
| **`go_router`** | Declarative deep-link and navigation routing | BSD-3-Clause | Navigation |
| **`sqflite`** | Local SQLite database for media indexing and metadata | BSD-2-Clause | Storage & DB |
| **`flutter_secure_storage`** | Secure key storage / Android Keystore binding | BSD-3-Clause | Security & Vault |
| **`local_auth`** | Android Biometric and PIN authentication | BSD-3-Clause | Authentication |
| **`cryptography`** / **`crypto`** | AES-256-GCM encryption, SHA-256 hashing | Apache-2.0 / BSD-3-Clause | Cryptography |
| **`image`** | Pure Dart image decoding, cropping, resizing, filtering | Apache-2.0 | Media Processing |
| **`photo_view`** | Interactive zoom, pan, and rotation viewer | Apache-2.0 | Media Viewing |
| **`video_player`** | Hardware-accelerated offline video playback (adopted in Phase 5) | BSD-3-Clause | Video Playback |
| **`flutter_svg`** | Scalable vector graphics (.svg) rendering | MIT | Media Viewing |
| **`pdf`** | Multi-page PDF creation from photos | Apache-2.0 | Media Conversion |
| **`flutter_tesseract_ocr`** | On-device offline OCR, English and Malayalam (adopted in Phase 12). Wraps Tesseract4Android; its only Dart dependencies are `flutter`, `path` and `path_provider`, and it has no HTTP client. Language data ships in `assets/tessdata/` and is never downloaded | BSD-3-Clause (Tesseract itself Apache-2.0) | Intelligence |
| **`mobile_scanner`** | On-device QR and Barcode scanner | BSD-3-Clause | Intelligence |
| **`system_info2`** | Device RAM detection for dynamic memory scaling | MIT | Performance |
| **`qr_flutter`** | Draws the peer-to-peer pairing QR code (adopted in Phase 11). Pure Dart, no platform code, no network | BSD-3-Clause | Local Transfer |
| **`intl`** | Date formatting and multi-language support | BSD-3-Clause | Localization |
| **`flutter_localizations`** | SDK localizations (English & Malayalam) | BSD-3-Clause | Localization |

---

## 3. Strictly Prohibited & Blocked Packages

The following packages (and their transitive dependencies) are **permanently blocked**:

| Prohibited Category | Examples | Reason for Prohibition |
|---|---|---|
| **HTTP / Networking Clients** | `http`, `dio`, `retrofit`, `chopper` | The app never contacts a remote server. Relaxing the offline rule for local transfer did not unblock these |
| **Cloud BaaS & Remote Sync** | `firebase_*`, `supabase_flutter`, `amplify` | Zero cloud dependencies; all data is local |
| **Crash & Telemetry SDKs** | `sentry_flutter`, `datadog`, `bugsnag` | Strict user privacy; no remote telemetry |
| **Analytics & Trackers** | `google_analytics`, `mixpanel`, `amplitude` | No user tracking or behavioral telemetry |
| **Ad Networks & Monetization** | `google_mobile_ads`, `unity_ads`, `applovin` | Ad-free, private open-source application |
| **Network Status Checkers** | `connectivity_plus`, `internet_connection_checker` | Irrelevant for a purely offline application |

---

## 3a. Packages Considered and Not Used

| Package | Why it was not used |
|---|---|
| **`chewie`** | Its control bar ships its own strings and gestures. That clashes with the rule that every visible label comes from `AppLocalizations`, and with the brightness, volume, and seek gestures the app defines itself. The controls are built directly on `video_player` instead. |
| **`photo_view`** | Flutter's built-in `InteractiveViewer` already gives pinch, pan, and inertia. The rest (double-tap zoom target, rotation, swipe-down dismiss) is small pure logic that is unit tested in `ViewerTransformService`. Approved, but not needed. |
| **`screen_brightness`** | Screen brightness, media volume, and keep-awake are a few dozen lines of Kotlin on the app's own `playback` method channel, and need no extra Android permission. |
| **`google_mlkit_text_recognition`** | Approved on paper in the original plan, then dropped in Phase 12 without ever being added. **It has no Malayalam model.** ML Kit's on-device text recognition covers Latin, Chinese, Devanagari, Japanese and Korean only, so it cannot do the job a bilingual app needs. It is also a closed-source Google binary, which sits badly with hard rule 1. `flutter_tesseract_ocr` replaced it: Tesseract is open source and does have a Malayalam model. Do not re-add ML Kit for OCR. |
| **`url_launcher`** | The in-image scanner has to hand a scanned code to another app. That is four short Android intents, and the app already owns six method channels, so `IntentChannelHandler` does it directly. Owning the code is the point: the list of schemes the app will ever launch lives in one place, is checked on both the Dart and the Kotlin side, and a scanned code cannot reach `intent:` or `content:` through it. |

> **Note on `video_player`:** its Android implementation wraps ExoPlayer, which declares
> `INTERNET`, `ACCESS_NETWORK_STATE`, and `WAKE_LOCK` for streaming. The app plays local
> files only, so all three are stripped from the merged manifest with `tools:node="remove"`
> in `android/app/src/main/AndroidManifest.xml`. Verify this after any dependency change by
> building the dev APK and listing the permissions in the packaged manifest.

---


## 4. New Dependency Approval Checklist

Before adding any new package:
1. [ ] Confirm the package is open-source (check license in repository).
2. [ ] Verify the package does NOT declare `android.permission.INTERNET` in its Android manifest.
3. [ ] Check transitive dependencies for hidden networking packages.
4. [ ] State clear justification in the implementation plan.
5. [ ] Run `flutter analyze` and `flutter test` to ensure clean integration.
