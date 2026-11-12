# Allow re-sending files in a manual send

Implements plan: `plans/20261111_141544_resend_selected_photos.md`

## What changed

A manual send (select photos, then "Send to device") now sends every picked
file, even one already sent to the same phone. A warning line says how many
were sent before. Device Sync is unchanged: files already sent are skipped,
so a retry after a Wi-Fi drop sends only what is missing.

- `lib/core/domain/sync/sync_selection_rules.dart` — `plan()` takes
  `allowResend` and `sentThisSession`. With `allowResend`, files sent before
  stay in the send and are counted in `resendCount`; files already sent in
  this session are not offered again, so "Send the rest" does not repeat them.
- `lib/models/sync/send_plan.dart` — new `resendCount` field (in `==` and
  `hashCode`).
- `lib/core/domain/sync/send_limit_rules.dart` — passes `resendCount` through.
- `lib/widgets/sync/send_picker_view.dart` — sets `allowResend` from
  `transferPurposeProvider` (`quickSend` only), remembers the ids sent in this
  session, and shows the new warning. After a send, an empty plan now shows
  "All sent" in a manual send too (it was keyed only on `alreadySentCount`,
  which is 0 in a manual send).
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` — new key
  `bodySyncPlanResend`; generated files updated with `flutter gen-l10n`.
- `test/core/domain/sync/send_limit_rules_test.dart` — new group with four
  tests (resend in a manual send, skip in Device Sync, a file in two groups
  sent once, no repeat within a session). Added here, not in a new file,
  because this file already holds the `SyncSelectionRules` tests.

## Not changed

The receiving phone still skips a file whose exact content (SHA-256) is
already in its gallery. If the other phone deleted the photo, it is received.

## Checks

- `flutter analyze`: no issues.
- `flutter test`: all tests pass.
- Not yet tried on a phone.

## Needs review

The new Sanskrit text in `app_sa.arb` (`bodySyncPlanResend`) needs the
owner's review, as for all new Sanskrit.
