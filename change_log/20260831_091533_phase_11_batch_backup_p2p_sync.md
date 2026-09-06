# Change Log — Phase 11: Batch Operations, Encrypted Backup/Restore & Local P2P Wi-Fi Sync

**Date:** 2026-08-31
**Implements:** [plans/20260830_200444_phase_11_batch_backup_p2p_sync.md](../plans/20260830_200444_phase_11_batch_backup_p2p_sync.md)
**Tracks:** [docs/implementation_plan.md](../docs/implementation_plan.md) — Phase 11

---

## 1. The rule change

Phase 11 needed sockets, and Android requires `android.permission.INTERNET` for
any socket at all — including one that only ever reaches another phone on the
same Wi-Fi router. The old hard rule 2 said the app carried no such permission,
so the rule had to change before anything could be built. The user approved the
change.

**Old rule:** "Fully offline-first. The app operates 100% offline with zero
network dependencies and no `android.permission.INTERNET`."

**New rule:** "Local network only, never the internet. The app never talks to a
remote server: no HTTP client, no cloud backend, no analytics, no telemetry, no
update check. `android.permission.INTERNET` is declared for exactly one feature
— the device-to-device transfer screen. Every connection is refused unless the
peer's address is private, the listener binds to the device's own Wi-Fi address
rather than `0.0.0.0`, and it runs only while the transfer screen is open."

The new rule is enforced in code, not just written down:

| Guarantee | Enforced by |
|---|---|
| Never connect off the local network | `LocalAddressRules`, checked in the pairing codec, the client and the server |
| Never bind to every interface | `P2pServerService.start` refuses `0.0.0.0` outright |
| The listener lives only with the screen | `SyncReceiveScreen` stops it in `dispose`, on backgrounding, and on every failure |
| One peer per session | The listener closes as soon as a peer completes the handshake |
| No HTTP client is unblocked | The blocked list in `docs/dependencies.md` is unchanged |

`test/services/sync/local_address_rules_test.dart` fails if a public address,
an IPv6 form, a hostname, or a leading-zero octet is ever accepted. The release
checklist now names that test.

Files carrying the rule change: `CLAUDE.md`, `AGENTS.md`,
`android/app/src/main/AndroidManifest.xml`, `docs/security.md`,
`docs/Project_Idea.md`, `docs/architecture.md`, `docs/dependencies.md`.

## 2. Manifest

