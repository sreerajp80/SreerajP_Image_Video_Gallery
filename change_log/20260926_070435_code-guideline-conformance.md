# Change log: Make the app code follow the guidelines strictly

**Date:** 2026-09-26  
**Plan:** [plans/20260926_062415_code-guideline-conformance.md](../plans/20260926_062415_code-guideline-conformance.md)  
**Status of the plan:** completed (all four phases).

Decisions used (approved by the user): all phases; D2 = no bundled fonts, use a
`fontFamilyFallback` chain; D3 = keep `../` imports in `test/` as a written exception;
D4 = replace `package_info_plus` with a Kotlin method channel.

---

## Result

- `flutter analyze`: no issues.
- `dart format`: 0 files changed.
- `flutter test`: **1,957 tests, all pass** (1,896 before).
- `flutter build apk --flavor dev --debug`: builds (checks the new Kotlin handler and the Gradle change).
- `lib/` has no `print` or `debugPrint`. `pubspec.lock` has no `http` package.

---

## Phase A — quick fixes

**Localization**
- `lib/l10n/app_ml.arb`: added the 7 missing keys (`tabTimeline`, `tabFolders`, `tabAlbums`,
  `foldersTitle`, `foldersEmpty`, `foldersEmptyBody`, `folderItemCount`).
- `lib/l10n/app_en.arb`, `app_ml.arb`: new keys `tooltipShowPassword`, `tooltipHidePassword`,
  `labelDistanceKm`, `compareBadgeLabel`, the eight `aboutDetail<Key>` labels, `madeWithLove`,
  `madeWithLoveA11y`.
- Tooltips added: back button on the compare screen (now a `BackButton`), play/pause in the vault
  viewer, show/hide password in the backup dialog.
- Hard-coded strings removed: the km chips in `media_privacy_sheet.dart` (number formatted per
  locale), the `A:`/`B:` badges in `curtain_comparison_view.dart` (now "Photo A: …"), and the
  `MaterialApp.title` literal (now `onGenerateTitle`).
- New `lib/core/l10n/formatting_locale.dart`; used by `restore_preview_sheet.dart` (which had no
  locale at all), `timeline_date_header.dart` and `media_details_sheet.dart`.
- `main.dart`: explicit `localeResolutionCallback` that falls back to English (§8.4).

**Errors and logging (G7, G8)**
- New `lib/core/logging/app_logger.dart`: six levels, output through `dart:developer`, no package,
  no log file. `trace`/`debug` are silent outside the dev flavor. Outside the dev flavor an
  `error` object is reduced to its type name, so an exception text with a file path cannot leak.
- New `lib/widgets/common/safe_error_fallback.dart`.
- `main.dart`: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and a release-only
  `ErrorWidget.builder`. Two silent `catch (_) {}` blocks now log.
- `app_flavor_config.dart`, `config_service.dart`: `debugPrint` replaced with `AppLogger`.

**About screen (G4, G5)**
- `lib/core/config/app_config.dart`: new `LocalizedText`; `appName`, `description` and `details`
  values are string-or-locale-map.
- `assets/config/app_config.json`: `{"en","ml","sa"}` maps, `lowerCamelCase` detail keys.
- `lib/screens/settings/about_screen.dart`: resolves values for the current language, labels
  from `aboutDetail<Key>` (raw key as last resort), ends with the badge.
- New `lib/widgets/made_with_love.dart` (the fixed badge from `guideline.md` §1.7).

**Build (G6)**
- `android/app/build.gradle.kts`: `bundle { language { enableSplit = false } }`.

**Tests**
- New `test/core/logging/app_logger_test.dart`, `test/core/l10n/formatting_locale_test.dart`,
  `test/l10n/translation_parity_test.dart` (key parity, placeholders, no copied English outside an
  allow-list, `{heart}` marker, label length for prefixed keys, `app_config.json` parity).
- Rewrote `test/core/config/config_service_test.dart` and
  `test/screens/settings/about_screen_test.dart` for the new format; added Malayalam and badge
  tests.
- `test/screens/compare/photo_compare_screen_test.dart`: badge text is now "Photo A: …".

## Phase B — layer fixes

- New `lib/services/privacy/privacy_export_service.dart`: reads the original, cleans it
  (EXIF scrub or GPS shift), then shares it or writes a temp file, publishes it to MediaStore
  and **deletes the temp file** (the old code left it in the cache). Returns a
  `PrivacyExportResult`; never throws.
- `lib/providers/privacy_providers.dart`: `privacyExportServiceProvider`.
- `lib/widgets/privacy/media_privacy_sheet.dart`: four handlers now call the service. No
  `dart:io`, `path_provider`, repository or channel use is left in the widget. Snackbar messages
  are unchanged.
- `lib/providers/viewer_providers.dart`: new `ViewerActions` (`toggleFavorite`, `moveToTrash`,
  `restoreFromTrash`) and `viewerActionsProvider`. `media_viewer_screen.dart` uses it.
- `lib/providers/vault_providers.dart`: new `VaultOpenedItem`, `VaultViewerActions`
  (`open`, `discardWorkingFile`) and `vaultViewerActionsProvider`.
  `vault_viewer_screen.dart` uses it and no longer imports the repository. The free function
  `unawaitedShred` was removed. The actions object is read in `initState`, so `dispose` never
  touches `ref`. A decrypted video file is now also shredded if the screen closes while the file
  is still being decrypted.
