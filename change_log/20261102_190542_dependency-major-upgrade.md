# Change log — move to the upgraded packages (Riverpod 3, local_auth 3, go_router 18 + material_ui)

**Plan:** [plans/20261102_184653_dependency-major-upgrade.md](../plans/20261102_184653_dependency-major-upgrade.md) (option (b))
**Date:** 2026-11-02

`pubspec.yaml` had been moved to new major versions, and the prod release build failed with
hundreds of compile errors. The owner chose to keep the upgrade. The app now builds on it
(checked by analyze and tests, not yet by an Android build), with one deliberate exception:
secure storage stays on 10, not 11.

| Package | Before | Now |
|---|---|---|
| `flutter_riverpod` | 2.x | 3.4.3 |
| `go_router` | 14.x | 18.1.2 |
| `local_auth` / `local_auth_android` | 2.x / 1.x | 3.0.2 / 2.3.0 |
| `flutter_secure_storage` | 9.2.x | **10.3.4** (11.2.0 was requested; held back, see below) |
| `flutter_lints` | 4 | 6 |
| `material_ui` / `cupertino_ui` | — | 1.9.0 / 1.1.5 (new) |

---

## 1. Secure storage: 10.3.4, not 11

- **Why:** the package's own source for version 11 says data written by version 9 is unreadable:
  "Upgrading to v10 before v11 would have migrated it." The vault PIN hash, salt and settings were
  written exactly that way, so a direct move to 11 would lock existing users out of their vault.
- `pubspec.yaml`: `flutter_secure_storage: 10.3.4`, pinned exactly, with the reason written beside
  it.
- `vault_credential_store.dart`:
  - new `SecureVaultCredentialStore.androidOptions`, set to `migrateOnAlgorithmChange: true`,
    `migrateWithBackup: true`, `resetOnError: false`;
  - the deprecated `encryptedSharedPreferences: true` is removed. 10.3.4 ignores it and moves
    version 9 data across on its own.
- **Why `resetOnError: false`:** version 10 changed the default to wipe all stored data on an
  error. Here that would erase the vault PIN.
- New `test/services/vault/vault_credential_store_test.dart` pins all three options, and fails if
  the package leaves 10.x.
- New gap **G49**: move to 11 later, only after a 10.x release has run everywhere, using 11's
  `checkUpgradeStatus()`.

## 2. local_auth 3

- `authenticate(...)` now takes `biometricOnly: false, persistAcrossBackgrounding: false`. These
  are the same choices as before, with the same comments.
- Errors arrive as `LocalAuthException`. The new `LocalAuthBiometricService.resultForCode` maps all
  14 `LocalAuthExceptionCode` values onto the existing outcomes:
  - user or system cancel, time-out, "use PIN" → **cancelled**;
  - lockouts → **failed**;
  - device problems and unknown errors → **unavailable**.
- The plugin no longer shows error dialogs. The gate screen already shows its own messages
  (`vaultBiometricFailed`, `vaultBiometricUnavailable`), and a cancel shows none, so no new text
  was needed.
- New `test/services/vault/vault_biometric_service_test.dart` covers every code.

## 3. Riverpod 3

- 57 files:
  - `import 'package:flutter_riverpod/legacy.dart'` where `StateNotifier`,
    `StateNotifierProvider`, `StateProvider` or `StateController` are used;
  - `.valueOrNull` → `.value` (52 places);
  - `misc.dart` for `Override`.
- **Retry off:** new `lib/providers/provider_retry.dart` (`noProviderRetry`), passed as
  `ProviderScope(retry: ...)` in `main.dart`. The reason is in the file and in
  `docs/architecture.md` §8. New `test/providers/provider_retry_test.dart`.
- **Behaviour note:** in Riverpod 2, `AsyncValue.value` threw on an error. In 3 it returns null,
  like the old `valueOrNull`, so the few places that used `.value` no longer throw. That is safer.
