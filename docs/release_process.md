# Release Process — SreerajP Image Video Gallery

This is the release runbook for the SreerajP Image Video Gallery app: versioning, hardening,
signing, build commands, checks, the Google Play gate, rollback and evidence. Read it before you
build or ship any production release. It follows the section order of the shared template;
iOS and Windows sections are marked `N/A` because the app is Android only.

### Read first
- [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md)
- [security.md](security.md)
- [known_gaps.md](known_gaps.md)
- [guidelines/release_process.md](guidelines/release_process.md) (the shared template)
- [guidelines/flutter_build_flavors_guide.md](guidelines/flutter_build_flavors_guide.md)
- [guidelines/guideline.md](guidelines/guideline.md) §2 (keystore rules — source of truth)

---

## 1. Release Scope

- **App:** SreerajP Image Video Gallery (`in.sreerajp.imgvidgal`)
- **Release profile:** public
- **Supported release platforms:** Android only (minSdk 24, targetSdk 36, compileSdk 36)
- **Engineering standard profiles in force:** `Core Baseline` + `Production App Extension` +
  `Sensitive Data Extension`

---

## 2. Roles And Responsibilities

| Role | Responsibility | Owner |
|---|---|---|
| Release owner | Readiness and final sign-off | The app developer |
| Engineering | Code freeze, fixes, checks | The app developer |
| QA | Test run and device check | The app developer |
| Store / distribution owner | Uploads and store metadata | The app developer |

---

## 3. Versioning Policy

- **Version format:** `MAJOR.MINOR.PATCH+BUILD` (currently `2.5.2+15`).
- **Source of truth:** `pubspec.yaml`. Gradle reads it through `flutter.versionName` /
  `flutter.versionCode`, and a Gradle task writes `lib/core/constants/app_version.g.dart` from
  it. Keep `assets/config/app_config.json` (`version`, `build`) in step.
- **Build-number rule:** `BUILD` goes up by one on every build you upload or hand out, and is
  never reused.
- **Git tag format:** `vX.Y.Z` (for example `v2.5.2`).

---

## 4. Branch And Merge Policy

- **Release branch strategy:** trunk-based on `master`.
- **Hotfix strategy:** fix on `master`, raise `PATCH` and `BUILD`, and run the full checklist.
- **Required checks before a release commit:** `dart format`, `flutter analyze` (zero issues)
  and `flutter test` (all pass). There is no CI yet, so run them by hand.

---

## 5. Environment And Flavor Matrix

| Flavor | Application ID | Display Name | Signing | Mode | Purpose | Example Command |
|---|---|---|---|---|---|---|
| `dev` | `in.sreerajp.imgvidgal.dev` | SreerajP Gallery Dev | Debug keystore (automatic) | debug | Daily development | `flutter run --flavor dev` |
| `dev` | `in.sreerajp.imgvidgal.dev` | SreerajP Gallery Dev | Debug keystore | release | Release-like testing | `flutter build apk --flavor dev --release` |
| `prod` | `in.sreerajp.imgvidgal` | SreerajP Image Video Gallery | Release keystore (`android/key.properties`) | release | Store and direct release | See §9 |

> `--flavor <name>` sets `FLUTTER_APP_FLAVOR` automatically. Do not pass it with
> `--dart-define`. No other `--dart-define` values are needed.

---

## 6. Release Build Hardening

Every production build MUST use `--release`, `--obfuscate` and `--split-debug-info`. Leaving
any of them out blocks the release.

### 6.1 Obfuscation And Debug Symbols

```bash
--obfuscate --split-debug-info=build/symbols/android-prod-<version>/
```

- Archive `build/symbols/android-prod-<version>/` safely after every production build, and keep
  it for the life of that version. Without it, crash traces cannot be read.
- `build/symbols/` is git-ignored. Never commit it.

### 6.2 ProGuard / R8

- `isMinifyEnabled = true` and `isShrinkResources = true` for release in
  `android/app/build.gradle.kts`.
- `android/app/proguard-rules.pro` keeps classes reached by reflection.
- After adding any dependency, test a full release build: R8 can strip reflection-only classes,
  which fails only in release.

### 6.3 App Size Analysis

```bash
flutter build apk --flavor prod --release --analyze-size --target-platform android-arm64
```

Record the result in the release evidence (§14) and compare with the last release. A rise of
more than 10% needs a written reason.

| Artifact | Target | Hard limit |
|---|---|---|
| APK, arm64 | < 30 MB | 50 MB |
| App Bundle download | < 20 MB | 40 MB |

