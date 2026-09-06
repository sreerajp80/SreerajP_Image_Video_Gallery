# Change Log: Upgrade Gradle, Android Gradle Plugin, and Kotlin Versions

**Date:** 2026-09-06
**Plan:** `plans/20260906_115600_upgrade_gradle_agp_kotlin_versions.md`

---

## 1. Summary of Changes

Upgraded Android build toolchain dependencies (Gradle, Android Gradle Plugin, and Kotlin Gradle Plugin) to versions recommended by the Flutter SDK. This resolves Flutter's deprecation warnings regarding upcoming dropped support for older build toolchain versions.

---

## 2. Changes Made

### `android/gradle/wrapper/gradle-wrapper.properties`
- Updated `distributionUrl` from `gradle-8.9-all.zip` to `gradle-8.14-all.zip`.

### `android/settings.gradle.kts`
- Updated Android Gradle Plugin (`com.android.application`) from `8.7.0` to `8.11.1`.
- Updated Kotlin Android Plugin (`org.jetbrains.kotlin.android`) from `2.0.21` to `2.2.20`.

---

## 3. Verification

- Ran `flutter analyze`: 0 issues found.
- Ran `flutter test`: all 1,804 tests passed.
- Ran `flutter build apk --flavor dev`: built successfully (`app-dev-release.apk`) with Gradle 8.14, AGP 8.11.1, and Kotlin 2.2.20 without any Flutter build dependency validation warnings.
