# Align project docs with the updated shared guidelines

**Status:** completed

## 1. Issue

The `docs/guidelines` submodule was just updated (see
`change_log/20260926_103125_update-guidelines-submodule.md`). An audit of the project docs
against it found two kinds of problems:

- **Format problems.** The docs do not fully follow `DOCS_FOLDER_GUIDELINE.md`,
  `CLAUDE_MD_GUIDELINE.md`, `AGENTS_MD_GUIDELINE.md` and the two blueprints
  (`architecture.md`, `security.md`).
- **Wrong facts.** Several docs no longer match the code. For example, some still say
  `INTERNET` is absent, although the transfer feature needs it and the manifest declares it.

The audit also found gaps in the **app code**, mostly around the new three-language rule.
This plan does **not** fix code. It writes those gaps down honestly in one place so a later
plan can fix them.

### 1.1 Findings, file by file

| File | Findings |
|---|---|
| `CLAUDE.md`, `AGENTS.md` | The "Read these docs" table points to the submodule templates (`docs/guidelines/architecture.md`, `security.md`, `release_process.md`) even though filled-in local copies exist, and "local copy wins". The localization section says the app "ships only English", but it ships English and Malayalam. The section is also missing the rules the guideline now requires: three languages (`en`, `ml`, `sa`), Sanskrit-not-Hindi, the in-app language picker, short labels, tooltips on icon-only controls, and the About "Made with ❤️ from India" badge. The permission rule lists only 3 of the 12 declared permissions. |
| `docs/GUIDELINES_MANIFEST.md` | Out of date with the submodule copy (one row differs). The guideline says this file is copied unchanged. |
| `docs/architecture.md` | The H1 uses the wrong app name ("Image & Video Gallery"). It has 6 sections, but the blueprint has 22, and it is missing the initialization sequence, lifecycle, offline behavior, error handling, the domain model with **schema version (currently 3)**, DI, persistence, build model, logging, decisions and risks. It points to `security.md §11` for the intent gate, but that section is §12. It has no Sanskrit status. |
| `docs/security.md` | Wrong app name in the H1. §3 says exfiltration is prevented "by omitting `INTERNET`", and OWASP M5 says "`INTERNET` permission absent", but both are false. The §7 table misses `READ_MEDIA_VISUAL_USER_SELECTED` and `ACCESS_NETWORK_STATE`. The §9 list misses `CHANGE_WIFI_STATE`. Compared with the blueprint, it has no storage model, logging policy, data retention/purge, security testing, incident response, open risks or review checklist sections. |
| `docs/release_process.md` | The checklist and commands say to confirm `INTERNET` is **absent**, which is wrong and would fail every release. It runs `build_runner`, but the project has no `build_runner`. It hard-codes version `1.0.0` although the app is at `2.5.2+15`. Compared with the template, it is missing the versioning policy, network-security/cleartext check, asset and secret leak audit, exported-component audit, localization checklist, the **mandatory Google Play readiness gate (§9A)**, rollback, release evidence and post-release checks. It uses a `> [!WARNING]` block where the guideline asks for a plain `>` callout. |
| `docs/dependencies.md` | Wrong app name. The package table lists packages that are **not** in `pubspec.yaml` (`riverpod_annotation`, `cryptography`, `photo_view`, `flutter_svg`), and it misses packages that are (`package_info_plus`, `path`, `path_provider`, `local_auth_android`, dev deps). `photo_view` appears as both "approved" and "not used". The `video_player` note says `INTERNET` and `ACCESS_NETWORK_STATE` are stripped, which is false (only `WAKE_LOCK` is removed). Checklist item 2 ("package must not declare `INTERNET`") is outdated. The guideline wants "declared vs integrated" shown. |
| `docs/project_structure.md` | Wrong app name. The tree is far out of date: it lists a `.agents/` folder that does not exist, and it misses about 20 `services/` folders, the `models/` subfolders and many `screens/` and `widgets/` folders. |
| `docs/workflow_rules.md` | Wrong app name. It uses the plan status values `Pending Approval` / `Implemented`, but the rules now use `draft`, `approval_pending`, `in_progress`, `completed`, `dropped` and `partial_completion`. The privacy list misses network share names, local server URLs and personal email addresses. |
| `docs/Project_Idea.md` | Has no purpose paragraph, no "Read first" links, no `---` after the intro, and no app name in the H1 format. Its UI section names only English and Malayalam, with no note on Sanskrit. (The file name is not `snake_case`. The guideline says older names are tolerated and must **not** be renamed just for style, so I will keep the name.) |
| `docs/feature_improvements_and_standout_features.md` | Not a recognized doc type. It reads as a one-off feature review, so it should be a **point-in-time** doc with a `**Date:**` line. It links to the submodule templates instead of the local docs. It has wrong claims: "100% offline, zero internet calls", "zero internet permissions" and "X25519 key exchange" (the real pairing uses a shared secret + HMAC). |
| `docs/implementation_plan.md`, `docs/implementation_progress.md` | These are point-in-time docs, so the old text stays as it is. `implementation_progress.md` needs a new dated entry that records the guideline update and links to the new gaps file. |
| `README.md` | §21.3 says the README must say which `--dart-define` values are needed (none here) and how code generation runs (`flutter gen-l10n` only, no `build_runner`). Its debug-symbol path has no version in it, unlike `CLAUDE.md`. |

### 1.2 Code gaps found (recorded, **not** fixed by this plan)

