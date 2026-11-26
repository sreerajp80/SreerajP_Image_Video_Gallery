# Plan — Read back every vault payload before trusting it

**Status:** completed

Builds on:
- [plans/20261124_204202_fast-vault-envelope-encryption.md](20261124_204202_fast-vault-envelope-encryption.md)
- [plans/20261125_042609_vault-lock-choice.md](20261125_112609_vault-lock-choice.md)

## The issue

Three vault paths write an encrypted file and then let go of the readable copy. None of them
checks that the new file actually opens and holds the same bytes:

| Path | What is lost if the new file is bad |
|---|---|
| Format upgrade (`VaultUpgradeService`) | The old encrypted file is **deleted** right after the row update |
| Import (`VaultImportService`) | The original is hidden from the gallery, and **shredded** when the user chose that |
| Phone-move receive (`VaultTransferService.receive`) | The staged copy is **shredded**; the sending phone may be wiped later |

The phone test on 2026-11-25 showed the new format working (sizes exact, and Tink's tags rule
out changed bytes). But that is one phone, one Android version, and one run. A bug that shows
up only on another device, such as a broken crypto provider, a full disk mid-write, or a
truncated stream, would turn into **permanent loss of private photos**. This must be in place
before the new code goes onto the Play Store app that holds the owner's real vault.

## The fix

### 1. Kotlin measures what it encrypts

`encryptFile` and `encryptBytes` already stream every plaintext byte through the cipher. They
will also feed those bytes through SHA-256 (`MessageDigest` / `DigestInputStream`). This costs
almost nothing, because the bytes are already passing by. Each call returns:
- `sha256`: the digest of the plaintext;
- `plainBytes`: its length.

### 2. A new read-back call

New channel method `digestPayload(sourcePath, iv, format, keysetPath)`. It decrypts the
payload **as a stream** and returns only `{sha256, plainBytes}`. No plaintext crosses the
channel and nothing is written, so memory stays flat even for a 2 GB video. A failed tag check
is reported as `payload_tampered`, as today.

### 3. One rule in Dart

New `VaultCryptoService.verifyWritten(result)`. It calls `digestPayload` on the file just
written and checks that the digest and the length match what the encrypt call returned. If
they don't match, or the read fails, it throws `VaultException(code: 'verify_failed')`.

It is called right after each payload and preview is written, in:

- **`VaultUpgradeService._upgradeOne`**: before the row is moved and before the old file is
  deleted.
  - On failure, the new files are deleted, the old row and old file are kept, and **the
    whole run stops**. A failure here most likely means something is wrong on this device, and
    repeating slow format-1 decrypts for every item would waste the user's time. The next
    unlock tries again.
  - Why this proves the conversion: the old plaintext comes from a format-1 decrypt whose GCM
    tag was checked, so it is exactly what was stored. The encrypt call measures that same
    plaintext. The read-back proves the new file gives it back.
- **`VaultImportService._importOne`**: before the row is inserted. So an item that fails is
  never counted as moved, never hidden from the gallery, and its original is never shredded.
  The batch reports it as failed, as with any other import error.
- **`VaultTransferService.receive`**: before the row is inserted. The staged file is still
  shredded on every path, as today, and a failed item is reported as not received.

A preview that fails verification is dropped (the tile shows an icon), never fatal, as with
every other preview error.

### Cost

One extra streaming decrypt per file, on the normal CPU (format 2). On the test phone a 7.2 MB
photo opened in under 2 s, including decoding and drawing, so the decrypt itself is a fraction
of that. Format-1 files are not read again: their digest comes from the encrypt step.

## Files to change

| File | Change |
|------|--------|
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt` | SHA-256 while encrypting (`sha256`, `plainBytes` in the result); new `digestPayload` method (streamed, both formats) |
| `lib/services/vault/vault_channel.dart` | Parse `sha256` / `plainBytes`; new `digestPayload()` |
| `lib/models/vault/vault_crypto_result.dart` | `plainSha256`, `plainBytes` fields (`==` / `hashCode`) |
| `lib/models/vault/vault_payload_digest.dart` | **New** small immutable model `{sha256, plainBytes}` |
| `lib/services/vault/vault_crypto_service.dart` | `verifyWritten(VaultCryptoResult)` |
| `lib/services/vault/vault_upgrade_service.dart` | Verify payload and preview before `updateEncryption`; on failure delete the new files and stop the run |
| `lib/services/vault/vault_import_service.dart` | Verify before the row insert; a preview that fails is dropped |
| `lib/services/vault/vault_transfer_service.dart` | Verify before the row insert |
| `test/services/vault/fake_vault_channel.dart` | Return digests; a switch to corrupt the next written file, so a failure can be tested |
| `test/services/vault/vault_upgrade_service_test.dart` | A bad write keeps the old row and old file, deletes the new files, and stops the run |
| `test/services/vault/vault_import_service_test.dart` | A bad write leaves no row, the gallery item not hidden, and nothing shredded |
| `test/services/vault/vault_transfer_service_test.dart` | A bad write adds no row; staged file still shredded |
| `test/services/vault/vault_crypto_service_test.dart` | `verifyWritten` passes for a good file, fails on changed bytes and on a length mismatch |
| `docs/security.md` | §6: the read-back rule |

No new package, permission, database change or user-visible string. Failures reuse the
existing "could not be moved" messages.

## Security impact

Touches crypto and storage. It removes a data-loss risk and adds nothing that leaves the
device. The SHA-256 of the plaintext is held only for the moment of the check: it is not
stored and not logged.

## Checks after the change

- `dart format .`, `flutter analyze` (zero issues), `flutter test`.
- On the test phone (dev build):
  - old-code dev build → move photos in → new build → unlock → conversion still works;
  - moving a photo in still works;
  - check how long one conversion and one import take.
- Stop the Gradle daemons afterwards.

## After this

With this in place, the owner can install the new build over the Play Store app.

The app's Backup does **not** cover the vault: it holds tags, albums and notes, never photo
bytes, and leaves vaulted rows out (`docs/security.md` §14.1). So the vault has no second
copy. For photos that must not be lost, restore them from the vault to a folder first (vault →
select → Restore), and move them back in after the update. This needs the vault grid's
long-press selection, which is broken today (separate fix), so that fix may be worth doing
first.
