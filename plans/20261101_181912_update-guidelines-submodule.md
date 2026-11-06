# Update the guidelines submodule

**Status:** completed

## Issue

The `docs/guidelines` submodule is behind its remote `master` branch by 9 commits
(`3f1aa0b` to `644faee`). This project is reading older rules than the current shared guidelines.

## Files to be changed

- `docs/guidelines` - the submodule moves to `644faee`. No file inside it is edited by hand.
- `change_log/` - one new change log.
- This plan file - status updates only.

## Plan for the fix

1. Move the submodule to the newest remote commit:
   `git submodule update --remote docs/guidelines`
2. Check that `git submodule status` shows `644faee`.
3. Check that the references this project makes into the guidelines still point to the right
   place: the paths in `CLAUDE.md` and `docs/GUIDELINES_MANIFEST.md`, and the section numbers
   `CLAUDE.md` cites (engineering standard 7.8, 8.3.1, 8.5, 8.6, and `guideline.md` section 1).
4. Report anything that no longer matches. Do not change it in this plan.
5. Write the change log.

## Out of scope

- Changing app code or project docs to meet the new guideline rules. If needed, that gets its own plan.
- Committing. The change stays uncommitted, like the other changes now in the working tree.

## Risk

Low. Only documents change, and app code and the build are not affected. To undo it, check out
`3f1aa0b` inside the submodule.