Declared with the reason written beside each: `INTERNET` (local transfer only),
`ACCESS_WIFI_STATE` (read the device's own address to bind to), 
`ACCESS_NETWORK_STATE`, and `CAMERA` (the pairing QR scan, nothing else). The
camera is declared `required="false"`, so a device without one can still pair
by typing the code. `WAKE_LOCK` is still removed from the merged manifest.

## 3. Batch operations

- Models: `BatchAction`, `BatchProgress`, `BatchOutcome`.
- `BatchActionRules` — pure. Decides which actions a selection allows, why one
  is blocked, and which need a second confirmation. Both the action bar and the
  runner ask this class, so the two cannot drift and offer something that then
  fails.
- `BatchRunnerService` — sequential, cancellable between files (never during
  one), and it never sinks the whole batch for one bad file.
- `GalleryBatchHandler` — delegates every action to the Phase 6–10 services.
  Nothing is reimplemented, so a batch conversion and a single-file conversion
  cannot behave differently.
- App-wide selection state, so ticks survive moving between the timeline, an
  album and a search. Capped, and the cap is enforced at the point of ticking
  rather than at the point of running.
- UI: long-press to select, a tick overlay on every tile while selecting, the
  selection app bar, and the action bar. A blocked action is greyed out and says
  why when tapped, rather than vanishing.
- Actions covered: convert, watermark, PDF, add/remove tags, add to album,
  favourite, unfavourite, move to vault, transfer, move to trash.

## 4. Encrypted backup and restore

- The `.gallerybak` container: `GBAK` magic, format version, PBKDF2 salt,
  iteration count and IV in the clear at the front, then AES-256-GCM ciphertext
  of the gzipped JSON body.
- **The header is authenticated, not encrypted.** It has to be readable without
  the password, because it carries what the password is stretched with; it must
  not be changeable, or an attacker could rewrite the iteration count down to 1
  and turn a strong password into a weak one. It is passed to GCM as additional
  authenticated data, so altering any byte makes the archive refuse to open.
- Key derivation: PBKDF2-HMAC-SHA256, 210 000 iterations, 16-byte random
  per-file salt, in Kotlin. The password is used and dropped; there is no
  recovery, and the create dialog says so.
- The archive holds metadata, not media: tags, virtual albums, album
  membership, favourites, notes and places. Vaulted and trashed rows are
  excluded.
- `BackupMergeService` — pure. Matches each archive record to a local file by
  id, then content digest, then path, then name-size-date fingerprint. Each
  local file is claimed once, so a burst of identical frames does not pile every
  tag onto one photo.
- **A restore only adds and fills gaps.** `RestorePlan` has no delete list at
  all. A note or favourite already on the device is never replaced by an older
  one from the archive, and no media row is ever invented for a photo that is
  not on the phone. The full plan is shown before a single row is written.
- Storage Access Framework for both directions, so no storage permission is
  requested and none is held. Staging files are app-private and deleted in a
  `finally`, so an interrupted backup leaves no plaintext copy.
- Screens: `/backup`, the password dialog with its no-recovery warning, and the
  restore preview sheet.

## 5. Local peer-to-peer Wi-Fi transfer

- `LocalAddressRules` — pure, no imports, no configuration, no way to switch it
  off. The single place that decides whether an address may be talked to.
- `PairingCodec` — pure. The QR string and a six-group typed fallback in a
  reduced alphabet (no `I`, `L`, `O`, `U`). Refuses a wrong version, a bad
  checksum, a non-local address, or a well-known port.
- **The pairing code carries a short secret, not the key.** A 32-byte AES key
  cannot be read aloud, so the code carries 9 random bytes and both devices
  derive the same key with `HMAC-SHA256(secret, label)`. That is what makes the
  typed code a real fallback rather than a weaker one; the first attempt at this
  had the typed path unable to connect at all, and this replaced it.
- `TransferProtocol` and `FrameReader` — pure. Length-prefixed frames,
  reassembly across arbitrary reads, and refusal of an oversized frame on its
  *announced* length, before anything is allocated.
- Handshake: the connecting device sends a challenge, the listening device
  answers with an HMAC under the session key (proving possession without
  sending the key), and every frame after that is AES-256-GCM encrypted, so the
  connecting device proves possession implicitly. A device on the same Wi-Fi
  that never saw the code opens a socket and gets no further.
- `P2pServerService`, `P2pClientService`, `P2pConnection`,
  `TransferExchangeService`, `TransferSessionService`.
- **Nothing reaches the gallery on the sender's word.** Every incoming file is
  staged app-private, checked against the promised byte length *and* SHA-256,
  and has its name stripped of directory separators, parent references, leading
  dots and control characters. It is then published through MediaStore with
  `IS_PENDING` set until the bytes are all written. A file that fails any check
  is deleted, not saved.
- Screens: `/sync`, `/sync/receive` (shows the code, owns the listener) and
  `/sync/send` (reads the code, with the typed fallback always available).

## 6. Two design problems found and fixed while building

1. **The backup collector lost album membership.** It first kept only media
   records carrying user data, which meant a plain photo sitting in an album had
   no record for the album link to hang on, and the album would have restored
   empty — losing exactly what most people make a backup for. The collector now
   gathers links first and keeps a record when it carries user data *or* anchors
   a link.
2. **The typed pairing code could never connect.** It carried 9 bytes of a
   32-byte key, so the receiving side could not reconstruct the key at all. The
   fix was to make the code carry a pairing secret and have both sides derive the
   key from it, which also removed the asymmetry between the two pairing routes.

A third, smaller one: `P2pConnection` first delivered frames over a
single-subscription stream, which cannot be awaited twice and would have broken
on the second handshake read. It now uses a frame queue, so a frame arriving
between two awaits is kept rather than dropped.

## 7. Dependencies

Added `qr_flutter` ^4.1.0 (BSD-3-Clause, pure Dart, draws the pairing QR) and
`mobile_scanner` ^5.2.3 (BSD-3-Clause, already on the approved baseline list,
reads it). No package was added for compression — `dart:io`'s `GZipCodec` does
it. The blocked list is unchanged: relaxing hard rule 2 unblocked no package.

## 8. Verification

- `flutter analyze` — clean, no issues.
- `flutter test` — 1409 tests pass.
- New tests: the address rules (the guard on the relaxed rule), the pairing
  codec and both derivation routes, the frame protocol, the batch rules and
  runner, the backup container, serializer and merge plan, the selection state,
  the new routes, and a real loopback socket moving real files end to end with
  digest checks, cancellation, and every refusal path.
- Every new user-visible string is in both `app_en.arb` and `app_ml.arb`, each
  with an `@key` description. 112 keys added per file; `flutter gen-l10n` run.

## 9. Not done

The transfer's receiving side accepts everything the peer offers rather than
showing a per-file tick list. The screen states what will be transferred before
the session starts, and a second list to work through while the other person
waits would be a worse experience rather than a safer one. If a per-file choice
is wanted later, `TransferExchangeService.receive` already takes an `accept`
callback for exactly that.