### 6.4 Debuggable, Backup And Permission Verification

```bash
# bash / zsh
APK="build/app/outputs/apk/prod/release/app-arm64-v8a-prod-release.apk"
aapt2 dump badging "$APK" | grep -i debuggable          # expect: no output
aapt2 dump xmltree "$APK" --file AndroidManifest.xml | grep -i allowBackup   # expect: =0x0
aapt2 dump xmltree "$APK" --file AndroidManifest.xml | grep -i dataExtractionRules   # expect: one line
aapt2 dump permissions "$APK"                            # expect: exactly the 12 below
```

```powershell
# PowerShell (Windows)
$APK = "build\app\outputs\apk\prod\release\app-arm64-v8a-prod-release.apk"
aapt2 dump badging $APK | Select-String -Pattern "debuggable"        # expect: no output
aapt2 dump xmltree $APK --file AndroidManifest.xml | Select-String -Pattern "allowBackup"  # expect: =0x0
aapt2 dump xmltree $APK --file AndroidManifest.xml | Select-String -Pattern "dataExtractionRules"  # expect: one line
aapt2 dump permissions $APK                                          # expect: exactly the 12 below
```

**Expected permissions — exactly these 12, no more and no fewer** (reasons in
[security.md](security.md) §11). The first 11 are declared in our manifest; the last one is added
by `androidx.core` and is private to this app:

