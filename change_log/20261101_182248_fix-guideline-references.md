# Fix outdated guideline references

Implements plan: `plans/20261101_182131_fix-guideline-references.md`

## What changed

- `CLAUDE.md` and `AGENTS.md`: the Sanskrit rule now points to the glossary in
  `docs/guidelines/language_packs/sanskrit_malayalam.md` section 4.4. The pack is added to the "Read these docs" table.
- `docs/known_gaps.md`: G9 now cites engineering standard 8.5 and the review rule in language pack 4.4.
  G14 now cites language pack 3 and 4.4. Both gaps stay open.
- `docs/GUIDELINES_MANIFEST.md`: replaced with the submodule's current copy. The `guideline.md` row keeps this
  project's points, because the new copy calls the badge optional and does not name the three languages.
  The wording was adjusted to fit the new row.

## Checks

- `guideline.md` section 2 is still the keystore rules, so the citation in `docs/release_process.md` stays.
- Every `docs/guidelines/` path in the new manifest exists, and so does the language pack path.
- No file inside `docs/guidelines` was changed. The submodule is still at `644faee`.
- Only documents changed, so no build or test was run. Nothing was committed.

## Still open

- The new guidelines require `docs/PROJECT_PROFILE.md`, which does not exist.
- The app has not been checked against the other new guideline rules, including the language pack.
