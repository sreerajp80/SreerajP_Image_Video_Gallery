# Ensure App is Default App for Images and Videos on Android Devices

**Status:** completed

**Date:** 2026-09-06  
**Reference:** Android ACTION_VIEW intent filters, default app settings, and external media handling  

---

## 1. Goal & Problem Description

The user wants this application to be the default app for viewing images and videos on Android devices.

Currently:
1. `android/app/src/main/AndroidManifest.xml` only registers `MAIN` and `LAUNCHER` intent filters. It has no intent filters for `android.intent.action.VIEW` with `image/*` or `video/*`. Because of this, Android will never show this app in the system "Open with" chooser, and the user cannot select "Always" to make it the default handler.
2. `MainActivity.kt` and the Flutter channel layer do not capture incoming media intents when launched by external apps or when receiving new intents (`onNewIntent`).
3. `lib/screens/viewer/media_viewer_screen.dart` assumes the opened media is already present in `timelineItemsProvider`. If opened from an external app (such as WhatsApp, Downloads, or a file manager), `startIndex` is negative, showing an error instead of displaying the media.
4. There is no option or guide in the Settings screen allowing users to easily open Android's "Default apps" settings.

---

## 2. Proposed Changes

### `android/app/src/main/AndroidManifest.xml`
- Add `<intent-filter>` declarations to `MainActivity` for `android.intent.action.VIEW`:
  - Image intent filters for `image/*` supporting `content` and `file` schemes, and generic MIME matching with `DEFAULT` and `BROWSABLE` categories.
  - Video intent filters for `video/*` supporting `content` and `file` schemes, and generic MIME matching with `DEFAULT` and `BROWSABLE` categories.

### `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt`
- Keep track of the latest launch intent.
- Override `onNewIntent(intent: Intent)` to capture media intents while the app is running and forward them to the intent channel.

### `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt`
- Add `getInitialMediaIntent` method to extract URI, MIME type, and display name from the launching intent.
- Add `openDefaultAppsSettings` method to launch Android's `Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS` (falling back to `Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS` or `Settings.ACTION_APPLICATION_DETAILS_SETTINGS`).
- Add helper method to send incoming intents via `channel.invokeMethod("onMediaIntent", map)`.

### `lib/services/intent/media_intent_service.dart` [NEW]
- Create a service to interface with the native intent channel for incoming media intents and default app settings.
- Expose methods to check for initial media launch intents and listen for incoming intents stream.

### `lib/providers/media_intent_providers.dart` [NEW]
- Expose `mediaIntentServiceProvider`.
- Expose `externalMediaItemProvider` to hold transient external `MediaItem` records when media is opened from external apps without being in the local database.

### `lib/repositories/database/media_dao.dart`
- Add `getMediaItemByUri(String uri)` to locate indexed media by its content URI.

### `lib/screens/viewer/media_viewer_screen.dart`
- Support viewing single/external items if `widget.mediaId` is not found in `timelineItemsProvider`.
- Check `mediaItemProvider(widget.mediaId)` and `externalMediaItemProvider(widget.mediaId)`.
- If found as a single item, render it with full image zoom/pan or video player controls.
- Handle back navigation safely: if opened from external intent, close viewer to return to previous app or navigate to timeline.

### `lib/screens/settings/settings_screen.dart`
- Add a "Default App" card in Settings with:
  - Title: "Default gallery app"
  - Subtitle: "Set as default app for viewing photos and videos"
  - Action to open a guide dialog or launch Android's Default Apps settings directly.

### `lib/l10n/app_en.arb`
- Add localized strings for the Default App setting and dialog.
- Run `flutter gen-l10n`.

### `lib/main.dart`
- Initialize `MediaIntentService` listener on startup to route incoming media intents to `mediaViewerPath(mediaId)`.

---

## 3. Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure 0 errors and 0 warnings.
- Run `flutter test` to ensure all existing and new unit/widget tests pass.
- Add unit test for `MediaIntentService` and external media resolution.

### Manual / Integration Verification
- Verify `AndroidManifest.xml` contains valid `ACTION_VIEW` intent filters for images and videos.
- Verify opening external images and videos displays the viewer correctly without crashes.
- Verify opening Default Apps settings from the app settings works as intended.
