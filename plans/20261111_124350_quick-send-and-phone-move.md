# Quick "Send to device" and "Move to a new phone" over Wi-Fi

**Status:** completed

Follows `plans/20261111_110538_device-sync.md`, which built the Wi-Fi transfer.

## 1. The issue

The owner reported two problems.

### 1.1 "Send to device" from a selection opens the wrong screen

When the user selects photos and taps **Send to device**:

- The app opens the general **Transfer** screen (`/sync`). It shows Send, Receive and
  "Scan a code". **Receive makes no sense** here: the user came to send.
- **The selection is lost.** `lib/widgets/batch/batch_action_bar.dart` clears the selection
  *before* it opens the screen. If the user goes back, nothing is selected any more.
- Found while planning: `transferOutboxProvider` is never emptied. If the user opens Transfer
  later from the home menu, it can still show "1 file offered" from an old selection.
- After pairing, the picker lists **every folder and album** too, with the selection ticked.
  For a quick send, the user only wants the selected photos.

### 1.2 Settings › Device Sync › "Send photos by Wi-Fi" is not a phone move

The owner wants this entry for **moving to a new phone**: the chosen folders and albums,
**plus the whole app data**. Today:

- Each sent file carries its own data (tags, album names, notes, favourite, place, folder).
- **Not sent:** app data not tied to a sent file. For example empty albums, and tags or notes
  on photos the user did not pick. Only the QR way sends the whole app data today.
- **Not sent:** settings.
- **Not sent:** the private vault.
- The label "Send photos by Wi-Fi" and the shared Send/Receive screen hide what it is for.

### 1.3 The owner's decisions

- Wi-Fi phone move sends **the whole app data** with the chosen folders and albums.
- **Settings are always sent.**
- **The vault is sent only if the user chooses it.**

## 2. The plan

The work has three parts. Each part can be built, tested and logged on its own.
**I suggest doing them in order A → B → C**, and checking each on two phones before the next.

### Part A: quick send from a selection

1. A new value `TransferPurpose { quickSend, phoneMove }` in `lib/models/sync/`, held in a
   provider in `lib/providers/sync_providers.dart`. It tells the shared transfer screens why
   they were opened.
2. A new screen `lib/screens/sync/quick_send_screen.dart` (route `/sync/quick-send`):
   - Heading: "Send N photos" (count from the outbox).
   - Two choices only: **"Show a code"** and **"Scan the other phone's code"**. Either phone
     may show the code; this phone is always the sender. No Receive card.
3. `batch_action_bar.dart`: fill the outbox, set purpose `quickSend`, open the new screen.
   **Do not clear the selection.** The selection is cleared only after a send finishes
   without error. Going back keeps it.
4. The outbox is emptied when the quick-send screen is left (`dispose`), so an old selection
   can never show up in a later transfer.
5. Picker (`lib/widgets/sync/send_picker_view.dart`, `sync_source_service.dart`): in
   `quickSend` the sources are **the selection only**. No folder or album list.
6. The general Transfer screen (`sync_home_screen.dart`, opened from the home menu) becomes
   the **receive** side: "Show a code" and "Scan the sender's code", plus one line: "To send,
   select photos and tap Send to device." Its Send card is removed.

### Part B: "Move to a new phone" with the whole app data and settings

1. Device Sync screen (`device_sync_screen.dart`) cards are renamed:
   - Wi-Fi send: **"Move to a new phone"** — "Folders and albums you pick, with all app
     data and settings. Both phones on the same Wi-Fi."
   - Wi-Fi receive: **"Get from your old phone"**.
   - The QR cards stay as they are.
   Both Wi-Fi cards set purpose `phoneMove`.
2. Picker in `phoneMove`: folders and albums (as today), and two fixed rows at the top:
   - **App data** (tags, albums, favourites, notes, places) — always on, shown for clarity.
   - **Settings** — always on.
3. **When the app data travels:** once, when the sender taps **Finish**, after the last
   batch of files. That way the receiver can match the data to all the files it just got
   (by fingerprint, as backup restore does). "Send the rest" batches before that are
   unchanged.
4. Protocol (`transfer_protocol.dart`): new frame kinds **at the end** of `FrameType`, so old
   numbers stay valid:
   - `appData(15)` — the same payload the QR way builds
     (`BackupCollectorService.collectFingerprinted`), gzip-compressed, sent in chunks over the
     already-encrypted link, with a size limit in `AppConstants`.
   - `appDataAck(16)`.
   The transfer protocol version goes up by one. An older build on the other phone is refused
   with a clear "Update the app on both phones" message, not a broken transfer.
5. Settings travel inside the app-data payload as a separate, optional `settings` section:
   theme, language, grid columns, flashbacks, "confirm before destructive actions",
   "protect all screens", secure delete. **Not sent:** vault PIN and biometric setup, Android
   permissions (for example "Manage media"), this install's id, and the "sent to that phone"
   marks. Those belong to one phone.