- No Sanskrit: `app_sa.arb`, `sa` in `supportedLocales`, the Sanskrit fallback delegates and a
  Sanskrit option in the language picker are all missing (engineering standard §8.3, §8.4).
- No "Made with ❤️ from India" badge on the About screen (`guideline.md` §1.7).
- `app_config.json` prose values are plain strings, not `{"en","ml","sa"}` maps (§1.2).
- `bundle.language.enableSplit = false` is not set in `android/app/build.gradle.kts` (§8.1).
- Tooltip (§7.8) and label-length (§8.6) audits have not been done against the new rules.

## 2. Decisions this plan makes

1. **Rules follow the guideline. Facts follow the code.** `CLAUDE.md` and `AGENTS.md` state
   the full three-language rule, because they are rules. Descriptive docs (`architecture.md`,
   `README.md`, `Project_Idea.md`) say what the app does today (English + Malayalam) and link
   to the gap.
2. **One home for the gaps:** a new `docs/known_gaps.md` (a recognized point-in-time type).
3. **No renames.** `Project_Idea.md` keeps its name, as the guideline says.
4. **Point-in-time docs are not rewritten.** `implementation_plan.md` and
   `implementation_progress.md` keep their history. The feature review gets a `**Date:**` line
   and a dated "Corrections" section instead of silent edits.
5. **Nothing is invented.** Where the blueprint asks for a fact (init order, logging,
   lifecycle), I will read the code to get it. If the code has nothing for a section, the
   section will say so and point to `known_gaps.md` if that matters.

## 3. Files to be changed

| File | Change |
|---|---|
| `CLAUDE.md` | Point the docs table to local docs, plus the submodule reference docs. Replace the localization section with the guideline's full version. List all declared permissions in the security rule (short form, linked to `docs/security.md`). |
| `AGENTS.md` | The same changes, kept identical to `CLAUDE.md` except for the lines that are meant to differ. |
| `docs/GUIDELINES_MANIFEST.md` | Re-copy it unchanged from `docs/guidelines/GUIDELINES_MANIFEST.md`. |
| `docs/architecture.md` | Rebuild it on the blueprint's 22-section order. Keep all current content, move it into the matching sections, and fill the missing sections from the code. Fix the app name and the §12 link. |
| `docs/security.md` | Rebuild it on the blueprint's 18-section order. Keep all current content, fix the `INTERNET` claims, make the permission table and the release list match the manifest (12 permissions), and fill the missing sections. |
| `docs/release_process.md` | Rebuild it on the template's order for Android only. Fix the `INTERNET` check (it must be **present**, with the full expected list). Remove `build_runner`, use `<version>` placeholders, and add the §9A Play readiness gate and a localization checklist. Use a plain `>` callout. |
| `docs/dependencies.md` | Rebuild the table from `pubspec.yaml`, with a "declared / integrated" column. Fix the `video_player` note and the approval checklist. Fix the app name. |
| `docs/project_structure.md` | Regenerate the tree from the real folders. Fix the app name. |
| `docs/workflow_rules.md` | Fix the status values and the privacy list so they match `CLAUDE.md`. Fix the app name. |
| `docs/Project_Idea.md` | Add the H1 app name, a purpose paragraph, "Read first" links and `---`. Add one line on Sanskrit status that links to `known_gaps.md`. |
| `docs/feature_improvements_and_standout_features.md` | Add the app name to the H1 and a `**Date:** 2026-09-06` line. Change the links to point to the local docs. Add a dated "Corrections (2026-09-26)" section that fixes the wrong claims. |
| `docs/implementation_progress.md` | Add a dated entry (2026-09-26) for the guideline update, linking to `known_gaps.md`. |
| `docs/known_gaps.md` | **New.** A point-in-time doc listing the code gaps from §1.2, each with the guideline section it breaks. |
| `README.md` | Add "no `--dart-define` values needed" and "code generation is `flutter gen-l10n` only". Use versioned symbol paths. Add `known_gaps.md` and the other docs to the docs table. |
| `change_log/20260926_<time>_align-docs-with-guidelines.md` | **New** change log. |

Not changed: anything in `lib/`, `test/`, `android/`, `assets/`, and anything inside
`docs/guidelines/`.

## 4. Every doc will follow the standard anatomy (`DOCS_FOLDER_GUIDELINE.md` §4)

`# Title — SreerajP Image Video Gallery`, then a purpose paragraph, then "Read first" relative
links, then `---`, then numbered `##` sections split by `---`. Commands go in language-tagged
fences, warnings go in `>` callouts, all links are relative, and the writing is simple English.
Point-in-time docs also get a `**Date:**` line.

## 5. Verification

- Check every relative link in `docs/`, `README.md`, `CLAUDE.md` and `AGENTS.md` with a small
  script that confirms each target file exists.
- Diff `CLAUDE.md` against `AGENTS.md`. Only the intended lines may differ.
- Diff `docs/GUIDELINES_MANIFEST.md` against the submodule copy. There should be no difference.
- Grep the docs for `INTERNET.*absent`, `Image & Video Gallery` and `ships only English`.
  There should be no hits.
- Run the §10 checklist of `DOCS_FOLDER_GUIDELINE.md` against each doc.
- No code changes, so `flutter analyze` and `flutter test` are not affected. I will still run
  `flutter analyze` once as a sanity check.

## 6. Follow-up (separate plans)

- Add Sanskrit (`app_sa.arb`, delegates, picker), localized `app_config.json`, the About
  badge, `enableSplit = false`, and the tooltip and label-length audits. After that, update
  `known_gaps.md` and the descriptive docs.
