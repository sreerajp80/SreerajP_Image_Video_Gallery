# Plan: Align project structure with the guidelines

**Status:** completed

**Date:** 2026-09-26

---

## 1. What the issue is

The project was checked against the structure rules in:

- `docs/guidelines/guideline.md` §3 (standard `lib/` layout) and §4 (checklist)
- `docs/guidelines/flutter_project_engineering_standard.md` §3 (Tier 1 layout, structure rules,
  recommended root layout)
- `docs/guidelines/DOCS_FOLDER_GUIDELINE.md` (the `docs/` folder)

Most of the project already follows them: `lib/` is Tier 1 layer-first, `core/config/` holds
`AppConfig` + `ConfigService`, the About screen is under `screens/`, `plans/` and `change_log/`
exist, and all 8 baseline docs exist. These gaps were found:

| # | Gap | Rule |
|---|-----|------|
| 1 | No `analysis_options.yaml` at the project root. `flutter_lints` is already a dev dependency, but it is never turned on, so `flutter analyze` runs with default rules only. | Engineering standard §3.3 root layout |
| 2 | `DeviceMemoryService` is a service, but it lives in `lib/core/device/`. The project already has `lib/services/device/`. Services belong in `services/`. | guideline.md §3 (`services/` = platform + business services) |
| 3 | Five screen tests live under `test/widgets/` while the screens live under `lib/screens/`. The test folder does not mirror `lib/`. | Engineering standard §3.2 ("`test/` SHOULD mirror `lib/`"), CLAUDE.md testing rules |
| 4 | `docs/project_structure.md` must be updated to match the changes above. | DOCS_FOLDER_GUIDELINE.md §5 (living doc kept current) |

The five misplaced tests (gap 3):

| Now | Moves to (mirrors `lib/`) |
|-----|---------------------------|
| `test/widgets/folders_tab_test.dart` | `test/screens/home/folders_tab_test.dart` |
| `test/widgets/compare/photo_compare_screen_test.dart` | `test/screens/compare/photo_compare_screen_test.dart` |
| `test/widgets/settings/about_screen_test.dart` | `test/screens/settings/about_screen_test.dart` |
| `test/widgets/settings/settings_screen_test.dart` | `test/screens/settings/settings_screen_test.dart` |
| `test/widgets/viewer/media_viewer_screen_test.dart` | `test/screens/viewer/media_viewer_screen_test.dart` |

### Checked and left as they are (with reason)

- **`assets/tessdata_config.json`** sits at the `assets/` root, not in `assets/config/`. The OCR
  plugin hard-codes this exact path, so it cannot move. It will be noted as an exception in
  `docs/project_structure.md`.
- **Missing `lib/l10n/app_sa.arb` (Sanskrit).** This is a real MUST gap, but it is a full
  translation job, not a folder move. It is already tracked as G1–G3 in `docs/known_gaps.md`.
  Out of scope here.
- **`docs/Project_Idea.md`** is not snake_case. DOCS_FOLDER_GUIDELINE.md §3 says older files
  are tolerated and must **not** be renamed just for style, and many plans/logs link to it.
  Left as is.
- **`.github/workflows/`** and **`integration_test/`** are optional in the recommended root
  layout ("required only when end-to-end coverage applies"). Not added.
- **`photo_vault*.jpg`** at the root are local test images. They are already git-ignored and
  never committed. No change.
- **Extra `core/` folders** (`routing/`, `storage/`, `text/`) and `widgets/dev/` are allowed —
  guideline.md §3 lets apps add folders, and Tier 2 lists `core/storage/` too.
- Grouped test files (for example `test/core/routing/vault_routes_test.dart`,
  `test/models/pdf/pdf_models_test.dart`) have no single matching source file, but they sit in
  the folder that mirrors what they test. No change.

---

## 2. Files to be changed

| File | Change |
|------|--------|
| `analysis_options.yaml` | **New.** `include: package:flutter_lints/flutter.yaml`; exclude generated files (`lib/l10n/generated/**`, `**/*.g.dart`). |
| Any `lib/` or `test/` file that the new lints flag | Fix the lint findings (only if there are some). |
| `lib/core/device/device_memory_service.dart` | **Move** to `lib/services/device/device_memory_service.dart` (`git mv`). Remove the empty `lib/core/device/` folder. |
| `lib/providers/media_providers.dart` | Update the import path. |
| `lib/services/thumbnail/thumbnail_service.dart` | Update the import path. |
| `test/core/device/device_memory_service_test.dart` | **Move** to `test/services/device/device_memory_service_test.dart`; update import. |
| `test/services/thumbnail/thumbnail_service_test.dart` | Update the import path. |
| The five screen tests in the table above | **Move** with `git mv`; fix any relative helper imports if needed. |
| `docs/project_structure.md` | Update the `lib/` and `test/` trees; add `analysis_options.yaml` to the root tree; note the `tessdata_config.json` exception. |
| `docs/architecture.md`, `AGENTS.md`, `README.md` | Only if they mention `core/device/` or the old test paths (a grep will confirm). |
| `change_log/<timestamp>_align-project-structure.md` | **New** change log after the work is done. |

---

## 3. Plan for the fix

1. Create `analysis_options.yaml` using the `flutter_lints` rules.
2. Run `flutter analyze`. Fix any new findings. If the new rules flag a very large number of
   issues (more than about 40), stop and report back before fixing them, since that would grow
   the change well beyond a structure fix.
3. `git mv` the device memory service and its test into `services/device/`, and update the
   four imports.
4. `git mv` the five screen tests into `test/screens/...`.
5. Grep the whole repo (code and docs) for the old paths and fix every reference.
6. Update `docs/project_structure.md`.
7. Run `dart format .`, `flutter analyze` (must be clean) and `flutter test` (must pass).
8. Write the change log and set this plan's status to `completed`.

No app behaviour changes. Only file locations, imports, lint config and docs change.
