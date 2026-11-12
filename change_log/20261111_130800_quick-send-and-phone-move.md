# Quick "Send to device" and "Move to a new phone" over Wi-Fi

Implements [plans/20261111_124350_quick-send-and-phone-move.md](../plans/20261111_124350_quick-send-and-phone-move.md)
(all three parts, A to C, approved together).

## Part A: quick send from a selection

- New `TransferPurpose` (`quickSend`, `phoneMove`) in `lib/models/sync/transfer_purpose.dart`,
  held in `transferPurposeProvider`.
- New `SendStartScreen` (`/sync/start-send`): "Show a code" or "Scan their code". This phone
  always sends. No Receive card.
- `batch_action_bar.dart`: "Send to a device" opens the new screen and **no longer clears the
  selection**. The selection is cleared in `listenToTransfer` only after a quick send delivered
  files.
- The outbox is emptied when the send start screen closes, so an old selection never shows up
  in a later transfer.
- `SyncSourceService.load(selectionOnly:)`: a quick send offers the selection only.
- `SyncHomeScreen` (home menu, now "Receive from device") is the receive side only: "Show a
  code" or "Scan their code", plus a hint on where sending starts. Its shared parts became
  public widgets (`SyncPrivacyCard`, `SyncNoNetwork`, `SyncChoiceCard`).

## Part B: Move to a new phone, with app data and settings

- Device Sync cards renamed: "Move to a new phone" and "Get from old phone".
- Transfer protocol version 2 → **3**. New frames at the end: `appDataStart(15)`,
  `appDataChunk(16)`, `appDataAck(17)`.
- New `PhoneMoveDataService`: packs the backup payload plus `AppSettings` into one gzip
  envelope; reads it back with size, digest, format and inflate-size checks.
- `TransferSessionService.finish(withAppData:, withVault:)` sends the vault (Part C) and then
  the app data, after the last batch. A failure there ends as the new
  `TransferFailure.appDataFailed`; files already sent stay.
- The receiver holds the data in `TransferSessionState.receivedAppData`. New `AppDataReview`
  widget opens the normal restore preview once by itself, applies on yes, then asks
  separately before taking the settings (`AppSettingsNotifier.applyAll`).
- New `SyncPhase.appData` for the progress screen.
- The picker shows an "App data & settings" row in a phone move.

## Part C: the vault, only if chosen

- New `VaultTransferService` (`lib/services/vault/`): decrypt one item into a working file and
  shred it after sending; on the receiver, encrypt into this phone's vault, add the row last,
  and shred the staged copy on every path.
- `TransferEntry.vault` flag; `PeerInfo.vaultReady` from the receiver.
- `ReceivedMediaService`: vault entries go to the vault, never to MediaStore; refused if there
  is no vault; never skipped as "already have it".
- `TransferExchangeService.send(afterFile:)` so the working copy is shredded right after each
  file, sent or not.
- Send start screen (phone move only): "Private vault" switch, off by default. Turning it on
  needs the vault unlocked; if it is locked, the vault gate opens first.

## Strings

30 new keys in English, Malayalam and Sanskrit. Changed: `titleSyncOpen`, `bodySyncIntro`,
`bodySyncReceive`, `labelDeviceSyncWifiSend`, `bodyDeviceSyncWifiSend`,
`labelDeviceSyncWifiReceive`. Removed (no longer used): `bodySyncSend`,
`bodySyncSendPickLater`, `bodySyncOfferHeading`.

**The new and changed Sanskrit text needs the owner's review**, as CLAUDE.md asks.

## Docs

- `docs/architecture.md`: route tree, the two ways to start a send, the phone move on Finish.
- `docs/security.md`: `vaultReady` in §19.6, protocol 3, and new §19.6.1 on app data,
  settings and the vault.

## Tests

- New: `test/services/sync/phone_move_data_service_test.dart`,
  `test/services/sync/received_media_service_test.dart`,
  `test/services/sync/sync_source_service_test.dart`,
  `test/services/vault/vault_transfer_service_test.dart`.
- Updated: `test/services/sync/transfer_protocol_test.dart` (fixed wire numbers),
  `test/services/sync/p2p_socket_test.dart` (new `alreadyHave` signature).
- `dart format` clean, `flutter analyze` no issues, `flutter test` all 2423 pass.

## Differences from the plan

- Settings: the plan said "one extra ticked line in the restore preview". It is a separate
  question after the preview instead ("Use old settings?" — Keep mine / Use theirs). Same
  effect, and the shared preview sheet did not need to change.
- The vault goes on Finish (before the app data), not as a tickable source in the picker. This
  keeps the 5 GB send rules for gallery files unchanged.
- An older build is not told "update the app" by name. A pairing code from another version is
  simply not recognised; a typed one is refused with the existing "different version" message.

## Not verified

- Not run on two real phones. The full Wi-Fi flow (quick send, phone move with app data,
  settings and vault) still needs a check on devices.
- No end-to-end socket test of the new app-data frames. The parts are tested on their own.
