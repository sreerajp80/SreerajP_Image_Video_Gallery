# Strict guideline adherence — close the open gaps

**Status:** completed

> Batch 2 is done: [change_log/20261102_132333_strict-guideline-adherence-batch-2.md](../change_log/20261102_132333_strict-guideline-adherence-batch-2.md).
> Batches 3–5 are not part of this plan's approval; each gets its own plan.

**Date:** 2026-11-02
**Asked for:** "Ensure the project adheres to guidelines strictly."
**Builds on:** [docs/known_gaps.md](../docs/known_gaps.md) (36 open gaps, G9–G46) and
[plans/20261101_202921_guideline-audit-fix-batch-1.md](20261101_202921_guideline-audit-fix-batch-1.md).

---

## 1. What the issue is

The project does not yet meet the shared guidelines (`docs/guidelines`, submodule at `644faee`,
which is still the latest upstream commit). The 2026-11-01 review listed 36 open gaps. I checked
them again today and they are all still open. For example:

- `targetSdk = 35`, AGP 8.11.1, KGP 2.2.20, Gradle 8.14, `kotlinOptions` still used (G19, G21).
- No `LICENSE`, no `PRIVACY.md`, no `.github/workflows/` (G25, G17, G23).
- `provider_paths.xml` shares the whole cache folder with `path="."` (G29), but the only
  share path in the app is `cache/shared_media/`.
- `AppException` is an `abstract class`, not `sealed`; 6 raw `StateError`/`ArgumentError` throws (G32).
- `lib/models/help/help_topic.dart` imports `material.dart` (G15).
- Plan status lines: 33 plans use words that are not allowed (`Approved` 7, `Completed` 13,
  `Implemented` 11, `Pending` 1, `Proposed` 1). Four more look stale: three OCR plans and
  `20261101_182404_review-app-against-new-guidelines.md` (still `in_progress`) (G43).
- 10 files over 500 lines with no written reason (G41).

Baseline today: `flutter analyze` finds no issues, `dart format` changes nothing (528 files), and
`flutter test` passes all 1,992 tests. No Android build was run.

Not every gap can be closed by code. Some need a person (a fluent Sanskrit reader, a device, the
Play Console) and some need the owner's decision. "Strictly" therefore means: close every gap that
can be closed in the repo, and for the rest, either get the decision or record it clearly.

---

## 2. Plan: work in batches

36 gaps is too much for one safe change. Each batch below ends with `flutter analyze` clean,
`dart format` clean, all tests passing, a change log, and an update to `docs/known_gaps.md`.
**This approval covers Batch 2 only.** Batches 3–5 get their own short plan and approval when we
reach them, because their details depend on what earlier batches find.

### Batch 2 — docs, config and small safe code fixes (this approval)

| Gap | Fix | Files |
|---|---|---|
| G42 | Count the manifest permissions again (12 `<uses-permission>` today). Make `docs/security.md` §11 and the counts in `CLAUDE.md` / `AGENTS.md` list exactly what the manifest declares. Note the merged-manifest `DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` as added by AndroidX, not by us. | `docs/security.md`, `CLAUDE.md`, `AGENTS.md` |
| G43 | Change only the `**Status:**` word in old plans to an allowed value (`Approved`/`Implemented`/`Completed` → `completed` when a matching change log exists; `Pending`/`Proposed` → checked one by one). Close `20261101_182404` as `completed` (its change log exists). Ask you about the three OCR plans (see §4). Nothing else in old plans changes. | `plans/*.md` (status line only) |
| G30 | Add a `**Last updated:**` line to `implementation_progress.md`; name `en-IN` in `release_process.md`; point its store gate (§9A) at `platform_store_readiness.md` instead of keeping a copy. | `docs/implementation_progress.md`, `docs/release_process.md` |
| G26 | Add to `CLAUDE.md` and `AGENTS.md`: submodule is read-only, CI only runs checks, the declared store with a link to `platform_store_readiness.md`, and `PROJECT_PROFILE.md` in the read list. | `CLAUDE.md`, `AGENTS.md`, `docs/workflow_rules.md` (added during work: it must match `CLAUDE.md`) |
| G25 | Add an MIT `LICENSE` file (the profile already says MIT). Update the About `license` row to name the app's own licence too. | `LICENSE` (new), `assets/config/app_config.json` |
| G20 | Add the Security Baseline table (§1.1) and the entry-point list (§3.1) to `docs/security.md`, filled from the real code (manifest, intent filters, channels, the transfer listener). | `docs/security.md` |
| G29 | Narrow `provider_paths.xml` to `cache/shared_media/` only. Add a check in Kotlin `shareFile` that the file is inside that folder, and a test for the Dart side. | `android/app/src/main/res/xml/provider_paths.xml`, `IntentChannelHandler.kt`, `test/services/platform/share_service_test.dart` |
| G15 | Move the UI parts out of `HelpTopic`: the model keeps `id` and `badge`; a small mapper in `lib/screens/settings/help/` gives the icon and the localized text. | `lib/models/help/help_topic.dart`, a new mapper file, the help screens that use it, their tests |
| G14 | Change Malayalam `languageSystem` to the glossary word `സിസ്റ്റം സ്വതവേ`. | `lib/l10n/app_ml.arb` (+ `flutter gen-l10n`) |
| G27 | Add `res/values-ml/strings.xml` and `res/values-sa/strings.xml` with the localized launcher name. Note in `known_gaps.md` that Android may not offer Sanskrit as a system language. | two new `strings.xml` files |

