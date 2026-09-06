# Change Log: Ensure App is Default App for Images and Videos

**Date:** 2026-09-06  
**Plan:** [plans/20260906_133000_default_app_for_images_and_videos.md](../plans/20260906_133000_default_app_for_images_and_videos.md)  

---

## 1. Summary of Changes

Configured the application to be the default app for images and videos on Android devices. Added Android intent filters for viewing image and video content, implemented incoming intent handling in native Kotlin and Flutter, enabled single and external media display in the viewer, and added a dedicated Default Gallery App card in Settings that allows users to view setup instructions and open Android's Default Apps system settings directly.

---

## 2. Details of Changes

1. **Android Manifest (`android/app/src/main/AndroidManifest.xml`)**:
   - Added `android.intent.action.VIEW` intent filters to `MainActivity` for both `image/*` and `video/*`.
   - Included `DEFAULT` and `BROWSABLE` categories and support for both `content` and `file` URI schemes.
   - Allows Android to present the app in the system "Open with" chooser so the user can select "Always" to set it as the default gallery and video player.

2. **Android Native Layer (`android/app/src/main/kotlin/in/sreerajp/imgvidgal/`)**:
   - `MainActivity.kt`: Overrode `onNewIntent(intent: Intent)` to capture incoming media intents when the app is already in memory (`singleTop`) and route them to `IntentChannelHandler`.
   - `tools/IntentChannelHandler.kt`:
     - Added `getInitialMediaIntent` to extract safe URI, MIME type, display name, and size from launch intents.
     - Added `openDefaultAppsSettings` to launch Android's system Default Apps settings screen (`Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS`, with fallback to `Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS` or `Settings.ACTION_APPLICATION_DETAILS_SETTINGS`).
     - Added `handleNewIntent` to forward new media intents arriving at runtime over the method channel to Flutter via `onMediaIntent`.

3. **Data Access & Repositories (`lib/repositories/`)**:
   - `database/media_dao.dart`: Added `getMediaItemByUri(String uri)` to retrieve indexed media by content URI.
   - `media_repository.dart`: Added `getMediaItemByUri(String uri)` query method.

4. **Intent Service & Providers (`lib/services/intent/`, `lib/providers/`)**:
   - Created `MediaIntentService` (`lib/services/intent/media_intent_service.dart`) to interface with the native intent channel, listen for runtime media intents, and resolve incoming URIs against the database or as safe transient `MediaItem` instances.
   - Created `media_intent_providers.dart` (`lib/providers/media_intent_providers.dart`) exposing `mediaIntentServiceProvider`, `externalMediaRegistryProvider`, and `externalMediaItemProvider`.

5. **Viewer Screen (`lib/screens/viewer/media_viewer_screen.dart`)**:
   - Updated `MediaViewerScreen` to support single and external items when the item ID is not present in the timeline list (e.g. files opened from WhatsApp, Downloads, or file managers).
   - Supported full image zoom/pan and video playback controls for external items.
   - Updated the viewer back button and swipe-to-dismiss behavior so that if opened externally as a single screen, it exits cleanly back to the calling app (`SystemNavigator.pop()`).

6. **Settings Screen & Localization (`lib/screens/settings/`, `lib/l10n/`)**:
   - Added a "Default Gallery App" card in `lib/screens/settings/settings_screen.dart` with an action that explains how to set the app as default in Android and offers a button to open Android Settings.
   - Added localized strings to `lib/l10n/app_en.arb` and `lib/l10n/app_ml.arb` for the Default App section and dialog.
   - Regenerated localizations with `flutter gen-l10n`.

7. **Application Lifecycle (`lib/main.dart`)**:
   - Converted `GalleryApp` to `ConsumerStatefulWidget` to initialize `MediaIntentService`.
   - Checks for initial media launch intent at cold start and listens for incoming media intents during runtime, navigating directly to the fullscreen viewer.

8. **Automated Tests (`test/`)**:
   - Added unit tests in `test/services/intent/media_intent_service_test.dart` for `MediaIntentData` parsing, initial intent retrieval, incoming stream handling, and media item resolution.
   - Added unit test in `test/repositories/media_repository_test.dart` for `getMediaItemByUri`.
   - Updated widget tests in `test/widgets/settings/settings_screen_test.dart` to verify the 7 settings section cards and testing the Default App dialog.

---

## 3. Verification

- `dart format .`: All files formatted cleanly.
- `flutter analyze`: Passed with 0 errors and 0 warnings.
- `flutter test`: All 1,824 tests passed cleanly across the entire test suite.
