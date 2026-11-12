# Allow re-sending photos the user picked by hand

**Status:** completed

## The issue

On the Transfer (send) screen, the "Selected photos" group is the set of
photos the user picked in the gallery before opening Transfer. Today these go
through the same "already sent" check as folders and albums. If a photo was
sent to this phone before, it is left out. When every picked photo was sent
before, the screen says "Everything you picked is already on the other phone"
and the Send button is disabled.

That check is right for **syncing** a folder or album (send only what is
new). It is wrong for a **manual share**: the user picked these photos on
purpose and wants them sent, even if they went before (for example, the other
phone deleted them).

## What should happen

The rule depends on **why the transfer was opened** (`TransferPurpose`):

- **Manual send** (`TransferPurpose.quickSend` — the user selected photos and
  tapped "Send to device"): every picked file is sent, even if it was sent
  to this phone before. A warning note says how many were sent before.
- **Device Sync** (`TransferPurpose.phoneMove` — Settings › Device Sync):
  unchanged. Files already sent are skipped. This matters when a send is
  retried after a Wi-Fi drop: only the files that did not arrive go again,
  with no duplicates.
- In both cases, after one send the picker comes back with the same ticks
  for "Send the rest". In a manual send, a file sent **in this session** must
  not be offered again, or "Send the rest" would re-send the same files
  forever.

(Plan revised after feedback: the first version decided by group kind —
"Selected photos" vs folders/albums. Deciding by purpose says what we mean
and stays right if a manual send ever offers folders.)

## Not changed (on purpose)

The receiving phone still skips a file whose exact content it already has
in its gallery (`alreadyHave`, checked by SHA-256). That check protects
against true duplicates on the other phone. If the other phone deleted the
photo, the check passes and the photo is received. So "send again" works
exactly in the case the user cares about. The result card shows such a file
as "skipped".

## Plan for the fix

1. `lib/core/domain/sync/sync_selection_rules.dart`
   - `plan(...)` gets two new optional arguments: `bool allowResend`
     (default `false`) and `Set<String> sentThisSession` (default empty).
   - When `allowResend` is true: every picked file is a candidate unless its
     id is in `sentThisSession`. Files whose mark says "sent before" are
     counted in a new `resendCount`. `alreadySentCount` stays 0.
   - When `allowResend` is false: unchanged (`splitBySent`).
2. `lib/models/sync/send_plan.dart` — add `final int resendCount` (default 0),
   include it in `==` and `hashCode`.
3. `lib/core/domain/sync/send_limit_rules.dart` — pass `resendCount` through
   to `SendPlan`, the same way `alreadySentCount` is passed.
4. `lib/widgets/sync/send_picker_view.dart`
   - Read `transferPurposeProvider`; pass
     `allowResend: purpose == TransferPurpose.quickSend`.
   - Keep a `Set<String> _sentThisSession`. In `onSend`, add the plan's item
     ids before calling `widget.onSend(plan)`. Pass it to the rules.
   - In `_PlanBar`, when `plan.resendCount > 0`, show a muted note:
     "Sent to this phone before: N files. Sending again."
5. ARB files — one new key `bodySyncPlanResend` (plural), with a real
   translation in all three files and an `@` description in `app_en.arb`:
   - `lib/l10n/app_en.arb`
   - `lib/l10n/app_ml.arb`
   - `lib/l10n/app_sa.arb` (new Sanskrit text — needs the owner's review)
   - then `flutter gen-l10n` (updates `lib/l10n/generated/*`).
6. Tests — new `test/core/domain/sync/sync_selection_rules_test.dart`:
   - manual send: a file sent before is still in `toSend`, `resendCount` is 1;
   - Device Sync: a file sent before is skipped, `alreadySentCount` is 1;
   - a file in two ticked groups is sent once;
   - manual send: a file in `sentThisSession` is not offered again.
7. Run `dart format .`, `flutter analyze`, `flutter test`.
8. Write the change log.

## Files to change

(Steps 2 and 3 were already applied before the plan was revised; they are
needed by both versions.)

- `lib/core/domain/sync/sync_selection_rules.dart`
- `lib/core/domain/sync/send_limit_rules.dart`
- `lib/models/sync/send_plan.dart`
- `lib/widgets/sync/send_picker_view.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, `lib/l10n/app_sa.arb`
- `lib/l10n/generated/*` (generated, by `flutter gen-l10n`)
- `test/core/domain/sync/sync_selection_rules_test.dart` (new)

## Security impact

None. Same local transfer path, same peer, same checks. Only which already
picked files go into the send list changes.

## Side note seen in the screenshot

The screenshot shows "1 files". The current `app_en.arb` already has a
`=1` plural case, so the phone is probably running an older build. Nothing to
change for that here.
