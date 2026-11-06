# Change log — Phase C: layers, large files, unused keys, language key

**Plan:** [plans/20261102_201827_finish-all-pending-guideline-work.md](../plans/20261102_201827_finish-all-pending-guideline-work.md) (Phase C, steps 10–13)
**Date:** 2026-11-03 to 2026-11-04
**Gaps closed:** G10, G41, G44, G46

## What changed

- **G46: the UI no longer imports services.**
  - 18 pure helpers with no I/O moved from `lib/services/` to `lib/core/domain/<area>/`, and
    their tests to `test/core/domain/`.
  - Nine value types moved from service files to `lib/models/`. Each service re-exports its
    type, so other importers did not change.
  - Screens and widgets now reach services only through providers.
  - New `test/tool/layer_imports_test.dart` fails if a screen or widget imports a service.
- **G41: large files.**
  - Split, with no change in behaviour:
    - the media viewer: `lib/widgets/viewer/viewer_app_bar.dart`, `viewer_bottom_bar.dart`,
      `viewer_dialogs.dart`;
    - the timeline: `lib/widgets/timeline/timeline_body.dart`, `timeline_messages.dart`;
    - the privacy sheet: `lib/widgets/privacy/privacy_audit_card.dart`;
    - the photo compare screen: `lib/widgets/compare/compare_controls.dart`.
  - The nine files still over 500 lines each have a reason in the new "Files Over 500 Lines"
    table in `docs/architecture.md`.
- **G44:** 29 ARB keys used nowhere were removed from all three ARB files and from the parity
  test's allow-list.
- **G10: the language key.**
  - The language choice is stored in `SharedPreferences` under `app_language` (`system` or a
    language code), through the new `lib/services/settings/language_preference_store.dart`.
  - `AppSettingsService` reads it and writes it, and no longer writes `localeCode` to the JSON
    file.
  - The first load moves an old `localeCode` across once.
  - New dependency: `shared_preferences` (BSD-3-Clause). Its tree adds only the
    `shared_preferences` platform packages, and no blocked package.
  - Tests: `test/services/settings/app_settings_language_test.dart` (migration, round trip,
    unreadable store).

## Security impact

Storage: one non-secret value (the language) now sits in `SharedPreferences`. `docs/security.md`
and `docs/architecture.md` say so. Nothing secret moved.

## Lesson recorded

Git Bash rewrites command arguments that start with `//`. Split anchors written as `///` lost a
slash, which damaged two doc comments and dropped two constants. `flutter analyze` caught it, and
the tests did not. Later scripts set `MSYS_NO_PATHCONV=1` or keep the anchors inside the script.
