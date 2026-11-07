# Plan — README refresh with feature graphic and screenshots

**Status:** completed

**Date:** 2026-11-06

---

## 1. The issue

- `README.md` shows no pictures. The feature graphic and 7 screenshots now exist in
  `docs/images/`, but nothing links to them.
- `docs/images/` and `PRIVACY.md` are **untracked** in git. GitHub cannot show an image or open a
  link to a file that is not pushed, so the README would show broken images until both are
  committed and pushed.
- Several README facts are out of date or too loose:

| README now | Fact |
|---|---|
| Flutter `^3.41.0` "or higher", Dart `^3.11.0` | The project builds with Flutter **3.47.6** / Dart **3.13.5**; 3.41.0 / 3.11.0 are only the lowest allowed (`CLAUDE.md`, CI) |
| `git clone ... <repository-url>` | The real URL is public: `https://github.com/sreerajp80/SreerajP_Image_Video_Gallery` |
| Conversion "JPEG, PNG, WebP" | Also BMP, PDF export, images from a PDF, video trim, frame grab and GIF |
| OCR "English and Malayalam" | True (`eng`, `mal` trained data). Keep |
| Says nothing on privacy, permissions, the vault PIN, availability, licence | `PRIVACY.md`, 11 permissions (`docs/security.md` §11), no PIN recovery, Play closed testing, MIT `LICENSE` |
| Docs table | Missing `PRIVACY.md`, `LICENSE`, `docs/PROJECT_PROFILE.md` |

## 2. The fix

Rewrite `README.md` with the same shape as the Authenticator's README, which already renders well
on GitHub:

1. Feature graphic banner at the top (`<p align="center"><img ... width="100%">`).
2. One-paragraph description, then badges: Android 7.0+, Flutter 3.47, MIT licence (shields.io
   images; these are loaded by the reader's browser on GitHub, not by the app).
3. **Why this app** — short bullets: offline, no account, no tracking, encrypted vault, phone-to-
   phone transfer, open source.
4. **Screenshots** — an HTML `<table>` of the 7 images at width 200, 4 + 3, each with `alt` text.
   Line: "All pictures in the screenshots are made up." Note that the vault blocks screenshots.
5. **Features** — grouped as in the store listing (browse, organise, edit, convert, text and
   codes, vault, transfer and backup, languages). Only features checked in code; no HDR or
   240 fps claims.
6. **Availability** — Android 7.0 (API 24) or newer; Google Play closed testing first; split APKs.
7. **Privacy and permissions** — the 11 permissions in plain words (one table), the local-only
   network rule, the vault warning (no PIN recovery; restore before uninstalling), links to
   `PRIVACY.md` and `docs/security.md`.
8. **Developer sections kept, with facts fixed** — prerequisites (exact and lowest versions),
   clone with the real URL, code generation, run, analyze/test/format, release builds (bash and
   PowerShell), database migrations, docs table (with the missing entries).
9. **Licence** — MIT, link to `LICENSE`.

All image paths are relative (`docs/images/...`), so they work on GitHub and in a local clone.

## 3. Files to be changed

| File | Action |
|---|---|
| `README.md` | Rewrite as above |
| `change_log/<timestamp>_readme-refresh-with-images.md` | New |

Not changed: app code, other docs, the submodule. Committing and pushing `docs/images/`,
`PRIVACY.md` and `README.md` is the owner's step; I will list it at the end.

## 4. Security impact

None on the app. The README describes the existing permissions and network rule only. The images
hold only made-up pictures and no device details.

## 5. Checks

- Every relative link and image path in the README points to a file that exists.
- No absolute path, local detail or secret in the README.
- Preview the README as GitHub would (rendered Markdown) before finishing.
