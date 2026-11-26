# Plan — Vault lock choice (phone lock or vault PIN) and vault access fixes

**Status:** completed

Builds on: [plans/20261124_204202_fast-vault-envelope-encryption.md](20261124_204202_fast-vault-envelope-encryption.md)

## The owner's request

- Let the user choose how the vault is locked: with the **phone's own lock** (screen PIN,
  pattern, password, or fingerprint) or with a **separate vault PIN**.
- Put the choice in Settings, and make **phone lock the default**.
- Allow biometrics for the vault.

## Problems found on the test phone that belong to the same area

These are all about "who can open the vault, and when". The phone test on 2026-11-25 showed
them.

1. **The fingerprint shortcut also accepts the phone PIN.** `local_auth` 3.0.2 defaults to
   `biometricOnly: false`, and `LocalAuthBiometricService.authenticate` does not change it.
   So on a phone with a fingerprint enrolled, the prompt has a "Use PIN" button, and the
   phone's screen PIN opens the vault. The separate vault PIN is quietly bypassed.
2. **Vault settings open without unlocking.** Settings → Privacy → Vault settings pushes
   `/vault/settings`. go_router builds only that page, not the gate, and the page never checks
   the lock. Anyone holding the phone can turn the fingerprint switch on or off and change the
   auto-lock time. A lock-type choice must not be added there until this is fixed.
3. **"Move to vault" from the multi-select bar skips set-up and unlock.** The viewer checks
   first; the batch bar does not. On the phone it said "3 files done" before any PIN existed,
   and the "no way to recover a forgotten PIN" warning appeared only afterwards.
4. **Biometric never offered on this phone.** The phone has 0 fingerprints enrolled, and the
   app offers the shortcut only when one is. Phone-lock mode solves this: it also accepts the
   phone PIN or pattern.

## Design

### Two lock modes

New field `lockMode` in `VaultSecuritySettings` (stored in the existing secure-storage JSON
as `lock_mode`):

| Mode | How the vault opens | Fingerprint |
|---|---|---|
| `phoneLock` (default for a **new** vault) | Android's own prompt: fingerprint, or the phone's PIN, pattern or password (`biometricOnly: false`) | Included automatically when enrolled |
| `vaultPin` | The app's own 4–8 digit PIN | Optional shortcut, **fingerprint only** (`biometricOnly: true`), so the phone PIN can never open it (fixes problem 1) |

- **Existing vaults keep working as they are.** A stored PIN with no `lock_mode` means
  `vaultPin`. The owner's real vault stays on its PIN until the owner changes it.
- **Phone lock needs a secure lock screen.** Checked with `isDeviceSupported()` (Android's
  `KeyguardManager.isDeviceSecure`). On a phone with no screen lock, phone lock is shown
  greyed out with a short reason, and only the vault PIN can be chosen.
- **Phone lock removed later.** If a phone-lock vault finds the phone has no screen lock any
  more, the gate says to turn a screen lock back on in Android settings. There is no
  bypass. (To remove a screen lock, Android first asks for it, so this does not give a
  stranger a way in.)
- **Wrong tries.** Phone lock uses Android's own lockout. The app's PIN back-off applies only
  to the vault PIN.
- The data key is not tied to either mode. Both modes are an app-level gate in front of the
  same Keystore key, exactly as the PIN is today.

### Set-up screen

Creating the vault now starts with the choice, **phone lock pre-selected**:

- **Use phone lock** (recommended): one tap, then Android's prompt once to confirm it works.
- **Use a separate vault PIN**: the current PIN pad (choose, then repeat).

The "no way to recover a forgotten PIN" warning shows only for the PIN option. For phone
lock, a short line instead says that anyone who knows the phone's unlock can open the
vault.

### Settings

- **Vault settings → "Vault lock"**: two options, phone lock or vault PIN.
  - PIN → phone lock: confirm with Android's prompt, then the vault PIN is erased.
  - Phone lock → PIN: choose a new PIN twice.
- "Change PIN" shows only in PIN mode. The "Fingerprint unlock" switch shows only in PIN mode
  (in phone-lock mode the fingerprint is already part of the prompt).
- App Settings → Privacy → "Vault settings" keeps its place. It now opens the vault gate
  first when the vault is shut (problem 2), then the settings.

### Other access fixes

- `VaultSettingsScreen` (and `VaultViewerScreen`, as a second line) show the gate instead of
  their content when the vault is not unlocked.
