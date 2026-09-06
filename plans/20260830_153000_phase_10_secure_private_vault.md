# Phase 10 — Secure Private Vault (AES-256-GCM, Biometrics, Shredding, FLAG_SECURE)

**Status:** completed

**Date:** 2026-08-30
**Implements:** `docs/implementation_plan.md` → Phase 10
**Follows:** `plans/20260830_145010_phase_9_albums_folders_smart_albums.md`

---

## 1. What this phase must deliver

From the implementation plan, Phase 10 has six action steps:

1. Integrate Android Keystore for master encryption key generation.
2. Implement AES-256-GCM authenticated encryption for private media files.
3. Implement BiometricPrompt authentication via `local_auth` with PIN fallback.
4. Implement multi-pass zero-fill anti-forensic media shredding.
5. Enforce `FLAG_SECURE` window protection against screenshots and screen recording.
6. Implement auto-lock on app backgrounding and a configurable inactivity timeout.

`docs/architecture.md` already names the routes this phase adds:

```
/vault                  (Private Vault - biometric / PIN gated)
/vault/viewer/:id       (Secure in-vault media viewer)
```

`docs/security.md` §5 and §6 fix the cryptography and the lock rules: an
Android Keystore master key, AES-256-GCM with a fresh random 96-bit IV and a
128-bit tag per file, multi-pass shredding (zeroes, then random, then sync,
then unlink), auto-lock on `paused` / `inactive`, and a timeout choice of
30 seconds, 1 minute, or 5 minutes.

---

## 2. What already exists (and what is missing)

**Already there:**

- `lib/models/vault_item.dart` — the immutable `VaultItem` model, with the
  original path and name, the obfuscated `.enc` name, the thumbnail name, the
  IV, the auth tag, sizes, dates, tags, and notes. `toMap` / `fromMap` /
  `copyWith` are done.
- `lib/repositories/database/vault_dao.dart` — insert, delete, get by id,
  get all, count.
- The `vault_items` table in `database_helper.dart`, and the `is_vaulted`
  column plus its index on `media_items`.
- `MediaDao.updateVaulted`, and every media query already excludes
  `is_vaulted = 1`, so a vaulted item disappears from the timeline, albums,
  search, and the duplicate scan on its own.
- `AppConstants.vaultAutoLockTimeoutSeconds` and
  `AppConstants.vaultStorageDirectoryName` are already declared.
- `AndroidManifest.xml` already declares `USE_BIOMETRIC`, and already keeps
  `INTERNET` out of the merged manifest.
- `MainActivity` is a `FlutterFragmentActivity`, which is what BiometricPrompt
  needs.

**Missing — this is the actual work:**

| Gap | Why it matters |
|-----|----------------|
| No Android Keystore code at all | There is no master key, so nothing can be encrypted. |
| No AES-256-GCM encrypt / decrypt path | The `iv` and `auth_tag` columns are never written. |
| No authentication of any kind | `local_auth` is not in `pubspec.yaml`. |
| No PIN storage | `flutter_secure_storage` is not in `pubspec.yaml`. |
| No shredder | Originals would be left recoverable after an import. |
| No `FLAG_SECURE` control | The vault would show up in the app switcher and in screenshots. |
| No lock state, no auto-lock, no inactivity timer | The vault would stay open forever once opened. |
| No vault repository, providers, screens, or routes | `/vault` does not exist in `app_router.dart`. |
| `VaultDao` cannot update a row or list ids | Renaming, notes, and tag edits have no write path. |
| No vault directory management | Nothing creates `.secure_vault` or its `.nomedia` marker. |

---

## 3. Design decisions (and the reasons)

**a. The master key never leaves Android.**
The AES-256 key is generated inside the Android Keystore under a fixed alias
and is used only by native code. Dart never sees key bytes, so no Dart-side
bug, log line, or crash dump can leak it. StrongBox is requested when the
device advertises it, and the code falls back to the normal hardware-backed
keystore when it does not.

