# Workflow Rules — Image & Video Gallery

This document defines the development lifecycle, planning process, user approval gate, and changelog requirements for all modifications in the Image & Video Gallery repository. Every developer and AI assistant must follow these rules without exception.

### Read first
- [AGENTS.md](../AGENTS.md)
- [CLAUDE.md](../CLAUDE.md)
- [guidelines/guideline.md](guidelines/guideline.md)

---

## 1. Core Workflow Cycle

Every change to the repository follows the 3-step cycle:

```text
1. Write Plan (plans/) ──► 2. Obtain Explicit User Approval ──► 3. Implement & Log (change_log/)
```

---

## 2. Rule 1: Plan Before Changing

Before creating, editing, or deleting any project files (except creating the plan itself), a full plan MUST be written.

### Plan Specifications
- **Location**: `plans/yyyymmdd_hhMMss_<short-slug>.md` (e.g. `plans/20260818_161600_create_baseline_documentation_suite.md`).
- **Required Sections**:
  - `**Status:** Pending Approval` (updated to `Implemented` upon completion).
  - `## 1. Issue & Objective`: Plain-language explanation of what problem is being solved.
  - `## 2. Files to Change / Create / Delete`: List of affected files.
  - `## 3. Detailed Proposed Changes`: Exact breakdown of modifications per layer or component.
  - `## 4. Verification Plan`: Automated test commands and manual testing steps.

---

## 3. Rule 2: Explicit User Approval Gate

> [!IMPORTANT]
> Writing a plan is not permission to implement it. After creating or updating the plan file, the assistant MUST STOP and wait for explicit user approval.

- **What Counts as Approval**: Clear affirmative statements like "Approved", "Proceed", "Yes, go ahead", or clicking the Proceed action button.
- **What Does NOT Count**: Questions, requests for clarification, hypothetical comments, or ambiguous feedback.

---

## 4. Rule 3: Log After Changing

Immediately after completing the implementation and passing verification tests, a changelog MUST be written.

### Changelog Specifications
- **Location**: `change_log/yyyymmdd_hhMMss_<short-slug>.md` (matches plan timestamp and slug).
- **Required Sections**:
  - Reference to the corresponding plan in `plans/`.
  - Summary of changes made.
  - List of created, modified, or deleted files.
  - Verification results (`flutter analyze`, `flutter test`, `dart format`).

---

## 5. Rule 4: Relative Paths & Privacy Protection

Plans and changelogs are committed to version control and may become public on the internet.

### Strict Privacy Constraints
- **Relative Paths Only**: Always use repository-relative paths (e.g. `lib/screens/timeline_screen.dart`). NEVER use absolute paths (e.g. `C:\...`, `l:\...`, `file:///...`).
- **No Local System Details**: Never mention hostnames, OS usernames, local drive letters, LAN IP addresses, device serials, or local server ports.
- **No Secrets**: Never include keystore passwords, encryption keys, tokens, or personal identifiers.

---

## 6. Rule 5: Plain English Communication

- Write all responses, plans, changelogs, code comments, and documentation in **simple, plain English**.
- Use short sentences and common words.
- Clearly explain any unavoidable technical jargon.

---

## 7. Verification & Code Quality Gates

Before committing any change or marking a task complete:
1. Format code: `dart format .`
2. Run static analysis: `flutter analyze` (must be 0 warnings, 0 errors).
3. Run test suite: `flutter test` (must pass 100%).
