# Plan — Fast vault: envelope encryption

**Status:** completed

## The issue

Opening a vault photo is very slow. One photo is slow; two are about twice as slow.

The cause is in `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt`:

1. **Every byte goes through the Android Keystore.** The vault's AES-256-GCM key is a Keystore
   key, and on phones that have it, a StrongBox key (a separate security chip). A Keystore key
   never leaves the secure hardware, so the whole photo is sent to that hardware to be
   encrypted or decrypted. The secure hardware is built for small secrets, not megabytes.
   StrongBox is the slowest of all.
2. **Tiny pieces.** `decryptToBytes` and `decryptToFile` read through `CipherInputStream`, which
   feeds the cipher about 512 bytes at a time. A 4 MB photo means about 8,000 separate trips to
   the secure hardware.

A smaller, separate cost: the PIN check (`VaultPinService.pbkdf2`, 120,000 HMAC rounds) runs in
Dart on the UI isolate, so the screen can freeze for a second or two on unlock.

Not yet measured on a real phone. I am about 80% sure point 1 is the main cause. Step 0 checks
it before any code changes.

## The fix in one line

Keep the Keystore key, but use it only to lock a small **data key**. The photos and videos are
encrypted with that data key on the normal CPU, which is hundreds of times faster.

This is "envelope encryption". It is how Android's own `EncryptedFile` and Google's Tink work.

## Design

### Keys

- **Master key** — unchanged. The existing Keystore key (`imgvidgal_vault_master_key`,
  StrongBox when the phone has it). It now encrypts only one small thing: the data keyset.
  Going through StrongBox for a few hundred bytes is fine.
- **Data keyset** — new. One Tink `StreamingAead` keyset (`AES256_GCM_HKDF_1MB`), made on first
  use. It is stored **encrypted by the master key** in one file inside the app-private vault
  directory (`vault_data_key.bin`). It is decrypted into memory when the vault unlocks and
  dropped when the vault locks.

### Why Tink StreamingAead and not plain AES-GCM

Plain AES-GCM in Android's normal crypto provider (Conscrypt) keeps the **whole** file in
memory while decrypting, because it cannot hand out any bytes until it has checked the tag at
the very end. That is fine for a photo but would run a large video out of memory.

Tink's streaming format cuts the file into 1 MB pieces. Each piece has its own tag, so it can
be checked and handed out one at a time. It also stops pieces being cut off, swapped or
reordered. Writing this format ourselves is possible, but a home-made crypto format is easy to
get subtly wrong. Tink is written and reviewed by Google's crypto team.

- **Dependency:** `com.google.crypto.tink:tink-android` (Apache-2.0). It is a Gradle (Android)
  dependency, not a pub package. Before adding it I will check its own dependency list, to
  confirm it brings in no networking code (the cloud key-service parts are separate modules
  that we will not add), and check the R8/ProGuard rules it needs.
- **Size:** adds roughly 1 MB to the APK before R8 shrinks it.

### Old and new items side by side

- New DB column `payload_format` on `vault_items` (schema **v10**), `INTEGER NOT NULL DEFAULT 1`.
  - `1` = old format: raw AES-GCM under the Keystore key, IV in the `iv` column.
  - `2` = new format: Tink streaming ciphertext under the data keyset. `iv` is not needed;
    it is stored as an empty string. (The column is `NOT NULL`, so it cannot be null.)
- The same marker covers the thumbnail: `thumbnail_format`, same rule.
- Reading checks the marker and picks the right path. Nothing is guessed from file contents.

### Old items get re-encrypted once

After unlock, a background job converts format-1 items to format 2, one item at a time:

1. Decrypt the old payload and encrypt it in the new format into a **new** file.
2. In one DB transaction, point the row at the new file and set `payload_format = 2`.
3. Only then delete the old file. It only ever held ciphertext, so a plain delete is enough
   (the same rule the orphan sweep uses today).

A crash at any point leaves either the old row and old file, or the new row and new file. The
orphan sweep on the next unlock removes the leftover file. The job stops when the vault locks
and continues at the next unlock. No decrypted bytes are written to disk: photos go through
memory, and videos go through the existing app-private working file, which is shredded.

Until an item is converted it still opens, just slowly. Point 2 above (512-byte pieces) is also
fixed for the old path, by feeding the cipher in 64 KB pieces, so old items get faster too.

### PIN check off the UI thread

`VaultAuthService` runs `VaultPinService.hashPin` / `verifyPin` inside `Isolate.run`. Same
algorithm, same 120,000 rounds, same stored hash. Only where it runs changes.

## Step 0 — measure first (owner runs it)

Before coding, the owner times opening one vault photo on the phone (a stopwatch is enough)
and notes the photo's size and whether the phone has StrongBox. After the change, the same test
shows whether the fix worked.

## Files to change

