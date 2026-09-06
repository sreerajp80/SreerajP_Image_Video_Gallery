# Change Log — Phase 10: Secure Private Vault

**Date:** 2026-08-30
**Implements:** `plans/20260830_153000_phase_10_secure_private_vault.md`
**Covers:** `docs/implementation_plan.md` → Phase 10

---

## 1. What was built

The private vault: an Android Keystore master key, AES-256-GCM file
encryption, biometric unlock with a PIN fallback, multi-pass shredding,
`FLAG_SECURE` window protection, and auto-lock on backgrounding and on an idle
timeout.

All six action steps in the plan are done. `flutter analyze` is clean,
`flutter test` passes 1175 tests, and `flutter build apk --flavor dev --debug`
builds.

---

## 2. Dependencies added

| Package | Version | Licence |
|---|---|---|
| `local_auth` | ^2.3.0 | BSD-3-Clause |
| `local_auth_android` | ^1.0.0 | BSD-3-Clause |
| `flutter_secure_storage` | ^9.2.2 | BSD-3-Clause |

All three were already on the approved list in `docs/dependencies.md`. None
declares an HTTP client, a cloud SDK, analytics, or crash reporting.

The merged manifest was checked after adding them. It holds no `INTERNET`,
`ACCESS_NETWORK_STATE`, or `WAKE_LOCK` permission — see §7.

---

## 3. New files

### Models — `lib/models/vault/`

| File | Holds |
|---|---|
| `vault_lock_state.dart` | Where the vault stands, when it was last touched, and the wrong-PIN count. |
| `vault_security_settings.dart` | Auto-lock timeout, biometric toggle, shred passes, shred-on-import default. |
| `vault_auth_outcome.dart` | How one unlock attempt ended. |
| `vault_crypto_result.dart` | The name, IV, and size of one encrypted payload. |
| `vault_import_result.dart` | What a batch managed, failed, and shredded. |

### Services — `lib/services/vault/`

| File | Does |
|---|---|
| `vault_channel.dart` | The Android boundary. No method returns key material. |
| `vault_key_service.dart` | Creates the master key, and reports whether this device can hold one. |
| `vault_crypto_service.dart` | Where a payload goes, and whether a decrypt may go through memory. |
| `vault_pin_rules.dart` | Pure PIN validation. |
| `vault_pin_service.dart` | Pure PBKDF2-HMAC-SHA256, salt generation, constant-time compare. |
| `vault_credential_store.dart` | The salt and hash in `flutter_secure_storage`, plus an in-memory version for tests. |
| `vault_biometric_service.dart` | The biometric prompt, behind an interface tests can stand in for. |
| `vault_auth_service.dart` | Who may open the vault. |
| `vault_lock_policy.dart` | Pure: when an open vault has to shut. |
| `vault_storage_service.dart` | The `.secure_vault` directory, its `.nomedia` marker, and the sweeps. |
| `vault_naming_service.dart` | Pure: random hex names that carry nothing. |
| `vault_shredder_service.dart` | Multi-pass overwrite, with a Dart fallback. |
| `vault_preview_service.dart` | Builds previews in memory, never through the disk cache. |
| `vault_import_service.dart` | Moves media in, and rolls back after itself. |
| `vault_export_service.dart` | Takes media back out, and erases it for good. |

Also `lib/services/device/secure_window_service.dart` for the `FLAG_SECURE`
toggle.

### Repository, providers, screens, widgets

- `lib/repositories/vault_repository.dart` — the only thing the screens touch.
- `lib/providers/vault_providers.dart` — the services, `VaultLockController`,
  and `VaultBatchController`.
- `lib/screens/vault/` — the gate, the grid, the in-vault viewer, the settings.
- `lib/widgets/vault/` — the secure-screen wrapper, the auto-lock scope, the
  PIN pad, the tile, the import sheet.

### Android

- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt`
  — key generation, streamed cipher, shredder, and the window flag.

---

## 4. Changed files

| File | Change |
|---|---|
| `pubspec.yaml` | The three packages above. |
| `lib/core/constants/app_constants.dart` | The Phase 10 constants; `databaseVersion` 1 → 2. |
| `lib/core/errors/app_exception.dart` | `VaultException` and `VaultAuthException`. |
| `lib/core/routing/app_router.dart` | `/vault`, `/vault/settings`, `/vault/viewer/:id`. |
| `lib/models/vault_item.dart` | New `thumbnailIv` field — see §5. |
| `lib/repositories/database/database_constants.dart` | `schemaVersion` 1 → 2, `colVaultThumbnailIv`. |
| `lib/repositories/database/database_helper.dart` | The new column, and the v2 migration. |
| `lib/repositories/database/vault_dao.dart` | `updateVaultItem`, `getVaultItemsByIds`, `deleteVaultItems`, `getAllEncryptedFilenames`. |
| `lib/screens/timeline/timeline_screen.dart` | Vault in the overflow menu. |
| `lib/screens/viewer/media_viewer_screen.dart` | "Move to vault" action. |
| `android/.../MainActivity.kt` | Registers and disposes the vault handler. |
| `android/app/src/main/AndroidManifest.xml` | `USE_FINGERPRINT` declared explicitly — see §7. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | 82 new keys each, then `flutter gen-l10n`. |
| `docs/security.md` | The permission table now lists `USE_FINGERPRINT`. |
| `docs/implementation_progress.md` | Phase 10 marked complete. |

---

## 5. Two problems found and fixed during the work

**The keystore will not take a caller-supplied IV.**
The first version of the encrypt path generated a random IV in Kotlin and
passed it to `Cipher.init`. The master key is created with randomised
encryption required, which makes the keystore insist on drawing the IV itself
and refuse the one handed to it. The fix reads the IV back off the cipher
instead. This is the stronger arrangement: reusing an IV under this key is now
impossible rather than merely discouraged.

**One IV cannot decrypt two files.**
`VaultItem` had a single `iv` field, but each record has two encrypted files —
the payload and the preview — and each is encrypted under its own fresh IV.
Reading the preview with the payload's IV would have failed the authentication
tag on every vault tile, on a real device, every time. A repository test caught
it.

Fixed properly rather than worked around: a `thumbnail_iv` column, schema
version 2, and a migration that adds it. A row written before the column
existed reads as null, and the reader shows an icon rather than handing the
cipher an IV that was never used on those bytes. Two tests now pin this down.

---

## 6. Decisions worth recording

**The master key is not bound to user authentication at the Keystore level.**
Binding it would make the vault unopenable on a device with no screen lock and
no enrolled biometric, with no way back to the photos inside. The app gates the
vault instead: biometric or PIN before anything is decrypted.

**A device with no usable keystore gets no vault.**
It stays shut and says so. Falling back to a key the app made up itself would
look like a vault while giving almost none of its protection.

**There is no PIN recovery, and the set-up screen says so before a PIN is
chosen.** A recovery path would be a back door.

**Video is the one place vault content touches disk in the clear.** The
platform player cannot read from memory, so a clip is decrypted into a working
file inside the app-private vault directory — not the public cache, not the
temporary directory. It is shredded when the player closes, when the vault
locks, and swept on every unlock in case a crash left one behind. Photos and
previews never touch disk at all.

**Shredding says where it stops working.** On flash storage with wear
levelling, an overwrite is a best effort. It defeats undelete tools; it is not
a guarantee against a laboratory. The settings screen says this in as many
words rather than overselling it.

**Shredding an original is opt-in, off by default, and behind a second
confirmation** that names how many files will be destroyed.

---

## 7. Permissions

The merged manifest was checked after the build. It holds:

`READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `READ_MEDIA_VISUAL_USER_SELECTED`,
`READ_EXTERNAL_STORAGE` (maxSdk 32), `USE_BIOMETRIC`, `USE_FINGERPRINT`.

No `INTERNET`, no `ACCESS_NETWORK_STATE`, no `WAKE_LOCK`. The app stays fully
offline.

`USE_FINGERPRINT` is new. It arrives transitively from `androidx.biometric`
and is the older fingerprint permission for API 24 to 28. Since minSdk is 24
those devices are in range and genuinely need it, so it is kept rather than
removed — but it is now written out in the app manifest with `maxSdkVersion=28`
and a comment, so the merged manifest holds no permission the project's own
file does not name. `docs/security.md` §7 was updated to match; that file was
not in the plan's list, and the one-row addition is noted here for that reason.

---

## 8. Tests

New: 14 test files across the models, services, repository, DAO, and routes.

Worth calling out:

- The PBKDF2 implementation is checked against the published RFC 6070 vectors,
  not just against itself.
- The shredder test holds a second file handle open so it can read the bytes
  back after the overwrite and before the unlink, which is the only way to show
  the overwrite actually happened.
- The import roll-back is tested with a DAO whose insert fails, and asserts
  that no orphan payload and no touched original are left behind.
- The route test proves `/vault/settings` is never read as a vault item id.

Full suite: 1175 tests, all passing. `flutter analyze`: no issues.

---

## 9. Not done, and why

Left to their own phases, as the plan set out:

- Batch move to the vault from a multi-select toolbar — Phase 11.
- Encrypted backup and restore of the vault — Phase 11.
- Vault notes and markdown attachments — Phase 12.

One thing observed but not changed: the build warns that four plugins want
`compileSdk 36` while the project is on 35. Three of the four predate this
phase, the build succeeds, and changing `compileSdk` was not in the approved
plan, so it was left alone. It is worth picking up separately.
