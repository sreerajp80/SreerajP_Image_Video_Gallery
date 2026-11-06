# Change log: Tidy a stale plan status and a few out-of-date doc facts

**Plan:** [plans/20261105_183939_tidy-stale-plan-and-doc-facts.md](../plans/20261105_183939_tidy-stale-plan-and-doc-facts.md)  
**Date:** 2026-11-05

## What changed

1. `plans/20260910_194900_update_roadmap_matrix_versioning.md`: status changed from
   `approval_pending` to `dropped`, with a "Why dropped" line. The plan was never carried out;
   a later note in the feature doc (read the §7 version labels as priority order only) replaced it.
   The rest of the plan is kept as a record.
2. `docs/known_gaps.md` §5: added "Results on 2026-11-05" under the 2026-11-01 line:
   `flutter analyze` clean, `dart format` changes nothing, `flutter test` passes all 2,204 tests,
   no Android build run. The 2026-11-01 line (1,990 tests) is kept, because it was true on its date.
3. `docs/feature_improvements_and_standout_features.md`:
   - tech table: `flutter_riverpod` `(v2.x, …)` → `(v3.x, …)`, matching the Riverpod 3 upgrade;
   - "§7 roadmap" note: "The app is already at `2.5.2`." → "The app is already past these
     versions (see `pubspec.yaml`)." so it does not go stale with each release.

## Notes

- The first edit added lines with LF endings into files that use CRLF in the working copy. The
  three files were made uniform again; Git stores them with LF as before.
- Markdown only. No code changed, so analyze and tests were not re-run.
- Security impact: none.
