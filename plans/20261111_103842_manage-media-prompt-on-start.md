# Ask for "Manage media" when the app starts

**Status:** completed

## Issue

"Manage media" (added in `plans/20261111_101658_fewer-delete-prompts-manage-media.md`) can only be
turned on from Settings → Safety. Most users will never find it, so they keep seeing Android's own
delete prompt.

The owner wants the app to ask for it on first launch, and again on every app start while it is
still off, and to take the user to Android's "Media management apps" page.

## Fix

Each time the app starts (a fresh start, not every return from the background), the home screen
shows a short dialog when **all** of these are true:

- the phone runs Android 12 or newer (`manageMediaSupported`);
- "Manage media" is off (`!manageMediaGranted`);
- photos and videos access is fully granted (`MediaPermissionStatus.granted`). The dialog never
  appears on top of the "Permission required" screen, nor with "selected photos only" access,
  where "Manage media" may have no effect;
- the dialog has not already been shown during this app start.

The dialog:
- Title: "Allow Manage media?"
- Text: explains that Android normally asks before every permanent delete, that with "Manage
  media" on the app asks once itself instead, and that it can be changed later in Settings →
  Safety.
- Buttons: **Not now** (closes it) and **Open settings** (opens Android's "Media management apps"
  page through the existing `openManageMediaSettings`).

When the user comes back from Android settings, the Safety card and the delete rule already read
the new state (from the earlier change).

### Layers
- `lib/providers/media_providers.dart`: `manageMediaPromptProvider`. It holds "already shown
  during this app start" (in memory only, never saved), plus a `shouldPrompt(info, status)` check.
  The rule lives here, not in the widget.
- `lib/widgets/home/manage_media_prompt_dialog.dart` (new): the dialog. It only asks and returns
  the choice.
- `lib/screens/home/home_shell_screen.dart`: after the first frame with full access, reads the
  provider and shows the dialog once.

## Files to change

- `lib/providers/media_providers.dart`
- `lib/widgets/home/manage_media_prompt_dialog.dart` (new)
- `lib/screens/home/home_shell_screen.dart`
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ generated files): new keys
  `titleManageMediaPrompt`, `bodyManageMediaPrompt`, `actionNotNow`. "Open settings" reuses
  `labelOpenSettings`.
- `docs/security.md` §11: the `MANAGE_MEDIA` row's "Requested when" column → "On each app start
  while off (Android 12+, full photo access), and from Settings → Safety".
- Tests: `test/providers/manage_media_prompt_test.dart` (the rule: each condition alone blocks the
  prompt, and it shows only once per start), `test/screens/home/home_shell_manage_media_test.dart`
  (dialog appears; "Open settings" calls the channel; "Not now" closes it and it does not come back
  in the same start).

## Security impact

No new permission, no network, no storage change. The dialog only explains and opens Android's
own settings page; the user still decides there.

## Risks and my view

- Asking on every start while the user keeps saying "Not now" may annoy some users. They might
  have said no on purpose, wanting Android's safety prompt. I suggested asking once plus at
  delete time with "Don't ask again"; the owner chose every start. This is noted, not a blocker.
  If needed later, a "Don't ask again" option is a small follow-up.
- Ignored if the app starts on another screen first (for example, opened from another app to
  view one photo): no home screen, so no dialog. That is on purpose.