- **`flutter_lints` 6** (also part of the upgrade) brought two new rules. Their 21 hits in 14 files
  were fixed with the official automatic fixes (`unnecessary_underscores`,
  `use_null_aware_elements`).

## 4. go_router 18 and the material_ui move (G22, owner chose option (b))

- `pubspec.yaml`: `material_ui: ^1.9.0` and `cupertino_ui: ^1.1.5`.
- `dart fix --dry-run --code=migrate_design_widgets` planned one import change in each of 148 files.
  It was then applied: 149 changes in 148 files (`lib/` and `test/`).
- **Sanskrit fallback delegates:**
  - `flutter_localizations` is imported for `GlobalWidgetsLocalizations` only;
  - Material and Cupertino text come from `material_ui` / `cupertino_ui`, whose `MaterialApp` looks
    up their own types;
  - the existing Sanskrit date-picker and dialog tests pass.
- **Generated delegate list:** the generated `AppLocalizations.localizationsDelegates` still lists
  the SDK delegates. It is generated, so it was not edited. The 11 test files that used it now use
  the app's own `appLocalizationsDelegates`.
- **Compatibility bridge:**
  - `MaterialUiCompatibilityBridge` was added in `MaterialApp.builder` for `qr_flutter`,
    `video_player` and `camera`, which still import the SDK Material.
  - They use only plain `Colors` constants and the old theme (the video progress bar). None reads
    Material localizations, so Sanskrit needs nothing extra.
  - The bridge is deprecated on purpose, as a temporary migration tool. One
    `// ignore: deprecated_member_use` with the reason is next to it, and it is recorded in
    `docs/architecture.md` §21 for removal later.
- New `test/tool/material_ui_imports_test.dart`: fails if any file imports
  `package:flutter/material.dart` or `cupertino.dart` again, or if the two packages lose their
  caret constraint.
- The analyzer found no SDK-versus-`material_ui` type clash.

## 5. Docs

- `docs/dependencies.md`: every upgraded package with its new notes; `material_ui` and
  `cupertino_ui` added.
- `docs/architecture.md`:
  - §8: Riverpod 3, retry off, pause;
  - §21: the bridge packages and the generated delegate list.
- `docs/security.md`: the secure storage options and why each is set.
- `docs/known_gaps.md`:
  - G22 fixed;
  - G39 and G40 partly done;
  - new G49.

## Files

- **Created:**
  - `lib/providers/provider_retry.dart`
  - `test/services/vault/vault_credential_store_test.dart`
  - `test/services/vault/vault_biometric_service_test.dart`
  - `test/providers/provider_retry_test.dart`
  - `test/tool/material_ui_imports_test.dart`
- **Changed (by hand):**
  - `pubspec.yaml`, `pubspec.lock`, `lib/main.dart`
  - `lib/services/vault/vault_credential_store.dart`,
    `lib/services/vault/vault_biometric_service.dart`
  - `lib/core/l10n/sanskrit_fallback_delegates.dart`
  - the four docs above
- **Changed by tools** (imports and renames only):
  - 57 files for Riverpod 3;
  - 14 files for the lint fixes;
  - 148 files for `material_ui`;
  - 11 test files for the delegate list.

## Check results

- `flutter pub get`: clean. No blocked package anywhere in `pubspec.lock`.
- `dart format --set-exit-if-changed lib test`: 558 files, 0 changed.
- `flutter analyze`: no issues.
- `flutter test`: all 2,069 tests pass (2,058 before; 11 new).

**Not checked (owner):**
1. The Android release build, then `android\gradlew --stop`.
2. **On a phone that already has a vault PIN: install the new build over the old one, then
   unlock with the old PIN.** If this fails, do not release. The old build can be reinstalled
   while the backup copy is still there.
3. Fingerprint unlock, including cancelling the prompt once.
4. The look of the main screens on `material_ui`, in light and dark.
5. Pairing by camera and the video progress bar, which go through the compatibility bridge.
