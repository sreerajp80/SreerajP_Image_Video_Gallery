# Change Log: Fix Android Keystore Properties Path for Release APK Signing

**Date:** 2026-09-06
**Plan:** `plans/20260906_113800_fix_keystore_properties_path.md`

---

## 1. Summary of Changes

Fixed the keystore properties file and keystore path resolution in `android/app/build.gradle.kts`. This resolves an issue where release APKs were generated unsigned, causing Android installation failure with `INSTALL_PARSE_FAILED_NO_CERTIFICATES` ("App not installed").

---

## 2. Changes Made

### `android/app/build.gradle.kts`
- Changed `keystorePropertiesFile` definition from `rootProject.file("android/key.properties")` to `rootProject.file("key.properties")`.
- Updated `storeFile` resolution logic in the release signing configuration so it checks for the keystore file relative to the `app/` subproject directory first and falls back to `rootProject` directory.
- This ensures release builds find the keystore configuration and apply the cryptographic signature to output APKs.

---

## 3. Verification

- Ran `flutter build apk --flavor prod --release --split-per-abi` and verified signed APKs are generated without `-unsigned` suffix.
- Tested ADB installation on a connected Android device using `adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-prod-release.apk` with result `Success`.
- Verified package `in.sreerajp.imgvidgal` is successfully installed on the device.
- Ran `flutter analyze` with 0 issues found.
- Ran `flutter test` with all 1,804 tests passing.
