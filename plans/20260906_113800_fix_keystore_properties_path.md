# Fix Android Keystore Properties Path for Release APK Signing

**Status:** completed

**Date:** 2026-09-06
**Implements:** Correct key.properties and keystore file resolution in Gradle build configuration

---

## 1. Context and Problem Statement

When attempting to install the built release APK on an Android device, installation fails with:
`INSTALL_PARSE_FAILED_NO_CERTIFICATES` (showing on Android devices as "App not installed as package appears to be invalid" or "App not installed").

The build outputs show:
`build/app/outputs/apk/prod/release/app-prod-arm64-v8a-release-unsigned.apk`

Investigation revealed that in `android/app/build.gradle.kts`:
1. `keystorePropertiesFile` was defined as `rootProject.file("android/key.properties")`. In Gradle for a Flutter app, `rootProject` is already the `android/` directory. Consequently, `rootProject.file("android/key.properties")` resolved to `android/android/key.properties`, which does not exist.
2. Because `keystorePropertiesFile.exists()` returned `false`, the release `signingConfig` was never configured or assigned to the release build type.
3. The release APK was produced without any cryptographic signing (unsigned), causing Android package manager to reject installation on physical devices and emulators.

---

## 2. Proposed Changes

### 2.1 File to modify
- `android/app/build.gradle.kts`

### 2.2 Concrete Changes
1. Change `keystorePropertiesFile` resolution to `rootProject.file("key.properties")`.
2. Make `storeFile` resolution robust by checking both relative to `app/` and relative to root `android/`:
   ```kotlin
   val storeFilePath = props.getProperty("storeFile")
   if (storeFilePath != null) {
       val fileInApp = file(storeFilePath)
       val fileInRoot = rootProject.file(storeFilePath)
       storeFile = if (fileInApp.exists()) fileInApp else fileInRoot
   }
   ```

---

## 3. Verification Plan

1. Rebuild the release APK using:
   `flutter build apk --flavor prod --release --split-per-abi`
2. Verify that Gradle produces signed APKs (e.g. without `-unsigned` suffix) and that signing credentials from `key.properties` are applied.
3. Test installation on the connected Android device via ADB:
   `adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk`
4. Confirm successful installation on the device.