`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`,
`READ_EXTERNAL_STORAGE` (maxSdkVersion 32), `USE_BIOMETRIC`, `USE_FINGERPRINT`
(maxSdkVersion 28), `CAMERA`, `INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE`,
`CHANGE_WIFI_STATE`, and `in.sreerajp.imgvidgal.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.

> `INTERNET` **must be present** — the local transfer feature needs it. What must be absent is
> `WAKE_LOCK` (ExoPlayer adds it; the manifest removes it) and any permission not on the list.
> A new permission from a dependency blocks the release until it is removed or approved and
> added to [security.md](security.md) §11.

### 6.5 Network Security Configuration And Cleartext Traffic

- The app has no HTTP client and makes no HTTP calls. There is no
  `network_security_config.xml`.
- `android:usesCleartextTraffic` is not set. It defaults to `false` on API 28+; on API 24–27 it
  defaults to `true`, but no HTTP code exists to use it. The transfer protocol is a raw socket
  with AES-256-GCM on every frame ([security.md](security.md) §19).
- Check before release: the merged manifest has no `usesCleartextTraffic="true"` and no
  network security config that trusts user certificates.

### 6.6 Pre-Release Asset And Secret Leak Audit

```bash
# bash / zsh
unzip -l build/app/outputs/apk/prod/release/app-arm64-v8a-prod-release.apk "assets/*"
```

```powershell
# PowerShell (Windows)
tar -tf build\app\outputs\apk\prod\release\app-arm64-v8a-prod-release.apk | Select-String "assets/"
```

- [ ] No `.env`, keys, `.pem`, `.p12` or keystores in the assets.
- [ ] No database files with test data.
- [ ] Only expected app assets: `assets/config/app_config.json`, `assets/tessdata_config.json`
      and `assets/tessdata/` (`eng.traineddata`, `mal.traineddata`), plus what Flutter and the
      plugins add (fonts, shaders, `AssetManifest`).

### 6.7 Exported Component Audit

- Only the main activity is `exported="true"`, because it receives "open with" intents for
  images and videos. Its input goes through `MediaIntentService`.
- The `FileProvider` is `exported="false"`.
- Any new activity, service, receiver or provider must declare `android:exported` on purpose.

---

## 7. Signing And Secret Handling

> **Never commit signing material.** `android/key.properties`, `*.jks` and `*.keystore` are
> git-ignored. Keep **at least two** offline backups of the keystore in separate safe places.
> Losing it means you can never ship an update under the same signature.

- **Keystore file:** `android/gallery-release.jks`
- **Alias:** `gallery_key`
- **Signing properties file:** `android/key.properties` (git-ignored)
- **Keystore owner:** the app developer.
- **Rotation:** only through Play App Signing's upload-key reset; the app signing key is never
  rotated by hand.

`android/key.properties` template (placeholders only — never real values):

```properties
storePassword=<RELEASE_KEYSTORE_PASSWORD>
keyPassword=<RELEASE_KEY_PASSWORD>
keyAlias=gallery_key
storeFile=gallery-release.jks
```

`android/app/build.gradle.kts` looks for `storeFile` first under `android/app/`, then under
`android/`, so `gallery-release.jks` finds the keystore in `android/`.

---

## 8. Release Checklist

Complete every item before tagging a release.

### Code And Quality

- [ ] `dart format --output=none --set-exit-if-changed .` passes.
- [ ] `flutter analyze` reports zero issues.
- [ ] `flutter test` passes.
- [ ] Generated code is current: `flutter gen-l10n` run after any ARB change. (There is no
      `build_runner` in this project. `app_version.g.dart` and `build_date.g.dart` are written by
      a Gradle task during the build.)
- [ ] No release-blocking bug is open.

### Performance

- [ ] Release build profiled for jank on the timeline and viewer.
- [ ] Size within budget (§6.3).
- [ ] Cold start under 2 seconds on a mid-range phone.

### Security

- [ ] `--obfuscate` and `--split-debug-info` used for every release artifact.
- [ ] Debug symbols archived for this version.
- [ ] R8 rules checked.
- [ ] `debuggable` absent/false, `allowBackup` false and `dataExtractionRules` set in the merged manifest (§6.4).
- [ ] Merged manifest has exactly the 12 expected permissions (11 ours + 1 private AndroidX), **including `INTERNET`** (§6.4).
- [ ] `test/services/sync/local_address_rules_test.dart` passes.
- [ ] Cleartext and network config checked (§6.5).
- [ ] Asset audit passed (§6.6).
- [ ] Exported component audit passed (§6.7).
- [ ] Security review checklist done ([security.md](security.md) §18).

### Localization

The app ships English, Malayalam and Sanskrit. Items marked **(gap)** cannot pass until the
matching item in [known_gaps.md](known_gaps.md) is fixed; until then, record them as open in the
release evidence rather than ticking them.

- [ ] `flutter test test/l10n` passes: all three ARB files have the same keys and placeholders, no
      English copied into `ml` or `sa` outside the technical allow-list, `app_config.json` has all
      three languages, and the Sanskrit Hindi-marker gate is clean.
- [ ] Sanskrit reviewed by a fluent reader. The full text was reviewed on 2026-11-05; check
      only strings added or changed since then.
- [ ] Short-label length budget respected (engineering standard §8.6). Every key has a category
      prefix, and the test checks every short label in every language with no exceptions.
- [ ] Every screen opened in `en`, `ml` and `sa` on a clean device — no missing glyphs (boxes), no
      overflow, no clipped Malayalam or Devanagari ascenders. The app bundles no fonts, so this
      check is what proves the system Noto fonts are there.
- [ ] Language picker works (System default / English / മലയാളം / संस्कृतम्), persists across
      restart, applies without restart.
- [ ] `bundle.language.enableSplit = false` still in `android/app/build.gradle.kts`.
- [ ] Every icon-only control has a localized tooltip.
- [ ] About screen ends with the "Made with ❤️ from India" badge in all three languages.

### Google Play Store Readiness

- [ ] Full §9A gate completed for this release.

### Product And Documentation

- [ ] Version updated in `pubspec.yaml` and `assets/config/app_config.json`.
- [ ] Release notes written.
- [ ] Docs updated for any user-visible change.

### Artifact Validation

- [ ] Artifacts build and install on a clean device.
- [ ] Prod build shows no dev badge and the prod app name.
- [ ] Version name and build number correct in Settings → About.
- [ ] Release build tested end to end, including a local transfer between two phones.

---

## 9. Android Release Steps

1. Check out the release commit; `git status` must be clean.
2. Check the version in `pubspec.yaml` and `assets/config/app_config.json`.
3. `flutter pub get`, then `flutter gen-l10n`.
4. Run format, analyze and test.
5. Build the artifacts below with all hardening flags.
6. Run size analysis and record it.
7. Run the manifest checks (§6.4) and the asset audit (§6.6).
8. Install and test on a real phone.
9. Archive `build/symbols/android-prod-<version>/`.
10. Complete the §9A gate before uploading to Play.
11. Upload / publish.
12. Tag the release (§15).

### Android Build Commands

**Pre-build checks**

```bash
flutter clean
flutter pub get
flutter gen-l10n
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

**Split APKs (direct distribution)**

```bash
# bash / zsh
flutter build apk --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod-<version>/ \
  --split-per-abi
```

```powershell
# PowerShell (Windows)
flutter build apk `
  --flavor prod `
  --release `
  --obfuscate `
  --split-debug-info=build/symbols/android-prod-<version>/ `
  --split-per-abi
```

Output: `build/app/outputs/apk/prod/release/app-arm64-v8a-prod-release.apk`, and one per ABI.

**App Bundle (Google Play)**

```bash
# bash / zsh
flutter build appbundle --flavor prod --release \
  --obfuscate --split-debug-info=build/symbols/android-prod-<version>/