**b. Encryption and decryption happen natively, streamed.**
A vault video can be gigabytes. Doing the cipher in Dart would need the whole
file in memory. The native handler streams source into a cipher stream and out
to the destination in blocks, so memory stays flat whatever the file size. Same
reasoning as the Phase 8 streamed SHA-256.

**c. The key is not bound to user authentication at the Keystore level.**
Requiring user authentication on the key itself would make it unusable on a
device with no enrolled biometric and no screen lock, which would lock a user
out of their own photos with no recovery. Instead the app gates the vault:
biometric or PIN before the vault opens, and the lock state is what guards the
decrypt calls. This is written down because it is a deliberate trade-off, not
an oversight.

**d. The PIN is a real fallback, not a bypass.**
The PIN is never stored. A random 16-byte salt plus a PBKDF2-HMAC-SHA256
derivation (120,000 iterations) is stored in `flutter_secure_storage`, and
unlocking compares derived bytes in constant time. PBKDF2 is written as a pure
Dart function over the existing `crypto` package, so it needs no new dependency
and can be unit tested on the host.

**e. Biometric unlock is a convenience over the PIN, and the PIN always works.**
`local_auth` is asked for a biometric prompt with device-credential fallback.
If it is unavailable, not enrolled, or fails, the PIN pad is what the user
sees. The vault can always be opened by someone who knows the PIN, and never by
someone who does not.

**f. Images and thumbnails decrypt to memory; video decrypts to a private file.**
`docs/security.md` §5.4 forbids decrypted vault content in the public cache or
the temporary directory. Images and thumbnails are decrypted straight into a
`Uint8List` and shown from memory, so they never touch disk. A video cannot be
played from memory by the platform player, so it is decrypted into a working
file **inside the app-private vault directory** — which is not public, not the
temporary directory, and not indexed by MediaStore — and that file is shredded
the moment the player closes, when the vault locks, and on every vault open as
a safety sweep. This limit is recorded here rather than hidden.

**g. Shredding is native and multi-pass.**
Zero-fill pass, random pass, a file descriptor sync, then unlink, exactly as
`docs/security.md` §5.3 lays out. It is honest about its limits: on a flash
device with wear levelling, an overwrite is a best effort, not a guarantee. The
number of passes is configurable and defaults to two.

**h. Shredding the original is opt-in and confirmed.**
Hard rule 4 in `CLAUDE.md` says no original is destroyed without explicit
confirmation. Import offers "keep the original" (the default) or "shred the
original", and the shred choice needs a second confirmation dialog that names
how many files will be destroyed.

**i. Lock policy is a pure function.**
`VaultLockPolicy` takes the lifecycle state, the last activity time, the
timeout, and the current time, and returns whether the vault should lock. No
timers, no `BuildContext`. The widget layer feeds it and acts on the answer, so
every rule is unit tested without pumping a widget tree.

**j. `FLAG_SECURE` is scoped to the vault screens, not the whole app.**
A `SecureScreen` wrapper turns the flag on when it mounts and off when it is
disposed, with a counter so nested vault screens do not switch it off early.
Applying it app-wide would stop a user screenshotting an ordinary holiday
photo, which is not what they asked for.

**k. The vault directory is app-private and marked `.nomedia`.**
`<app support>/.secure_vault/` holds the encrypted payloads. A `.nomedia` file
goes in beside them so no other app's scanner walks the directory, and the
names on disk are random hex, so the directory listing itself leaks nothing.

---

## 4. Dependencies to add

| Package | Version | Licence | Why | Network? |
|---|---|---|---|---|
| `local_auth` | `^2.3.0` | BSD-3-Clause | Android BiometricPrompt, named by plan step 3 and by `docs/dependencies.md`. | None. Wraps the platform biometric API only. |
| `local_auth_android` | `^1.0.0` | BSD-3-Clause | The Android implementation, pulled in by `local_auth`; named directly so the prompt strings can be supplied. | None. |
| `flutter_secure_storage` | `^9.2.2` | BSD-3-Clause | Keystore-backed store for the PIN salt and hash, required by the `CLAUDE.md` security rule. | None. |

