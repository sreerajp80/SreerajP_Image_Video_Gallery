# Change log — Read back every vault payload before trusting it

Implements: [plans/20261125_045802_vault-write-verification.md](../plans/20261125_045802_vault-write-verification.md)

## What changed

### Kotlin (`VaultChannelHandler.kt`)

- `encryptFile` and `encryptBytes` run the plaintext through SHA-256 while encrypting, and
  return `sha256` (hex) and `plainBytes` with the result. `copy()` now also returns the byte
  count and can feed a digest.
- New `digestPayload`: decrypts a payload as a stream (format 1 or 2) into a sink that only
  hashes and counts, and returns `{sha256, plainBytes}`. No plaintext crosses the channel or
  touches disk. A failed tag check is reported as `payload_tampered`, as on other reads.

### Dart

- **New** `lib/models/vault/vault_payload_digest.dart`: immutable `{sha256, plainBytes}`. Its
  `toString` leaves out the digest.
- `vault_crypto_result.dart`: new `plain` field.
- `vault_channel.dart`:
  - parses the digest from the encrypt answers, and refuses an answer without it;
  - new `digestPayload()`.
- `vault_crypto_service.dart`: new `verifyWritten(result)`. It throws
  `VaultException(code: 'verify_failed')` on a mismatch or a failed read.
- `vault_upgrade_service.dart`:
  - The payload is verified before the row moves and the old file is deleted.
  - A `verify_failed` **stops the whole run**, and the old files all stay.
  - A preview that fails is deleted, and the old preview is kept.
- `vault_import_service.dart`:
  - The payload is verified before the row insert. On failure the payload is deleted, and
    the original is never hidden or shredded.
  - A preview that fails is dropped, and the item goes in without one.
- `vault_transfer_service.dart`:
  - The payload is verified before the row insert. On failure the payload is removed, and the
    staged copy is still shredded.
  - A preview that fails is dropped, with a debug log line (the project's catch-policy test
    requires it).

### Tests

- Fake channel:
  - returns real SHA-256 digests;
  - `corruptNextWrites` damages a written file while still reporting success;
  - `onWrite` lets a test pick which write to damage;
  - `digested` records each read-back.
- Crypto: `verifyWritten` passes for a good file, and fails for a changed file and for a
  missing one.
- Upgrade:
  - every converted file is read back;
  - a bad payload keeps both rows and all old files, leaves no new file, and stops after one
    read-back;
  - a bad preview keeps the old preview.
- Import:
  - a bad payload means no row, the original not hidden and not shredded, and no file left;
  - a bad preview means the item goes in without one.
- Transfer: a bad payload means no row and no payload left, and the staged copy is still
  shredded.

### Docs

`docs/security.md` §6: the read-back rule.

## Checks

- `dart format`: no changes.
- `flutter analyze`: no issues.
- `flutter test`: all 2576 passed. The first full run failed one project check: a new `catch`
  had a comment but no log line. Fixed.

### Phone test (2026-11-25)

Dev build on the test phone (Android 10).

- New vault created with a PIN. The set-up screen pre-selected Vault PIN, because the phone has
  no screen lock, and the first PIN step shows "Next".
- Moved an 18 KB photo and a 7.2 MB photo in with multi-select. Both finished in **about 4 s
  in total, read-back included**, with no read-back failure.
- File sizes are exact: plaintext + 56 bytes for the one-segment file, and + 168 bytes for the
  8-segment file.
- Both open from the vault (about 2.5–4 s each, including the test script's 2 s polling
  step).
- Test photos deleted from the phone, Gradle daemons stopped.

**Not checked on the phone:**

- **The format-upgrade path.** It needs an old-code build first; that path was phone-tested
  on 2026-11-25 before this change, and is unit-tested with the check now.
- **The preview read-back.** The phone made **no preview even for the 800×600 photo**, so
  previews fail for every photo, not only big ones. That is a separate bug, most likely
  reading the file by its path, and needs its own plan.

## Security impact

Removes a data-loss risk on the three paths that let go of a readable copy. The plaintext
digest exists only for the moment of the check: it is never stored or logged. No new package,
permission, string or database change.
