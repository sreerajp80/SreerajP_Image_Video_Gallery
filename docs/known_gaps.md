# Known Gaps — SreerajP Image Video Gallery

This file lists what the shared guidelines require but the app does not do yet. Read it before
you plan work on localization, the About screen, error handling or logging. Each gap names the
guideline rule it breaks. Fixing a gap needs its own plan in `plans/`.

**Date:** 2026-11-05 (Sanskrit review applied; all fixes through the 2026-11-02 plans; review against the updated guidelines 2026-11-01; first written 2026-09-26)  
**Scope:** App code, config and docs, checked against the `docs/guidelines` submodule at `644faee`,
for the profiles and channels in [PROJECT_PROFILE.md](PROJECT_PROFILE.md). The working tree was
reviewed as it stood, with uncommitted changes.  
**Result:** G1–G50 fixed. No gap open. The owner's phone checks in §2 still apply before release.  
**Depth:** see §5 for what this review did not check.

### Read first
- [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md)
- [architecture.md](architecture.md)
- [guidelines/flutter_project_engineering_standard.md](guidelines/flutter_project_engineering_standard.md)
- [guidelines/guideline.md](guidelines/guideline.md)

---

## 1. Resolved

All fixed on 2026-09-26 by
[plans/20260926_112415_code-guideline-conformance.md](../plans/20260926_112415_code-guideline-conformance.md).

| # | Gap | Fix |
|---|---|---|
| G1 | No Sanskrit | `lib/l10n/app_sa.arb` added with every key; `sa` is in `supportedLocales`. The Sanskrit still needs a fluent reader's review — see G9. |
| G2 | No Sanskrit fallback delegates | `lib/core/l10n/sanskrit_fallback_delegates.dart`, registered first in `main.dart`. A widget test opens a date picker and a dialog under `sa`. |
| G3 | No Sanskrit option in the language picker | `संस्कृतम्` added to the Settings language screen; `sa` added to `AppConstants.supportedLocaleCodes`. |
| G4 | No "Made with ❤️ from India" badge | `lib/widgets/made_with_love.dart`, the last item on the About screen. |
| G5 | `app_config.json` values were plain strings | Display values are now `{"en","ml","sa"}` maps. `details` keys are `lowerCamelCase`, and row labels come from the `aboutDetail<Key>` ARB keys. |
| G6 | App Bundle language split was on | `bundle { language { enableSplit = false } }` in `android/app/build.gradle.kts`. |
| G7 | No global error boundaries | `FlutterError.onError`, `PlatformDispatcher.instance.onError` and a release-only `ErrorWidget.builder` (`SafeErrorFallback`) in `main.dart`. |
| G8 | No logger | `lib/core/logging/app_logger.dart`: six levels, silent `trace`/`debug` outside the dev flavor, error objects reduced to their type outside the dev flavor. The two `debugPrint` calls are gone. |

G16 (device transfer could copy app data) was fixed on 2026-11-01 by
[plans/20261101_184328_block-device-transfer-g16.md](../plans/20261101_184328_block-device-transfer-g16.md):
`data_extraction_rules.xml` excludes all app data. No real phone transfer has been tested.

G45 (an upgrade left old photos out of search) was fixed on 2026-11-02 by
[plans/20261102_124557_search-index-backfill.md](../plans/20261102_124557_search-index-backfill.md):
a test first proved the bug, then a new v4 migration added the missing search rows.

