# Fix outdated guideline references

**Status:** completed

## Issue

The update of `docs/guidelines` to `644faee` moved some content
(see `change_log/20261101_181948_update-guidelines-submodule.md`). Project docs now point to the wrong place:

- `CLAUDE.md` and `AGENTS.md` say the Sanskrit glossary is in engineering standard section 8.5. It is now in
  `docs/guidelines/language_packs/sanskrit_malayalam.md`, section 4.4.
- `docs/known_gaps.md` G9 and G14 cite sections 8.5.1 and 8.5.4, which no longer exist.
- `docs/GUIDELINES_MANIFEST.md` is an older copy. It does not list the new guideline documents.

## Files to be changed

- `CLAUDE.md`
- `AGENTS.md`
- `docs/known_gaps.md`
- `docs/GUIDELINES_MANIFEST.md`
- `change_log/` - one new change log.
- This plan file - status updates only.

No file inside `docs/guidelines` is changed.

## Plan for the fix

1. `CLAUDE.md` and `AGENTS.md`, same edit in both:
   - In the Sanskrit rule, point to `docs/guidelines/language_packs/sanskrit_malayalam.md` section 4.4.
   - Add the language pack to the "Read these docs" table, for work on translations. The pack is now
     mandatory for projects that declare these languages.
2. `docs/known_gaps.md`:
   - G9: cite engineering standard 8.5 and the review rule in language pack 4.4.
   - G14: cite language pack sections 3 and 4.4. The gap itself stays open, because the app wording is not changed.
3. `docs/GUIDELINES_MANIFEST.md`: replace it with the submodule's current copy, then put back this
   project's own wording in the `guideline.md` row (the About badge and the three mandatory languages),
   if the new copy does not already say the same thing.
4. Check that `guideline.md` section 2 is still the keystore rules, as `docs/release_process.md` cites it.
   Fix the citation if not.
5. Write the change log.

The other section numbers checked (7.8, 8.3.1, 8.3.3, 8.4, 8.6, 8.7, 8.8, 11.1, 14.1, 21.1.1) still exist, so they stay.

## Out of scope

- Making the app meet the new guideline rules. For example, `docs/PROJECT_PROFILE.md` is now required and
  does not exist, and the language pack rules have not been checked against the app. That needs its own review and plan.
- Changing the Malayalam wording in G14.
- Replacing section numbers with titles everywhere. It is more change than the problem needs now.
- Committing.

## Risk

Low. Only documents change, so no build or test is needed. `CLAUDE.md` and `AGENTS.md` guide later work,
so their new paths will be checked to confirm they exist.
