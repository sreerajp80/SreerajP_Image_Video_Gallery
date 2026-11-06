# Workflow Rules — SreerajP Image Video Gallery

This document sets out how every change to the SreerajP Image Video Gallery repository is
planned, approved, made and logged. Every developer and every AI assistant follows it, with no
exceptions. It is the detailed version of the workflow section in `CLAUDE.md` and `AGENTS.md`;
if they ever disagree, fix whichever is wrong so they match.

### Read first
- [CLAUDE.md](../CLAUDE.md) / [AGENTS.md](../AGENTS.md)
- [guidelines/flutter_project_engineering_standard.md](guidelines/flutter_project_engineering_standard.md) §21.1.1 (privacy rule)

---

## 1. Core Workflow Cycle

```text
1. Write plan (plans/) ──► 2. Get explicit approval ──► 3. Implement ──► 4. Write change log (change_log/)
```

---

## 2. Rule 1: Plan Before Changing

Before you create, edit or delete any project file (other than the plan itself), write a full
plan.

- **Location and name:** `plans/yyyymmdd_hhMMss_<short-slug>.md`, using local date and time
  (for example `plans/20260926_103730_align-docs-with-guidelines.md`).
- **The plan must include:**
  - a `**Status:**` line directly under the title;
  - what the issue is;
  - the list of files to be changed;
  - the plan for the fix;
  - how the change will be checked;
  - a short **"Security impact"** line when the plan touches network, storage, sign-in,
    permissions, deep links, WebViews, platform folders or dependencies (engineering standard
    §22.2).

### 2.1 Plan status values

Keep the `**Status:**` line current. Allowed values:

| Status | Meaning |
|---|---|
| `draft` | Being written; not yet shown for approval |
| `approval_pending` | Shown to the user; waiting for explicit approval |
| `in_progress` | Approved; work is under way |
| `completed` | Work finished and the change log written |
| `dropped` | Abandoned; will not be done |
| `partial_completion` | Some of the plan was done, the rest was not |

Normal path: `draft` → `approval_pending` → `in_progress` → `completed`. `dropped` and
`partial_completion` are end states for plans that stop early.

---

## 3. Rule 2: Explicit User Approval Gate

> **Writing a plan is not permission to carry it out.** After writing or changing a plan, STOP
> and wait for the user's explicit approval.

- **Counts as approval:** a clear yes, such as "yes", "approved" or "go ahead".
- **Does not count:** silence, a question, a request for clarification, or an unclear reply.
  Ask again.
- If the plan changes after feedback, show it again and get approval again.
- An earlier "go ahead" does not carry over to a later change.
- The only exception is when the user explicitly says to skip the plan for a specific change.

---

## 4. Rule 3: Log After Changing

After the change is made and checked, write a change log.

- **Location and name:** `change_log/yyyymmdd_hhMMss_<short-slug>.md`, using the local date and
  time when it is written.
- **The change log must include:**
  - a link to the plan it implements;
  - what was changed, and why;
  - the files created, changed or deleted;
  - the check results (`dart format`, `flutter analyze`, `flutter test`, or the doc checks
    used).

---

## 5. Rule 4: Relative Paths & Privacy Protection

`plans/` and `change_log/` files are committed and may become public on the internet. Write them
as if a stranger will read them; nothing should reveal the machine they came from.

- **Relative repository paths only** — for example `lib/main.dart`. Never an absolute path such
  as `C:\...`, `l:\...` or `file:///...`.
- **No local system details:** no OS user name, computer or host name, home or drive-letter
  path, network share name, LAN or internal IP address, local server URL with a port, device
  serial number, or personal email address.
- **No secrets:** no API key, token, password, keystore passphrase, credential or personal data.

| Do not write | Write instead |
|---|---|
| `l:\Android\MyApp\lib\main.dart` | `lib/main.dart` |
| `192.168.1.42:8080` | "the local dev server" |
| `someone@example.com` | "the release owner" |
| `keystorePassword=...` | "the keystore password (stored outside the repo)" |

---

## 5A. Rule 4A: The Guidelines Submodule Is Read-Only

`docs/guidelines/` is a git submodule shared by other projects. It is read-only here.

- Never edit, pull, check out or commit the submodule or its version.
- If a guideline needs a change, write a note for the user instead
  ([guidelines/DOCS_FOLDER_GUIDELINE.md](guidelines/DOCS_FOLDER_GUIDELINE.md) §1.1).
- If the folder is empty or missing, stop and ask the user.

---

## 5B. Rule 4B: CI Is Checks Only

GitHub CI runs only `flutter pub get`, code generation (`flutter gen-l10n`), the format check,
`flutter analyze`, `flutter test`, and other pass/fail check scripts.

- No Dependabot or other update bot. Dependencies are updated by hand.
- CI never builds release artifacts, signs, holds signing secrets, uploads, or publishes.
- Release builds are done locally
  ([guidelines/flutter_project_engineering_standard.md](guidelines/flutter_project_engineering_standard.md) §19).

---

## 6. Rule 5: Plain English Communication

- Write all responses, plans, change logs, code comments and documentation in **simple, plain
  English**.
- Use short sentences and common words.
- Explain any technical word you cannot avoid.

---

## 7. Verification & Code Quality Gates

Before committing any change or marking a plan `completed`:

```bash
dart format .
flutter analyze   # must report zero issues
flutter test      # must pass 100%
```

For a docs-only change, instead check that every relative link resolves and that the doc still
follows [guidelines/DOCS_FOLDER_GUIDELINE.md](guidelines/DOCS_FOLDER_GUIDELINE.md).
