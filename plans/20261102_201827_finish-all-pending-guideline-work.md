# Finish all pending guideline work (build fix, owner's toolchain versions, and every open gap)

**Status:** completed

**Date:** 2026-11-02
**Asked for:** "First fix this app and implement all that is pending to make it adhere to the
guideline documents", and "upgrade Flutter to 3.47.6, AGP to 9.4.1 and Gradle to 9.8.0, Kotlin
to 2.4.10".
**Replaces the rest of:** [plans/20261102_192913_guideline-batch-4-build-data-ci.md](20261102_192913_guideline-batch-4-build-data-ci.md)
(steps 1–6 and 8 are done; it is closed as `partial_completion`, and its open steps continue here).
**Gaps:** G10, G11, G12, G13, G17, G18, G19, G21, G23, G24, G28, G41, G43, G44, G46, plus G9
(needs a person), in [docs/known_gaps.md](../docs/known_gaps.md).

**Security impact:**
- **Changed:** the build tools, one dependency's source (the OCR plugin), the target API,
  screen-capture protection (G28), and a new public privacy policy and support contact
  (G17, G18).
- **Not changed:** no network rule, no new permission, and no data leaves the device.

---

## 1. Where things stand

- **The build fails.** `flutter_tesseract_ocr` 0.4.31 is the newest **published** version, and
  its `android/build.gradle` calls `jcenter()`, which Gradle 9 removed. Any Gradle 9 fails the
  same way, whatever versions we pick. The plugin's GitHub repository
  (`github.com/khjde1207/tesseract_ocr`) has already removed `jcenter()`, but that fix is
  **not released** to pub.dev. The plugin is BSD-3-Clause.
- **Versions you asked for, all checked today on the official repositories:**

  | Item | You asked for | Status |
  |---|---|---|
  | Flutter | 3.47.6 | Already in use |
  | AGP | 9.4.1 | Exists. The newest stable is 9.5.0 |
  | Gradle | 9.8.0 | Exists, final, 2026-09-24. The newest is 9.8.2 |
  | Kotlin Gradle plugin | 2.4.10 | Exists. The newest 2.4.x is 2.4.21 |

- **Honest note about the standard:** §5.3 says to use the versions Flutter generates
  (for 3.47.6 those are AGP 9.1.0, KGP 2.4.0 and Gradle 9.3.1) and not to hand-pick. Your
  versions are newer than that. This plan uses them because you asked, and records the choice
  as an owner decision with its reason in `docs/architecture.md` §21, so it is a documented
  exception, not a silent one. If Flutter warns that the AGP is newer than it tested, that
  warning is expected.

## 2. Plan

### Phase A — make it build, and finish Batch 4

1. **OCR plugin.** Use the plugin's fixed, unreleased source through
   `dependency_overrides: flutter_tesseract_ocr: git:` with `ref` pinned to the exact commit
   (`259994d4d93d755f8d365907df0f3b174f85ff57`), so the build cannot drift.
   - If that commit still fails on AGP 9 (it keeps an old `lintOptions` block and an AGP 7
     `buildscript`), then **vendor** the plugin into `packages/flutter_tesseract_ocr/` with a
     corrected `android/build.gradle`, keeping its BSD licence file.
   - That adds about 45 MB of prebuilt Tesseract library to the repository, so it is the
     fallback, not the first choice.
   - Either way, record why in `docs/dependencies.md`, and remove the override once a fixed
     version reaches pub.dev.
2. **Toolchain at your versions.**
   - AGP **9.4.1** and KGP **2.4.10** in `android/settings.gradle.kts`.
   - Gradle **9.8.0** in the wrapper.
   - Keep `android.builtInKotlin=false` and `android.newDsl=false`.
3. **You build** (`flutter build apk --flavor prod --release --split-per-abi`, then
   `android\gradlew --stop`). A new failure means fix and build again, one cause at a time.
4. **G19 — `targetSdk` 36**, with every doc that says 35. Then you build again.
5. **G24 — 16 KB page size:** I read the ELF program headers of every `.so` in the built arm64
   APK (read-only, a small Python script). A library whose `LOAD` segments are not aligned to
   16 KB is listed with the plugin it comes from.
6. **G23 — close:** the CI file already exists; close the gap. Its first real run happens when
   you push.

### Phase B — decisions you give (defaults in §3)

7. **G17, G18 — privacy policy and support contact.**
   - Write `PRIVACY.md`, matching the app exactly: no data collected, nothing sent off the
     device, Wi-Fi transfer only between phones you pair.
   - Add `privacyPolicy` and `email` rows to `assets/config/app_config.json` (en/ml/sa) and to
     the About screen, and to `docs/PROJECT_PROFILE.md`.
   - Needs from you: the support email to publish, and whether the repository is or will be
     public (the store needs a public URL).
8. **G28 — screen protection outside the vault:** a Settings switch "Hide content from
   screenshots and recent apps", default **off**, which sets `FLAG_SECURE` app-wide when on.
   The vault keeps it always on. ARB text in en/ml/sa, and a test.
9. **G43 — the three OCR plans from 2026-09-26** (image preparation and crop, best data / DPI /
   layout, share text). I check the code for each feature:
   - built → `completed`, with a short change log;
   - not built → `dropped`.

   No question for you unless the code is unclear.

### Phase C — code structure

