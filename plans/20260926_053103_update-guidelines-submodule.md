# Update the `docs/guidelines` submodule

**Status:** completed

## Issue

The `docs/guidelines` submodule (shared Flutter guidelines) points to commit `7e664ba`.
The upstream `master` branch is now at `eb4b462`, which is 3 commits ahead
(`8c4861a`, `7ed5a36`, `eb4b462`).

The new commits change 20 files in the submodule (about 2,200 lines added, 86 removed).
The biggest changes are in:

- `flutter_project_engineering_standard.md`
- `guideline.md`
- `release_process.md`
- `flutter_build_flavors_guide.md`
- `AGENTS_MD_GUIDELINE.md`, `CLAUDE_MD_GUIDELINE.md`, `GUIDELINES_MANIFEST.md`, `README.md`

## Files to be changed

- `docs/guidelines` (submodule pointer only: `7e664ba` → `eb4b462`)
- `change_log/20260926_<time>_update-guidelines-submodule.md` (new change log)

No app source code (`lib/`, `test/`, `android/`) is changed.

## Plan

1. Check out `origin/master` (`eb4b462`) inside `docs/guidelines`.
2. Confirm with `git submodule status` that the parent repo sees the new pointer.
3. Write the change log.
4. Do not commit unless the user asks.

## Note

The updated guidelines may add new rules (for example, about localization and the
About screen). This plan only moves the pointer. Any follow-up work to make the app
match new rules will need its own plan.
