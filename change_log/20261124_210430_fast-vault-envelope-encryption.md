# Change log — Fast vault: envelope encryption

Implements: [plans/20261124_204202_fast-vault-envelope-encryption.md](../plans/20261124_204202_fast-vault-envelope-encryption.md)

## Why

Opening a vault photo was very slow, and each extra photo made it slower. Every byte was
encrypted and decrypted inside the Android Keystore (StrongBox when the phone has it), and
reading went through `CipherInputStream`, which sends about 512 bytes per call into the secure
hardware. That hardware is built for small secrets, not megabytes.

## What changed

### Android (Kotlin)

- `VaultChannelHandler.kt`
  - **Envelope encryption.** The Keystore master key is unchanged, but it now seals only a Tink
    `AES256_GCM_HKDF_1MB` streaming keyset (the "data keyset"). The keyset is stored sealed in
    `vault_data_key.bin` in the vault folder, written atomically (temp file + sync + rename).
    It is created only when missing. A keyset file that will not open is an error, never a
    reason to make a new one.
  - Every write (`encryptFile`, `encryptBytes`) is format 2 and returns `format`.
  - Reads (`decryptToBytes`, `decryptToFile`) take `format`: 2 reads through the data keyset,
    1 (old) reads through the master key, now in 64 KB pieces instead of `CipherInputStream`,
    so old items are faster too.
  - New `forgetDataKey` drops the keyset from memory.
  - A failed Tink segment check is reported as `payload_tampered`, as before.
- `build.gradle.kts`: `com.google.crypto.tink:tink-android:1.24.0` (Apache-2.0). Its POM lists
  only annotation libraries and `gson`; no network code.
- `proguard-rules.pro`: two `-dontwarn` lines for compile-time annotations. Tink ships its own
  protobuf rules.

### Dart

- `app_constants.dart`: `vaultDataKeyFileName`, `vaultPayloadFormatLegacy` (1),
  `vaultPayloadFormatStreaming` (2).
- `vault_channel.dart`: `keysetPath` on every crypto call, `format` on reads, new
  `forgetDataKey()`.
- `vault_crypto_result.dart`: carries `format`.
- `vault_crypto_service.dart`: passes the keyset path; reads take `format`; new
  `encryptBytesToPayload` (used by the upgrade) and `forgetDataKey`.
- `vault_item.dart`: `payloadFormat`, `thumbnailFormat` (default 1).
- Database **schema v10** (`database_constants.dart`, `database_helper.dart`,
  `column_value_rules.dart`): `vault_items.payload_format` and `thumbnail_format`, `INTEGER NOT
  NULL DEFAULT 1`, allowed values 1 and 2 (CHECK on a new database, triggers on an upgraded one).
- `vault_dao.dart`:
  - New `updateEncryption` writes only the crypto columns and returns how many rows changed.
  - New `getLegacyFormatIds`.
  - `updateVaultItem` (rename, notes, tags) **no longer writes the crypto columns**. Without
    this, a screen holding a row loaded before the upgrade could point it back at a deleted old
    file.
- Import, transfer and export services and the repository store and pass the format.
- **New** `lib/services/vault/vault_upgrade_service.dart` (services layer): converts format-1
  items after unlock, one at a time. Order: write the new file under a new name → one row
  update → delete the old ciphertext. A failure leaves the old row and old file; an item
  deleted meanwhile gets its new files removed. Videos go through the app-private working
  file, shredded at once.
- `vault_providers.dart`:
  - The lock controller starts the upgrade after unlock (not awaited) and calls
    `forgetDataKey` on lock.
  - The upgrade stops when the vault locks or a vault batch starts. A batch waits for the item
    in progress, then re-reads its rows, so it works on the files that are really there.
  - Converted items bump the vault revision, so views reload.
- `vault_pin_service.dart` / `vault_auth_service.dart`: PIN hashing and checking run in
  `Isolate.run`. Same algorithm, same 120 000 rounds, same stored hash.

### Tests

- Fake channel: records the format of each written file and refuses a read with the wrong
  format, so a caller that forgets the format fails a test.
- New `vault_upgrade_service_test.dart` (7 tests) and `vault_lock_controller_test.dart`
  (5 tests).
- New DAO tests (formats, `updateEncryption`, `updateVaultItem` leaves crypto columns,
  `getLegacyFormatIds`), a v9 → v10 migration test, and crypto service tests (write format,
  keyset path, old-format read, keyset file never swept).
- Existing tests updated for the new arguments.

### Docs

- `docs/security.md`: key table, §6 diagram, envelope encryption and formats, PIN on an
  isolate.
- `docs/architecture.md`: schema v10 row, data key lifecycle.
- `docs/dependencies.md`: Tink entry.

## Small differences from the plan

- **The `iv` column for format 2.** The plan said an empty string. Instead it holds a random
  128-bit file id, bound to the ciphertext as Tink associated data. This keeps the existing
  "IV must not be empty" checks, and it makes two payload files swapped on disk fail their
  check.
- **"Vault reset" row.** The app has no path that wipes vault payloads, so there was nothing to
  change. The keyset file is safe from the sweeps because its extension matches none of
  `.enc`, `.thm`, `.dec` (tested).
- **Added beyond the plan.** `updateVaultItem` skips the crypto columns, and batches wait for
  and re-read rows (race safety). Both are described above.

## Checks

- `dart format`: no changes needed.
- `flutter analyze`: no issues.
- `flutter test`: all 2541 tests passed.

## Not done yet (owner)

- **Done on 2026-11-25** (see "Phone test" below). Not yet installed over the Play Store
  (prod) app, which holds the real vault.

## Phone test (2026-11-25)

Test phone: Android 10, 32-bit ARM, no StrongBox. Debug dev builds only, with generated
7.2 MB test photos; no real photos were used.

1. Installed a dev build of the **old** code (previous commit) and moved 3 photos into its
   vault.
2. Opening one photo took **about 43 s** (measured twice).
3. Installed the **new** dev build over it and unlocked.
   - All 3 old items were converted within seconds of unlock.
   - The old files were gone, and `vault_data_key.bin` (162 bytes) was created.
   - Each new file is exactly the original size + 168 bytes: a 40-byte header plus 8 × 16-byte
     segment tags. So no bytes were lost, and the tags rule out changed bytes.
4. Opening a photo took **about 3 s**, and most of that is the 2 s polling step of the test
   script.
5. Lock, then unlock (the keyset reloads from its file): photos still open in about 3 s.
6. A new import through the viewer (the streaming `encryptFile` path) wrote the expected size
   and opened in about 4 s.
7. No app exceptions in the log. Gradle daemons stopped afterwards.

Problems seen during the test that this change did not cause (they need their own plans):

- The multi-select "Move to vault" skips the vault set-up/unlock check.
- Every touch in the vault reloads the list and decrypts all thumbnails again, which breaks
  long-press selection.
- No previews are made for large photos.
- The PIN pad's delete key reads "Clear selection".

## Security impact

- **At rest:** same strength (AES-256-GCM).
- **While unlocked:** the data keyset is in app memory, and it is dropped on lock.
- **New single point of loss:** `vault_data_key.bin`.
- **New dependency:** Tink, open source, no network code.
- No change to permissions, the manifest, the network or logging.
