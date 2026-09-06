# Create Proper .gitignore File

**Status:** completed

**Date:** 2026-09-06
**Implements:** Comprehensive and clean .gitignore configuration for Flutter and Android development

---

## 1. Context and Problem Statement

The project's existing `.gitignore` is incomplete:
1. It misses Android local properties (`android/local.properties` or `**/local.properties`), which contains machine-specific SDK paths that must not be committed.
2. It misses Android Gradle and Kotlin build caches (`.gradle/`, `android/.gradle/`, `android/.kotlin/`).
3. It uses `/build/` which only ignores the root `build/` directory, leaving Android-specific subfolder build outputs (`android/build/`, `android/app/build/`) unignored.
4. It lacks standard system ignore rules (such as Windows `Thumbs.db`, `desktop.ini`, `$RECYCLE.BIN/`, and macOS metadata files).
5. It lacks patterns for test coverage outputs (`coverage/`, `*.lcov`) and standalone package build outputs (`*.apk`, `*.aab`).
6. Guidelines (`docs/guidelines/guideline.md` and `docs/guidelines/flutter_project_engineering_standard.md`) require proper exclusion of keys, local state, machine-local files, and build outputs.

---

## 2. Files to Change

- `.gitignore` (relative path)

---

## 3. Proposed Changes

Update `.gitignore` to include all standard Flutter, Dart, Android, IDE, and operating system ignore patterns with clear section headers:

1. **Flutter & Dart**:
   - `.dart_tool/`
   - `.flutter-plugins`
   - `.flutter-plugins-dependencies`
   - `.packages`
   - `.pub-cache/`
   - `.pub/`
   - `**/doc/api/`

2. **Build Outputs & Binaries**:
   - `build/`
   - `**/build/`
   - `*.apk`
   - `*.aab`
   - `*.aar`
   - `*.msix`
   - `*.ipa`

3. **Android Build & Local Configuration**:
   - `.gradle/`
   - `android/.gradle/`
   - `android/.kotlin/`
   - `android/captures/`
   - `android/local.properties`
   - `**/local.properties`
   - `android/.cxx/`
   - `android/.externalNativeBuild/`
   - `**/GeneratedPluginRegistrant.java`
   - `**/GeneratedPluginRegistrant.kt`

4. **Signing, Keystore & Secrets (Hard Security Rule)**:
   - `key.properties`
   - `android/key.properties`
   - `**/key.properties`
   - `*.jks`
   - `*.keystore`
   - `android/*.jks`
   - `android/*.keystore`

5. **Debug Symbols**:
   - `build/symbols/`
   - `*.symbols/`

6. **IDEs & Editors**:
   - `.idea/`
   - `*.iml`
   - `*.ipr`
   - `*.iws`
   - `out/`
   - `.vscode/`
   - `*.swp`
   - `*~`
   - `*.bak`

7. **Operating System Artifacts**:
   - Windows: `Thumbs.db`, `Thumbs.db:encryptable`, `ehthumbs.db`, `ehthumbs_vista.db`, `[Dd]esktop.ini`, `$RECYCLE.BIN/`
   - macOS: `.DS_Store`, `._*`, `.AppleDouble`, `.LSOverride`, `.Spotlight-V100`, `.Trashes`

8. **Test & Local Artifacts**:
   - `coverage/`
   - `*.lcov`
   - `photo_vault*.jpg` (local test fixtures)
   - `.buildlog/`
   - `migrate_working_dir/`

---

## 4. Verification Plan

1. Verify `.gitignore` syntax and formatting.
2. Run `git status` and `git check-ignore` on sensitive and build files:
   - `android/local.properties` (must be ignored)
   - `android/key.properties` (must be ignored)
   - `android/sreeimgvid.jks` (must be ignored)
   - `android/.gradle` (must be ignored)
   - `android/.kotlin` (must be ignored)
   - `android/build` (must be ignored)
   - `photo_vault1.jpg` (must be ignored)
3. Ensure required tracking files remain tracked:
   - `android/gradlew`
   - `android/gradlew.bat`
   - `android/gradle/wrapper/gradle-wrapper.jar`
   - `android/gradle/wrapper/gradle-wrapper.properties`
   - `pubspec.lock`
   - `lib/core/config/app_version.g.dart`
   - `lib/core/config/build_date.g.dart`
