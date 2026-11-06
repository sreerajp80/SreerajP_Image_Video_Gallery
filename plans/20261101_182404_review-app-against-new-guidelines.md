# Review the app against the updated guidelines

**Status:** completed

## The issue

`docs/guidelines` moved to `644faee`. The last full check of the app (`docs/known_gaps.md`) was made
against `eb4b462`. Since that commit the guidelines changed a lot: about 5,000 lines added across 22
documents. New documents include `platform_store_readiness.md`, `AI_AGENT_START_HERE.md`,
`PROJECT_PROFILE_TEMPLATE.md` and the language pack.

Nobody has checked the app against these rules, so `docs/known_gaps.md` may be out of date.

One document must come first. Rules for platforms, stores and languages apply only to what
`docs/PROJECT_PROFILE.md` declares, and that file does not exist. Without it the review cannot say
which rules apply.

## Files to change

| File | Change |
|---|---|
| `docs/PROJECT_PROFILE.md` | New. Copied from the template and filled in. |
| `docs/known_gaps.md` | Updated with the review result and the guideline commit `644faee`. |
| `change_log/<timestamp>_review-app-against-new-guidelines.md` | New. Records what was reviewed. |

No app code, test, build file or submodule file changes in this plan. Each fix gets its own plan
later. This keeps the review apart from the fixes, as `AI_AGENT_START_HERE.md` §5 asks.

## The plan

### Step 1. Create the project profile

1. Fill in what the code and docs already show: app name, app id, package name, Android only,
   minSdk, flavors, three languages, Riverpod, Tier 1 layout, permissions, no backend, no analytics.
2. Ask the user, in one numbered list, only what the code cannot show. For example: store or direct
   APK, public support contact, privacy policy URL, licence, who reviews each translation, and
   release owner.
3. Write anything still unknown as `TODO — needed before <gate>`. Never guess a value.
4. Propose these profiles, for the user to confirm:
   - `Core Baseline`: always applies.
   - `Sensitive Data Extension`: the vault is a local encrypted store, so the rule points here.
   - `Production App Extension`: only if the app ships to real users or a store.
5. Show the filled profile and get the user's yes before saving it.

### Step 2. Review, reading only

Check the app against the rules that the profile turns on:

| Area | Rules | What to check |
|---|---|---|
| Docs set | `DOCS_FOLDER_GUIDELINE.md` §6 | The 9 baseline files exist and follow the file rules |
| Agent files | `CLAUDE_MD_GUIDELINE.md`, `AGENTS_MD_GUIDELINE.md` | `CLAUDE.md` and `AGENTS.md` meet the required content |
| Common rules | `guideline.md`, including its §4 checklist | About config and badge, keystore, `lib/` layout |
| Engineering | `flutter_project_engineering_standard.md` | Structure, UI, accessibility, l10n, logging, errors, database, CI (§19), Definition of Done (§23) |
| Security | Standard §15.1, `security.md` §1.1 and §12 | Security Baseline, OWASP checklist, against `docs/security.md` |
| Flavors | `flutter_build_flavors_guide.md` | Gradle, signing and flavor setup |
| Languages | `language_packs/sanskrit_malayalam.md` | Glossary and Sanskrit rules |
| Stores | `platform_store_readiness.md` §1 and the declared channel | Only for channels the profile declares |
| Release | `release_process.md` §8, `AI_AGENT_START_HERE.md` §6 | Our `docs/release_process.md` against the new template |

Also recheck each open gap (G9 to G15), since their rule numbers may have moved.

The user runs these two commands and shares the result, because the rule checks do not replace them:

```bash
flutter analyze
```

```bash
flutter test
```

### Step 3. Write the result

1. Update `docs/known_gaps.md`. Each new gap gets a number, what the app does today, and the exact
   rule it breaks.
2. Mark each gap as one of: `release blocker`, `should fix`, or `accepted exception`.
3. If a rule itself looks wrong or conflicts with another, write a note for the user. Do not edit the
   submodule.
4. Write the change log.
5. Give the user a short list of suggested fix plans, in priority order.

## Limits of this review

- It finds rule gaps by reading code. It does not prove the app behaves correctly on a device.
- Store rules change every year. Current store rules still need a check before each release.
- Sanskrit quality stays unverified until a fluent reader checks it (G9).
- The working tree has many uncommitted changes. The result describes the tree as it is on review
  day, not a fixed commit, unless the user commits first.

## Tests

No code changes, so no new tests. `flutter analyze` and `flutter test` are part of Step 2.
