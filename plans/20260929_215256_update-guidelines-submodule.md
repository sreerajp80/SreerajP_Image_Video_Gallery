# Update the docs/guidelines submodule

**Status:** completed

## Files to be changed

- `docs/guidelines` (submodule pointer only)

## What the issue is

The `docs/guidelines` submodule (shared Flutter guidelines) is 2 commits behind its
remote `master` branch. The new upstream commits add four words (Contact, Call, Tag,
Phone number) to the §8.5.4 glossary in `flutter_project_engineering_standard.md`,
plus the plan and change log for that upstream change. 3 files, 76 lines added,
nothing removed.

## Plan for the fix

1. Fast-forward the submodule to the latest remote `master`
   (`git -C docs/guidelines pull --ff-only origin master`).
2. Check that `git submodule status` shows the new commit.
3. Do not commit. The parent repo will show the new submodule pointer as a change, for
   the user to commit with their other work.
4. Write a change log in `change_log/`.

No app code changes, so no need to run `flutter analyze` or `flutter test`.
