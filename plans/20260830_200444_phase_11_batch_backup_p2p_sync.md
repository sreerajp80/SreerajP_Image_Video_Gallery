# Phase 11 — Batch Operations, Encrypted Backup/Restore & Local P2P Wi-Fi Sync

**Status:** completed

**Date:** 2026-08-30
**Implements:** `docs/implementation_plan.md` — Phase 11
**Tracks:** `docs/implementation_progress.md` — Phase 11

---

## 1. What this phase delivers

Three things, in this order:

1. **Batch operations.** A multi-select mode on the timeline, album, folder and search
   grids, with one shared action bar that runs the tools built in Phases 6 to 10 over
   many files at once: convert, compress, watermark, PDF, tag, album, vault, favourite,
   and trash.
2. **Encrypted backup and restore.** One password-protected `.gallerybak` file holding
   every tag, virtual album, favourite, user note and metadata edit, written and read
   through the Android file picker so no storage permission is needed.
3. **Local peer-to-peer Wi-Fi sync.** Direct device-to-device transfer of photos, videos
   and their metadata over the local Wi-Fi network, paired by QR code, with no server
   and no cloud.

---

## 2. The issue: part 3 breaks a hard rule

`CLAUDE.md` hard rule 2 says the app is fully offline with **no**
`android.permission.INTERNET`, and `android/app/src/main/AndroidManifest.xml` removes
that permission on purpose with `tools:node="remove"`.

Android needs `INTERNET` for **any** socket, including one that only ever talks to
another phone on the same Wi-Fi router. So P2P sync cannot be built while that rule
stands as written.

**The user has decided to relax the rule** so P2P sync can be built. This plan therefore
changes the rule from "no sockets at all" to "**local network only, never the
internet**", and writes that new, narrower promise into every document that carries the
old one. This is a real, permanent change to what the app promises, so it is called out
here rather than buried in a file list.

### The new rule, exactly as it will be written

> The app never talks to a remote server. It has no HTTP client, no cloud backend, no
> analytics and no telemetry. `android.permission.INTERNET` is present for one reason
> only: the peer-to-peer transfer feature, which opens a socket to another device on the
> same local Wi-Fi network. Every connection is refused unless the peer's address is in a
> private range (`10/8`, `172.16/12`, `192.168/16`, `169.254/16` link-local). The socket
> listener only runs while the user has the transfer screen open, and is closed the
> moment they leave it.

### How the promise is kept in code

- `LocalAddressRules` (pure, unit tested) decides whether an address is private. Anything
  else is refused before a socket is opened, on both the sending and receiving side.
- The `ServerSocket` binds to the device's own Wi-Fi address, never `0.0.0.0`.
- The listener starts when the transfer screen opens and stops when it closes, on app
  background, and after an idle timeout.
- Every transfer is authenticated and encrypted with a session key that only ever exists
  inside the QR code, so a device on the same Wi-Fi that did not scan the code cannot
  read or push anything.
- The blocked-dependency list keeps `http`, `dio`, `firebase`, analytics and crash
  reporting blocked. `dart:io` sockets are the only networking allowed.

---

## 3. Files to change

### 3.1 Rule and documentation changes (the relaxation)

| File | Change |
|---|---|
| `CLAUDE.md` | Rewrite hard rule 2 to the "local network only" wording. Update the security-rules section. Add the transfer screen to the route list. |
| `AGENTS.md` | Same rule change, kept word for word in step with `CLAUDE.md`. |
| `android/app/src/main/AndroidManifest.xml` | Remove the `tools:node="remove"` block for `INTERNET`; declare `INTERNET`, `ACCESS_WIFI_STATE`, `ACCESS_NETWORK_STATE` and `CAMERA` with a comment saying exactly why each is there. Keep `WAKE_LOCK` removed. |
| `docs/security.md` | New section "Local Peer-to-Peer Transfer": threat model, session key, address rules, listener lifetime. New section "Backup Archive Format". Update the permission table and the M-series checklist. |
| `docs/Project_Idea.md` | Change "fully offline / zero network" wording to "no remote network; local Wi-Fi transfer only". |
| `docs/dependencies.md` | Add `qr_flutter` and `mobile_scanner` with licence and reason. Restate that HTTP clients stay blocked and that only `dart:io` sockets are allowed. |
| `docs/architecture.md` | Add the `sync/`, `backup/` and `batch/` service groups and the new routes. |
| `docs/implementation_progress.md` | Tick every Phase 11 box, set the phase to Completed / 100%. |