Both packages are on the approved list in `docs/dependencies.md`. Neither
declares an HTTP client, a cloud SDK, analytics, or crash reporting. After
`flutter pub get` the merged manifest is checked again to confirm no `INTERNET`
permission sneaks in; if one does, it is removed with `tools:node="remove"` the
same way ExoPlayer's was.

---

## 5. Files to change

### 5.1 New — models (`lib/models/vault/`)

| File | Contents |
|---|---|
| `vault_lock_state.dart` | `VaultLockStatus` enum (`unknown`, `notSetUp`, `locked`, `unlocked`) and the immutable `VaultLockState` holding the status, last activity time, and failed-attempt count. |
| `vault_security_settings.dart` | Immutable settings: auto-lock seconds, biometric enabled, shred passes, shred-on-import default. `toJson` / `fromJson` / `copyWith`. |
| `vault_auth_outcome.dart` | Immutable result of an unlock attempt: outcome enum (`success`, `wrongPin`, `biometricUnavailable`, `biometricFailed`, `cancelled`, `lockedOut`, `error`) plus an optional cool-down. |
| `vault_crypto_result.dart` | Immutable encrypt result: base64 IV, ciphertext byte count, and the on-disk name. |
| `vault_import_result.dart` | Immutable batch result: imported ids, skipped count, shredded count, failure list. |

### 5.2 New — services (`lib/services/vault/`)

| File | Contents |
|---|---|
| `vault_channel.dart` | `VaultChannel` abstract class plus `PlatformVaultChannel`: `ensureMasterKey`, `isKeystoreReady`, `encryptFile`, `decryptToBytes`, `decryptToFile`, `shredFile`, `setSecureFlag`. Injected, so tests use a fake. |
| `vault_key_service.dart` | Creates the master key on first use and reports whether the keystore is usable, so the UI can explain a failure instead of crashing. |
| `vault_crypto_service.dart` | The encrypt and decrypt orchestration over `VaultChannel`, mapping failures to `VaultException`. |
| `vault_pin_rules.dart` | Pure validation: 4 to 8 digits, digits only, not one repeated digit, not a straight run. Returns a typed reason, never a string. |
| `vault_pin_service.dart` | Pure PBKDF2-HMAC-SHA256 over `crypto`, salt generation, and a constant-time compare. No I/O. |
| `vault_credential_store.dart` | Abstract store plus `SecureVaultCredentialStore` over `flutter_secure_storage`, holding the salt, the hash, the iteration count, and the settings JSON. |
| `vault_biometric_service.dart` | Abstract wrapper plus `LocalAuthBiometricService` over `local_auth`: availability and one `authenticate` call. Abstract so tests never touch the platform. |
| `vault_auth_service.dart` | Ties the three together: set-up, change PIN, unlock by PIN, unlock by biometric, failed-attempt back-off. |
| `vault_lock_policy.dart` | Pure: should the vault lock, given lifecycle state, last activity, timeout, and now. Also holds the allowed timeout choices. |
| `vault_storage_service.dart` | Owns `.secure_vault/`: creates it, writes `.nomedia`, builds payload paths, sweeps stale working files. |
| `vault_naming_service.dart` | Pure: random 16-byte hex payload and thumbnail names, and the exported name when an item goes back out. |
| `vault_shredder_service.dart` | Multi-pass shred over `VaultChannel`, with a Dart zero-fill fallback when the native side is missing. |
| `vault_import_service.dart` | Import: read original, encrypt, write payload, build the encrypted thumbnail, insert the row, mark `is_vaulted`, and optionally shred the original. Rolls back its own payload file if any step fails. |
| `vault_export_service.dart` | Restore: decrypt, write beside the original folder through `OutputNamingService` and `AtomicSaver`, clear `is_vaulted`, shred the payload, delete the row. |
| `secure_window_service.dart` (in `lib/services/device/`) | `FLAG_SECURE` on and off, with the nesting counter. |

