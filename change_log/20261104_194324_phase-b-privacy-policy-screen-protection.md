# Change log — Phase B: privacy policy, support contact, screen protection, old OCR plans

**Plan:** [plans/20261102_201827_finish-all-pending-guideline-work.md](../plans/20261102_201827_finish-all-pending-guideline-work.md) (Phase B, steps 7–9)
**Date:** 2026-11-02 to 2026-11-03
**Gaps closed:** G17, G18, G28, G43

## What changed

- **G17, G18.**
  - New `PRIVACY.md`: no data collected, nothing sent off the device, Wi-Fi transfer only
    between phones the user pairs.
  - `assets/config/app_config.json` gained `email` and `privacyPolicy` rows (the policy URL
    points at `PRIVACY.md` in the public repository).
  - The About screen labels them (`aboutDetailEmail`, `aboutDetailPrivacyPolicy`), and the
    `https://` row opens through the existing `intents` channel.
  - `docs/PROJECT_PROFILE.md` updated.
  - Tests: `test/core/config/store_required_rows_test.dart` and a new About screen test.
- **G28.**
  - New setting `AppSettings.protectAllScreens` (default off), with a switch on the privacy
    settings screen and text in all three languages.
  - New `lib/widgets/common/app_screen_protection.dart`, placed in `MaterialApp.builder`. It
    sets `FLAG_SECURE` for the whole app when the switch is on. The vault stays protected
    whatever the switch says.
  - Tests: `test/widgets/common/app_screen_protection_test.dart` and a settings model test.
- **Bug found and fixed:** under Riverpod 3, `ref` cannot be used in `dispose()`. Two places
  failed silently because of it: the transfer screens' listener stop, and the `FLAG_SECURE`
  release in `SecureScreen`. They now keep the actions they need from `initState`. The new
  `test/tool/no_ref_in_dispose_test.dart` stops this pattern coming back.
- **G43:** the three OCR plans from 2026-09-26 are marked `dropped`, each with its reason.

## Security impact

Screen capture: protection can now cover every screen, and the vault is unchanged. The new
policy and contact are public text only; no data flow changed.