Batch 2 of [plans/20261102_131432_strict-guideline-adherence.md](../plans/20261102_131432_strict-guideline-adherence.md)
fixed nine gaps on 2026-11-02: G14 (Malayalam "System default" now uses the glossary word), G15
(`HelpTopic` is plain data; icon and text moved to `HelpTopicPresentation` in `lib/widgets/help/`),
G20 (`docs/security.md` §1.1 baseline and §3.1 entry points), G25 (MIT `LICENSE`; About `license`
row names it), G26 (submodule, CI, store and profile rules in `CLAUDE.md`, `AGENTS.md` and
`workflow_rules.md`), G27 (prod and dev launcher names in `values-ml` and `values-sa`), G29 (file
provider limited to `cache/shared_media/`, checked again in Kotlin), G30 (`implementation_progress.md`
is a living doc; `release_process.md` §9A points to `platform_store_readiness.md`), and G42 (11
Android permissions plus AndroidX's private one, written the same way everywhere). G43 is partly
fixed. Sharing and the launcher names have not been checked on a phone, and no Android build was run.

Batch 3 of the same work, planned in
[plans/20261102_133537_guideline-batch-3-errors-a11y-memory.md](../plans/20261102_133537_guideline-batch-3-errors-a11y-memory.md),
fixed G31–G37 on 2026-11-02:

- **G31:** every `catch` in services and repositories now rethrows, logs, or says why silence
  is safe. `test/tool/catch_policy_test.dart` keeps it that way.
- **G32:** `AppException` is `sealed`, with 19 feature exceptions under `FeatureException`, and
  there are no raw throws.
- **G33:** a refused or failed "open with" shows a message. The logic moved out of `main.dart`.
- **G34:** the five drawing tools have screen-reader labels; crop and mask also have move and
  resize actions.
- **G35:** 48 dp targets, checked by Flutter's own guideline tests.
- **G36:** caches are cleared on memory pressure, and small tiles decode at their shown size.
- **G37:** one localized unit formatter.

The work also found and fixed two real problems:

- If removing metadata or moving the GPS position failed, the original photo, GPS included, was
  shared or saved as the "clean" copy. Now the action fails and nothing goes out.
- The duplicate cleaner and the batch result sheet showed raw exception text.

Not checked on a device: TalkBack, real memory pressure, and an "open with" from a real file
manager.

G47 (closed-source ML Kit inside `mobile_scanner`) was fixed on 2026-11-02 by
[plans/20261102_142047_replace-mlkit-barcode-g47.md](../plans/20261102_142047_replace-mlkit-barcode-g47.md).
Codes are now read by ZXing core (Apache-2.0) in Kotlin, and the pairing camera uses the official
`camera` plugin (CameraX). A first choice, `flutter_zxing`, was dropped because it pulled in `http`.
`test/tool/dependency_policy_test.dart` now checks the whole lock file. Not yet checked: an
Android build, decoding real photos, and pairing by camera on a phone.

On 2026-11-02 the packages were moved to new major versions by
[plans/20261102_184653_dependency-major-upgrade.md](../plans/20261102_184653_dependency-major-upgrade.md):
Riverpod 3, `local_auth` 3, `go_router` 18 and `flutter_lints` 6, with `flutter_secure_storage`
held at 10.3.4 (G49).

**G22 is fixed:** the whole app uses `material_ui` / `cupertino_ui`, guarded by
`test/tool/material_ui_imports_test.dart`.

Not yet checked:
- an Android build;
- the vault on a phone that already holds data, after installing over the old version;
- the look of the screens on a phone.

A second audit on 2026-11-01 found six problems that were never given a number. All six were fixed
by [plans/20261101_202921_guideline-audit-fix-batch-1.md](../plans/20261101_202921_guideline-audit-fix-batch-1.md):
links from other apps could reach private files, WAL was set in a way the standard says fails on
Android, database upgrades had no tests, a prod release could build unsigned, GPS blurring did not
use secure randomness, and three DAO files were not formatted. The link rule, WAL and the signing
check have not yet been tested on a device or in a real build.

The 2026-09-26 plan also fixed problems found in a fresh audit that were not listed here before:
7 Malayalam strings missing, an `http` package pulled in by `package_info_plus` (now removed),
a widget and two screens that called repositories, file I/O or platform channels directly,
3 icon buttons without a tooltip, hard-coded UI strings, and a date shown only in English.
The three checks listed as "not yet checked" (tooltips, label length, ARB parity test) now
have tests or were audited.


The plans [20261102_192913](../plans/20261102_192913_guideline-batch-4-build-data-ci.md) and
[20261102_201827](../plans/20261102_201827_finish-all-pending-guideline-work.md) fixed the rest on
2026-11-02 to 2026-11-04:

| # | Fix |
|---|---|
| G10 | The language is stored in `SharedPreferences` under `app_language` (`system` or a code). An old `localeCode` moves across once. |
| G11 | Every ARB key carries a §8.6 prefix (966 renamed). The length test covers every short label; 40 English labels were shortened; the six long translations were fixed later (G50). |
| G12 | All seven screen test files run in `en`, `ml` and `sa` through `test/helpers/locale_checks.dart`: no overflow, no leaked English, tooltips present. It found a real overflow in the viewer's bottom bar, now fixed. |
| G13 | Sixteen new provider test files. `media_providers` and `media_intent_providers` were already tested under other names. |
| G17, G18 | `PRIVACY.md`, and `privacyPolicy` and `email` rows in `app_config.json`, shown on the About screen. |
| G19 | `targetSdk = 36`. Phone check still due (see §2). |
| G21 | AGP 9.4.1, KGP 2.4.10, Gradle 9.8.0, Flutter 3.47.6 (the owner's versions). The OCR plugin comes from a commit that only replaces `jcenter()`. |
| G23 | `.github/workflows/ci.yml`, checks only. |
| G24 | Every native library in the arm64 release APK is aligned to 16 KB or more. |
| G28 | A "Hide content" setting protects every screen; the vault is always protected. |
| G38 | Schema v5: `CHECK` constraints on new databases, triggers on upgraded ones. |
| G39 | `crypto` and `flutter_secure_storage` pinned exactly; the discontinued `js` package is gone. |
| G40 | The standard's 24 extra lint rules are on. |
| G41 | The viewer, timeline, privacy sheet and compare screen were split; the nine files still over 500 lines have a reason in `architecture.md`. |
| G43 | The three old OCR plans are marked `dropped`, each with its reason. |
| G44 | The 29 unused ARB keys were removed. |
| G46 | No screen or widget imports a service; `test/tool/layer_imports_test.dart` keeps it so. |
| G48 | `AppLogger` reduces an error to its type in every flavor. |
| G49 | `flutter_secure_storage` 11.2.0; no phone held version 9 vault data. |
| G50 | The owner shortened the four long Malayalam labels on 2026-11-05 ([plan](../plans/20261105_075808_shorten-malayalam-labels-g50.md)). The length test now has no exceptions in any language. |
| G9 | The owner reviewed all 1,078 Sanskrit strings (ARB and `app_config.json`) on 2026-11-05 and corrected 145 ([plan](../plans/20261105_073420_apply-sanskrit-review.md)). New or changed Sanskrit needs the same review. |

---

## 2. Still open

No gap is open. New gaps get the next number (G51).

**Still to check on a phone (owner):** every main screen in light and dark with gesture and button
navigation (targetSdk 36 ends the edge-to-edge opt-out), OCR on one photo, the "Hide content"
switch, and creating and unlocking a vault.

---

## 3. Accepted exceptions

These break the letter of a rule on purpose. Each has a reason.

- **Relative imports in `test/`.** Ten test files import shared fakes with `../` paths. Dart
  cannot import a file under `test/` with a `package:` URI, so this is the standard Dart
  practice. `lib/` uses `package:` imports only.
- **Technical values equal to English in `ml` and `sa`.** File formats (`GIF`, `RAW`, `SVG`,
  `HD`, `ISO`), aspect ratios, `A4`, placeholder-only strings and the language endonyms. The list
  lives in `sameAsEnglishAllowed` in `test/l10n/translation_parity_test.dart`.
- **Sanskrit words that contain a Hindi marker's letters.** The language pack's gate matches
  `क्या` and `रहा` anywhere in the text. Eight reviewed Sanskrit strings contain them inside a word
  (`अशक्या`, `सङ्ग्रहान्वेषणम्`). Each key and token is named in `sanskritInsideMarker` in
  `test/l10n/sanskrit_hindi_marker_test.dart`; any other marker in those lines still fails. A note
  asks the guideline owner to match these tokens as whole words
  ([plan §8](../plans/20261105_073420_apply-sanskrit-review.md)).
- **Freehand drawing needs touch.** Markup and hide (redaction) strokes cannot be drawn with a
  screen reader. Both surfaces say so in their hint and point to the controls panel, which is
  fully accessible. Crop and masks can be moved and resized with screen-reader actions.
- **No bundled fonts.** Android 7+ ships Noto fonts for Malayalam and Devanagari. The theme names
  them in `fontFamilyFallback`. Rendering must still be checked on a clean device for every
  release (engineering standard §8.3.3; see [release_process.md](release_process.md)).

---

## 4. Out of scope

- iOS, Windows, macOS, Linux and web. The app is Android only.
- RTL layout (engineering standard §8.8). None of the three languages is right-to-left. The
  app still detects text direction per field for mixed input.

---

## 5. Depth of the 2026-11-01 review

**Passed the checks made:** the 9 baseline docs exist; no HTTP client in `pubspec.lock`; no
certificate override or WebView; no `print` or `debugPrint`; no SQL in `lib/` built by
adding a value into a `rawQuery` or `execute` string on the same line; signing files are ignored by
git; language split is off; only the main activity is exported; `plans/` and `change_log/` have no
absolute paths, private IPs or personal emails in a pattern search.

**Correction:** the first review said the app had no `Random()`. It had one, in GPS blurring, now
fixed. The second audit covered the areas below by search and by reading selected files.

**Not reviewed in depth, so problems may remain:** color contrast and text scaling (§7), jank and
performance measurement (§10), label length since the 2026-09-26 audit, Sanskrit quality, and the
flavors guide line by line.

**Needs a device or a store console:** release build test, 16 KB check, font rendering on a clean
device, Data safety form, content rating, listing assets, direct-APK developer verification
(store readiness §2.5A).

**Results on 2026-11-01, after batch 1:** `flutter analyze` is clean, `dart format` changes nothing,
and `flutter test` passes all 1,990 tests. No Android build was run.

**Results on 2026-11-05:** `flutter analyze` is clean, `dart format` changes nothing, and
`flutter test` passes all 2,204 tests. No Android build was run.