### 5.3 New — repository

| File | Contents |
|---|---|
| `lib/repositories/vault_repository.dart` | The only way screens reach the vault: list items, get one, import, export, delete for good, rename, set notes, set tags, count, and read decrypted bytes. Widgets never see a DAO or a cipher. |

### 5.4 New — providers

| File | Contents |
|---|---|
| `lib/providers/vault_providers.dart` | The channel, the services, the repository, `vaultLockControllerProvider` (a `StateNotifier` over `VaultLockState`), `vaultSettingsProvider`, `vaultItemsProvider`, `vaultRevisionProvider`, and `vaultThumbnailProvider.family`. |

### 5.5 New — screens (`lib/screens/vault/`)

| File | Contents |
|---|---|
| `vault_gate_screen.dart` | `/vault`. First run shows PIN set-up; after that the biometric prompt and the PIN pad. Hands off to the vault grid once unlocked. |
| `vault_screen.dart` | The unlocked grid, the item count, the import action, multi-select, export, and delete for good. |
| `vault_viewer_screen.dart` | `/vault/viewer/:id`. Image from memory with the existing zoom gestures; video from a working file that is shredded on close. |
| `vault_settings_screen.dart` | `/vault/settings`. Auto-lock timeout, biometric toggle, shred passes, shred-on-import default, change PIN. |

### 5.6 New — widgets (`lib/widgets/vault/`)

| File | Contents |
|---|---|
| `secure_screen.dart` | Wraps a child and keeps `FLAG_SECURE` on while it is mounted. |
| `vault_auto_lock_scope.dart` | Watches lifecycle and pointer activity, feeds `VaultLockPolicy`, and locks when it says so. |
| `vault_pin_pad.dart` | The digit pad, the dot indicator, the error line, and the biometric button. |
| `vault_grid.dart` | The vault item grid with selection. |
| `vault_item_tile.dart` | One tile, decrypting its thumbnail into memory. |
| `vault_import_sheet.dart` | Picks items to import and carries the keep-or-shred choice with its confirmation. |

### 5.7 Changed — existing files

| File | Change |
|---|---|
| `pubspec.yaml` | Add the three packages from §4. |
| `lib/core/constants/app_constants.dart` | Vault channel name, keystore alias, IV and tag lengths, PBKDF2 iterations, salt length, PIN length bounds, failed-attempt limit and back-off, auto-lock choices, shred pass bounds, vault thumbnail size, largest importable file, working-file suffix, `.nomedia` name. |
| `lib/core/errors/app_exception.dart` | Add `VaultException` and `VaultAuthException`. |
| `lib/core/routing/app_router.dart` | Add `/vault`, `/vault/viewer/:id`, `/vault/settings` and their path builders; update the header comment that currently says the vault is not wired yet. |
| `lib/repositories/database/vault_dao.dart` | Add `updateVaultItem`, `getVaultItemsByIds`, `getAllEncryptedFilenames` (for the orphan sweep), and `deleteVaultItems`. |
| `lib/screens/timeline/timeline_screen.dart` | Add the Vault entry to the overflow menu. |
| `lib/screens/viewer/media_viewer_screen.dart` | Add "Move to vault" to the viewer actions. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | Every new user-visible string, each with its `@key` description. Then run `flutter gen-l10n`. |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt` | Register and dispose `VaultChannelHandler`. |
| `android/app/src/main/AndroidManifest.xml` | Only if `flutter pub get` adds an unwanted permission; then remove it with `tools:node="remove"`. |
| `docs/implementation_progress.md` | Tick the Phase 10 boxes and set the row to Completed. |

### 5.8 New — Android

| File | Contents |
|---|---|
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt` | The `in.sreerajp.imgvidgal/vault` channel: keystore key generation (StrongBox when offered), streamed AES-256-GCM encrypt and decrypt, decrypt-to-bytes, the multi-pass shred with a descriptor sync, and the `FLAG_SECURE` toggle. Work runs on a single background executor, every result is posted back on the main thread, and every failure is a channel error rather than a crash. |

