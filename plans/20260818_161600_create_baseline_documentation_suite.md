# Plan: Create Baseline Documentation Suite

**Status:** Implemented

## 1. Issue & Objective
The `docs/Project_Idea.md` document has been validated and finalized. In accordance with `docs/guidelines/DOCS_FOLDER_GUIDELINE.md` §6, every new Flutter project must have the 8 mandatory baseline documentation files initialized before source code implementation begins.

We need to create the complete baseline documentation suite under `docs/` tailored specifically for the Image & Video Gallery app.

## 2. Files to Create
- `docs/architecture.md` (Living)
- `docs/security.md` (Living)
- `docs/release_process.md` (Living)
- `docs/workflow_rules.md` (Living)
- `docs/dependencies.md` (Living)
- `docs/project_structure.md` (Living)
- `docs/implementation_plan.md` (Point-in-time)
- `docs/implementation_progress.md` (Point-in-time)

## 3. Detailed Scope & Content per Document

### 1. `docs/architecture.md` (Living)
- System design, Tier 1 layer-first structure (`core/`, `models/`, `repositories/`, `services/`, `providers/`, `screens/`, `widgets/`, `theme/`, `l10n/`).
- Riverpod state management, `go_router` navigation with auth/vault gating, `sqflite` + SQLite FTS5 database schema, and isolates/background processing.
- Multi-script / bi-directional rendering (English & Malayalam), `AtomicSaver` for safe file operations, and RAM-aware memory policy (`system_info2`).

### 2. `docs/security.md` (Living)
- 100% offline security boundary (zero internet permission, no network dependencies).
- Scoped storage & MediaStore integration (granular permissions without broad legacy storage).
- Hardware-backed AES-256-GCM encryption with Android Keystore for Private Vault.
- Anti-forensic secure media shredding (zero-fill multi-pass overwrite).
- `FLAG_SECURE` window protection, biometric/PIN auth, and zero-cache-leak policies.
- OWASP Mobile Top 10 compliance table.

### 3. `docs/release_process.md` (Living)
- Flavor matrix (`dev`, `prod`), package IDs, and display names.
- Keystore signing configuration, `--obfuscate`, and `--split-debug-info`.
- R8/ProGuard shrinking rules and `android:debuggable=false` verification.
- Release checklist, split APK and app bundle build commands.

### 4. `docs/workflow_rules.md` (Living)
- Plan-before-changing rule (`plans/yyyymmdd_hhMMss_<short-slug>.md` with status).
- Explicit user approval gate before executing code/doc modifications.
- Log-after-changing rule (`change_log/yyyymmdd_hhMMss_<short-slug>.md`).
- Relative repository paths only, privacy protection (no local system details or secrets).

### 5. `docs/dependencies.md` (Living)
- Approved open-source dependencies (Riverpod, `go_router`, `sqflite`, `crypto`, `image`, `local_auth`, `flutter_secure_storage`, `system_info2`, etc.).
- Explicitly blocked/prohibited dependencies (HTTP clients, cloud/BaaS, analytics, ads, network checkers).
- License compliance verification (open source only).

### 6. `docs/project_structure.md` (Living)
- Detailed directory layout matching Tier 1 layer-first architecture.
- Clear ownership and boundary rules for each directory.

### 7. `docs/implementation_plan.md` (Point-in-time)
- Dated roadmap (`2026-08-18`) breaking development into logical, testable phases:
  - Phase 1: Project Setup, Flavors, Keystore, App Config & Base Theme
  - Phase 2: Core Models, Database (`sqflite` + FTS5), and Storage Abstractions
  - Phase 3: Media Indexing, Scoped Storage & Fast Thumbnail Engine
  - Phase 4: Chronological Timeline, Dynamic Grid & Flashback Memories ("On This Day")
  - Phase 5: Fullscreen Image Viewer & Hardware Video Player
  - Phase 6: Non-Destructive Image Editor, Annotations, Redaction & Watermarking
  - Phase 7: Format Conversion, Compression, PDF Export & Video Utilities
  - Phase 8: Search, Multi-Tag Filtering & Duplicate/Similar Media Detection (pHash)
  - Phase 9: Virtual Albums & Device Folders
  - Phase 10: Secure Private Vault (AES-256-GCM, Biometrics, Shredding, `FLAG_SECURE`)
  - Phase 11: Batch Operations, Backup/Restore (`.gallerybak`) & Local P2P Wi-Fi Sync
  - Phase 12: In-Image Scanner (QR/Barcode) & Offline OCR
  - Phase 13: Localization (English & Malayalam), Settings, About Screen & Hardening

### 8. `docs/implementation_progress.md` (Point-in-time)
- Dated progress tracker (`2026-08-18`) with granular checkboxes for each phase and deliverable.

## 4. Verification Plan
- Verify all 8 files adhere to `docs/guidelines/DOCS_FOLDER_GUIDELINE.md` standards (snake_case naming, relative links, simple English, standard headers).
- Ensure zero contradictions with `AGENTS.md`, `CLAUDE.md`, and `docs/Project_Idea.md`.
- Verify no absolute paths or local system details exist in any file.
