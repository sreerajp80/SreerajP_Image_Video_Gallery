# Update Android compileSdk to 36

**Status:** completed

**Date:** 2026-09-06
**Implements:** Bump Android compileSdk to 36 in app build configuration

---

## 1. Context and Problem Statement

When building the Android app (e.g. `flutter build apk`), Gradle produces build configuration warnings indicating that several plugins require compiling against Android SDK 36:
- `flutter_plugin_android_lifecycle` compiles against Android SDK 36
- `local_auth_android` compiles against Android SDK 36
- `sqflite_android` compiles against Android SDK 36
- `video_player_android` compiles against Android SDK 36

Currently, `android/app/build.gradle.kts` specifies:
```kotlin
android {
    compileSdk = 35
    ...
}
```

Compiling against Android SDK 36 (`compileSdk = 36`) resolves this warning while maintaining full backward compatibility. The runtime target (`targetSdk = 35`) and minimum SDK (`minSdk = 24`) remain unchanged.

---

## 2. Proposed Changes

### 2.1 File to modify
- `android/app/build.gradle.kts`

### 2.2 Concrete Change
Update line 13:
```kotlin
-    compileSdk = 35
+    compileSdk = 36
```

Keep `targetSdk = 35` and `minSdk = 24` under `defaultConfig`.

---

## 3. Verification Plan

1. Run `flutter analyze` to ensure Dart codebase remains clean.
2. Run `flutter test` to ensure existing unit and widget tests pass.
3. Verify Gradle configuration by running a dry-run or release apk build check (`flutter build apk --flavor dev` or `flutter build apk --flavor prod --release --split-per-abi`).
