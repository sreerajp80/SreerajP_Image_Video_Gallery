# Plan: Phase 1 — Project Setup, Build Flavors, Keystore & Theme Baseline

**Status:** Implemented

## 1. Issue & Objective
Phase 1 of the SreerajP Image Video Gallery roadmap establishes the foundation for the entire application.
The objective is to:
1. Initialize the Flutter project structure adhering to the Tier 1 layer-first layout.
2. Configure Android build flavors (`dev` and `prod`) with correct application IDs (`in.sreerajp.imgvidgal.dev` and `in.sreerajp.imgvidgal`).
3. Configure release signing handling (`android/key.properties` and keystore setup) and update `.gitignore`.
4. Configure ProGuard / R8 rules (`android/app/proguard-rules.pro`).
5. Implement `AppFlavorConfig` and `ConfigService` loading `assets/config/app_config.json` with dynamic metadata support.
6. Implement the Material 3 design system with Light, Dark, and AMOLED True Black theme modes.
7. Configure localization with `l10n.yaml` and initial ARB translation templates (`lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`).
8. Set up `main.dart` with `ProviderScope`, theme state, and a clean baseline landing UI.
9. Add unit tests for configuration and theme loading.

## 2. Files to Create / Modify

### Configuration & Root Files
- `pubspec.yaml` (Project metadata, dependencies, assets declaration)
- `l10n.yaml` (Localization generation settings)
- `.gitignore` (Git ignore rules including keystores, `key.properties`, build artifacts)
- `assets/config/app_config.json` (About metadata configuration source of truth)

### Android Platform Configuration
- `android/settings.gradle.kts`
- `android/build.gradle.kts`
- `android/app/build.gradle.kts` (Flavors `dev` / `prod`, release signing configuration, ProGuard)
- `android/app/proguard-rules.pro` (R8 rules for Flutter and plugins)
- `android/app/src/main/AndroidManifest.xml` (Permissions baseline, `android:allowBackup="false"`, no INTERNET)
- `android/app/src/dev/res/values/strings.xml` (Dev app title: `SreerajP Gallery Dev`)
- `android/app/src/prod/res/values/strings.xml` (Prod app title: `SreerajP Image Video Gallery`)

### Core Dart Code (`lib/`)
- `lib/main.dart` (App entry point with Riverpod `ProviderScope`)
- `lib/core/config/app_config.dart` (Immutable `AppConfig` model with fallback)
- `lib/core/config/config_service.dart` (`ConfigService` asset loader)
- `lib/core/config/app_flavor_config.dart` (Flavor reader and environment setup)
- `lib/core/constants/app_constants.dart` (Technical constants)
- `lib/theme/color_schemes.dart` (Light, Dark, and AMOLED True Black palettes)
- `lib/theme/app_theme.dart` (ThemeData builders for all 3 modes)
- `lib/providers/theme_provider.dart` (Theme mode state management)
- `lib/l10n/app_en.arb` (English ARB localization source)
- `lib/l10n/app_ml.arb` (Malayalam ARB localization)
- `lib/screens/home_screen.dart` (Baseline initial screen)

### Tests (`test/`)
- `test/core/config/config_service_test.dart` (Unit tests for `AppConfig` and `ConfigService`)
- `test/theme/app_theme_test.dart` (Unit tests for Theme configurations)

### Documentation Tracker
- `docs/implementation_progress.md` (Update Phase 1 checklist and progress)

## 3. Implementation Steps in Detail

1. **Project Initialization & Dependencies:**
   - Create `pubspec.yaml` declaring `flutter_riverpod`, `go_router`, `package_info_plus`, `intl`, and `flutter_localizations`.
   - Ensure zero prohibited dependencies (no HTTP, no cloud SDKs, no trackers).
   - Set up `l10n.yaml` with synthetic package output.

2. **Android Flavor & Signing Setup:**
   - Configure `android/app/build.gradle.kts` with `flavorDimensions += "environment"`.
   - Add `dev` flavor (`applicationIdSuffix = ".dev"`, `resValue("string", "app_name", "SreerajP Gallery Dev")`).
   - Add `prod` flavor (`resValue("string", "app_name", "SreerajP Image Video Gallery")`).
   - Wire `android/key.properties` loading for release signing with safety guards.
   - Configure `android/app/proguard-rules.pro` with keep rules.
   - Set up `AndroidManifest.xml` with `android:allowBackup="false"` and offline permissions.

3. **Core Configuration Layer:**
   - Create `assets/config/app_config.json` containing app identity metadata.
   - Create `lib/core/config/app_config.dart` with immutable `AppConfig`, `fromJson`, and safe `fallback`.
   - Create `lib/core/config/config_service.dart` with asset loading and version verification.
   - Create `lib/core/config/app_flavor_config.dart` reading `appFlavor` / `FLUTTER_APP_FLAVOR`.

4. **Design System & Theme Engine:**
   - Define color schemes for Light, Dark, and AMOLED True Black (`#000000` pure black background).
   - Create `lib/theme/app_theme.dart` configuring Material 3 `ThemeData` with customized cards, app bar, navigation bar, and color schemes.
   - Create Riverpod `themeModeProvider` allowing switching between System, Light, Dark, and AMOLED.

5. **Localization Baseline:**
   - Create `lib/l10n/app_en.arb` with baseline keys for app title, theme options, settings, and common actions.
   - Create `lib/l10n/app_ml.arb` with Malayalam equivalents.

6. **Entry Point & Baseline Screen:**
   - Wire `main.dart` with `runApp(ProviderScope(child: GalleryApp()))`.
   - Build a clean initial screen displaying flavor, loaded config values, and theme toggling to verify Phase 1.

7. **Testing & Verification:**
   - Run `flutter pub get`.
   - Run `flutter gen-l10n`.
   - Run `flutter analyze` to ensure zero warnings or errors.
   - Run `flutter test` to ensure all tests pass.

## 4. Verification Plan

### Automated Tests
- `flutter analyze`
- `flutter test`

### Flavor Verification
- Verify flavor definitions in Gradle build files.
- Verify `pubspec.yaml` syntax, asset bundling, and localization generation.
