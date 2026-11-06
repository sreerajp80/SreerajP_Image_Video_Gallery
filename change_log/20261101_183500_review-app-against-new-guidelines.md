# Review the app against the updated guidelines

Implements plan: `plans/20261101_182404_review-app-against-new-guidelines.md`

## What changed

- Added `docs/PROJECT_PROFILE.md`, approved by the user. It declares all three profiles, Android only,
  Google Play and direct APKs, and English, Malayalam and Sanskrit.
- Updated `docs/known_gaps.md` for guideline commit `644faee`: 15 new gaps (G16 to G30), a priority
  for all open gaps, and a section on how deep the review went.

No app code, test, build file or submodule file changed.

## Main findings

Release blockers: Sanskrit review (G9), device transfer rules (G16), privacy policy (G17), support
contact (G18), `targetSdk` (G19), Security Baseline record (G20), and 16 KB check (G24).

`docs/security.md` §10 says backup settings cover device transfer. That is wrong on Android 12 and
above, and it was not fixed here because this plan changes no code or security docs.

## Not done

- `flutter analyze` and `flutter test` were not run; they are with the user.
- Some standard sections were not reviewed in depth. `docs/known_gaps.md` §5 lists them.
- No gap was fixed. Each fix needs its own plan.
- Nothing was committed.