### 3.2 New dependencies (`pubspec.yaml`)

| Package | Licence | Why |
|---|---|---|
| `qr_flutter` | BSD-3-Clause | Draws the pairing QR code. Pure Dart, no network, no platform code. |
| `mobile_scanner` | BSD-3-Clause | Reads the pairing QR code from the camera. Already on the approved baseline list in `docs/dependencies.md`. Pinned to the bundled scanner so no model is ever downloaded. |

No package is added for compression: `dart:io`'s built-in `GZipCodec` does it. `camera`
comes in through `mobile_scanner` and is not added directly.

### 3.3 New models (`lib/models/`)

| File | Holds |
|---|---|
| `lib/models/batch/batch_action.dart` | `BatchAction` enum and its metadata (icon key, label key, which media types it accepts). |
| `lib/models/batch/batch_progress.dart` | Immutable `BatchProgress` (done, total, current name, cancelled). |
| `lib/models/batch/batch_outcome.dart` | Immutable `BatchOutcome` (succeeded ids, failed ids, skipped ids, first error message). |
| `lib/models/backup/backup_manifest.dart` | Immutable header: format version, schema version, app version, created-at, item counts. |
| `lib/models/backup/backup_payload.dart` | Immutable body: tags, media-tag links, virtual albums, album membership, and per-media metadata records. |
| `lib/models/backup/backup_media_record.dart` | Immutable per-file record: id, path, display name, size, date taken, sha256, favourite, notes, address, latitude, longitude. |
| `lib/models/backup/restore_plan.dart` | Immutable merge plan: what will be added, what will be updated, what cannot be matched. |
| `lib/models/backup/restore_summary.dart` | Immutable result of applying a plan. |
| `lib/models/sync/pairing_payload.dart` | Immutable pairing data: host, port, session key, fingerprint, device name, protocol version. |
| `lib/models/sync/transfer_manifest.dart` | Immutable list of offered items (name, size, type, sha256, metadata). |
| `lib/models/sync/transfer_progress.dart` | Immutable per-file and overall progress. |
| `lib/models/sync/transfer_outcome.dart` | Immutable result: received, sent, skipped, failed. |
| `lib/models/sync/sync_role.dart` | `SyncRole` enum (`send`, `receive`) and `SyncPhase` enum (idle, waiting, paired, transferring, done, failed). |

### 3.4 New services (`lib/services/`)

**Batch**

| File | Does |
|---|---|
| `lib/services/batch/batch_action_rules.dart` | Pure. Which actions a selection allows (for example, PDF needs at least one image; watermark refuses videos), and the reason string key when an action is not allowed. |
| `lib/services/batch/batch_runner_service.dart` | Runs one action over a list of items, one at a time, reporting progress and honouring a cancel flag. Never stops the whole batch for one bad file. Delegates to the Phase 6-10 services; contains no image or crypto code of its own. |

**Backup**

| File | Does |
|---|---|
| `lib/services/backup/backup_format.dart` | Pure. The `.gallerybak` container constants and the header encode/decode: magic `GBAK`, format version, KDF salt, iteration count, IV, and the authenticated-header bytes. |
| `lib/services/backup/backup_serializer.dart` | Pure. `BackupPayload` to and from JSON, with a round trip that must be exact. |
| `lib/services/backup/backup_collector_service.dart` | Reads the DAOs and builds a `BackupPayload`. |
| `lib/services/backup/backup_merge_service.dart` | Pure. Builds a `RestorePlan` from a payload plus what is already in the database. Matches a backup record to a local file by id first, then by exact path, then by display name + size + date taken. Never invents a media row for a file that is not on this device. |
| `lib/services/backup/backup_apply_service.dart` | Applies a `RestorePlan` to the DAOs inside one transaction. |
| `lib/services/backup/backup_crypto_channel.dart` | Dart side of the `backup` method channel: derive-and-encrypt to a document, and decrypt-from-a-document. |
| `lib/services/backup/backup_service.dart` | The whole write path: collect, serialise, gzip to an app-private staging file, ask the user for a destination, encrypt into it, delete the staging file. |
| `lib/services/backup/restore_service.dart` | The whole read path: ask the user for a file, decrypt to an app-private staging file, gunzip, parse, build the plan, and (after the user confirms) apply it. |
| `lib/services/backup/document_picker_channel.dart` | Dart side of the Storage Access Framework picker (create document, open document). |

