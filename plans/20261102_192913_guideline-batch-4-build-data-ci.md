# Guideline Batch 4 — toolchain, targetSdk 36, secure storage 11, database checks, lints, CI

**Status:** partial_completion

> Steps 1–6, 5a and 8 are done: [change_log/20261102_202350_guideline-batch-4-partial.md](../change_log/20261102_202350_guideline-batch-4-partial.md). Step 7 and the rest continue in [plans/20261102_201827_finish-all-pending-guideline-work.md](20261102_201827_finish-all-pending-guideline-work.md).

**Date:** 2026-11-02
**Part of:** [plans/20261102_131432_strict-guideline-adherence.md](20261102_131432_strict-guideline-adherence.md) (Batch 4)
**Gaps:** G19, G21, G23, G38, G39, G40, G49 (and the G48 decision) in [docs/known_gaps.md](../docs/known_gaps.md)

**Security impact:**
- **Changed:** the Android build tools, the target API, secure storage (the vault PIN store),
  the database schema, and a new CI workflow on GitHub.
- **CI:** it uses no secrets, has read-only permission, and only runs checks (`CLAUDE.md`
  workflow rule 5).
- **Not changed:** no permission, network rule or launchable scheme.

---

## 1. What the issue is (checked today)

| Gap | Today | Rule |
|---|---|---|
| G21 | AGP 8.11.1, KGP 2.2.20, Gradle 8.14. A throwaway `flutter create` with this Flutter (3.47.6) generates **AGP 9.1.0, KGP 2.4.0, Gradle 9.3.1**, Java 17, and `kotlin { compilerOptions }`. The last build printed "support … will soon be dropped" for all three. `build.gradle.kts` still has `kotlinOptions` (fails on AGP 9) and uses `project.exec` in `generateBuildMetadata` (removed in Gradle 9). The exact Flutter version is not pinned in `CLAUDE.md` / `AGENTS.md`. | Standard §5.3 |
| G19 | `targetSdk = 35`. Flutter 3.47.6 generates 36. The app never opted out of edge-to-edge, so 36 takes nothing away it relies on. | Standard §5.3; store readiness §2.2 |
| G49 | `flutter_secure_storage` is held at 10.3.4 to protect version 9 vault data. **The owner confirmed on 2026-11-02 that the app has never been installed anywhere else and no vault exists**, so no phone holds version 9 data. | — |
| G39 | `crypto` uses `^3.0.3`. The discontinued `js` package is no longer in the lock file (it went with the earlier upgrades). | Standard §16.6 |
| G40 | `flutter_lints` 6 is on, but none of the standard's 24 extra rules. Measured on a scratch copy: **217 findings** (200 `avoid_redundant_argument_values`, 9 `noop_primitive_operations`, 4 `avoid_bool_literals_in_conditional_expressions`, 3 `prefer_final_locals`, 1 `close_sinks`). | Standard §16.1 |
| G38 | No `CHECK` constraints. Columns holding enum values: `media_items.media_type`, `albums.album_type`, `vault_items.media_type`. Five 0/1 flag columns: `is_favorite`, `is_vaulted`, `is_trash`, `is_pinned`, and the vault's. Schema version 4. | Standard §13.4 |
| G23 | No `.github/workflows/`. The repository has a GitHub remote. | Standard §19.1 |
| G48 | The dev-flavor log keeps the full error text, which can quote a path. **Owner's decision needed** (§4). | `CLAUDE.md` security rules |

## 2. Plan for the fix

Order: lowest risk first. After each step: `flutter analyze` clean and `flutter test` passing.

1. **G39 — pin `crypto`:** `crypto: 3.0.6`, or whatever exact version the lock file holds today,
   read and not typed. Add a comment saying why.
2. **G49 — secure storage 11:**
   - `flutter_secure_storage: 11.2.0`, pinned exactly.
   - Keep `resetOnError: false`. 11 still wipes everything on an error by default, which would
     erase the vault PIN.
   - Keep `migrateOnAlgorithmChange` and `migrateWithBackup`. They are harmless with no old data,
     and they protect a future algorithm change.
   - Update `vault_credential_store_test.dart` (the pin moves to 11.x).
   - Docs: the "10 first" rule becomes history.
   - Close G49.
