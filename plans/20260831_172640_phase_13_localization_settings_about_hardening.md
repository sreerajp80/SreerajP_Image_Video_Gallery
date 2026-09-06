# Phase 13 — Localization, Settings, About Screen & Hardening

**Status:** completed

**Date:** 2026-08-31
**Implements:** [docs/implementation_plan.md](../docs/implementation_plan.md) — Phase 13

---

## 1. What Phase 13 asks for

From the implementation plan:

1. Create complete ARB localization files for English (`app_en.arb`) and Malayalam (`app_ml.arb`).
2. Integrate `AdaptiveDirectionality` and `detectTextDirection` across all text views.
3. Build a Settings screen and a dynamic About screen consuming `app_config.json`.
4. Run the full test suite, static analysis, and a release build check with `--obfuscate`.

---

## 2. What is already done, and what is missing

I read the code before planning. The state today:

| Item | State |
|---|---|
| `app_en.arb` / `app_ml.arb` | **Done.** 749 keys each, no gaps, every key has an `@` description. Only 14 values are the same in both files, and all of them are technical labels (GIF, RAW, HD, A4, 16:9) that should not be translated. |
| Locale switching | **Missing.** `MaterialApp.router` never sets `locale`, so the app always follows the phone. The user cannot pick a language. |
| `detectTextDirection` / `AdaptiveDirectionality` | **Missing.** Neither exists anywhere in `lib/`. |
| Settings screen | **Missing.** The `/settings` route points at `lib/screens/home_screen.dart`, a Phase 1 scratch screen that mixes theme buttons, a dev scan panel, and About rows in one list. |
| About screen | **Missing as a screen.** `/settings/about` is in `docs/architecture.md` but is not a route. |
| Settings persistence | **Missing.** `themeProvider` starts at `system` on every launch and never saves. Grid density is also forgotten on every launch. |
| `assets/config/app_config.json` | **Stale.** It says `"Network Policy": "100% Offline (Zero INTERNET permission)"`. That stopped being true in Phase 11: the app does declare `INTERNET`, for local Wi-Fi transfer only. |
| `AtomicSaver.writeString` | **Latent bug.** It encodes with `String.codeUnits`, which cuts every character down to one byte. Any Malayalam text written through it would be silently corrupted. |

So Phase 13's real work is items 2, 3 and 4, plus locale switching, settings persistence, and the two correctness fixes above.

---

## 3. Files to be changed

### New files

| File | What it is |
|---|---|
| `lib/core/text/text_direction.dart` | `detectTextDirection(String)` — pure function, no Flutter widgets. |
| `lib/widgets/common/adaptive_directionality.dart` | `AdaptiveDirectionality` widget that wraps a child in the direction detected from a piece of text. |
| `lib/models/settings/app_settings.dart` | Immutable `AppSettings` model (`const`, `copyWith`, `toJson`, `tryFromJson`, `defaults`). |
| `lib/services/settings/app_settings_service.dart` | Loads and saves the settings JSON file. Never throws at the caller. |
| `lib/providers/settings_providers.dart` | `appSettingsProvider` (load + save), `localeProvider`, `appConfigProvider`. |
| `lib/screens/settings/settings_screen.dart` | The real Settings screen. |
| `lib/screens/settings/about_screen.dart` | Config-driven About screen at `/settings/about`. |
| `test/core/text/text_direction_test.dart` | Direction detection tests. |
| `test/models/settings/app_settings_test.dart` | Model round-trip and bad-input tests. |
| `test/services/settings/app_settings_service_test.dart` | File load/save, missing file, corrupt file. |
| `test/widgets/common/adaptive_directionality_test.dart` | Widget test for the wrapper. |
| `test/widgets/settings/settings_screen_test.dart` | Widget test: theme and language rows render and switch. |
| `test/widgets/settings/about_screen_test.dart` | Widget test: `details` rows render straight from config. |

### Changed files

