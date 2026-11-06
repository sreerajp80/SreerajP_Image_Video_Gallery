# Change log — strict guideline adherence, Batch 2

**Plan:** [plans/20261102_131432_strict-guideline-adherence.md](../plans/20261102_131432_strict-guideline-adherence.md) (Batch 2 only)
**Date:** 2026-11-02

Batch 2 closes nine gaps from [docs/known_gaps.md](../docs/known_gaps.md) and part of a tenth.
It changes docs, Android config and two small pieces of code. Batches 3–5 are not started.

---

## What changed, and why

### G43 — plan status lines (partly fixed)
- 33 old plans used words the workflow does not allow. Only the `**Status:**` word changed:
  - `Approved`, `Completed`, `Implemented`, `Proposed` → `completed` (each has a matching change log);
  - `Pending Approval` → `approval_pending` for `20260910_194900_update_roadmap_matrix_versioning.md`.
    It has no change log and its edit was never made, so it is still waiting.
- `20261101_182404_review-app-against-new-guidelines.md`: `in_progress` → `completed` (its change log exists).
- Still open: the three OCR plans (`20260926_071538`, `_071539`, `_071540`). Only the owner knows whether they were done or dropped.

### G42 — permission count
- The manifest declares **11** Android permissions. The old docs said "12" but listed 11. The
  merged manifest has 12, because `androidx.core` adds `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`.
  This is a signature-level permission that only this app holds.
- All docs now say this the same way: `CLAUDE.md`, `AGENTS.md`, `docs/security.md` §11 and §18,
  `docs/architecture.md`, `docs/PROJECT_PROFILE.md`, and `docs/release_process.md` §6.4 and §8.

### G26 — required rules in the agent files
- `CLAUDE.md` and `AGENTS.md` now have:
  - a `Distribution` row and the store guide in the read list;
  - `docs/PROJECT_PROFILE.md` in the read list;
  - the "Security impact" line rule;
  - workflow rule 4 (the guidelines submodule is read-only);
  - workflow rule 5 (CI only runs checks).
- `docs/workflow_rules.md` got the same rules. Its first lines say it must match `CLAUDE.md`. This
  file was added to the plan during the work.

### G30 — small docs issues
- `docs/implementation_progress.md` is now a living doc with `**Last updated:** 2026-11-02`.
- `docs/release_process.md` §9A no longer keeps a copy of the store gate. The store guide says a
  project must never keep one. §9A now points to `guidelines/platform_store_readiness.md`
  §1, §2, §2.5A and §7, and keeps only this app's own answers, including the listing languages `en-IN` and `ml-IN`.

### G20 — security baseline and entry points (was a release blocker)
- New `docs/security.md` §1.1: one line per baseline rule. Each line was checked against the code
  and manifest, and is marked `verified`, `n/a` (with a reason) or `open`.
- New `docs/security.md` §3.1: every way data reaches the app from outside, and how each is checked.
- One line is `open`: third-party SDKs (see G47 below).

### G25 — licence
- New `LICENSE` (MIT, as the profile declares).
- The About `license` row now starts with "MIT License" in `en`, `ml` and `sa`.

### G29 — file provider paths
- `provider_paths.xml` now exposes only `cache/shared_media/`. Before, it exposed the whole cache
  folder and the whole external cache folder.
- `IntentChannelHandler.kt` `shareFile` refuses any file outside that folder, checked on the
  canonical path. It returns a clear error instead of crashing.
- `ShareService.shareBytes` keeps only the name part of the file name. Before, a name such as
  `../x.jpg` could write outside the share folder. A name with no usable part is refused.
  `ShareService` now takes the cache folder as a parameter, so tests can replace it.

### G15 — `HelpTopic` model imported Flutter UI
- `lib/models/help/help_topic.dart` now holds plain data only: `id`, `badge`, `all` and `findById`.
- The icon and the localized text moved to the `HelpTopicPresentation` extension in
  `lib/widgets/help/help_topic_presentation.dart`.
- The call sites did not change; they now import the extension. The plan said
  `lib/screens/settings/help/`. It went into `lib/widgets/help/` instead, because the widget
  `help_topic_card.dart` uses it too.

### G14 — Malayalam wording
- `languageSystem` (ml) is now `സിസ്റ്റം സ്വതവേ`, as in the glossary. Regenerated with `flutter gen-l10n`.

### G27 — launcher name per language
- New `strings.xml` in `values-ml` and `values-sa`, for both flavors:
  - prod uses the `appName` values from `app_config.json`;
  - dev uses `appTitle` + "Dev", as the English dev name does.
- They went under `src/prod/res/` and `src/dev/res/`, not `src/main/res/` as the plan said. A file
  in `main` would have given the dev build the prod name.

### New gap found: G47
- `mobile_scanner` 5.2.3 depends on Google's closed-source ML Kit barcode library on Android
  (`com.google.mlkit:barcode-scanning`). This breaks hard rule 1, and it makes the About line
  "All libraries used are open source" untrue.
- Recorded as a release blocker in `docs/known_gaps.md`. Nothing was changed for it in this batch.

---

## Files

**Created:**
- `LICENSE`
- `lib/widgets/help/help_topic_presentation.dart`
- `android/app/src/prod/res/values-ml/strings.xml`
- `android/app/src/prod/res/values-sa/strings.xml`
- `android/app/src/dev/res/values-ml/strings.xml`
- `android/app/src/dev/res/values-sa/strings.xml`
- `test/services/platform/share_service_test.dart`
- `test/android/provider_paths_test.dart`
- `test/android/launcher_name_test.dart`
- `test/widgets/help/help_topic_presentation_test.dart`

**Changed:**
- Agent files: `CLAUDE.md`, `AGENTS.md`
- Docs: `docs/workflow_rules.md`, `docs/security.md`, `docs/release_process.md`,
  `docs/architecture.md`, `docs/PROJECT_PROFILE.md`, `docs/implementation_progress.md`,
  `docs/known_gaps.md`
- Config and Android: `assets/config/app_config.json`,
  `android/app/src/main/res/xml/provider_paths.xml`,
  `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt`
- Code: `lib/services/platform/share_service.dart`, `lib/models/help/help_topic.dart`,
  `lib/screens/help/help_topic_screen.dart`, `lib/widgets/help/help_topic_card.dart`
- Localization: `lib/l10n/app_ml.arb`, `lib/l10n/generated/app_localizations_ml.dart` (generated)
- Tests: `test/models/help/help_topic_test.dart`, `test/screens/help/help_topic_screen_test.dart`,
  `test/screens/settings/settings_screen_test.dart`
- Plans: 34 old plan files (status line only), and this batch's plan

---

## Check results

- `flutter gen-l10n`: ran clean.
- `dart format --set-exit-if-changed lib test`: 533 files, 0 changed.
- `flutter analyze`: no issues.
- `flutter test`: all 2,003 tests pass (1,992 before; 11 new).

**Not checked:**
- No Android build was run, so the Kotlin change and the new resource folders have not been compiled.
- Sharing has not been tested on a phone after the provider change.
- The launcher names have not been checked on a phone set to Malayalam.
- Android may not offer Sanskrit as a system language at all.