**Sync**

| File | Does |
|---|---|
| `lib/services/sync/local_address_rules.dart` | Pure. Is this IPv4 address in a private range? Used to bind, and to refuse any peer that is not local. This is the file that keeps the new rule honest. |
| `lib/services/sync/network_interface_service.dart` | Finds the device's own Wi-Fi IPv4 address through `NetworkInterface.list`, refusing anything `LocalAddressRules` rejects. |
| `lib/services/sync/pairing_codec.dart` | Pure. `PairingPayload` to and from the compact QR string, and to and from the six-group manual code. Rejects a malformed or wrong-version string. |
| `lib/services/sync/transfer_protocol.dart` | Pure. Frame encode and decode: a four-byte big-endian length, a one-byte frame type, then the body. Plus the handshake, manifest, file-header, chunk and acknowledgement frame shapes. |
| `lib/services/sync/transfer_crypto_service.dart` | Session-key AES-256-GCM over the `backup` channel, reused for the wire so no plaintext photo crosses the Wi-Fi. |
| `lib/services/sync/p2p_server_service.dart` | Binds a `ServerSocket` to the local address on an ephemeral port, accepts exactly one peer, checks the handshake against the session key, refuses a non-private remote address, then serves or receives. Closes on stop, on error, and on idle timeout. |
| `lib/services/sync/p2p_client_service.dart` | Connects to a scanned peer, does the handshake, then sends or receives. Refuses a non-private address before connecting. |
| `lib/services/sync/transfer_session_service.dart` | Drives one whole session for the UI: role, phase, progress, cancel. Owns the server or client and guarantees the socket is closed. |
| `lib/services/sync/received_media_service.dart` | Writes an incoming file through `AtomicSaver` into the shared gallery folder, imports its metadata, and asks for a media scan. Never overwrites: a clashing name gets a suffix through `OutputNamingService`. |

### 3.5 New providers (`lib/providers/`)

| File | Holds |
|---|---|
| `lib/providers/selection_providers.dart` | `SelectionNotifier` (a `Set<String>` of media ids), `selectionModeProvider`, and the resolved `selectedMediaProvider`. |
| `lib/providers/batch_providers.dart` | `batchRunnerProvider`, `batchProgressProvider`, and the controller that starts and cancels a batch. |
| `lib/providers/backup_providers.dart` | Service providers, the backup controller, and the restore controller with its plan preview. |
| `lib/providers/sync_providers.dart` | Service providers, the session controller, and the discovered-pairing state. |

### 3.6 New screens and widgets

| File | Is |
|---|---|
| `lib/screens/backup/backup_screen.dart` | `/backup`. Create a backup, restore a backup, and the restore preview with its counts. |
| `lib/screens/sync/sync_home_screen.dart` | `/sync`. Choose Send or Receive, with the local-network warning and what will be transferred. |
| `lib/screens/sync/sync_receive_screen.dart` | `/sync/receive`. Shows the QR code and the manual code, waits for a peer, then shows progress. |
| `lib/screens/sync/sync_send_screen.dart` | `/sync/send`. Scans the QR code (or takes the manual code), then shows progress. |
| `lib/widgets/batch/selection_app_bar.dart` | The count, select-all, and close actions shown while selecting. |
| `lib/widgets/batch/batch_action_bar.dart` | The bottom action bar and its overflow sheet. |
| `lib/widgets/batch/batch_progress_dialog.dart` | Progress, current file, and Cancel. |
| `lib/widgets/batch/batch_result_sheet.dart` | What worked and what did not, after a batch. |
| `lib/widgets/backup/backup_password_dialog.dart` | Password entry, with confirm-and-strength on create and a plain field on restore. |
| `lib/widgets/backup/restore_preview_sheet.dart` | The merge plan in words before anything is written. |
| `lib/widgets/sync/pairing_qr_card.dart` | The QR image plus the manual code. |
| `lib/widgets/sync/qr_scanner_view.dart` | The camera preview and its permission and error states. |
| `lib/widgets/sync/transfer_progress_view.dart` | Per-file and overall progress. |

