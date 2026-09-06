# Fix Media Permission Request Flow on Timeline Screen

**Status:** completed

**Date:** 2026-09-06
**Implements:** Correct permission checking, requesting, settings navigation, and lifecycle refresh

---

## 1. Context and Problem Statement

When opening the gallery app for the first time on Android, the timeline screen displays the permission prompt:
- Title: "Media access needed" ("മീഡിയ അനുമതി ആവശ്യമാണ്")
- Body: "Allow access to your photos and videos so the gallery can show them. Nothing ever leaves your device."
- Button: "Allow access" ("അനുമതി നൽകുക")

When the user taps "Allow access", nothing happens: no Android permission dialog appears, no photos load, and no error message is displayed.

### Root Cause Analysis

There are three key issues causing this behavior:

1. **Premature `permanentlyDenied` Detection on Android**:
   In `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`:
   ```kotlin
   val permanentlyDenied = requiredPermissions().any { permission ->
       !isGranted(permission) &&
           !ActivityCompat.shouldShowRequestPermissionRationale(activity, permission)
   }
   ```
   On Android, `ActivityCompat.shouldShowRequestPermissionRationale` returns `false` both when a permission is permanently denied AND when the permission has **never been requested before** (fresh install).
   Because of this, `currentPermissionStatus()` returned `STATUS_PERMANENTLY_DENIED` immediately on first install before asking the user.

2. **`MediaPermissionService.ensureGranted()` Guard**:
   In `lib/services/media/media_permission_service.dart`:
   ```dart
   Future<MediaPermissionStatus> ensureGranted() async {
     final current = await check();
     if (current.canRead || current == MediaPermissionStatus.permanentlyDenied) {
       return current;
     }
     return request();
   }
   ```
   Because `check()` returned `permanentlyDenied`, `ensureGranted()` returned `permanentlyDenied` immediately without ever calling `request()`.

3. **Timeline Screen Button Action & Missing Lifecycle Observer**:
   In `lib/screens/timeline/timeline_screen.dart`:
   - The button callback called `ref.read(mediaScanControllerProvider.notifier).scan()`.
   - `scan()` called `ensureGranted()`, which aborted immediately due to the false `permanentlyDenied` status.
   - `mediaPermissionStatusProvider` was not invalidated or refreshed.
   - Even when a permission is truly permanently denied, the screen did not show "Open settings" or navigate to Android settings.
   - When returning to the app from Android Settings, the timeline screen did not listen to lifecycle resume events to re-check permissions.

---

## 2. Proposed Changes

### 2.1 Android Platform Channel Handler
File: `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- Track whether media permission has been requested at least once via `SharedPreferences` (`gallery_permissions`, key `media_permissions_requested`).
- In `currentPermissionStatus()`, if the permission has never been requested before, return `STATUS_DENIED` instead of `STATUS_PERMANENTLY_DENIED`.
- When `requestPermissions()` is called, set `media_permissions_requested` to `true`.

### 2.2 Timeline Screen
File: `lib/screens/timeline/timeline_screen.dart`
- In `_TimelineScreenState`, add an `AppLifecycleListener` for `onResume`. When the app resumes from background or Android Settings, invalidate `mediaPermissionStatusProvider` to check the updated permission state.
- Listen to `mediaPermissionStatusProvider` using `ref.listen`. If permission transitions to granted (`canRead == true`), trigger `mediaScanControllerProvider.notifier.scan()`.
- For the permission message state button:
  - If `status == MediaPermissionStatus.permanentlyDenied`:
    - Display button label: `l10n.openSettings` ("Open settings" / "ക്രമീകരണങ്ങൾ തുറക്കുക").
    - On tap: call `ref.read(mediaPermissionServiceProvider).openSettings()`.
  - If `status == MediaPermissionStatus.denied`:
    - Display button label: `l10n.grantPermission` ("Allow access" / "അനുമതി നൽകുക").
    - On tap: call `ref.read(mediaPermissionServiceProvider).request()`, invalidate `mediaPermissionStatusProvider`, and if granted, trigger `scan()`.

### 2.3 Media Providers
File: `lib/providers/media_providers.dart`
- In `MediaScanController`, notify or invalidate `mediaPermissionStatusProvider` when `scan()` checks or updates permissions so the UI status stays synchronized.

### 2.4 Tests
Files:
- `test/providers/media_permission_test.dart` (new): Test permission status handling, `MediaPermissionService`, and `MediaScanController` integration.

---

## 3. Verification Plan

### Automated Tests
- Run `flutter test` to verify all existing and new unit tests pass.
- Run `flutter analyze` to verify zero analysis warnings.

### Manual Verification
- Build and run the app on an Android device or emulator.
- On fresh install, verify that tapping "Allow access" ("അനുമതി നൽകുക") presents the system permission dialog.
- Verify that granting access immediately indexes and shows the user's photos and videos in the timeline.
- Verify that denying access permanently changes the button to "Open settings" ("ക്രമീകരണങ്ങൾ തുറക്കുക") and opens device app settings.
- Verify that granting access in settings and returning to the app automatically loads the timeline.
