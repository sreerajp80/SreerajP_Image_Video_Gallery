# Build Metadata Generation and About Screen Build Date

**Status:** Completed

## Files to Change

- `tool/generate_app_version.dart` [NEW] - Script to read version from `pubspec.yaml` and generate `lib/core/constants/app_version.g.dart`.
- `tool/generate_build_date.dart` [NEW] - Script to generate `lib/core/constants/build_date.g.dart` with current date.
- `tool/refresh_build_metadata.ps1` [NEW] - PowerShell convenience script to execute metadata generators.
- `android/app/build.gradle.kts` [MODIFY] - Register Gradle task `generateBuildMetadata` hooked into `preBuild` and `compileFlutterBuild*`.
- `lib/core/constants/app_version.g.dart` [NEW] - Generated constant `kAppVersion`.
- `lib/core/constants/build_date.g.dart` [NEW] - Generated constant `kBuildDate`.
- `lib/l10n/app_en.arb` [MODIFY] - Add `aboutBuildDate` translation string and description.
- `lib/l10n/app_ml.arb` [MODIFY] - Add `aboutBuildDate` Malayalam translation string and description.
- `lib/screens/settings/about_screen.dart` [MODIFY] - Display build date `ListTile` using `kBuildDate` and `l10n.aboutBuildDate`.
- `test/widgets/settings/about_screen_test.dart` [MODIFY] - Update tests for the new fixed row and verify build date display.

## Issue

1. When building the app with `flutter build apk ...`, build metadata (`app_version.g.dart` and `build_date.g.dart`) is not automatically updated and logged.
2. The About screen displays app name, version, and build number, but does not display the build date.

## Fix

1. **Add Build Metadata Generation Scripts:**
   - Create `tool/generate_app_version.dart` to read `pubspec.yaml` and generate `lib/core/constants/app_version.g.dart` with `kAppVersion`, printing `app_version.g.dart updated → <version>`.
   - Create `tool/generate_build_date.dart` to generate `lib/core/constants/build_date.g.dart` with `kBuildDate` formatted as `YYYY-MM-DD`, printing `build_date.g.dart updated → <date>`.
   - Add `tool/refresh_build_metadata.ps1` helper script.
2. **Hook into Gradle Build Process:**
   - In `android/app/build.gradle.kts`, register task `generateBuildMetadata` that executes both Dart generator scripts before Flutter compiles Dart and before Android builds.
   - Attach it as a dependency of `preBuild` and tasks matching `compileFlutterBuild*`.
3. **Localize and Display on About Screen:**
   - Add `aboutBuildDate` to `lib/l10n/app_en.arb` ("Build date") and `lib/l10n/app_ml.arb` ("ബിൽഡ് തീയതി").
   - Run `flutter gen-l10n` to regenerate localization code.
   - In `lib/screens/settings/about_screen.dart`, add a `ListTile` with icon `Icons.calendar_today_outlined`, title `l10n.aboutBuildDate`, and subtitle `Text(kBuildDate)`.
4. **Update Tests and Verification:**
   - Update `test/widgets/settings/about_screen_test.dart` to check that the 3 fixed rows (app info, version/build, and build date) render accurately.
   - Run `flutter analyze` and `flutter test`.
