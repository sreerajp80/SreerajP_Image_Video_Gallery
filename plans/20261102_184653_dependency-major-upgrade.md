# Make the app build on the upgraded packages (Riverpod 3, local_auth 3, secure storage, go_router 18 + material_ui)

**Status:** completed

> Done: [change_log/20261102_190542_dependency-major-upgrade.md](../change_log/20261102_190542_dependency-major-upgrade.md). The Android build and the phone checks in §5 are still to be run by the owner.

**Date:** 2026-11-02
**Related gaps:** G39 (security packages pinned and current), G22 (`material_ui`, closed by this plan), in
[docs/known_gaps.md](../docs/known_gaps.md)

**Security impact:** this touches secure storage (the vault PIN hash, salt and settings), the
biometric unlock, and dependencies. A wrong step here can lock users out of their own vault, or
let a storage error reset the vault PIN. No permission and no network rule changes. The
whole-tree dependency test (`test/tool/dependency_policy_test.dart`) must stay green.

---

## 1. What the issue is

On 2026-11-02 `pubspec.yaml` was changed to new **major** versions:

| Package | Was | Now |
|---|---|---|
| `flutter_riverpod` | ^2.5.1 | ^3.4.3 |
| `go_router` | ^14.2.0 | ^18.1.2 |
| `local_auth` | ^2.3.0 | ^3.0.2 |
| `local_auth_android` | ^1.0.0 | ^2.3.0 |
| `flutter_secure_storage` | ^9.2.2 | ^11.2.0 |

The prod release build then failed: hundreds of compile errors in about 40 files. The owner chose
to keep the upgrade and migrate the code (not to roll it back).

What each package changed, read from its own CHANGELOG and source in the package cache:

### Riverpod 3 (code changes, mostly mechanical)

| Change | How much code it touches | Fix |
|---|---|---|
| `StateNotifier`, `StateNotifierProvider`, `StateProvider` moved to `package:flutter_riverpod/legacy.dart` | 32 notifier classes, 32 + 29 providers | Import `legacy.dart` where they are used. No behaviour change. |
| `AsyncValue.valueOrNull` is now `AsyncValue.value` (nullable) | 52 uses in 28 files | Rename. |
| `Override` moved to `package:flutter_riverpod/misc.dart` | `main.dart` and 1 test | Import `misc.dart`. |
| **Automatic retry**: a provider that throws is retried with back-off by default | Every `FutureProvider` (thumbnails, EXIF, vault previews, scans) | Turn it off app-wide with `ProviderScope(retry: (_, _) => null)`. The app was written for "fail once, show the fallback" (hard rule 5); retrying a corrupt file only wastes battery. |
| Listeners in widgets hidden by `TickerMode` are **paused** | Screens behind other routes | Keep it. The full test run shows whether a screen relied on updates while hidden, for example the timeline auto-refresh. |
| An error rethrown through `ref.watch` / `ref.read` is wrapped | Code that catches a typed error from `ref.read(x.future)` (none found by search) | Check while fixing; tests cover it. |

Later and optional: moving the 32 `StateNotifier`s to the new `Notifier` class. That is a
rewrite, not needed to build, and gets its own plan if wanted.

### `flutter_secure_storage` 9 → 11 — **must not be done in one step**

- Version 10 replaced the Android storage. It moves data written by version 9 with
  `encryptedSharedPreferences: true` to the new format by itself
  (`migrateOnAlgorithmChange`, on by default).
- **Version 11 removed the old reader.** Its own `UpgradeInspector` says of version 9 data:
  "Upgrading to v10 before v11 would have migrated it." Version 11 leaves the old data unreadable.
- The vault keeps its PIN hash, salt, iteration count and settings exactly that way. Going
  straight from 9 to 11 would lose them on every phone that already has the app, including the
  owner's.
- Version 10 also changed a default: `resetOnError` is now **true**, so on a storage error the
  plugin **wipes** its data. For this app, that means the vault PIN disappears.

