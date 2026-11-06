# Change log — guideline Batch 4 (partly done; the rest continues in a new plan)

**Plan:** [plans/20261102_192913_guideline-batch-4-build-data-ci.md](../plans/20261102_192913_guideline-batch-4-build-data-ci.md)
(status `partial_completion`)
**Continued by:** [plans/20261102_201827_finish-all-pending-guideline-work.md](../plans/20261102_201827_finish-all-pending-guideline-work.md)
**Date:** 2026-11-02

## Done

| Step | Gap | What changed |
|---|---|---|
| 1 | G39 | `crypto: 3.0.8`, pinned exactly (the version already in the lock file). |
| 2 | G49 | `flutter_secure_storage: 11.2.0`, pinned. The owner confirmed that no install with a vault exists, so no phone holds version 9 data. `resetOnError: false` is kept, and the option comment was corrected. The test now checks for an exact pin. |
| 3 | G40 | The standard's 24 extra lint rules are in `analysis_options.yaml`. 256 automatic fixes went into 98 files. The vault settings booleans were rewritten as plain pattern matches. The one `close_sinks` finding was a test fake, which now closes its own stream. Two imports were left unused by the fixes and were removed. |
| 4 | G38 | Schema v5 with the new `lib/repositories/database/column_value_rules.dart`. New databases get `CHECK` constraints on `media_type`, `album_type`, the vault `media_type` and 4 flag columns. Upgraded databases get `BEFORE INSERT/UPDATE` triggers with the same rules, and no table rebuild (a rebuild would cascade-delete album and tag links). The plan said 5 flags; the vault has none, so it is 4. |
| 5 | G48 | `AppLogger` reduces an error to its type in **every** flavor (owner's choice (a)). The stack trace is kept. |
| 5a | — | The two `resValue("string", "app_name", ...)` lines were removed from the flavors (AGP 9 turns the feature off; the flavor `strings.xml` files hold the same names). Approved by the owner after the first toolchain build failed. |
| 6 | G21 | AGP 9.1.0, KGP 2.4.0 and Gradle 9.3.1, copied from a fresh `flutter create`. `kotlinOptions` was replaced by `kotlin { compilerOptions }`, and `project.exec` by an injected `ExecOperations`. Flutter 3.47.6 / Dart 3.13.5 are pinned in `CLAUDE.md` / `AGENTS.md`. |
| 8 | G23 | `.github/workflows/ci.yml` (checks only, `master`, Flutter 3.47.6, read-only, no secrets) and `test/tool/ci_workflow_test.dart`. Both CI checks pass locally: the whole repository is formatted, and the generated localizations are not stale. |

New tests: `test/repositories/database/column_value_rules_test.dart`, two schema-v5 groups in
`database_migration_test.dart`, `test/tool/ci_workflow_test.dart`, and the updated logger and vault
credential tests.

## Not done here (moved to the new plan)

- **The toolchain build fails.** `flutter_tesseract_ocr` 0.4.31 (its newest release) calls
  `jcenter()`, which Gradle 9 removed. The owner also asked for AGP 9.4.1, Gradle 9.8.0 and
  KGP 2.4.10, so the versions from step 6 will change again.
- Step 7 (G19, targetSdk 36), and the docs in step 8.

## Check results

- `dart format --output=none --set-exit-if-changed .`: 567 files, 0 changed.
- `flutter analyze`: no issues.
- `flutter test`: all tests pass.
- Android build: **fails** on the OCR plugin (see above).
