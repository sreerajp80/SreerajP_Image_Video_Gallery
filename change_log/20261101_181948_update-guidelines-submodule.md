# Update the guidelines submodule

Implements plan: `plans/20261101_181912_update-guidelines-submodule.md`

## What changed

- `docs/guidelines` moved from `3f1aa0b` to `644faee`, the newest commit on the remote `master` branch (9 commits).
- No file inside the submodule was edited by hand.
- After the update, the submodule was put back on its local `master` branch and fast-forwarded.
  `git submodule update --remote` had left it on a detached HEAD at the same commit. This step was not in the plan.
- Nothing was committed.

## Reference check

Still correct:

- All guideline paths named in `CLAUDE.md` and `docs/GUIDELINES_MANIFEST.md` exist.
- Sections 7.8, 8.3.1 and 8.6 of the engineering standard and section 1 of `guideline.md` exist with the expected topics.

No longer correct (not changed here, as the plan said):

- `CLAUDE.md` and `AGENTS.md` point to a Sanskrit glossary in engineering standard section 8.5. The glossary is now in
  `docs/guidelines/language_packs/sanskrit_malayalam.md`, section 4.4.
- `docs/known_gaps.md` (G9 and G14) cites sections 8.5.1 and 8.5.4, which were not found as headings in the
  engineering standard. Section 8.5 is now one short section on translation quality and language packs.
- `docs/GUIDELINES_MANIFEST.md` is older than the submodule's copy. It does not list `platform_store_readiness.md`,
  `AI_AGENT_START_HERE.md`, `PROJECT_PROFILE_TEMPLATE.md` or the language pack.

## Not checked

Whether the app meets the new guideline rules. This update only changes documents, so no build or test was run.
