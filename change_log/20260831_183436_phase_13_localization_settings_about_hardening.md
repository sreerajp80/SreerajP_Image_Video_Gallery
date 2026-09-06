# Change Log — Phase 13: Localization, Settings, About Screen & Hardening

**Date:** 2026-08-31
**Implements:** [plans/20260831_172640_phase_13_localization_settings_about_hardening.md](../plans/20260831_172640_phase_13_localization_settings_about_hardening.md)
**Plan status:** completed

---

## 1. What this change does

Phase 13 finishes the app: the user can now pick a language, the app remembers
how they like it, the About screen is driven by config alone, and text the app
did not write is laid out the way it actually reads. Two real defects found on
the way were fixed, and the release build was verified end to end.

---

## 2. What the plan expected, and what was actually found

The plan's first step was "create complete ARB files". Reading the code first
showed that step was already done in earlier phases: both files held 749 keys
with no gaps and full `@` descriptions. So the work went to the parts that were
genuinely missing — direction handling, the two screens, language selection and
preference storage — plus the correctness fixes below.

Three things came out differently from the plan, all noted here rather than
quietly absorbed:

1. **`lib/widgets/media/media_grid_tile.dart` was not changed.** The plan listed
   it as a place showing a file name. It shows no text at all. The file name is
   shown in the viewer's top bar and in the details sheet instead, so those two
   were wrapped in its place.
2. **A new test helper and a new provider test file were added.** A widget test
   runs in fake time, so real file writes inside one never finish. The screen
   test uses an in-memory store, and the write-through behaviour is proved in a
   plain async provider test.
3. **A ProGuard rule had to be added.** The release build failed on missing Play
   Core classes. See section 5.

---

## 3. New files

| File | What it is |
|---|---|
| `lib/core/text/text_direction.dart` | `detectTextDirection`, a pure function following the Unicode first-strong rule. Digits, punctuation, symbols and emoji are neutral and skipped, so a note opening with a number or a smiley still takes its direction from the first real word. Returns `null` when there is nothing to go on. |
| `lib/widgets/common/adaptive_directionality.dart` | `AdaptiveDirectionality`, which lays a child out in the direction its text reads in, keeping the ambient direction when the text is neutral. |
| `lib/models/settings/app_settings.dart` | Immutable `AppSettings`: theme, language code, grid columns, memories row, delete confirmation. Reads field by field, so one bad value cannot cost every other preference. |
| `lib/services/settings/app_settings_service.dart` | Keeps preferences in one JSON file written through `AtomicSaver`. Never throws at the caller. |
| `lib/providers/settings_providers.dart` | `appSettingsProvider` and the derived `localeProvider`, `confirmDestructiveProvider`, `showFlashbacksProvider`, `appConfigProvider`. |
| `lib/screens/settings/settings_screen.dart` | The real Settings screen. |
| `lib/screens/settings/about_screen.dart` | The config-driven About screen. |
| `test/helpers/recording_settings_service.dart` | In-memory settings store for widget tests. |
| Six new test files | Direction detector, directionality wrapper, settings model, settings store, settings providers, and the two screens. |

## 4. Changed files

| File | Change |
|---|---|
| `lib/main.dart` | Loads the settings before the first frame and seeds the provider through a `ProviderScope` override, so the app never flashes the wrong theme or language. Sets `locale` on `MaterialApp.router`. |
| `lib/providers/theme_provider.dart` | Now a read of the stored preferences rather than a store of its own, so a theme choice survives a restart. |
| `lib/providers/timeline_providers.dart` | The grid density starts at the last one pinched to and saves each new one. |
| `lib/core/routing/app_router.dart` | `/settings` points at the real screen; `/settings/about` added. |
| `lib/core/constants/app_constants.dart` | Added `supportedLocaleCodes` and `appSettingsFileName`. |
| `lib/core/storage/atomic_saver.dart` | `writeString` now encodes as UTF-8. See section 5. |
| `lib/screens/home_screen.dart` | Deleted. Its parts moved into the two new screens. |
| `lib/screens/timeline/timeline_screen.dart` | The memories row is not built at all when the setting is off, rather than built and hidden. |
| `assets/config/app_config.json` | Network policy line corrected. See section 5. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | 30 new keys in each, with `@` descriptions. 779 keys per file, still in step. |
| Eight widget and screen files | `AdaptiveDirectionality` applied to notes and their previews, recognised text, scanned code payloads, tag names, album names, the viewer's file name and every details row, and recent searches. |
| `android/app/proguard-rules.pro` | Added the Play Core rule. See section 5. |
| `docs/implementation_progress.md` | Phase 13 marked complete with its checklist. |

---

## 5. Three fixes worth naming

**The About screen was claiming something untrue.** `app_config.json` said
`"Network Policy": "100% Offline (Zero INTERNET permission)"`. That stopped
being true in Phase 11: the app does declare `INTERNET`, for local Wi-Fi
transfer. It now says there is no remote server, no account and no analytics,
and that internet access is used only to reach another phone on the user's own
Wi-Fi, from the transfer screen. A privacy claim that oversells itself is worse
than no claim.

**`AtomicSaver.writeString` would have destroyed Malayalam text.** It encoded
with `String.codeUnits`, which packs UTF-16 units into single bytes and throws
away everything above 255. It was unused in `lib/` — the only reason this had
not bitten yet — and Phase 13 was about to add a second JSON store. It now uses
`utf8.encode`, with a test that round-trips Malayalam, Arabic and an emoji.

**The release build was broken before this change and nobody had run it.** R8
failed on missing `com.google.android.play.core.**` classes, referenced by the
Flutter embedding's deferred-component support. The app has no deferred
components. The fix is a `-dontwarn` rule, not the Play Core dependency: that
SDK is proprietary, and hard rule 1 allows open source only. The rule carries a
comment saying so, so nobody later "fixes" it by adding the dependency.

---

## 6. Choices made, and why

- **No new package.** Preferences reuse the one-JSON-file pattern the recent
  searches already use. `shared_preferences` was deliberately not added.
- **Not secure storage.** Theme, language, grid density and two switches are not
  secrets. The vault keeps its own settings in `flutter_secure_storage`, and
  that was left alone.
- **A failed save is not an error.** The screen is already correct; a lost write
  costs the user that value on the next launch and nothing sooner. An error
  dialog over a theme switch would be worse.
- **The email row goes through the existing `IntentChannel`.** Not a channel of
  its own, so the check on outgoing schemes stays in one place.
- **Directionality is applied only to text the app did not write.** Translated
  labels already follow the chosen language, and second-guessing them would be
  wrong.

---

## 7. Verification

| Check | Result |
|---|---|
| `flutter gen-l10n` | Regenerated; both locales carry all 779 keys. |
| `dart format .` | 444 files, 7 changed. |
| `flutter analyze` | No issues found. |
| `flutter test` | 1793 tests passing, up from 1713. |
| Release build | `flutter build apk --flavor prod --release --obfuscate --split-debug-info=... --split-per-abi` succeeded for armeabi-v7a, arm64-v8a and x86_64, with debug symbols written for all three. |

The deprecated `RadioListTile.groupValue` API surfaced during analysis and was
replaced with a `RadioGroup` ancestor, keeping analysis at zero warnings.

---

## 8. Known, out of scope

The release build prints warnings that four plugins want `compileSdk 36` while
the project pins 35. This predates Phase 13, the build succeeds, and the SDK
level is fixed by project rules, so it was left alone. It is worth a decision of
its own before the next dependency bump.

No keystore is present in this working copy, so the verification build is
unsigned. Signing is a release-time step and is covered by
`docs/release_process.md`.