3. **G40 — the standard's extra lint rules:**
   - Add all 24 rules from §16.1 to `analysis_options.yaml`.
   - Fix the 217 findings: `dart fix --apply` for the automatic ones (most are
     `avoid_redundant_argument_values`); the rest by hand.
   - **The one `close_sinks` finding is read with care.** It may be a real leaked stream or file
     sink, and it gets a test if so.
4. **G38 — database checks, schema v5:**
   - **New installs:** the `CREATE TABLE` statements get real `CHECK` constraints:
     - `media_type IN ('image','video','gif','rawImage','svg')`;
     - `album_type IN (` the 9 `AlbumType` names `)`;
     - each flag column `IN (0, 1)`.

     The lists are built from the Dart enums, so the two cannot drift apart.
   - **Existing installs (v4 → v5):** SQLite cannot add a `CHECK` to an existing table, only
     rebuild it. A rebuild is **not safe here**: with foreign keys on, `DROP TABLE media_items`
     deletes every album and tag link by cascade. So the v5 migration adds
     `BEFORE INSERT` / `BEFORE UPDATE` triggers that `RAISE(ABORT)` on a bad value. Same rule,
     same values, no rebuild.
   - **Tests** (`test/repositories/database/`):
     - a bad value is refused both on a fresh v5 database and on one upgraded from v4;
     - the upgrade keeps every row, album link and tag link;
     - every enum value is accepted, so adding an enum value without updating the schema fails
       a test.
