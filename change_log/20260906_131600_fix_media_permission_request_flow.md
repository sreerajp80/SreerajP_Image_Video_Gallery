# Change Log: Fix Media Permission Request Flow on Timeline Screen

**Date:** 2026-09-06
**Plan:** `plans/20260906_124100_fix_media_permission_request_flow.md`

---

## 1. Summary of Changes

Fixed an issue where tapping the "Allow access" ("അനുമതി നൽകുക") button on the timeline screen did nothing. The native Android channel handler prematurely reported permissions as permanently denied before any permission prompt had been shown to the user. Updated the Android handler to properly track request history, updated the timeline screen to request permissions and handle settings redirection, and added app lifecycle refresh when returning to the app.

---

## 2. Changes Made

### `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- Added SharedPreferences tracking (`media_permissions_requested`) to record when media permissions are requested.
- Fixed `currentPermissionStatus()` so it returns `STATUS_DENIED` instead of `STATUS_PERMANENTLY_DENIED` when permissions have not yet been requested on a fresh install.
- Updated `requestPermissions()` to store `media_permissions_requested = true`.

### `lib/screens/timeline/timeline_screen.dart`
- Added an `AppLifecycleListener` to detect app resume events and refresh the permission status when returning from system settings or background.
- Added a Riverpod listener on `mediaPermissionStatusProvider` to trigger media scanning as soon as permissions become granted.
- Updated the permission message button:
  - If permanently denied: shows "Open settings" (`openSettings` / "ക്രമീകരണങ്ങൾ തുറക്കുക") and opens system application details.
  - If denied: shows "Allow access" (`grantPermission` / "അനുമതി നൽകുക") and invokes the native system permission dialog.

### `lib/providers/media_providers.dart`
- Added `onPermissionChecked` callback to `MediaScanController` to invalidate `mediaPermissionStatusProvider` whenever scanning runs, keeping UI state synchronized.

### `test/providers/media_permission_test.dart`
- Added comprehensive unit tests for `MediaPermissionService` and `MediaScanController`.

---

## 3. Verification

- Ran `flutter analyze` with 0 issues found.
- Formatted all code using `dart format .`.
- Ran `flutter test` with all 1,811 tests passing.
