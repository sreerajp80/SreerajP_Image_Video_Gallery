# Change log — README refresh with feature graphic and screenshots

**Plan:** [plans/20261106_223813_readme-refresh-with-images.md](../plans/20261106_223813_readme-refresh-with-images.md)
**Date:** 2026-11-06

## What changed

`README.md` rewritten, in the same shape as the Authenticator's README:

- Feature graphic banner, a short description, and badges (Android 7.0+, Flutter 3.47, MIT).
- "Why this app" bullets.
- Screenshots: an HTML table of the 7 images (`docs/images/screenshots/`), with alt text, a note
  that all pictures are made up, and why there is no vault screenshot.
- Features grouped as in the store listing, limited to features checked in code. Adds BMP, PDF
  export, images from a PDF, video trim, frame and GIF tools, trash, default-app option.
- Availability: Android 7.0 (API 24)+, Play closed testing first, split APKs.
- Privacy and permissions: the local-only network rule, a plain-words table of the 11 permissions,
  links to `PRIVACY.md` and `docs/security.md` §11.
- Vault warning: a forgotten PIN cannot be recovered; restore before uninstalling.
- Developer sections with facts fixed: Flutter 3.47.6 / Dart 3.13.5 (lowest 3.41.0 / 3.11.0), real
  clone URL, flavors table, one command per block, Gradle daemon stop, migration example now V6
  (schema is at 5).
- Docs table gains `PRIVACY.md` and `docs/PROJECT_PROFILE.md`. Licence section added.

## Checks

- Every relative link and image path in the README points to an existing file.
- No absolute path, local address or secret in the README.
- **Not previewed as rendered on GitHub.** The in-app browser cannot act on local files. Check
  the page on GitHub after pushing.

## Still to do (owner)

`docs/images/` is untracked. Commit and push it with `README.md`, or GitHub shows broken images.
