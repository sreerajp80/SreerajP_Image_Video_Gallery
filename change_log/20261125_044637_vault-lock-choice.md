# Change log — Vault lock choice (phone lock or vault PIN) and vault access fixes

Implements: [plans/20261125_042609_vault-lock-choice.md](../plans/20261125_042609_vault-lock-choice.md)

## What changed

### Lock choice

- **New** `lib/models/vault/vault_lock_mode.dart`: `VaultLockMode.phoneLock` / `vaultPin`.
- `vault_credential_store.dart`:
  - The mode is stored as its own secure-storage value (`vault_lock_mode`).
  - New `readLockMode()`, `writeLockMode()` and `clearPin()`. `clear()` also removes the mode.
  - **Rule:** a stored PIN with no mode is a PIN vault, so older vaults (including the owner's
    real one) stay on their PIN.
- `vault_biometric_service.dart`:
  - New `isDeviceSecure()`.
  - `authenticate()` now requires `biometricOnly`.
- `vault_auth_service.dart`:
  - `isSetUp()` covers both modes.
  - New `lockMode()`, `canUsePhoneLock()`, `setUpWithPhoneLock()`, `unlockWithPhoneLock()`,
    `switchToPhoneLock()`, `switchToVaultPin()`.
  - `setUpVault()` records the PIN mode.
  - The fingerprint shortcut is PIN-mode only and uses `biometricOnly: true`.
- `vault_auth_outcome.dart`: new `phoneLockUnavailable`.
- `vault_providers.dart`:
  - Lock controller: `setUpWithPhoneLock()` and `unlockWithPhoneLock()`.
  - New `vaultLockModeProvider` and `vaultPhoneLockAvailableProvider` (read fresh, because the
    user can change the screen lock at any time).
- `vault_gate_screen.dart`:
  - The create-vault screen starts with "Choose a lock".
  - **Phone lock is pre-selected when the phone has a screen lock. The vault PIN is
    pre-selected, and phone lock is greyed out with the reason, when it has none** (the
    owner's follow-up request).
  - The "no recovery" warning and the PIN pad show only for the PIN choice.
  - A phone-lock vault shows a "Use phone lock" button and offers Android's prompt once on
    open.
  - The first PIN step's button now says "Next" instead of "Unlock".
- `vault_settings_screen.dart`:
  - New "Vault lock" section. Switching to phone lock runs Android's prompt and then erases
    the PIN; switching to a PIN asks for it twice.
  - "Change PIN" and "Fingerprint unlock" show only in PIN mode.

### Access fixes

- `vault_settings_screen.dart`: shows the gate while the vault is shut. Before, Settings →
  Privacy → Vault settings opened without unlocking.
- `vault_viewer_screen.dart`: draws nothing while shut (before, it drew one more frame of the
  photo before closing), and watches only the open/shut flag.
- `batch_action_bar.dart`: multi-select "Move to vault" opens the vault gate first, as the
  viewer does.
- `vault_pin_pad.dart`: the delete key's tooltip is "Delete digit", not "Clear selection".

### Strings

15 new keys in `app_en.arb` (with `@` descriptions), `app_ml.arb` and `app_sa.arb`, then
`flutter gen-l10n`. Two English labels were shortened to fit the §8.6 label budget: "Choose a
lock" and "Use phone lock". **The new Sanskrit text needs the owner's review.** It uses
दूरवाणी (phone), पिधानम् (lock), गूढाङ्कः (PIN), पटलपिधानम् (screen lock) and विन्यासः
(settings), following the glossary and the app's existing words.

### Docs

- `docs/security.md`:
  - §7 now covers the two modes and their threat difference, the `biometricOnly` rule, the
    switching order and the route guards.
  - §4 has a new "Vault lock mode" row.
- `docs/architecture.md`: the vault lock choice.

### Tests

- Auth service: 13 new tests (both modes, old vaults read as PIN, `biometricOnly` in each
  mode, no screen lock, cancelled set-up, switching both ways and its failure cases).
- Secure store: 5 tests for the mode rule, using `flutter_secure_storage`'s test mock.
- **New** `test/screens/vault/vault_gate_screen_test.dart` (5 tests):
  - the default choice, with and without a screen lock;
  - the PIN choice;
  - a phone-lock vault's gate;
  - vault settings showing the gate while shut.
- Batch bar: "Move to vault" opens the gate and moves nothing if the user backs out.
- Lock controller: phone-lock unlock.

## Difference from the plan

The plan said `lockMode` would be a field in `VaultSecuritySettings`. It is a separate stored
value instead. A vault whose settings were never saved has no settings JSON, and reading the
new default (phone lock) for it would quietly move it off its PIN. A separate value with a
"PIN means PIN mode" rule cannot do that.

## Checks

- `dart format`: no changes.
- `flutter analyze`: no issues.
- `flutter test`: all 2567 passed.

### Phone test (2026-11-25)

Dev build on the test phone (Android 10).

- The existing PIN vault in the dev app still opens with its PIN.
- Vault settings show the "Vault lock" section. Phone lock is greyed out with "This phone has
  no screen lock". **The test phone has no screen lock**, which is also why the fingerprint
  option never appeared.
- Multi-select "Move to vault" with the vault shut opens the PIN gate. Backing out moved
  nothing: the gallery is unchanged and the vault still has 4 files.
- A brand-new vault (dev app data cleared) shows "Choose a lock", with **Vault PIN selected**
  and phone lock disabled.
- The PIN pad delete key reads "Delete digit".
- **Not checked on the phone:**
  - **Phone-lock mode itself**: it needs a screen lock on the phone, which is the owner's
    setting to change. Unit and widget tests cover it.
  - **Vault settings opened from app Settings while shut**: the layout reader does not update
    for pages pushed from Settings (it did not before this change either). The window did turn
    secure, but the screen could not be read. The widget test covers it.
- Gradle daemons stopped afterwards.

## Security impact

- **New, weaker option:** phone-lock mode can be opened by anyone who knows the phone's
  unlock. The create screen says so in one line. PIN mode is unchanged.
- **Closed:** the phone PIN opening a PIN vault through the fingerprint prompt
  (`biometricOnly` was `false`).
- **Closed:** vault settings opening while the vault was shut.
- **Closed:** batch "Move to vault" skipping set-up.
- No new permission, no new package, no database change.