- Tests: new `test/services/privacy/privacy_export_service_test.dart`,
  `test/providers/vault_providers_test.dart`; new `ViewerActions` group in
  `test/providers/viewer_providers_test.dart`.

## Phase C — `http` removed

- `pubspec.yaml`: removed `package_info_plus`. `pubspec.lock` lost `package_info_plus`,
  `package_info_plus_platform_interface`, `http` and `http_parser`.
- New Kotlin `android/app/src/main/kotlin/in/sreerajp/imgvidgal/device/AppInfoChannelHandler.kt`
  on channel `in.sreerajp.imgvidgal/app_info` (reads this app's own `PackageManager` record; no
  permission, no network). Registered in `MainActivity.kt`.
- `lib/core/constants/app_constants.dart`: `appInfoChannelName`.
- New `lib/services/device/app_info_service.dart` (`AppInfo`, `AppInfoService`; returns null
  instead of throwing).
- `lib/providers/settings_providers.dart`: `appInfoServiceProvider`; `appConfigProvider` passes
  it to `ConfigService.loadAndVerify`.
- `lib/providers/backup_providers.dart`: `appVersionProvider` uses the service.
- Test: new `test/services/device/app_info_service_test.dart`.

## Phase D — Sanskrit (G1, G2, G3) and fonts

- New `lib/l10n/app_sa.arb`: all 1,042 keys, `"@@locale": "sa"`. Written using the §8.5
  glossary. Before merging, a script checked placeholders, plural branches, allowed characters
  and the §8.5.1 Hindi markers. Seven values were reworded because inflected forms of
  `सङ्ग्रह` contain the letters `रहे`/`रहा`, which the substring gate treats as Hindi.
- New key `languageSanskrit` (`संस्कृतम्`) in all three files; `settingsLanguageSubtitle` now
  lists Sanskrit.
- New `lib/core/l10n/sanskrit_fallback_delegates.dart` (Material, Cupertino and Widgets delegates
  answering `sa` with English framework text, plus `appLocalizationsDelegates`). `main.dart` uses it.
- `lib/core/constants/app_constants.dart`: `supportedLocaleCodes` includes `sa`;
  `lib/models/settings/app_settings.dart` doc comment updated.
- `lib/screens/settings/language_settings_screen.dart`: `संस्कृतम्` option.
- `lib/theme/app_theme.dart`: `fontFamilyFallback` = Noto Sans Malayalam, Noto Sans Devanagari.
- `assets/config/app_config.json`: `sa` values; `languages` row now says all three languages.
- Tests: new `test/l10n/sanskrit_hindi_marker_test.dart` (Dart port of the §8.5.1 gate with its
  self-test) and `test/l10n/sanskrit_locale_test.dart` (date picker and dialog open under `sa`;
  About screen renders in Sanskrit with the badge).

**Needs native-reader review:** every Sanskrit value in `lib/l10n/app_sa.arb` and the `sa`
values in `assets/config/app_config.json`. Terms coined for this app that are not in the §8.5.4
glossary include: चित्रशाला (gallery), सङ्कलनम् (album), चिह्नम् (tag), अवकरपात्रम् (trash),
गुप्तकोशः (vault), गूढाङ्कः (PIN), गूढशब्दः (password), माध्यमम् (media), द्विरुक्तम् (duplicate),
छायाग्राहकः (camera), चित्राणुः (pixel), स्थानान्तरणम् (transfer), दूरवाणीयन्त्रम् (phone),
जलचिह्नम् (watermark). Recorded as gap G9.

## Docs

- `docs/known_gaps.md`: G1–G8 moved to Resolved; new open gaps G9–G15; new "Accepted exceptions"
  section (test `../` imports, technical values equal to English, no bundled fonts).
- `CLAUDE.md`, `AGENTS.md`: Sanskrit "current state" line; `AppLogger` rule.
- `README.md`, `docs/Project_Idea.md`: three languages.
- `docs/architecture.md`: init sequence, error handling, localization, fonts, About screen,
  logging, `app_info` channel, test layout and critical tests, risks.
- `docs/security.md`: logging controls, M2 supply-chain row, open risks.
- `docs/dependencies.md`: `package_info_plus` moved to "considered and not used" with the reason;
  `logger` listed as not needed.
- `docs/project_structure.md`: new folders and files; `app_sa.arb`; `test/l10n/`; the test
  import exception.
- `docs/release_process.md`: localization checklist rewritten for three languages.
- `docs/implementation_progress.md`: new dated entry. `docs/feature_improvements_and_standout_features.md`:
  dated note on its Sanskrit correction row.

## Not done / found along the way

- **G15 (new):** `lib/models/help/help_topic.dart` imports `material.dart` (`IconData`) and takes
  `AppLocalizations`, which breaks the model-layer rule. Found while updating the docs; outside
  this plan's scope, so it is recorded, not changed.
- The plan listed a separate controller for the privacy sheet. The widget calls
  `privacyExportServiceProvider` directly instead; the service already returns a result, and a
  controller would only have passed it through.
- `lib/core/constants/build_date.g.dart` changed because the Gradle build regenerates it.
- Other open items (Sanskrit review, `app_language` storage key, key prefixes, three-locale
  screen tests, provider tests, one Malayalam glossary word) are in `docs/known_gaps.md` §2.
