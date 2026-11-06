# Align project docs with the updated shared guidelines

Implements plan: `plans/20260926_053230_align-docs-with-guidelines.md`

## Summary

All project docs now follow the updated shared guidelines (`DOCS_FOLDER_GUIDELINE.md`,
`CLAUDE_MD_GUIDELINE.md`, `AGENTS_MD_GUIDELINE.md`, and the architecture, security and release
templates). Facts that no longer matched the code were corrected. Code that the new rules need
but the app does not have yet is recorded in a new `docs/known_gaps.md`. No app code changed.

## Files changed

| File | What changed |
|---|---|
| `CLAUDE.md` | The docs table now points to the local `docs/` files, plus the submodule reference docs. The localization section is replaced with the guideline's full three-language version, including a "current state" line that links to the gaps. The permission rule now lists all 12 declared permissions. Scanner link updated to `docs/security.md` §20. |
| `AGENTS.md` | Regenerated from `CLAUDE.md`. Only the five intended lines differ (title, banner, tree comments, dos-and-don'ts heading). |
| `docs/GUIDELINES_MANIFEST.md` | Re-copied unchanged from the submodule. |
| `docs/architecture.md` | Rebuilt on the blueprint's 22 sections. Added the start-up order, lifecycle behavior, offline behavior, error classes, schema version 3 with migration history, real indexes, DI, the real route tree (from `app_router.dart`), storage, all 9 method channels, build model, logging, test strategy, decisions and risks. Fixed the app name and the security section link. |
| `docs/security.md` | Rebuilt on the blueprint's 18 sections, with transfer (§19) and scanner/OCR/PDF (§20) kept as app-specific sections. Removed the false "`INTERNET` absent" claims (threat model and OWASP M5). The permission table now matches the manifest (12). `FLAG_SECURE` is now correctly described as vault screens only. Vault metadata is now correctly described as plain text in the private database (OWASP M9 marked risk-accepted, with a hardening item). Added storage model, logging policy, retention, testing, incident response, open risks and a review checklist. |
| `docs/release_process.md` | Rebuilt on the template's order. The permission check now requires `INTERNET` to be **present**, with the full expected list. Removed `build_runner`. Replaced `1.0.0` with `<version>`. Added versioning, cleartext, asset audit, exported-component audit, localization checklist (open gaps marked) and the Google Play gate (§9A). Uses a plain `>` warning callout. The `key.properties` example now uses `storeFile=gallery-release.jks`, which the Gradle file resolves. |
| `docs/dependencies.md` | The package table is rebuilt from `pubspec.yaml`, with licenses read from each package's `LICENSE` file and a "declared / integrated" column. Removed packages that were never added. Corrected the `image` license (MIT). Fixed the `video_player` note (only `WAKE_LOCK` is removed). Rewrote the approval checklist around the 12-permission check. |
| `docs/project_structure.md` | Tree regenerated from the real folders. Removed the non-existent `.agents/` folder. Added `tool/`, `assets/tessdata/` and every feature subfolder. |
| `docs/workflow_rules.md` | Status values now match the rules (`draft` … `partial_completion`). Completed the privacy list. Added a check step for docs-only changes. |
| `docs/Project_Idea.md` | Added the H1 app name, purpose paragraph and "Read first" links. Added a Sanskrit status line. Changed the exact Flutter/Dart versions to the minimums in `CLAUDE.md`. |
| `docs/feature_improvements_and_standout_features.md` | Marked as a point-in-time proposal with a `**Date:**` line. "Read first" now links to the local docs. Added a dated §9 "Corrections" section (`INTERNET`, X25519, languages, version labels) without rewriting the original text. |
| `docs/implementation_progress.md` | Added a dated 2026-09-26 entry for the guideline update, with open items for the code gaps. |
| `docs/known_gaps.md` | **New.** Point-in-time list of 8 code gaps (Sanskrit ×3, About badge, localized config, language split, global error handlers, logger) and 3 audits still to do. |
| `README.md` | Added the clone-with-submodule step, a code-generation note, "no `--dart-define` needed", versioned symbol paths, the honest language status, and the missing docs in the docs table. |

Not changed: `lib/`, `test/`, `android/`, `assets/`, `docs/guidelines/`, and
`docs/implementation_plan.md` (point-in-time; left as written).

## Checks

- Relative links in `CLAUDE.md`, `AGENTS.md`, `README.md` and `docs/*.md`: 0 broken.
- `docs/GUIDELINES_MANIFEST.md` compared with the submodule copy: identical.
- `CLAUDE.md` compared with `AGENTS.md`: only the 5 intended line pairs differ.
- Search for stale phrases (`INTERNET … absent`, `Image & Video Gallery`, `ships only English`,
  `build_runner build`, `Pending Approval`): the only hit is the correct sentence that
  `WAKE_LOCK` must be absent.
- Every `docs/` H1 carries the app name (except the shared manifest, which is copied as-is).
- `flutter analyze`: no issues.

## Follow-up

The code gaps in `docs/known_gaps.md` need their own plan, mainly adding Sanskrit and the About
badge. `ACCESS_NETWORK_STATE` has no written reason in the manifest and no direct caller in app
code (`docs/security.md` §17). It should be explained or removed.