### `local_auth` 3

- `authenticate(options: AuthenticationOptions(...))` is gone; its fields are now separate
  parameters (`stickyAuth` → `persistAcrossBackgrounding`).
- `useErrorDialogs` is removed. The app must show its own message for each error.
- Failures now throw `LocalAuthException` with `LocalAuthExceptionCode`, not `PlatformException`
  with string codes. `_resultForCode` in `vault_biometric_service.dart` maps the old strings.

### `go_router` 15 → 18

| Version | Change | Effect here |
|---|---|---|
| 15 | URLs are case-sensitive | Route patterns here are lower case. Parameter values (ids) are not affected. |
| 16 | `GoRouteData` changes | Not used here. |
| 17 | `ShellRoute` observer changes | Not used here. |
| **18** | **Moves to the new `material_ui` and `cupertino_ui` packages.** Its pages import `package:material_ui/material_ui.dart` | The app imports `package:flutter/material.dart`, which in Flutter 3.47.6 is still its own separate copy (182 exports). With 18, the app carries **two** Material libraries, and go_router's page transitions do not see the app's theme. That is exactly gap G22. |

## 2. Plan for the fix

Order: smallest risk first. `flutter analyze` and `flutter test` must pass after each step.

1. **Secure storage: pin 10, not 11.**
   - `flutter_secure_storage: 10.3.4`, pinned exactly.
   - `SecureVaultCredentialStore` uses:
     - `AndroidOptions(migrateOnAlgorithmChange: true, migrateWithBackup: true, resetOnError: false)`;
     - with the deprecated `encryptedSharedPreferences: true` removed (10.3.4 migrates version 9
       data on its own).
   - A test checks these options, so a later edit cannot quietly turn `resetOnError` back on.
   - Moving to 11 becomes a **later, separate plan**, only after a release on 10 has run on every
     phone that holds vault data. That plan uses 11's `checkUpgradeStatus()` to prove nothing was
     lost.
2. **`local_auth` 3:**
   - Call `authenticate(localizedReason:, biometricOnly: false, persistAcrossBackgrounding: false)`.
   - Map `LocalAuthExceptionCode` to the existing `VaultBiometricResult` values, and update the
     tests.
   - Because the plugin no longer shows error dialogs, check that the gate screen already shows a
     message for `failed`, `cancelled` and `unavailable`. Where it does not, add a localized one
     (en/ml/sa).
3. **Riverpod 3:** `legacy.dart` and `misc.dart` imports, `valueOrNull` → `value`,
   `ProviderScope(retry: no retry)` in `main.dart` and in the test helpers. Then the full test run,
   fixing what the pause or error-wrapping changes break.
4. **go_router 18 + the `material_ui` move (G22) — option (b), chosen by the owner on 2026-11-02.**
   Steps follow engineering standard §6.1 ("Material And Cupertino Packages"):
   1. In `pubspec.yaml`, add `material_ui: ^1.9.0` and `cupertino_ui: ^1.1.5`, with caret
      constraints. `cupertino_ui` is needed because `sanskrit_fallback_delegates.dart` builds the
      Cupertino fallback. Keep `go_router: ^18.1.2`.
   2. Run `dart fix --dry-run --code=migrate_design_widgets` first and read what it plans. Then
      run `dart fix --apply --code=migrate_design_widgets` over `lib/` (124 files) and `test/`
      (24 files). If the tool writes `material_ui: any`, put the caret back.
   3. **Sanskrit fallback delegates** (`lib/core/l10n/sanskrit_fallback_delegates.dart`): they must
      return `material_ui` / `cupertino_ui` localization types and use `material_ui`'s own
      `GlobalMaterialLocalizations`. Otherwise Sanskrit falls back to nothing and date pickers
      break. The existing `sa` widget test (date picker and dialog) proves it.
   4. **Packages still on the SDK Material:** `qr_flutter`, `video_player` and `camera`, checked
      in the package cache. Wrap the app with `MaterialUiCompatibilityBridge` in
      `MaterialApp.builder`, so their widgets still find the theme and localizations.
      Record them in `docs/architecture.md` §21, as the standard asks.
   5. Check where an SDK type would meet a `material_ui` type (for example a `ColorScheme` or
      `TextTheme` passed into one of those three packages). The analyzer reports each one; fix
      it, or record it in §21 if it cannot be fixed here.
   6. Add a source test: no file in `lib/` imports `package:flutter/material.dart` or
      `package:flutter/cupertino.dart`. It keeps G22 closed.
   7. **Check the look:** run the app's screen tests in light and dark, en/ml/sa. You also look at
      the main screens on a phone, because `material_ui` can differ slightly from the frozen SDK
      copy.
