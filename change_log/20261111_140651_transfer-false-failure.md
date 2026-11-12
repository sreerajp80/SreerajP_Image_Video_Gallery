# Change log: receiving phone no longer shows a false failure after a send

Implements plan: `plans/20261111_133724_transfer-false-failure.md`

## What was wrong

After a successful send, the receiving phone showed "The transfer could not be finished".
The sender ends every send with a `complete` message. The receiver stopped reading as soon
as the last wanted file arrived, so `complete` stayed unread. The session loop then read it
as the start of the next send and ended the session with `TransferFailure.unknown`.

## What changed

- `lib/services/sync/transfer_exchange_service.dart`
  - `receiveOffer` now remembers whether it saw `complete`. If its loop stopped because
    all files arrived (or nothing was wanted), it reads the `complete` message before
    returning. A `cancel` in that place still ends the send as cancelled.
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (and the generated files, made by
  `flutter gen-l10n`)
  - `bodySyncPlanAlreadySent` is now a plural, so it says "1 file", not "1 files".
  - `bodySyncAllSent` now says "All sent. Pick more to send, or tap Finish." (and the same
    in Malayalam and Sanskrit).
  - **The new Sanskrit text needs the owner's review.**
- `test/services/sync/p2p_socket_test.dart`
  - Two new tests send twice over one pairing: once with two new files, once where the
    first file is already on the receiver. Both check that nothing is left unread.
  - Small change from the plan: these went into the existing socket test file, not a new
    `transfer_exchange_service_test.dart`. That file already has the fake cipher and the
    real-socket pairing setup the tests need.

## Checks

- With the fix turned off, both new tests fail with "Expected a manifest frame and got a
  complete one", the same error seen on the phone. With the fix, they pass.
- `dart format` clean, `flutter analyze` no issues, `flutter test` all 2425 tests pass.
- Not yet checked on two real phones.

## Security impact

None. The message format and the checks on received files are unchanged.