### 5.9 New — tests

| File | Covers |
|---|---|
| `test/models/vault/vault_lock_state_test.dart` | State transitions, equality, `copyWith`. |
| `test/models/vault/vault_security_settings_test.dart` | JSON round trip, defaults, clamping. |
| `test/services/vault/vault_pin_rules_test.dart` | Every accept and reject case. |
| `test/services/vault/vault_pin_service_test.dart` | PBKDF2 determinism, salt independence, verify pass and fail, constant-time compare behaviour. |
| `test/services/vault/vault_lock_policy_test.dart` | Background locks at once; timeout boundaries at 30 s, 60 s, and 300 s; activity resets the clock. |
| `test/services/vault/vault_naming_service_test.dart` | Name shape, extension, uniqueness over many draws. |
| `test/services/vault/vault_crypto_service_test.dart` | Encrypt and decrypt over a fake channel, including a failing channel. |
| `test/services/vault/vault_auth_service_test.dart` | Set-up, correct PIN, wrong PIN, back-off after repeated failures, biometric success and every biometric failure path. |
| `test/services/vault/vault_shredder_service_test.dart` | Pass count, the Dart fallback actually overwrites, a missing file is not an error. |
| `test/services/vault/vault_import_service_test.dart` | Import writes a row and marks `is_vaulted`; keep-original leaves the file; shred removes it; a mid-way failure leaves no orphan payload. |
| `test/services/vault/vault_export_service_test.dart` | Export writes a new file, clears `is_vaulted`, shreds the payload, and drops the row. |
| `test/repositories/vault_repository_test.dart` | The repository against a real database through `sqflite_common_ffi`. |
| `test/repositories/database/vault_dao_test.dart` | The new DAO methods. |
| `test/core/routing/vault_routes_test.dart` | The three route paths build and parse. |

---

## 6. Order of work

1. `pubspec.yaml`, then `flutter pub get`, then check the merged manifest for
   any new permission.
2. Constants and exceptions.
3. Models, with their tests.
4. Pure services — PIN rules, PIN hashing, lock policy, naming — with tests.
5. The Kotlin `VaultChannelHandler`, and its registration in `MainActivity`.
6. `vault_channel.dart` and the crypto, key, storage, and shredder services.
7. `VaultDao` additions, then `VaultRepository`, with tests.
8. Auth, import, and export services, with tests.
9. Providers.
10. Widgets, then screens, then the routes and the two menu entries.
11. ARB strings for English and Malayalam, then `flutter gen-l10n`.
12. `dart format .`, `flutter analyze` to zero, and `flutter test` all green.
13. Update `docs/implementation_progress.md`, then write the change log.

---

## 7. Risks and how they are handled

| Risk | Handling |
|---|---|
| The device has no hardware keystore, or key generation fails | `isKeystoreReady` is checked before the vault opens; the gate screen explains it plainly and the vault stays shut rather than falling back to weaker encryption. |
| The user forgets the PIN | Stated in the UI before set-up: there is no recovery, because a recovery path would be a back door. Biometric unlock is offered so the PIN is rarely needed. |
| An import is interrupted part-way | The payload is written first and only then is the row inserted and the original touched. A failure deletes the half-written payload and leaves the original alone. |
| A decrypted video working file is left behind by a crash | Swept and shredded on every vault open, on lock, and on player close. |
| A huge video exhausts memory | Encryption and decryption are streamed natively; `decryptToBytes` is capped and refuses anything over the image limit. |
| `local_auth` pulls in an unwanted permission | The merged manifest is checked and anything unwanted is removed with `tools:node="remove"`, exactly as ExoPlayer's network permissions already are. |

---

## 8. Out of scope for this phase

- Batch move to the vault from a multi-select toolbar — that is Phase 11.
- Encrypted backup and restore of the vault — Phase 11.
- Vault notes and markdown attachments — Phase 12.
