# Change log — Phase D: provider tests and screen tests in every language

**Plan:** [plans/20261102_201827_finish-all-pending-guideline-work.md](../plans/20261102_201827_finish-all-pending-guideline-work.md) (Phase D, steps 14–15)
**Date:** 2026-11-03
**Gaps closed:** G12, G13

## What changed

- **G13:** 16 new test files in `test/providers/`, one for each provider file that had none:
  album, backup, batch, convert, duplicate, memory, notes, ocr, pdf_tools, privacy, scan, search,
  sync, tag, theme and video_tools.
  - They cover state changes, error states and the revision bumps that refresh other screens.
  - `media_providers` and `media_intent_providers` were already tested under other file names.
  - Retry was not tested per provider, because the app turns it off once for every provider
    (`ProviderScope(retry: noProviderRetry)`).
- **G12: every screen test now runs in English, Malayalam and Sanskrit.**
  - New `test/helpers/locale_checks.dart`. After a screen is pumped, it checks for:
    - no exception (an overflow is one);
    - no English string from `app_en.arb` showing under `ml` or `sa`;
    - a tooltip on every `IconButton` and `FloatingActionButton`.
  - Seven screen test files use it: compare, viewer, folders, timeline, help, settings and
    About.
- **Bug found and fixed:** the viewer's bottom bar overflowed by 378 pixels in Malayalam and 165
  in Sanskrit. Its five actions now share the width equally (`Expanded`), and a label may use
  two lines (`lib/widgets/viewer/viewer_bottom_bar.dart`).

## Results

`flutter test`: 2,202 tests pass. `flutter analyze` and `dart format` are clean.