| File | Change |
|------|--------|
| `android/app/build.gradle.kts` | Add `com.google.crypto.tink:tink-android`, with a comment on licence and no-network check |
| `android/app/proguard-rules.pro` | Tink keep rules, if its own consumer rules are not enough |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt` | Data keyset load/create/wrap; new `encryptFileV2`, `encryptBytesV2`, `decryptToBytesV2`, `decryptToFileV2`, `forgetDataKey`; old decrypt path reads in 64 KB pieces instead of `CipherInputStream` |
| `lib/services/vault/vault_channel.dart` | New methods on `VaultChannel` and `PlatformVaultChannel` |
| `lib/services/vault/vault_crypto_service.dart` | New writes use format 2; reads pick the path by format |
| `lib/models/vault/vault_crypto_result.dart` | Carry the format of what was written |
| `lib/models/vault_item.dart` | `payloadFormat`, `thumbnailFormat` fields, `copyWith`, map, `==`, `hashCode` |
| `lib/repositories/database/database_constants.dart` | New column names; `schemaVersion = 10` |
| `lib/repositories/database/database_helper.dart` | Columns in the create SQL; v10 migration (`ALTER TABLE ... ADD COLUMN`); value-check triggers for the two columns |
| `lib/repositories/database/column_value_rules.dart` | Allowed values `1`, `2` for both columns |
| `lib/repositories/database/vault_dao.dart` | Read and write the new columns; update query for one converted row |
| `lib/repositories/vault_repository.dart` | Pass formats to crypto; `prepareForUnlock` never treats the keyset file as an orphan |
| `lib/services/vault/vault_storage_service.dart` | Keyset file name excluded from the orphan list |
| `lib/services/vault/vault_naming_service.dart` | Keyset file name constant |
| `lib/services/vault/vault_import_service.dart`, `vault_transfer_service.dart`, `vault_export_service.dart` | Use the format the crypto service returns, and read by format |
| `lib/services/vault/vault_upgrade_service.dart` | **New** (services layer). The one-time background conversion of format-1 items |
| `lib/providers/vault_providers.dart` | Provider for the upgrade service; start it after unlock, stop it on lock; tell Kotlin to forget the data key on lock |
| `lib/services/vault/vault_auth_service.dart` | PIN hashing in `Isolate.run` |
| Vault reset / "forget vault" path (wherever the master key and payloads are wiped) | Also shred the keyset file |
| `test/services/vault/fake_vault_channel.dart` | Fake the new methods |
| `test/services/vault/vault_crypto_service_test.dart`, `vault_import_service_test.dart`, `vault_export_service_test.dart`, `vault_transfer_service_test.dart`, `vault_auth_service_test.dart` | Cover format 1 and format 2 paths |
| `test/services/vault/vault_upgrade_service_test.dart` | **New.** Converts, survives a failure halfway, stops on lock |
| `test/repositories/vault_repository_test.dart`, `test/repositories/database/vault_dao_test.dart`, `database_migration_test.dart` | New columns, v9 → v10 migration, keyset file never swept |
| `docs/security.md` | §4/§6/§7 key table and crypto section: master key wraps a data keyset; Tink streaming format; legacy format note |
| `docs/architecture.md` | New upgrade service |
| `docs/dependencies.md` | Tink entry: why, licence, no-network check |

No file in `docs/guidelines/` (submodule) is touched. No user-visible text is added, so no ARB
changes. If the conversion later needs a progress line, that is a separate change with all
three languages.

## Security impact

Touches crypto, storage and dependencies.

- **At rest:** same strength. Files are still AES-256-GCM. The data keyset is useless without
  the hardware master key, so copying the vault folder off the phone still gives nothing.
- **While unlocked:** the data keyset is in app memory. Today the decrypted photos are already
  in app memory while you view them, so an attacker who can read app memory gains little new.
  The keyset is dropped on lock. (Java cannot promise memory is wiped; we clear what we hold.)
- **New single point of loss:** if `vault_data_key.bin` is deleted, format-2 items cannot be
  opened. Today the same is true of the Keystore key. The orphan sweep and every delete path
  must never touch this file; tests check it.
- **Dependency:** Tink is open source (Apache-2.0), with no networking in the module we add.
  To be checked before adding, as the project rules require.
- No permissions, manifest, network or logging changes.

## Checks after the change

- `dart format .`, `flutter analyze` (zero issues), `flutter test`.
- Owner: build the dev flavor, repeat Step 0, compare times. Then open an old (format-1) item,
  lock and unlock, and check it has been converted and still opens.
- Stop Gradle daemons after the build (global rule).

## Open questions for the owner

1. Tink dependency (recommended) or a home-made chunked AES-GCM format with no new dependency?
2. Convert old items automatically in the background (recommended), or leave them in the old
   format forever?