6. Receiver: when the app data arrives, it opens the **existing restore preview**
   (`RestoreService.openPayload` → preview → `applyPlan`). It is merge-only, as today. Settings
   show as one extra line in the preview ("Use the old phone's settings"), ticked by default.
   Settings replace the receiver's own, so the user must see and accept them first.
   Nothing is written before the user says yes.
7. If the link breaks before Finish, files already received stay. The screen says the app
   data was not sent, and the user can run the move again (sent files are skipped by the
   existing "sent" marks).

### Part C: the vault, only if the user chooses it

1. Picker in `phoneMove`: one more row, **"Private vault (N items)"**, **off by default**.
   Turning it on asks for the vault unlock (PIN or biometric) on the sending phone first.
2. Receiving phone: before the send starts, the receiver tells the sender whether its own
   vault is set up. If it is not, the receiver is asked to set it up first, or the vault part
   is skipped with a clear message. Vault files are **never** put in the public gallery.
3. Sending one vault item: decrypt into a working file inside the app's private vault folder
   (`VaultCryptoService.decryptToWorkingFile`), send it over the encrypted link, then shred
   the working file at once, also on error or cancel.
4. Receiving one vault item: write it to a private staging file (not MediaStore, not public
   cache), encrypt it into the receiver's vault with the receiver's own keystore key
   (`encryptToPayload`), add the vault row, then shred the staging file. Tags and notes come
   with it. A new vault-receive method goes in `lib/services/vault/` for this, following the
   same "write first, record last, clean up on failure" order as `VaultImportService`.
5. Manifest entries get a `vault: true` flag (a new optional field; old builds are already
   refused by the version bump).
6. Nothing in the sender's vault is removed. The vault is copied, not moved.

## 3. Files to change

**Part A**
- `lib/models/sync/transfer_purpose.dart` (new)
- `lib/providers/sync_providers.dart`
- `lib/screens/sync/quick_send_screen.dart` (new)
- `lib/screens/sync/sync_home_screen.dart`
- `lib/screens/sync/sync_receive_screen.dart`, `sync_send_screen.dart` (read the purpose)
- `lib/widgets/batch/batch_action_bar.dart`
- `lib/widgets/sync/send_picker_view.dart`
- `lib/services/sync/sync_source_service.dart`
- `lib/core/routing/app_router.dart`

**Part B**
- `lib/screens/sync/device_sync_screen.dart`
- `lib/services/sync/transfer_protocol.dart`
- `lib/services/sync/transfer_session_service.dart`, `transfer_exchange_service.dart`
- `lib/models/sync/transfer_session_state.dart`, `sync_role.dart` (new phase for app data)
- `lib/services/backup/backup_collector_service.dart`, `backup_serializer.dart`,
  `restore_service.dart` (optional settings section)
- `lib/services/settings/app_settings_service.dart` (apply received settings)
- `lib/widgets/sync/transfer_session_body.dart`, restore preview widget
- `lib/core/constants/app_constants.dart` (size limit, protocol version)

**Part C**
- `lib/services/vault/vault_receive_service.dart` (new)
- `lib/services/vault/vault_crypto_service.dart` (if a small helper is needed)
- `lib/models/sync/transfer_manifest.dart` (`vault` flag)
- `lib/services/sync/received_media_service.dart` (route vault entries away from MediaStore)
- `lib/providers/vault_providers.dart`, `sync_providers.dart`

**All parts**
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` and generated files (`flutter gen-l10n`)
- `docs/architecture.md`, `docs/security.md`, `docs/known_gaps.md` if needed
- Tests (see §5)

## 4. Security impact

- **No new permission, no new package, no new network reach.** Same local-only sockets,
  same `LocalAddressRules`, same screen-lifetime rule.
- **App data and settings** travel only over the already-encrypted, paired link. Same data the
  QR way already sends, plus non-secret preferences.
- **Vault (Part C) is the real risk.** Vault content leaves the phone for the first time.
  Safeguards: off by default; sender must unlock first; plaintext exists only in app-private
  working files that are shredded right after; it never touches MediaStore or public storage;
  the receiver re-encrypts with its own keystore key. `docs/security.md` gets a new section
  for this. Never logged.

## 5. Tests

- `test/services/sync/sync_source_service_test.dart`: quick send lists the selection only.
- Outbox is emptied when the quick-send screen goes; selection kept on back.
- `test/services/sync/transfer_protocol_test.dart`: new frame kinds round-trip; old numbers
  unchanged; version mismatch refused.
- App data payload with and without `settings`; restore applies settings only when ticked.
- Settings section never holds vault or device-only fields.
- Vault receive: a fake channel proves nothing goes to MediaStore, and staging files are
  shredded on success, failure and cancel.
- `test/l10n/` passes (keys in all three languages, no Hindi markers).

## 6. Honest notes

- Part C is the biggest and riskiest part. If time is short, A and B alone already fix both
  reported problems.
- New Sanskrit text needs the owner's review, as before.
- A phone move with many photos still needs several batches because of the size limit.
  That is unchanged and is on purpose.
