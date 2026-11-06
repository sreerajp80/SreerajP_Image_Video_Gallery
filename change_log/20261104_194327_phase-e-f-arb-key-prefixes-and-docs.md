# Change log — Phases E and F: ARB key prefixes, shorter labels, docs

**Plan:** [plans/20261102_201827_finish-all-pending-guideline-work.md](../plans/20261102_201827_finish-all-pending-guideline-work.md) (Phase E step 16 with the §6 addendum, option (a); Phase F)
**Date:** 2026-11-04
**Plan status:** `completed`
**Gaps closed:** G11. New gap: G50.

## What changed

- **G11: key prefixes.**
  - 967 ARB keys were renamed to a §8.6 category prefix (`action`, `label`, `title`, `tab`,
    `tooltip`, `desc`, `help`, `empty`, `error`, `body`). That is 966 by script, plus `appTitle`
    → `titleApp`.
  - Each key was sorted by its name, then by how the code uses it (tooltip, title, button,
    subtitle…), then by the length of its English text.
  - A trailing word that only repeats the prefix was dropped (`compareConfirmTitle` →
    `titleCompareConfirm`), unless that would clash with another key.
  - The renames were applied in all three ARB files (with their `@` descriptions), in 110 Dart
    files (only through an `AppLocalizations` receiver), and in the parity test's allow-list.
  - Only `madeWithLove` and `madeWithLoveA11y` keep their names, as `guideline.md` fixes them.
- **Shorter English (option (a)).** 40 short labels over 20 characters were shortened, keeping
  their meaning. Examples:
  - "Strip Camera & Lens Serial Numbers" → "Serial Numbers", under the section "Choose What to
    Strip";
  - "Skip forward 10 seconds" → "Forward 10 seconds", and its partner → "Back 10 seconds".

  Malayalam and Sanskrit were not changed.
- **Tests** (`test/l10n/translation_parity_test.dart`):
  - every key must carry a prefix;
  - the length test now covers every short label;
  - six Malayalam and Sanskrit labels that are still too long sit on `overBudgetAwaitingReview`
    (G50), and a test fails if one of them is fixed but left on the list.
- **Phase F docs.**
  - `docs/known_gaps.md`: G10–G13, G17–G19, G21, G23, G24, G28, G38–G41, G43, G44, G46, G48 and
    G49 are marked fixed. Open now: G9 and the new G50, plus the owner's phone checks.
  - `docs/architecture.md`: `lib/core/domain/`, schema v5, the toolchain choice, the language
    key and the "Hide content" setting.
  - `docs/dependencies.md`: the OCR plugin override, and `shared_preferences`.
  - `docs/security.md`: screen protection, `SharedPreferences` holding only the language, and
    the secure storage options at 11.2.0.
  - `docs/release_process.md`, `docs/implementation_progress.md`, `docs/project_structure.md`.

## Results

`flutter test`: 2,204 tests pass. `flutter analyze`: no issues. `dart format`: no changes.

## Still open

- G9 and G50 need a fluent Sanskrit and Malayalam reader.
- Owner: build after `targetSdk` 36, and phone checks (navigation modes, OCR, "Hide content",
  vault create and unlock).
