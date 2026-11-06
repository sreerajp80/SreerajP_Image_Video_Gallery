# Change log: Align project structure with the guidelines

**Date:** 2026-09-26

**Plan:** [plans/20260926_060817_align-project-structure.md](../plans/20260926_060817_align-project-structure.md)

---

## 1. Summary

The project layout now follows `docs/guidelines/guideline.md` §3 and
`docs/guidelines/flutter_project_engineering_standard.md` §3. Lint rules are switched on, one
misplaced service moved into `services/`, and screen tests now mirror `lib/screens/`. No app
behaviour changed.

---

## 2. What changed

### 2.1 Lint rules

- **New `analysis_options.yaml`** at the project root. It includes
  `package:flutter_lints/flutter.yaml` (already a dev dependency) and excludes generated files
  (`lib/l10n/generated/**`, `**/*.g.dart`, `build/**`).
- Turning the rules on raised 29 findings. All were fixed:
  - 27 were fixed with `dart fix --apply` (`const` use, `if` braces, a single cascade).
  - `lib/screens/notes/media_notes_screen.dart`: the back-navigation handler now checks
    `context.mounted` instead of `mounted` (`use_build_context_synchronously`).
  - `lib/services/viewer/viewer_transform_service.dart` imported `package:vector_math` without
    declaring it (`depend_on_referenced_packages`). It only needs `Matrix4`, so it now imports
    `package:flutter/rendering.dart show Matrix4`. `dart fix` had tried to add
    `vector_math: any` to `pubspec.yaml`; that was reverted, so **no dependency was added**.

### 2.2 Service moved into `services/`

| From | To |
|------|----|
| `lib/core/device/device_memory_service.dart` | `lib/services/device/device_memory_service.dart` |
| `test/core/device/device_memory_service_test.dart` | `test/services/device/device_memory_service_test.dart` |

Imports updated in `lib/providers/media_providers.dart`,
`lib/services/thumbnail/thumbnail_service.dart` and
`test/services/thumbnail/thumbnail_service_test.dart`. The empty `lib/core/device/` folder was
removed.

### 2.3 Screen tests moved to mirror `lib/screens/`

| From | To |
|------|----|
| `test/widgets/folders_tab_test.dart` | `test/screens/home/folders_tab_test.dart` |
| `test/widgets/compare/photo_compare_screen_test.dart` | `test/screens/compare/photo_compare_screen_test.dart` |
| `test/widgets/settings/about_screen_test.dart` | `test/screens/settings/about_screen_test.dart` |
| `test/widgets/settings/settings_screen_test.dart` | `test/screens/settings/settings_screen_test.dart` |
| `test/widgets/viewer/media_viewer_screen_test.dart` | `test/screens/viewer/media_viewer_screen_test.dart` |

The relative helper import in `settings_screen_test.dart` still resolves (same folder depth).
Empty `test/widgets/settings/` and `test/widgets/viewer/` folders were removed.

### 2.4 Docs

- `docs/project_structure.md`: added `analysis_options.yaml` to the root tree, removed
  `core/device/`, noted `DeviceMemoryService` under `services/device/`, explained why
  `assets/tessdata_config.json` stays at the `assets/` root, and added §4 "Test Layout".

---

## 3. Left as is (see plan §1)

- `lib/l10n/app_sa.arb` (Sanskrit) is still missing — tracked in `docs/known_gaps.md` G1–G3.
- `docs/Project_Idea.md` keeps its older name (guideline says not to rename for style only).
- `.github/workflows/` and `integration_test/` are optional and were not added.

---

## 4. Verification

- `dart format .` — clean.
- `flutter analyze` — no issues found (now with `flutter_lints` rules on).
- `flutter test` — all 1,896 tests passed.
