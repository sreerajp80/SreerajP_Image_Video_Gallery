# Project Profile — Drishya Gallery

> Filled in from `docs/guidelines/PROJECT_PROFILE_TEMPLATE.md`. Every rule that depends on a platform,
> store or language applies only when this file declares it (engineering standard §1.2.1).
> A plain value was given by the user or read from the code. `TODO` values block the gate they name.
> This file is committed: public information only.

---

## 0. Product brief

| Item | Value |
|---|---|
| What the app does | See §1 (short description) |
| Main features | Viewing, organizing and managing local media; encrypted vault; local Wi-Fi transfer between paired devices. Full list in `docs/Project_Idea.md` |
| Who uses it | People who want an offline gallery in English, Malayalam or Sanskrit |
| Out of scope for now | Cloud sync, remote servers, other platforms |

### 0.1 Data and privacy

| Item | Value |
|---|---|
| Works offline / needs the network | Offline. Local Wi-Fi only, for device-to-device transfer from the transfer screen |
| Backend or third-party API | none |
| User accounts / sign-in | none |
| Data the app stores, and where | Media index, notes, settings and the encrypted vault — device only |
| Personal, health, finance or secret data | Private photos and videos, vault contents and vault keys |
| Analytics | none |
| Crash reporting | none |
| Ads | none |
| Other third-party SDKs that send data | none |
| In-app purchases or subscriptions | none |
| Device permissions | The 11 permissions listed with reasons in `docs/security.md` §11 |

## 1. Identity

| Item | Value |
|---|---|
| App display name | Drishya Gallery (Malayalam ദൃശ്യ, Sanskrit दृश्य; dev build adds " Dev"). Formerly "SreerajP Image Video Gallery" |
| Short description (one line) | Offline-first image and video gallery application for viewing, organizing, and managing local media. |
| Organization / publisher | Sreeraj P (proposed, confirmed by user) |
| Reverse-DNS app id | `in.sreerajp.imgvidgal` |
| Dart package name | `in_sreerajp_imgvidgal` |
| Public support contact | sreerajp@zohomail.in (owner, 2026-11-02). Shown on the About screen (`email` row) and in `PRIVACY.md` |
| Website | https://github.com/sreerajp80/SreerajP_Image_Video_Gallery |
| Privacy policy URL | https://github.com/sreerajp80/SreerajP_Image_Video_Gallery/blob/master/PRIVACY.md — written 2026-11-02; live once pushed to `master` (the repository is public). Shown on the About screen (`privacyPolicy` row) |
| Copyright line | © 2026 Sreeraj P |
| License of the app's own code | MIT |

## 2. Applicability profiles (engineering standard §1.2)

- [x] `Core Baseline`
- [x] `Production App Extension` — not shipped yet; will ship
- [x] `Sensitive Data Extension` — local encrypted vault

## 3. Target platforms and distribution

| Platform | Ship? | Minimum OS | Distribution channels |
|---|---|---|---|
| Android | yes | `minSdk 24` (reason in `docs/architecture.md` §19) | Google Play, direct split APKs |
| iOS | no | — | — |
| Windows | no | — | — |
| macOS | no | — | — |
| Linux | no | — | — |
| Web | no | — | — |

Build flavors: `dev + prod`.

## 4. Languages

| Locale | Language | Script | Role | Language pack |
|---|---|---|---|---|
| `en` | English | Latin | Template ARB, ultimate fallback | — |
| `ml` | Malayalam | Malayalam | Full UI translation | `language_packs/sanskrit_malayalam.md` |
| `sa` | Sanskrit | Devanagari | Full UI translation | `language_packs/sanskrit_malayalam.md` |

- In-app language picker: required (3 languages).
- Languages without a Flutter framework translation: `sa`.
- Store-listing languages: Google Play `en-IN`, `ml-IN`. Sanskrit ships inside the app only.
- Store-listing app name (limit 30): `en-IN` "Drishya: Photo & Video Gallery", `ml-IN`
  "ദൃശ്യ: ഫോട്ടോ & വീഡിയോ ഗാലറി".
- Native-reader reviewer for each non-template language: app maintainer.

## 5. About screen

| Item | Value |
|---|---|
| `details` rows to show | `author`, `license`, `ideUsed`, `aiUsed`, `storageModel`, `networkPolicy`, `security`, `languages` |
| Signature badge | on |
| Badge text — English | `Made with {heart} from India` |
| Badge text — Malayalam | `സ്നേഹത്തോടെ {heart} ഇന്ത്യയിൽ നിന്ന്` |
| Badge text — Sanskrit | `सस्नेहं निर्मितम् {heart} भारततः` |
| Badge screen-reader text | `Made with love from India` / `സ്നേഹത്തോടെ ഇന്ത്യയിൽ നിന്ന്` / `सस्नेहं निर्मितम् भारततः` |

## 6. Optional project-specific values

| Item | Value |
|---|---|
| App size budget override | default |
| State management | Riverpod |
| Structure tier | Tier 1 layer-first |
| Brand colours | as set in `lib/theme/app_theme.dart` |
| Theme modes | light + dark + system |
| App icon source | supplied by user |

## 7. Tools and workflow

| Item | Value |
|---|---|
| AI agents used on the project | Claude Code, Gemini |
| IDE | Visual Studio Code, Antigravity |
| Can build iOS / macOS locally | not needed |
| Git hosting | GitHub |
| CI checks | GitHub CI — analyze/test only. Not set up yet; to be added under its own plan |
| Release owner (role) | app maintainer |
