# Change log — Phase A: owner's toolchain, working build, targetSdk 36, 16 KB check

**Plan:** [plans/20261102_201827_finish-all-pending-guideline-work.md](../plans/20261102_201827_finish-all-pending-guideline-work.md) (Phase A, steps 1–6)
**Date:** 2026-11-02 to 2026-11-04
**Gaps closed:** G19, G21, G23, G24

## What changed

| Step | Gap | Change |
|---|---|---|
| 1 | — | `flutter_tesseract_ocr` now comes from a `dependency_overrides` git entry pinned to commit `259994d4d93d755f8d365907df0f3b174f85ff57`. The published 0.4.31 calls `jcenter()`, which Gradle 9 removed. That commit differs from 0.4.31 only in `jcenter()` → `mavenCentral()`. The fallback (vendoring the plugin) was not needed. |
| 2 | G21 | AGP 9.4.1 and KGP 2.4.10 in `android/settings.gradle.kts`; Gradle 9.8.0 in the wrapper. `android.builtInKotlin=false` and `android.newDsl=false` stay. These are the owner's versions, newer than the standard's snapshot; the reason is in `docs/architecture.md` §15. |
| 3 | — | The owner built the prod release APKs; the build passed. |
| 4 | G19 | `targetSdk = 36` in `android/app/build.gradle.kts`, and every doc that said 35 (`CLAUDE.md`, `AGENTS.md`, `README.md`, `docs/architecture.md`, `docs/release_process.md`, `docs/security.md`, `docs/feature_improvements_and_standout_features.md`). |
| 5 | G24 | Every `.so` in the arm64 release APK has `LOAD` segments aligned to 16 KB or more (read-only ELF header check). |
| 6 | G23 | The CI file from Batch 4 was already in place; the gap is closed. Its first real run happens on the next push. |

## Security impact

Build tools and one dependency's source changed. The OCR plugin commit was read before use: it
changes only the Gradle repository line and adds no network code.

## Not checked here

- The build after `targetSdk` 36 and the later Dart-only phases has not been run by the owner.
- Phone checks with gesture and button navigation (targetSdk 36 ends the edge-to-edge opt-out).