- Batch "Move to vault" (`batch_action_bar.dart`) does what the viewer does: if the vault is
  not set up or not unlocked, open the vault gate first, and continue only once it is
  unlocked (problem 3).

## Files to change

| File | Change |
|------|--------|
| `lib/models/vault/vault_security_settings.dart` | `VaultLockMode` enum (`phoneLock`, `vaultPin`) and `lockMode` field; JSON read/write; a missing value with a stored PIN reads as `vaultPin` |
| `lib/services/vault/vault_credential_store.dart` | A set-up marker for phone-lock vaults (no PIN hash exists then); `clearPin()` that erases only the PIN, not the settings |
| `lib/services/vault/vault_biometric_service.dart` | `isDeviceSecure()`; `authenticate(biometricOnly:)` passed through; phone-lock availability no longer needs an enrolled fingerprint |
| `lib/services/vault/vault_auth_service.dart` | `isSetUp` covers both modes; `setUpWithPhoneLock()`, `unlockWithPhoneLock()`, `switchToPhoneLock()`, `switchToVaultPin(newPin)`; the PIN-mode shortcut uses `biometricOnly: true` |
| `lib/models/vault/vault_auth_outcome.dart` | New outcome `phoneLockUnavailable` (no screen lock any more) |
| `lib/providers/vault_providers.dart` | Lock controller: set-up and unlock for phone lock; providers for lock mode and device-secure state |
| `lib/screens/vault/vault_gate_screen.dart` | Set-up choice (phone lock pre-selected); phone-lock unlock button plus an automatic prompt on open; "turn on a screen lock" message |
| `lib/screens/vault/vault_settings_screen.dart` | "Vault lock" section and the switch flows; hide "Change PIN" and the fingerprint switch in phone-lock mode; show the gate when locked |
| `lib/screens/vault/vault_viewer_screen.dart` | Show the gate when locked |
| `lib/widgets/batch/batch_action_bar.dart` | Vault set-up/unlock check before "Move to vault" |
| `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ `flutter gen-l10n`) | New strings in all three languages, with `@key` descriptions. **New Sanskrit text needs the owner's review** (CLAUDE.md, G9 rule) |
| `lib/widgets/vault/vault_pin_pad.dart` | The delete key's tooltip reads "Clear selection"; give it its own "Delete digit" string (seen on the phone) |
| Tests: `test/models/vault/…settings`, `test/services/vault/vault_auth_service_test.dart`, `vault_biometric_service_test.dart`, `vault_credential_store_test.dart`, `test/providers/vault_lock_controller_test.dart`, widget tests for the gate set-up choice, the settings guard and the batch-bar check | Both modes; old JSON without `lock_mode`; `biometricOnly: true` in PIN mode; switching both ways; no screen lock; settings and viewer refuse while locked; batch move asks first |
| `docs/security.md` | Vault authentication section: two modes, their threat difference, the `biometricOnly` rule, settings behind the gate |
| `docs/architecture.md` | Vault flow: set-up choice and lock modes |

No new permission is needed: `USE_BIOMETRIC` is already declared, and the device-credential
prompt needs none. No new package. No database change.

## Security impact

Touches authentication.

- **Phone-lock mode is weaker against people who know the phone's unlock** (family, a
  partner, anyone who has watched you unlock). They can open the vault. The PIN mode stays
  for people who need that, and the set-up screen says so in one line.
- **This change also closes two existing holes:** the phone PIN opening a PIN vault
  through the fingerprint prompt, and vault settings opening while the vault is locked.
- The key handling, the encryption and the stored data are unchanged.

## Checks after the change

- `dart format .`, `flutter gen-l10n`, `flutter analyze` (zero issues), `flutter test`.
- On the test phone, with the dev build:
  - a new vault defaults to phone lock and opens with the phone PIN;
  - switch to vault PIN and back;
  - Settings → Privacy → Vault settings asks first;
  - batch "Move to vault" asks first;
  - in PIN mode the prompt offers no "Use PIN".
- Stop Gradle daemons after the build.

## Not in this plan (separate plans)

- The vault grid reloading and re-decrypting every thumbnail on each touch (also breaks
  long-press selection).
- No previews for large photos.
- A check in the format upgrade that the new file opens before the old one is deleted. This
  should come **before** the new code goes onto the Play Store app with the real vault.