5. **Docs:**
   - `docs/dependencies.md`: versions, plus the secure-storage two-step rule.
   - `docs/security.md` §4, §6: the storage options and why `resetOnError` is off.
   - `docs/architecture.md` §8: Riverpod 3 with legacy notifiers, and retry off.
   - `docs/known_gaps.md`: G39 updated; a new gap for "move to secure storage 11 after 10 has
     shipped".
6. **Change log**, then the owner's build and phone checks (§5).

## 3. Files to change

- `pubspec.yaml`, `pubspec.lock`
- `lib/main.dart`
- About 40 files in `lib/providers/`, `lib/screens/`, `lib/widgets/` (imports and the `value`
  rename)
- `lib/services/vault/vault_credential_store.dart`, `lib/services/vault/vault_biometric_service.dart`
- The vault gate screen, only if a message is missing, plus the ARB files then
- Tests: about 15 that use notifiers or overrides, the vault credential and biometric tests, and
  the test helpers that build a `ProviderScope`
- Docs listed in step 5
- For option (b): `lib/core/l10n/sanskrit_fallback_delegates.dart`, the `MaterialApp` in
  `lib/main.dart`, every file the migration tool touches (about 124 in `lib/`, 24 in `test/`),
  new `test/tool/material_ui_imports_test.dart`, and `docs/architecture.md` §21

## 4. Decision for the owner

go_router: the owner chose **(b)** on 2026-11-02, so go_router 18 and the G22 `material_ui` move are
both done in this change. The earlier option (a), pinning go_router 17, is dropped.

## 5. How it will be checked

- After each step: `flutter pub get` (and the dependency policy test), `dart format`,
  `flutter analyze`, `flutter test`.
- **Owner, on the build:** `flutter build apk --flavor prod --release --split-per-abi`, then
  `android\gradlew --stop`.
- **Owner, on a phone that already has the app with a vault PIN set: the most important check.**
  1. Install the new build **over** the old one. Do not uninstall first.
  2. Open the vault with the **old PIN**.
  3. Try fingerprint unlock, and cancel the fingerprint prompt once.

  If the old PIN does not work, stop and do not release. The old build can be put back while the
  version 9 data is still on the phone, because version 10 keeps a backup copy.

## 6. Risks

- **Vault data:** covered by pinning 10, `migrateWithBackup`, `resetOnError: false`, and the phone
  test above. Not provable on a PC; I am fairly sure the options are right, but only the phone
  test settles it.
- **Riverpod pause behaviour** could change a screen that refreshed while hidden. The tests should
  show it; anything they miss shows up in use.
- **Two migrations at once** (Riverpod 3 and `material_ui`) touch most files. To keep each
  failure easy to trace, they run as separate steps: Riverpod first, until the tests pass;
  `material_ui` after that.
- **The look may change a little** with `material_ui` compared with the frozen SDK copy. Only your
  eye on a phone can judge that.
- **Retry off** keeps today's behaviour. If you would rather have retry on some providers, that can
  be chosen per provider later.