| File | Change |
|---|---|
| `lib/main.dart` | Read settings before `runApp`, set `locale` on `MaterialApp.router`, take theme from settings. |
| `lib/providers/theme_provider.dart` | Becomes a thin read of `appSettingsProvider` so theme is saved; keeps the `ThemePreference` type. |
| `lib/providers/timeline_providers.dart` | Grid density seeds from saved settings and writes back on change. |
| `lib/core/routing/app_router.dart` | `/settings` → `SettingsScreen`; add `/settings/about` → `AboutScreen`; add `kRouteAbout`. |
| `lib/core/constants/app_constants.dart` | Add `appSettingsFileName`, `supportedLocaleCodes`. |
| `lib/core/storage/atomic_saver.dart` | `writeString` encodes as UTF-8 instead of `codeUnits`. |
| `lib/screens/home_screen.dart` | **Deleted.** Its parts move to the two new screens. |
| `assets/config/app_config.json` | Correct the network policy line; add `Email` and `AI used` rows. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | Add the new Settings/About keys (see §4.5). |
| `lib/widgets/notes/markdown_view.dart` | Wrap note body in `AdaptiveDirectionality`. |
| `lib/widgets/notes/notes_preview_tile.dart` | Same for the note preview. |
| `lib/screens/ocr/extracted_text_screen.dart` | Same for recognised text. |
| `lib/widgets/scan/scanned_code_card.dart` | Same for a scanned payload. |
| `lib/widgets/tags/tag_chip.dart` | Same for a tag name. |
| `lib/widgets/albums/album_card.dart` | Same for an album name. |
| `lib/widgets/media/media_grid_tile.dart` | Same for a file name label. |
| `lib/widgets/search/recent_search_list.dart` | Same for a stored search term. |
| `docs/implementation_progress.md` | Mark Phase 13 complete with its task checklist. |

---

## 4. The plan in detail

### 4.1 `detectTextDirection` and `AdaptiveDirectionality`

**The issue.** Malayalam and English are both left-to-right, but the app is meant to show
whatever text the user typed or the OCR read, and that text can be in any script. A note,
an OCR result, or a scanned QR payload can hold Arabic or Hebrew. Today every one of those
is forced into the app's own direction, so such a line reads backwards.

**The fix.** One pure function and one small widget.

`detectTextDirection(String text)` walks the string and returns:

- `TextDirection.rtl` if the first strongly-directional character is Arabic, Hebrew, Thaana,
  Syriac, or one of the Arabic presentation ranges;
- `TextDirection.ltr` if it is anything else strongly-directional (Latin, Malayalam — digits
  and punctuation are skipped as neutral);
- `null` if the text has no strong character at all (empty, only spaces, only punctuation),
  so the caller can keep the app's own direction.

`AdaptiveDirectionality({required String text, required Widget child, TextDirection? fallback})`
wraps `child` in a `Directionality` using that result, falling back to the ambient direction
when the text is neutral. It adds no layout and no padding.

Both are placed exactly where `docs/project_structure.md` says: the detector under `core/`,
the widget under `widgets/common/`.

**Where it is applied.** Only where the text comes from the user or from a file — never on
translated UI labels, which already follow the locale. That is the eight widget files listed
above: notes body and preview, OCR text, scanned code payload, tag name, album name, media
file name, and recent search term. Plus the About screen's `details` values.

### 4.2 `AppSettings` model and its store

**The issue.** Theme and grid density reset on every launch, and there is no way to choose a
language. There is no place at all to keep a user preference.

**The fix.** An immutable model:

```
AppSettings {
  ThemePreference theme;      // system | light | dark | amoled
  String? localeCode;         // null = follow the phone; 'en' or 'ml'
  int gridColumns;            // 1..5
  bool showFlashbacks;        // the timeline memories row
  bool confirmDestructive;    // ask again before a delete or overwrite
}
```

`tryFromJson` reads field by field and falls back per field, so a hand-edited or
half-written file can never crash the app — the same rule `AppConfig` already follows.
`gridColumns` is clamped to 1..5 on read. An unknown `localeCode` becomes `null`.

`AppSettingsService` stores it in one small JSON file (`app_settings.json`) in the app
support directory, written through `AtomicSaver`. This copies the pattern
`SearchHistoryService` already uses, so it needs **no new package** — `shared_preferences`
is deliberately not added. A failed read means "defaults"; a failed write is dropped with a
comment saying why. Settings are a convenience, not data worth failing a launch over.

This is not secure storage on purpose: none of these five values is a secret. Vault
settings stay where they are, in `flutter_secure_storage`.

**Startup.** `main()` loads the settings once before `runApp` and seeds the provider through
a `ProviderScope` override, so the first frame already has the right theme and language and
the app does not flash the wrong one.

### 4.3 Settings screen

`lib/screens/settings/settings_screen.dart`, at `/settings`. A plain `ListView` of grouped
rows:

- **Appearance** — theme (System / Light / Dark / AMOLED), grid density (1–5 slider),
  show flashbacks (switch).
