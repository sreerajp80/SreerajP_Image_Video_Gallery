# Fix: receiving phone shows "could not be finished" after a good send

**Status:** completed

## The issue

1. **False failure on the receiving phone (main bug).**
   After one send, the sending phone shows "This send is done, 1 file sent", but the
   receiving phone shows the error icon and "The transfer could not be finished", with
   "1 file received" under it. The file did arrive safely.

   Cause: when the sender has sent its last file, it sends one more message, `complete`
   (`TransferExchangeService.send`). On the receiving side, `receiveOffer` loops
   `while (expected.isNotEmpty)`. After the last file arrives, `expected` is empty, so the
   loop stops **before** reading `complete`. That message stays waiting on the connection.
   `_receiveLoop` in `TransferSessionService` then reads it as the start of the next send.
   It is not a `manifest`, so the loop throws `TransferFailure.unknown`
   ("Expected a send and got a complete frame"), and the session ends as failed.
   The same happens when every offered file is already on the receiving phone (nothing
   wanted, so the loop never runs).
   No test runs a full send from end to end, so this was not caught.

2. **Confusing text on the sending phone.**
   - `bodySyncPlanAlreadySent` says "Already on the other phone: 1 files". It has no
     plural form, so it reads "1 files".
   - `bodySyncAllSent` says "Everything you picked is already on the other phone." Right
     after a send this sounds like nothing was sent.

## Files to change

- `lib/services/sync/transfer_exchange_service.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, `lib/l10n/app_sa.arb`
- `lib/l10n/generated/*` (made again by `flutter gen-l10n`, not edited by hand)
- `test/services/sync/transfer_exchange_service_test.dart` (new)

## The fix

### 1. Read the `complete` message where it belongs

In `receiveOffer`, remember whether the loop already saw `complete` (or `cancel`).
If it did not, read one more message after the loop and require it to be `complete`
(using the existing `_expect`, which also turns a `cancel` into a cancelled result).
This keeps the rule "one send = manifest … complete" inside the exchange service, so
`_receiveLoop` only ever sees the start of the next send, `bye`, or `cancel`.

Why here and not "just ignore `complete` in `_receiveLoop`": ignoring it would hide the
bug instead of fixing the message order, and a stray message in the wrong place should
still be treated as an error.

### 2. Clearer sender text (all three languages)

- `bodySyncPlanAlreadySent` becomes a plural:
  - en: `{count, plural, =1{Already on the other phone: 1 file} other{Already on the other phone: {count} files}}`
  - ml: `=1{മറ്റേ ഫോണിൽ ഇതിനകം ഉള്ളത്: 1 ഫയൽ}` / `other{… {count} ഫയലുകൾ}`
  - sa: `=1{अन्यस्मिन् यन्त्रे पूर्वमेव: 1 सञ्चिका}` / `other{… {count} सञ्चिकाः}`
- `bodySyncAllSent`:
  - en: "All sent. Pick more to send, or tap Finish."
  - ml: "എല്ലാം അയച്ചു. കൂടുതൽ അയയ്ക്കാൻ തിരഞ്ഞെടുക്കുക, അല്ലെങ്കിൽ പൂർത്തിയാക്കുക അമർത്തുക."
  - sa: "सर्वं प्रेषितम्। अधिकं प्रेषयितुं चीयताम्, अथवा समाप्यताम् इति स्पृश्यताम्।"
  - **The new Sanskrit text needs the owner's review.**
- Run `flutter gen-l10n`.

### 3. Test

New `test/services/sync/transfer_exchange_service_test.dart`: two connections joined
in memory (the same kind of fake socket pair `p2p_socket_test.dart` uses, if it fits).
Sender sends one small file, then a second send over the same connection. Check that the
receiver gets both and that the frame after a send is the next `manifest`, not `complete`.
Also one case where the receiver already has the file (nothing wanted).

### 4. Checks

`dart format .`, `flutter analyze`, `flutter test`. Then try a real send between two phones.

## Security impact

None. The message format and the checks on received files do not change. The receiver
only reads one extra message that the sender already sends today. No new permission,
socket, or dependency.
