# Plan: Project Structure, Code, and Docs Guideline Conformance

**Status:** Implemented

## 1. Issue / Background
An audit of the project structure, code, and documentation against `docs/guidelines/guideline.md`, `docs/guidelines/flutter_project_engineering_standard.md`, `docs/guidelines/DOCS_FOLDER_GUIDELINE.md`, `AGENTS.md`, and `CLAUDE.md` revealed high conformance across the codebase:
- Static analysis is completely clean (`flutter analyze` reports 0 issues).
- Automated tests pass completely (1,793 tests pass).
- Formatting conforms to standards (all 444 Dart files formatted).
- Architecture adheres to Tier 1 layer-first structure with strict layer boundaries.
- Localization is 100% ARB-backed with `AppLocalizations` (EN and ML).
- About screen conforms to `guideline.md §1` dynamic data-driven pattern.
- Build flavors, ProGuard, and keystore security follow guidelines.

However, a few specific gaps must be addressed to achieve complete conformance:
1. **Missing Root `README.md`**: `flutter_project_engineering_standard.md §21.1` and `§21.3` mandate a root `README.md` covering prerequisites, setup, testing, code generation, build commands (flavors, APK split, AAB), database migrations, and offline architecture.
2. **`docs/project_structure.md`**: The top-level file tree does not list `README.md`, `AGENTS.md`, or `CLAUDE.md`.
3. **`docs/implementation_progress.md` and `docs/implementation_plan.md` Status**: All 14 phases (Phases 0 through 13) are 100% completed, but header status indicates "In Progress".
4. **Root Untracked Test Images**: Local test media files `photo_vault*.jpg` sit untracked in the root directory. They should be ignored in `.gitignore` to keep git status clean.

## 2. Proposed Changes

### Documentation & Structure
- **Create `README.md`**:
  - Add standard project overview.
  - Document prerequisites (Flutter SDK >=3.41.0, Dart SDK >=3.11.0, Android minSdk 24, targetSdk 35).
  - Detail setup steps (`flutter pub get`, `flutter gen-l10n`).
  - Document test commands (`flutter test`, `flutter analyze`).
  - Detail run and build commands with flavors (`--flavor dev`, `--flavor prod`), APK split-per-abi, and App Bundle commands with obfuscation and symbol extraction.
  - Document database migration procedure in `lib/repositories/database/`.
  - Document strict offline / local-only networking policy.
- **Update `docs/project_structure.md`**:
  - Include `README.md`, `AGENTS.md`, and `CLAUDE.md` in Section 1 Top-Level Project Layout.
- **Update `docs/implementation_plan.md` and `docs/implementation_progress.md`**:
  - Update status to `Completed`.

### Configuration
- **Update `.gitignore`**:
  - Add ignore entry for root test images `photo_vault*.jpg`.

## 3. Files to Create or Modify
- `README.md` (Create)
- `docs/project_structure.md` (Modify)
- `docs/implementation_plan.md` (Modify)
- `docs/implementation_progress.md` (Modify)
- `.gitignore` (Modify)
- `plans/20260905_203500_guideline_conformance_audit_and_readme.md` (This plan)
- `change_log/20260905_203500_guideline_conformance_audit_and_readme.md` (To be created after implementation)

## 4. Verification Plan
- Run `flutter analyze` to ensure 0 warnings.
- Run `flutter test` to ensure all 1,793 tests pass.
- Run `dart format .` to verify clean formatting.
- Check `git status` to verify clean working tree and proper `.gitignore` filtering.
