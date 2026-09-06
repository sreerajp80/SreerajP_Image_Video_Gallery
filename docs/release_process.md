# Release Process — SreerajP Image Video Gallery

This document defines the release lifecycle, build flavors, signing configuration, binary hardening rules, and release verification checklist for the SreerajP Image Video Gallery application. Read this before building or shipping any production release.

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [Project_Idea.md](Project_Idea.md)
- [security.md](security.md)
- [guidelines/release_process.md](guidelines/release_process.md)
- [guidelines/flutter_build_flavors_guide.md](guidelines/flutter_build_flavors_guide.md)

---

## 1. Release Scope & Platform Matrix

- **App Name**: SreerajP Image Video Gallery
- **Platform**: Android only (minSdk 24, targetSdk 35)
- **Release Profile**: Production Release
- **Standards in Force**: Core Baseline + Production App Extension + Sensitive Data Extension

---

## 2. Build Flavors

| Flavor | Application ID | Display Name | Signing Config | Purpose |
|---|---|---|---|---|
| **`dev`** | `in.sreerajp.imgvidgal.dev` | SreerajP Gallery Dev | Automatic Debug Keystore | Daily development, rapid testing |
| **`prod`** | `in.sreerajp.imgvidgal` | SreerajP Image Video Gallery | Release Keystore (`android/key.properties`) | Production release, Store distribution |

> Flutter passes `--flavor <name>` at build time, which sets `FLUTTER_APP_FLAVOR`.

---

## 3. Keystore & Signing Configuration

> [!WARNING]
> Keystore files (`*.jks`, `*.keystore`) and `key.properties` must NEVER be committed to version control. Keep at least two offline backups of the release keystore.

### Keystore Metadata
- **Keystore File**: `android/gallery-release.jks`
- **Alias**: `gallery_key`
- **Key Properties File**: `android/key.properties` (gitignored)

### `android/key.properties` Template
```properties
storePassword=<RELEASE_KEYSTORE_PASSWORD>
keyPassword=<RELEASE_KEY_PASSWORD>
keyAlias=gallery_key
storeFile=../gallery-release.jks
```

---

## 4. Binary Hardening & Verification

All production release builds MUST include the following mandatory flags:

### 4.1 Obfuscation and Symbol Splitting
```bash
--obfuscate --split-debug-info=build/symbols/android-prod-<version>/
```
- Obfuscates Dart class/method names.
- Saves symbol maps to `build/symbols/android-prod-<version>/` for decoding crash stack traces.
- Debug symbols must be archived securely with the release artifacts.

### 4.2 ProGuard / R8 Shrinking
- Code shrinking, resource shrinking, and obfuscation enabled in `android/app/build.gradle.kts`.
- Custom rules in `android/app/proguard-rules.pro` preserve reflection-accessed classes (e.g. `sqflite`).

### 4.3 App Size Budgets
- **Per-ABI APK**: < 30 MB (Hard limit: 50 MB)
- **App Bundle (AAB)**: < 25 MB (Hard limit: 40 MB)

### 4.4 Debuggable & Permission Verification
Run before distribution:
```powershell
# Verify android:debuggable is absent or false
aapt2 dump badging build\app\outputs\apk\prod\release\app-arm64-v8a-prod-release.apk | Select-String -Pattern debuggable

# Verify android.permission.INTERNET is completely absent
aapt2 dump permissions build\app\outputs\apk\prod\release\app-arm64-v8a-prod-release.apk | Select-String -Pattern INTERNET
```

---

## 5. Release Checklist

Complete all checklist items before tagging and shipping any release:

### Quality & Static Analysis
- [ ] `dart format --output=none --set-exit-if-changed .` passes cleanly.
- [ ] `flutter analyze` passes with zero warnings or errors.
- [ ] `flutter test` passes 100% of all unit and widget tests.
- [ ] Code generation up-to-date: `dart run build_runner build --delete-conflicting-outputs`.

### Security & Privacy
- [ ] Production build compiled with `--obfuscate` and `--split-debug-info`.
- [ ] Debug symbols archived to `build/symbols/`.
- [ ] `android:debuggable=false` verified in merged release manifest.
- [ ] `android.permission.INTERNET` confirmed ABSENT from merged release manifest.
- [ ] `android:allowBackup="false"` verified in manifest.
- [ ] OWASP Mobile Top 10 checklist reviewed in [security.md](security.md).

### Packaging & Artifacts
- [ ] Version and build number updated in `pubspec.yaml`.
- [ ] Release changelog logged in `change_log/`.
- [ ] Split APKs generated and verified on physical test devices.
- [ ] Production App Bundle (`.aab`) generated.

---

## 6. Build Commands

### Clean & Prepare
```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
```

### Build Split APKs (Direct Distribution)
```bash
flutter build apk \
  --flavor prod \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols/android-prod-1.0.0/ \
  --split-per-abi
```

### Build Production App Bundle (Google Play)
```bash
flutter build appbundle \
  --flavor prod \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols/android-prod-1.0.0/
```

### Size Analysis Command
```bash
flutter build apk --flavor prod --release --analyze-size
```

---

## 7. Post-Release & Tagging

After releasing:
1. Tag the release in Git:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
2. Archive the generated `build/symbols/android-prod-1.0.0/` directory alongside release binaries.
3. Record release evidence and changelog in `change_log/`.