### Batch 3 — error handling, accessibility, memory (later plan)

G31 (read the ~193 silent `catch` blocks; log through `AppLogger` or write why it is safe), G32
(make `AppException` `sealed`, replace raw throws), G33 (show a localized message when "open with"
fails), G34 (`Semantics` on crop, curve, markup, redaction and mask tools), G35 (48 dp touch
targets), G36 (clear the image cache on memory pressure, set `cacheWidth` on grid thumbnails),
G37 (units and the `releases` text into ARB files).

### Batch 4 — data, packages, toolchain, CI (later plan)

G38 (`CHECK` constraints through a v5 migration with a migration test), G39 (pin `crypto` and
`flutter_secure_storage`; the 9 → 11 upgrade must first prove that existing vault keys still
read back), G40 (`flutter_lints` 6 + the extra rules), G22 (`material_ui` migration), G21
(AGP 9 / KGP 2.4 / Gradle 9, `compilerOptions` instead of `kotlinOptions`, pin Flutter version),
G19 (`targetSdk` 36 with an edge-to-edge check of every screen), G23 (GitHub Actions on `master`:
analyze, format, test only).

### Batch 5 — large refactors (later plan)

G41 (split or justify the 10 large files), G46 (UI imports of services go through providers),
G44 (remove unused ARB keys), G11 (ARB key prefixes, about 1,000 renames), G12 (screen tests in
`ml` and `sa`), G13 (tests for 17 provider files), G10 (store the language under `app_language`).

### Needs a person, not code

| Gap | Who / what |
|---|---|
| G9 | A fluent Sanskrit reader must review `app_sa.arb` and the `sa` values in `app_config.json`. |
| G17, G18 | You must give a public support email. Then I can write `PRIVACY.md` and add the `email` and `privacyPolicy` About rows. |
| G24 | 16 KB page check on a release build. I will give you the command to run after Batch 4. |
| G28 | You decide: `FLAG_SECURE` in the normal viewer as a setting, or record it as an accepted exception. |

---

**Security impact:** G29 narrows what the file provider can expose (from the whole cache to one
folder) and adds a path check in Kotlin, so it lowers risk. No permission, network or storage
rule is loosened. G42 and G20 change docs only.

## 3. Testing for Batch 2

- `flutter gen-l10n`, `flutter analyze`, `dart format --set-exit-if-changed lib test`, `flutter test`.
- New test for the share folder rule; updated help-topic tests.
- `android\gradlew --stop` and a check for leftover Gradle/Kotlin daemons if any Android build is run.
- Not checked in Batch 2: sharing on a real phone after the provider path change, and the launcher
  name on a phone set to Malayalam.

## 4. Open questions for the owner

1. Approve Batch 2 as written?
2. The three OCR plans (`20260926_071538`, `_071539`, `_071540`) — were they done, or dropped?
3. Support email for G17/G18 (can wait until later).
4. G28 decision (can wait until later).

## 5. Risks

- G29: if any share path outside `shared_media/` exists that I missed, sharing it would fail.
  I found only one share call site (`privacy_export_service.dart` through `ShareService`); the
  Kotlin check will return a clear error rather than crash.
- G15: help screens change how they read topic text; tests cover the help screens.
- G43: editing old plan files changes history text, but only the status word.