10. **G46 — UI must not import services (34 files).**
    - Each use goes through a provider.
    - Pure helpers and value types that UI may read move to `lib/core/` or `lib/models/`.
    - A source test stops new service imports in `lib/screens/` and `lib/widgets/`.
11. **G41 — files over 500 lines (10 files).**
    - Split along natural seams, for example the viewer's toolbar, sheets and gestures into
      their own widgets, and `media_dao.dart` by query area.
    - Behaviour stays the same; the tests prove it.
    - Any file that should stay large gets a one-line reason in `docs/architecture.md`.
12. **G44 — unused ARB keys:** confirm each of the 29 is used nowhere (code and generated
    getters), then remove it from all three ARB files.
13. **G10 — language setting key:** store the choice under `app_language`, as standard §8.4
    asks. Read the old `localeCode` once and move it across, so nobody loses their choice. With
    a test.

### Phase D — tests

14. **G13 — a test file for each of the 16 untested provider files** (state changes, error
    paths, retry off).
15. **G12 — screen tests in `ml` and `sa`.** One shared helper pumps each main screen in all
    three languages and checks for no overflow and no missing text.

### Phase E — key names

16. **G11 — short-label key prefixes.**
    - 1,005 of 1,093 ARB keys have no `action…`, `label…`, `title…`, `tab…`, `nav…` or
      `tooltip…` (or `desc…`, `help…`, `empty…`, `error…`, `body…`) prefix.
    - A script renames them by how each is used (button, title, tooltip, body text…), in all
      three ARB files and every `l10n.` use, with `@` descriptions carried over.
    - The label-length test then covers every short label, as §8.6 intends.
    - Done last and alone, because it touches almost every UI file. The tests prove nothing
      broke.

### Phase F — close

17. Update `docs/known_gaps.md`, with every closed gap marked fixed. G9 (a fluent Sanskrit
    reader) stays open, because only a person can do it.
18. Update `docs/architecture.md`, `docs/dependencies.md`, `docs/security.md`,
    `docs/release_process.md`, `CLAUDE.md` / `AGENTS.md`, and `docs/implementation_progress.md`.
19. One change log per phase.

## 3. Decisions (defaults used unless you say otherwise)

| # | Question | Default |
|---|---|---|
| 1 | OCR plugin fix | Git override pinned to the fixed commit; vendor only if that fails |
| 2 | Support email for G18 | **Given by the owner on 2026-11-02.** It goes only into the public places (`app_config.json`, `PRIVACY.md`, `docs/PROJECT_PROFILE.md`), never into a plan or change log (`CLAUDE.md` workflow rule 3) |
| 3 | Repository public, for the privacy policy URL | **Yes, public** (owner, 2026-11-02). The policy URL is the `PRIVACY.md` branch link on GitHub (`.../blob/master/PRIVACY.md`), as store readiness §1 describes |
| 4 | G28 screen protection | A setting, default off |
| 5 | G11 key renames | Do all of them in Phase E |

Answers 2 and 3 are in, so no phase waits on a decision. Only the builds and the phone checks
need you.

## 4. Checks

- After every step: `dart format` (whole repository), `flutter analyze`, `flutter test`.
- **You:** the Android builds in Phase A (each followed by `android\gradlew --stop`), then on a
  phone:
  - every main screen in light and dark, with gesture and button navigation (targetSdk 36);
  - OCR on one photo (the patched plugin);
  - the new screen-protection switch;
  - the vault: create a PIN and unlock.

## 5. Risks

- **The OCR plugin is the weak point.** If even a corrected copy cannot build on AGP 9, the
  choice is to keep AGP 8 until the plugin is fixed upstream, or replace the OCR plugin. I
  would stop and ask you.
- **G11 renames about 1,000 keys.** It is mechanical but very wide, so it runs last and on its
  own.
- **G41 splits** change structure, not behaviour. Tests cover the main flows; anything they miss
  shows up in the phone check.

## 6. Addendum, 2026-11-03: G11 found text that is too long (option (a) approved 2026-11-04)

Phases C and D are done. A dry run of the G11 key renames sorts 966 keys into kinds. It
shows that 40 short English strings and 7 Malayalam or Sanskrit strings are longer than the
§8.6 limit (20 characters in English, 22 in other scripts). These are buttons, titles, switch
labels and tooltips, for example "Strip Camera & Lens Serial Numbers" (34) and "Move {count}
copies to the trash?" (33). Once the keys are renamed, the label-length test will fail on them.

The standard says to choose shorter words, not to shrink, cut or wrap the text. Renaming keys
was approved; changing what the user reads was not. So this needs a decision:

- **(a) Recommended.** Rename all keys. Shorten the 40 English strings, keeping their meaning
  (for example "Strip serial numbers"). Put the 7 Malayalam and Sanskrit strings on a short,
  named allow-list in the test, and add a known gap so a fluent reader shortens them. The
  allow-list cannot grow without a test change.
- **(b)** Rename all keys, and put all 47 on the allow-list as a known gap. No visible text
  changes now.

Either way, the Malayalam and Sanskrit text of the 40 English strings is not changed: those
translations are already within the limit.

Files: the three ARB files, the generated localization files, every Dart file that reads a
renamed key, `test/l10n/translation_parity_test.dart`, `docs/known_gaps.md`.

**Found while testing (G12), already fixed:** the viewer's bottom bar overflowed by 165 to 378
pixels in Malayalam and Sanskrit. Its five buttons now share the width equally, and a label
can use two lines.