5. **G21 — Android toolchain** (follows the standard's "Android Toolchain Baseline"):
   - `android/settings.gradle.kts`: AGP 9.1.0 and KGP 2.4.0, the versions Flutter generated
     today, copied from the throwaway project and not typed.
   - Gradle wrapper: 9.3.1.
   - `android/app/build.gradle.kts`:
     - `kotlinOptions { jvmTarget = "17" }` → a top-level
       `kotlin { compilerOptions { jvmTarget.set(JvmTarget.JVM_17) } }`;
     - `project.exec { }` → an injected `ExecOperations` (works on Gradle 8 and 9).
   - `android/gradle.properties`: keep `android.builtInKotlin=false` and `android.newDsl=false`,
     which the Flutter migrator wrote. Keep the project's own `-Xmx4G`: the throwaway project
     asked for 8G, but the global rule says not to raise it in a project.
   - `CLAUDE.md` / `AGENTS.md` identity table: pin **Flutter 3.47.6 / Dart 3.13.5**, the versions
     this project builds with.
5a. **Found by the owner's build on 2026-11-02 — approved by the owner the same day.** AGP 9 turns off `resValue(...)`
   by default, and the build failed: "Product Flavor dev contains custom resource values, but
   the feature is disabled."
   - **Fix:** remove the two `resValue("string", "app_name", ...)` lines from the flavors in
     `android/app/build.gradle.kts`.
   - **Why this fix:** the flavors guide says the app name must come from each flavor's
     `strings.xml`, never from `resValue`, because a `resValue` cannot be translated.
     `src/dev/res/values/strings.xml` and `src/prod/res/values/strings.xml` already hold the same
     names, and the Malayalam and Sanskrit ones were added in Batch 2. The launcher shows exactly
     the same name as before.
   - **Not chosen:** `buildFeatures { resValues = true }`. It would hide the problem and keep a
     guideline gap.
6. **G19 — targetSdk 36:**
   - `targetSdk = 36` (Flutter's generated value).
   - Update every doc that says 35: `CLAUDE.md`, `AGENTS.md`, `docs/security.md` §1,
     `docs/release_process.md` §9A, `docs/PROJECT_PROFILE.md`.
   - Edge-to-edge: no opt-out exists to remove. Screens are checked on the phone (§5).
7. **G23 — CI:** new `.github/workflows/ci.yml`, as in standard §19.1:
   - runs on pull requests and pushes to **`master`** (this repository's branch, not the
     example's `main`);
   - `permissions: contents: read`; no secrets;
   - `ubuntu-latest`; Flutter pinned to **3.47.6**;
   - steps: `flutter pub get`, `dart format --output=none --set-exit-if-changed .`,
     `flutter analyze`, `flutter test`, and a staleness check that runs `flutter gen-l10n` and
     fails if `lib/l10n/generated/` changed;
   - a source test that checks the workflow keeps to these rules;
   - `docs/PROJECT_PROFILE.md` §7 records "GitHub Actions".
8. **Docs, gaps, change log:**
   - `docs/known_gaps.md`: G19, G21, G23, G38, G39, G40 and G49 resolved, with G48 per your
     decision.
   - `docs/architecture.md`: schema v5 and the migration table.
   - `docs/dependencies.md`, `docs/release_process.md`.

## 3. Files to change

| Area | Files |
|---|---|
| Packages | `pubspec.yaml`, `pubspec.lock` |
| Lints | `analysis_options.yaml`, plus about 60–80 files with lint fixes (mostly automatic) |
| Vault | `lib/services/vault/vault_credential_store.dart` and its test |
| Database | `lib/repositories/database/database_helper.dart`, `database_constants.dart`, and new and updated tests in `test/repositories/database/` |
| Android | `android/settings.gradle.kts`, `android/gradle/wrapper/gradle-wrapper.properties`, `android/app/build.gradle.kts` |
| CI | new `.github/workflows/ci.yml`, new `test/tool/ci_workflow_test.dart` |
| Agent files | `CLAUDE.md`, `AGENTS.md` |
| Docs | `docs/known_gaps.md`, `docs/architecture.md`, `docs/dependencies.md`, `docs/security.md`, `docs/release_process.md`, `docs/PROJECT_PROFILE.md` |
| Only if you choose "always reduce" for G48 | `lib/core/logging/app_logger.dart` and its test |

## 4. Decision for the owner — G48

In the dev flavor, the logger keeps the full error, so an exception that quotes a file path shows
that path in the IDE console. `CLAUDE.md` says private metadata must not be logged "even in debug
builds".

- **(a) Always reduce errors to their type, in every flavor** (recommended). It matches the rule as
  written. The cost is less detail when you debug, but the operation name and error type are still
  logged, and you can always add a breakpoint.
- **(b) Record the dev flavor as an accepted exception.** The log only reaches your own IDE, but
  the written rule would then need an exception added.

> **Decision (2026-11-02):** the owner chose **(a)**, always reduce errors to their type. This adds
> `lib/core/logging/app_logger.dart` and its test to the change.

## 5. How it will be checked

- After each step: `dart format`, `flutter analyze`, `flutter test`.
- **You run the Android build** after step 5 and again after step 6, because the toolchain change
  can only be proven by a build:
  ```
  flutter build apk --flavor prod --release --split-per-abi
  android\gradlew --stop
  ```
- **You, on the phone:** open the main screens and check that nothing hides under the status bar
  or the navigation bar, using both gesture and three-button navigation (targetSdk 36). Create a
  vault PIN and unlock it, then close the app fully and unlock again (secure storage 11 on a fresh
  install).
- **CI** runs for real only after a push. I will not push. The workflow file is checked by its
  source test, and you see the first run on GitHub when you push.

## 6. Risks

- **AGP 9 / Gradle 9 is the biggest risk.** A plugin that is not ready for AGP 9 fails the build.
  If that happens, I stop and report which plugin, and we choose then: wait for it, or pin the
  previous AGP. The other steps stand on their own, so they keep working either way.
- **Triggers vs. `CHECK`:** upgraded databases enforce the rule with triggers, new ones with
  `CHECK`. Both refuse the same values, and the tests prove it on both paths.
- **The lint fixes touch many files,** but almost all are automatic, and the tests run after.
