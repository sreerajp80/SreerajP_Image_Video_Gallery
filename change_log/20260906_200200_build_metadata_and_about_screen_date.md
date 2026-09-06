# Change Log: Build Metadata Generation and About Screen Build Date

**Date:** 2026-09-06
**Plan:** `plans/20260906_195800_build_metadata_and_about_screen_date.md`

## Summary

Automated generation of build version and build date constants during project builds and displayed the build date on the About screen.

## Details of Changes

1. **Build Metadata Generators:**
   - Created `tool/generate_app_version.dart` to read `pubspec.yaml` and update `lib/core/constants/app_version.g.dart` with `kAppVersion`, printing `app_version.g.dart updated → <version>`.
   - Created `tool/generate_build_date.dart` to determine today's ISO date and update `lib/core/constants/build_date.g.dart` with `kBuildDate`, printing `build_date.g.dart updated → <date>`.
   - Added `tool/refresh_build_metadata.ps1` helper script.
2. **Gradle Build Hook Integration:**
   - In `android/app/build.gradle.kts`, registered `generateBuildMetadata` Gradle task that executes both generator scripts.
   - Configured `preBuild` and `compileFlutterBuild*` tasks to depend on `generateBuildMetadata` so metadata constants are always kept fresh during builds.
3. **Localization:**
   - Added `aboutBuildDate` to `lib/l10n/app_en.arb` ("Build date") and `lib/l10n/app_ml.arb` ("ബിൽഡ് തീയതി").
   - Regenerated localization files with `flutter gen-l10n`.
4. **About Screen UI:**
   - In `lib/screens/settings/about_screen.dart`, added a `ListTile` showing `Icons.calendar_today_outlined`, `l10n.aboutBuildDate`, and `kBuildDate`.
5. **Testing and Verification:**
   - Updated `test/widgets/settings/about_screen_test.dart` to check that the build date row renders and the 3 fixed rows (app info, version/build, and build date) are shown.
   - Verified that Gradle executes `:app:generateBuildMetadata` and outputs metadata update logs.
   - All 1,831 unit and widget tests passed; `flutter analyze` completed with 0 warnings.
