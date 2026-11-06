# Plan: Tidy a stale plan status and a few out-of-date doc facts

**Status:** completed

## Files to change

- `plans/20260910_194900_update_roadmap_matrix_versioning.md`
- `docs/known_gaps.md`
- `docs/feature_improvements_and_standout_features.md`
- `change_log/<timestamp>_tidy-stale-plan-and-doc-facts.md` (new)

## Issue

A check against the guidelines on 2026-11-05 found:

1. `plans/20260910_194900_update_roadmap_matrix_versioning.md` has been `approval_pending`
   since September. It was never carried out: the §7 roadmap table still shows `v1.1.0`–`v1.5.0`.
   Later, a note was added to the same doc (the "§7 roadmap" row in its gaps table) that says to
   read the version labels as priority order only. That note replaced the plan's idea. The
   workflow rules say a plan must end in a final status.
2. `docs/known_gaps.md` §5 ends with the results from 2026-11-01 (1,990 tests). That line is a
   true record for its date, but there is no newer result. Today: `flutter analyze` clean,
   `dart format` changes nothing, `flutter test` passes all 2,204 tests.
3. `docs/feature_improvements_and_standout_features.md` has two facts that are now wrong:
   - the tech table says `flutter_riverpod` (v2.x); the app moved to Riverpod 3 on 2026-11-02;
   - the "§7 roadmap" note says the app is at `2.5.2`; `pubspec.yaml` says `2.5.4`.

## Fix

1. In the old plan, set `**Status:** dropped` and add a short "Why dropped" line: superseded by
   the note in the same doc that treats the version labels as priority order only. Keep the rest
   of the plan as it is (it is a record).
2. In `known_gaps.md` §5, keep the 2026-11-01 line and add a new line under it:
   "Results on 2026-11-05: `flutter analyze` is clean, `dart format` changes nothing, and
   `flutter test` passes all 2,204 tests. No Android build was run."
3. In the feature doc:
   - change `(v2.x, strict layer separation)` to `(v3.x, strict layer separation)`;
   - change "The app is already at `2.5.2`." to "The app is already past these versions
     (see `pubspec.yaml`)." so the note does not go stale again with every release.
4. Write the change log.

No code changes. No tests needed; I will re-run nothing because only Markdown changes.

**Security impact:** none (docs and plan files only).