### 3.7 New Android code

| File | Does |
|---|---|
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/backup/BackupChannelHandler.kt` | The `backup` method channel. PBKDF2-HMAC-SHA256 key derivation from the user's password, streamed AES-256-GCM encryption into a Storage Access Framework document, and streamed decryption back out to an app-private file. The header bytes are passed as additional authenticated data, so the salt and iteration count cannot be tampered with. Also the session-key encrypt/decrypt used by the transfer. |
| `android/app/src/main/kotlin/in/sreerajp/imgvidgal/backup/DocumentPickerChannelHandler.kt` | The `documents` method channel. `ACTION_CREATE_DOCUMENT` and `ACTION_OPEN_DOCUMENT`, returning a content URI. No storage permission is requested; the user picks the file. |

`MainActivity.kt` is edited to build, wire and dispose both handlers, and to forward
`onActivityResult` to the picker.

### 3.8 Files edited

| File | Edit |
|---|---|
| `lib/core/routing/app_router.dart` | Add `/backup`, `/sync`, `/sync/send`, `/sync/receive` and their path builders. |
| `lib/core/constants/app_constants.dart` | Add the batch chunk size, transfer chunk size, socket and idle timeouts, backup KDF iteration count, and the pairing code length. |
| `lib/screens/timeline/timeline_screen.dart` | Long-press a tile to enter selection mode; tap toggles while selecting; swap in the selection app bar and the action bar; add Backup and Transfer to the overflow menu. |
| `lib/screens/albums/album_media_screen.dart`, `smart_album_screen.dart` | Same selection mode, through the shared album media grid. |
| `lib/widgets/albums/album_media_grid.dart` | Selection support passed through to the tile. |
| `lib/screens/search/search_screen.dart` | Same selection mode over the result grid. |
| `lib/widgets/media/media_grid_tile.dart` | Add `isSelected`, `selectionMode`, and `onLongPress`; draw the tick and the dimming overlay. |
| `lib/repositories/database/tag_dao.dart` | Add `getAllMediaTagLinks()` for the backup collector. |
| `lib/repositories/database/album_dao.dart` | Add `getAllAlbumMediaLinks()` for the backup collector. |
| `lib/repositories/database/media_dao.dart` | Add `getBackupRecords()` (only the user-owned columns) and `applyBackupRecord()`. |
| `lib/repositories/media_repository.dart` | Add `setNotes`, and a batch `setFavorite`/`setTrash`. |
| `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb` | Every new label, with an `@key` description for each. |
| `android/app/proguard-rules.pro` | Keep rules for `mobile_scanner` and the ML Kit barcode classes. |

### 3.9 New tests (`test/`)

Mirroring `lib/`:

- `test/models/batch/` — the three batch models.
- `test/models/backup/` — manifest, payload, media record, plan, summary, and JSON round trips.
- `test/models/sync/` — pairing payload, transfer manifest, progress, outcome.
- `test/services/batch/batch_action_rules_test.dart` — which action a mixed selection allows.
- `test/services/batch/batch_runner_service_test.dart` — progress order, cancel between files, and that one failure does not stop the rest.
- `test/services/backup/backup_format_test.dart` — header encode and decode, magic and version rejection, and a truncated file.
- `test/services/backup/backup_serializer_test.dart` — exact round trip, and an unknown future field being ignored rather than throwing.
- `test/services/backup/backup_merge_service_test.dart` — all three match routes, plus the unmatched case.
- `test/services/backup/backup_apply_service_test.dart` — against a real in-memory database.
- `test/services/sync/local_address_rules_test.dart` — every private range accepted, and a public address, an IPv6 address and rubbish all refused. **This is the test that guards the relaxed rule.**
- `test/services/sync/pairing_codec_test.dart` — round trip, wrong version, truncated string, and a bad checksum.
- `test/services/sync/transfer_protocol_test.dart` — frame round trip, split frames reassembled, an oversized frame refused, and a short read.
- `test/services/sync/network_interface_service_test.dart` — picking a private address out of a mixed list.
- `test/services/sync/p2p_socket_test.dart` — a real loopback server and client, exchanging a small file and its metadata.
- `test/providers/selection_providers_test.dart` — toggle, select all, clear, and mode.
- `test/core/routing/backup_sync_routes_test.dart` — the new route round trips.

---

## 4. Design decisions worth stating

1. **The backup holds metadata, not photos.** `docs/Project_Idea.md` asks for tags,
   albums, metadata edits, notes and favourites. Copying gigabytes of originals into an
   encrypted blob would make restore slow and the file unusable. Photos move device to
   device through P2P transfer instead, which is the tool built for it.
2. **Backup crypto is native, not Dart.** The vault already derives and uses keys in
   Kotlin, and reusing that path keeps every AES operation in one place and lets a large
   archive stream rather than sit in memory. PBKDF2-HMAC-SHA256 with a per-file random
   salt and a stored iteration count matches the vault's PIN hashing.
3. **The backup password is never stored.** It derives a key, is used, and is dropped.
   There is no recovery: the confirm dialog says so plainly.
4. **The file picker replaces a storage permission.** Storage Access Framework means the
   user picks where the backup goes and which file comes back, and the app asks for no
   new storage permission. That keeps hard rule 3 intact.
5. **Transfer is encrypted even on a home Wi-Fi.** The session key lives only in the QR
   code, so another device on the same router cannot read the transfer or push files
   into the gallery, even though it can see the port is open.
6. **The listener is short-lived.** The socket exists only while the transfer screen is
   open. There is no background service, no always-on port, and no discovery broadcast.
7. **Nothing received overwrites anything.** Incoming files go through `AtomicSaver` and
   `OutputNamingService`, so a name clash makes a new file, never a replacement.
8. **Batch runs one file at a time.** Sequential, cancellable, and reporting progress.
   Running conversions in parallel over a hundred photos would fight the thumbnail
   engine for memory on the low-end devices this app targets.
9. **A batch never stops on one bad file.** It counts the failure and carries on, then
   says at the end what did not work — the same contract as the vault import.

---

## 5. Order of work

1. Rule and documentation changes, and the manifest (the relaxation, done first and
   visibly).
2. `pubspec.yaml` and `flutter pub get`.
3. Models and their tests.
4. Pure services and their tests: batch rules, backup format, serializer, merge,
   address rules, pairing codec, transfer protocol.
5. Kotlin: `BackupChannelHandler`, `DocumentPickerChannelHandler`, `MainActivity` wiring.
6. Dart services over the channels, the DAO additions, and the repository additions.
7. Providers.
8. Widgets and screens, the router, and the selection mode on all four grids.
9. ARB strings for English and Malayalam, then `flutter gen-l10n`.
10. `dart format .`, `flutter analyze` to zero, `flutter test` all green.
11. Update `docs/implementation_progress.md` and write the change log.

---

## 6. Risks

| Risk | Handling |
|---|---|
| The relaxed rule is misread later as "the app may go online." | The new wording names the one allowed use, `LocalAddressRules` enforces it in code, and a unit test fails if a public address is ever accepted. |
| `mobile_scanner` pulls in a Google ML Kit binary. | It is already on the approved list in `docs/dependencies.md`. It is pinned to the bundled scanner so nothing is downloaded at runtime. If it needs Play Services on a target device, the manual six-group pairing code is a complete fallback and the QR scan becomes optional. |
| A half-finished transfer leaves a partial file in the gallery. | Every incoming file is staged app-private and only moved into place by `AtomicSaver` once its length and SHA-256 match the manifest. |
| A wrong backup password looks like a corrupt file. | AES-GCM authentication failure is reported as "wrong password or damaged file", never as a crash. |
| Restore could wipe user data. | Restore only adds and updates. It never deletes a tag, an album or a media row, and the preview sheet shows the counts before anything is written. |

---

## 7. Definition of done

- Selection mode works on the timeline, album, smart album, folder and search grids.
- Every batch action listed in `docs/Project_Idea.md` §2.11 runs, reports progress, and
  can be cancelled.
- A `.gallerybak` can be created, moved to another device, and restored, with tags,
  albums, favourites and notes coming back.
- Two devices on the same Wi-Fi can pair by QR and transfer photos, videos and metadata
  both ways.
- A peer with a public IP address is refused, and there is a test proving it.
- Every new user-visible string is in both `app_en.arb` and `app_ml.arb`.
- `flutter analyze` is clean and `flutter test` passes.
- `docs/implementation_progress.md` shows Phase 11 Completed, and a change log is written.