```

```powershell
# PowerShell (Windows)
flutter build appbundle `
  --flavor prod `
  --release `
  --obfuscate `
  --split-debug-info=build/symbols/android-prod-<version>/
```

Output: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`.

---

## 9A. Store Readiness (Mandatory Gate)

The store gates live in
[guidelines/platform_store_readiness.md](guidelines/platform_store_readiness.md). This project
does not keep a copy of them. Before the first upload, and again before every production
release, go through these sections of that file:

- **§1** — rules for every store.
- **§2** — Google Play (declared channel).
- **§2.5A** — direct APK downloads (declared channel: split APKs).
- **§7** — record the result in the release evidence (§14 below).

Store rules change every year. Check the store's current pages; never trust a value already in
this project. If a rule has changed, follow the store and tell the user, so they can update the
guidelines repository.

### 9A.1 Values that belong to this app

These are the answers the gate asks for. They are facts about this app, not a copy of the gate.

| Gate item | This app |
|---|---|
| Production `applicationId` | `in.sreerajp.imgvidgal` (no suffix; can never change) |
| `targetSdk` / `compileSdk` / `minSdk` | 36 / 36 / 24 (since 2026-11-02, the value Flutter 3.47.6 generates). Check Play's current target-API rule before each release. `minSdk` reason: [architecture.md](architecture.md) §19 |
| Native code for the 16 KB check | Flutter engine, Tesseract (OCR), CameraX (`camera` plugin), media plugins. ZXing core is plain Java, with no native library |
| Permissions | The 11 in [security.md](security.md) §11 plus AndroidX's private one (§6.4 above) |
| Foreground-only sensitive use | `CAMERA` for the pairing QR scan only; `CHANGE_WIFI_STATE` for network suggestions only |
| Not used | Foreground service, exact alarm, all-files access, SMS/call log, background location, `QUERY_ALL_PACKAGES` |
| Data safety answer | No data collected, no data shared. Data moves only device to device on the local network, at the user's request, encrypted in transit |
| Accounts | None, so account deletion does not apply |
| Ads | None |
| Listing languages | `en-IN` and `ml-IN`, with screenshots in each. Sanskrit is not a Play listing language; it ships inside the app only ([PROJECT_PROFILE.md](PROJECT_PROFILE.md) §4) |
| Privacy policy URL, support contact | `PRIVACY.md` in the public repository, and the support email; both are rows in `assets/config/app_config.json` and shown on the About screen |

---

## 10. iOS Release Steps

`N/A` — the app is Android only.

---

## 11. Windows Release Steps

`N/A` — the app is Android only.

---

## 12. Distribution Channels

| Channel | Artifact | Audience | Notes |
|---|---|---|---|
| Google Play | App Bundle (`.aab`) | Public | Gate §9A; staged rollout |
| Direct download | Split APKs per ABI | Public / testers | Same signing key as Play |

---

## 13. Rollback And Hotfix Process

- **Rollback trigger:** a critical security issue ([security.md](security.md) §16), data loss, or
  a crash rate above Play's bad-behavior threshold.
- **Rollback method:** halt the staged rollout in Play; ship a hotfix with a higher
  `versionCode` (Play cannot roll back to an older `versionCode`).
- **Hotfix naming:** raise `PATCH`, for example `2.5.3+16`.
- **After a rollback or hotfix:**
  - Run the full checklist (§8), even for a hotfix.
  - Archive the hotfix's debug symbols.

---

## 14. Release Evidence

Record these for each release in its change log in `change_log/` (relative paths and no local
machine details, per the workflow rules):

- Test report: `flutter analyze` and `flutter test` results.
- Size analysis output (§6.3).
- Manifest check output (§6.4).
- Debug symbols archive: where it is kept (described, not an absolute path).
- Built artifacts and their version.
- Release notes.
- Play rollout record.
- Security review sign-off ([security.md](security.md) §18) and date.
- Open localization gaps at release time ([known_gaps.md](known_gaps.md)).

---

## 15. Post-Release Checks

- [ ] Fresh install on a clean phone works (there is no crash reporting, by design).
- [ ] Android vitals reviewed in Play Console.
- [ ] User reports triaged.
- [ ] Tag created and pushed (commands below).
- [ ] Debug symbols confirmed in the safe archive.
- [ ] Follow-up tasks recorded in `plans/` or [known_gaps.md](known_gaps.md).

```bash
git tag v<version>
git push origin v<version>
```
