# Upgrade Gradle, Android Gradle Plugin, and Kotlin to Recommended Versions

**Status:** completed

**Date:** 2026-09-06
**Implements:** Upgrade Gradle wrapper to 8.14, Android Gradle Plugin (AGP) to 8.11.1, and Kotlin to 2.2.20

---

## 1. Context and Problem Statement

During Flutter builds, Flutter's Android dependency validation emits deprecation warnings regarding outdated build tooling:
- **Gradle:** Currently using `8.9.0`. Flutter warns that support will soon be dropped and recommends upgrading to at least `8.14.0`.
- **Android Gradle Plugin (AGP):** Currently using `8.7.0`. Flutter recommends upgrading to at least `8.11.1`.
- **Kotlin:** Currently using `2.0.21`. Flutter recommends upgrading to at least `2.2.20`.

Upgrading these versions ensures long-term compatibility with Flutter tooling, Android SDK 36 / 35, and removes build deprecation warnings.

---

## 2. Proposed Changes

### 2.1 Files to Modify

- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/settings.gradle.kts`

### 2.2 Details of Changes

1. In `android/gradle/wrapper/gradle-wrapper.properties`:
   - Update `distributionUrl`:
     ```properties
     distributionUrl=https\://services.gradle.org/distributions/gradle-8.14-all.zip
     ```

2. In `android/settings.gradle.kts`:
   - Update `com.android.application` plugin version from `8.7.0` to `8.11.1`.
   - Update `org.jetbrains.kotlin.android` plugin version from `2.0.21` to `2.2.20`.

---

## 3. Verification Plan

1. Verify static analysis remains clean:
   ```bash
   flutter analyze
   ```
2. Build development APK to verify Gradle download, configuration, and compilation without dependency validation warnings:
   ```bash
   flutter build apk --flavor dev
   ```
3. Run existing unit and widget test suite:
   ```bash
   flutter test
   ```