- **Language** — System default / English / Malayalam. Changing it rebuilds the app in the
  new language immediately; nothing needs a restart.
- **Safety** — confirm before destructive actions (switch). Wired to hard rule 4.
- **Storage & privacy** — a read-only line stating the app has no remote server and that
  `INTERNET` exists only for the local transfer screen. Links to the vault settings and the
  backup screen.
- **Developer** — the existing `MediaScanPanel`, shown on the `dev` flavor only, exactly as
  today.
- **About** — one row that opens `/settings/about`.

Every change writes through `appSettingsProvider`, which saves and then updates state. No
file I/O in the widget; that keeps the layer rule.

### 4.4 About screen

`lib/screens/settings/about_screen.dart`, at `/settings/about`. It follows
`docs/guidelines/guideline.md §1.6` to the letter:

- fixed top rows: `appName` + `description`, then `version` + `build`;
- then a loop over `config.details.entries`, one `ListTile` each, skipping any entry whose
  key or value is empty after trimming;
- no hard-coded field names — adding a key to the JSON is the only change needed to make a
  new row appear;
- a row whose key is `email` (any case) opens `mailto:` on tap;
- each value is wrapped in `AdaptiveDirectionality`;
- config load failure shows the `AppConfig.fallback` values, not an error dialog.

`assets/config/app_config.json` is corrected at the same time. `"Network Policy"` currently
claims "Zero INTERNET permission", which has been wrong since Phase 11. It becomes: *"No
remote server. INTERNET permission is used only for device-to-device transfer on your own
Wi-Fi."* This matters — an About screen that oversells its privacy is worse than none.

### 4.5 New localization keys

About 30 new keys, added to **both** ARB files with `@` descriptions, covering: the settings
section headings, language row and its three choices, grid density, flashbacks toggle,
destructive-action toggle, the privacy summary line, the About row, the app-name/description
labels, the build label, and the mail-open failure message. Malayalam values are real
translations, not copies. `flutter gen-l10n` is run afterwards.

### 4.6 Hardening

1. `AtomicSaver.writeString` switches from `String.codeUnits` to `utf8.encode`. As written it
   truncates every character to one byte, so the first Malayalam string saved through it
   would be destroyed. It is unused in `lib/` today, which is the only reason this has not
   bitten yet — and exactly why it must be fixed before Phase 13 adds a second JSON store.
   A test with Malayalam text is added.
2. The full check run: `flutter gen-l10n`, `dart format .`, `flutter analyze` (must be zero
   issues), `flutter test` (all must pass), and
   `flutter build apk --flavor prod --release --obfuscate --split-debug-info=... --split-per-abi`
   to confirm the release build and R8 rules still hold.

---

## 5. Tests to be added

| Test | Covers |
|---|---|
| `text_direction_test.dart` | English → ltr, Malayalam → ltr, Arabic/Hebrew → rtl, digits-only → null, empty → null, mixed leading-neutral text. |
| `app_settings_test.dart` | Defaults, `copyWith`, JSON round trip, out-of-range columns clamped, unknown locale dropped, wrong types ignored. |
| `app_settings_service_test.dart` | Missing file → defaults, corrupt file → defaults, save then load round trip, Malayalam locale survives the trip. |
| `adaptive_directionality_test.dart` | Wraps in rtl for Arabic, ltr for Malayalam, keeps the ambient direction for neutral text. |
| `settings_screen_test.dart` | Rows render, theme change is stored, language change is stored. |
| `about_screen_test.dart` | Every `details` entry becomes a row; empty entries are skipped; a fallback config still renders. |
| `atomic_saver_test.dart` (extended) | `writeString` round-trips Malayalam text. |

---

## 6. Rules this change is checked against

- **No new package.** Settings reuse the existing JSON-file pattern.
- **No network.** Nothing here opens a socket; the About screen's policy line is corrected to
  describe the real state rather than an ideal one.
- **Localization rule.** Every new user-visible string is an ARB key with an `@` description
  in both `en` and `ml`.
- **Layer rule.** Screens read providers; providers call the service; the service does the
  file I/O. No `BuildContext` in the service.
- **Immutability.** `AppSettings` is `const` with `copyWith`.
- **Never crash on bad input.** Missing, corrupt, or hand-edited settings and config files
  both fall back to safe defaults.

---

## 7. Out of scope

- No change to the vault's own settings or its secure storage.
- No new media features; Phase 13 is language, preferences and verification only.
- No third language. Only `en` and `ml` are supported, as specified.
