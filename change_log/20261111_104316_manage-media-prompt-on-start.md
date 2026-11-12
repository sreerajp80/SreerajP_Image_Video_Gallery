# Ask for "Manage media" when the app starts

Implements `plans/20261111_103842_manage-media-prompt-on-start.md`.

## What changed

On each fresh app start, the home screen now asks the user to turn on "Manage media" when all of
these are true: Android 12+, "Manage media" is off, full photos and videos access is given, and it
has not been asked yet during this start. The dialog has **Not now** and **Open settings**; the
second opens Android's "Media management apps" page.

- `lib/providers/media_providers.dart`: `shouldPromptManageMedia(...)` (the rule) and
  `ManageMediaPromptController` / `manageMediaPromptProvider` (in memory "already asked during
  this start"; reads the state fresh; any error means "do not ask").
- `lib/widgets/home/manage_media_prompt_dialog.dart` (new): the dialog. It only asks.
- `lib/screens/home/home_shell_screen.dart`: after the first frame with photo access, asks the
  provider and shows the dialog. "Open settings" calls `openManageMediaSettings`.
- ARB files (`en`, `ml`, `sa`): new keys `titleManageMediaPrompt`, `bodyManageMediaPrompt`,
  `actionNotNow`. "Open settings" reuses `labelOpenSettings`. Generated files rebuilt.
- `docs/security.md` §11: `MANAGE_MEDIA` row, "Requested when" column.

## Tests

- New `test/providers/manage_media_prompt_test.dart`: the rule (each condition alone blocks it),
  once per start, not when already on, and a fresh start asks again.
- New `test/widgets/home/manage_media_prompt_dialog_test.dart`: both buttons, and the dialog in
  Malayalam and Sanskrit shows no English.
- New `test/screens/home/home_shell_manage_media_test.dart`: no dialog over the "Permission
  required" screen.

`dart format`, `flutter analyze` (no issues) and `flutter test` (2,358 passed) were run.

## Not done / not checked

- No widget test of the home screen with full access showing the dialog: the three tabs need many
  more fakes. The rule and the dialog are tested on their own.
- Not run on a real phone.
- New Malayalam and Sanskrit text needs the owner's review. `ഇപ്പോൾ വേണ്ട` and `इदानीं न`
  ("Not now") are new terms — **needs native-reader review**.

## Security impact

No new permission, no network, no storage change. The dialog only explains and opens Android's own
settings page; the user decides there.
