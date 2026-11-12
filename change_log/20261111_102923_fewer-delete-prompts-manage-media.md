# Fewer delete prompts, and optional "Manage media" access

Implements `plans/20261111_101658_fewer-delete-prompts-manage-media.md`.

## What changed

"Delete permanently" from the selection bar or the media viewer asked three times on Android 11+:
the choice sheet, the app's own "Delete permanently?" dialog, and Android's own prompt. Now, after
the choice sheet, the user is asked **once**: by Android when Android will ask, otherwise by the
app.

| Android | "Manage media" | Who asks after the sheet |
|---|---|---|
| 10 and older | — | the app |
| 11 | — | Android |
| 12+ | off | Android |
| 12+ | on | the app |

If the answer is unknown (channel error, bad reply), the app asks. Worst case is one extra dialog,
never none.

### Android
- `android/app/src/main/AndroidManifest.xml`: declares `MANAGE_MEDIA`, with a comment. It does
  nothing until the user turns it on in Android settings.
- `MediaStoreChannelHandler.kt`: two new channel methods.
  - `deleteConfirmInfo` → `systemConfirmsDelete`, `manageMediaSupported`, `manageMediaGranted`.
  - `openManageMediaSettings` → opens `Settings.ACTION_REQUEST_MANAGE_MEDIA`, or the app's settings
    page if that is missing.
  The delete code is unchanged. With "Manage media" on, Android approves the delete request with
  no prompt.

### Dart
- New model `lib/models/media/delete_confirm_info.dart` (immutable, `copyWith`, safe `fallback`).
- `lib/services/media/media_store_channel.dart`: `deleteConfirmInfo()` (never throws) and
  `openManageMediaSettings()`.
- `lib/providers/media_providers.dart`: `deleteConfirmInfoProvider`.
- `lib/widgets/common/delete_choice_sheet.dart`: `appMustConfirmPermanentDelete(ref)`, read fresh
  before each delete.
- `lib/widgets/batch/batch_action_bar.dart` and `lib/screens/viewer/media_viewer_screen.dart`: show
  the app dialog only when that helper says so.
- `lib/screens/settings/safety_settings_screen.dart`: new "Manage media" card (Android 12+ only),
  with an Allowed / Not allowed label. Tapping it opens Android's page. The state is read again
  when the app comes back to the front.
- `lib/models/settings/app_permission_info.dart`: new kind `special` and id `manageMedia`.
- `lib/core/constants/app_permissions.dart` and `permissions_settings_screen.dart`: new section
  "You turn these on" with the "Manage media" row and its live state.
- ARB files (`en`, `ml`, `sa`): 5 new keys — `labelPermissionsSpecial`,
  `descPermissionsSpecial`, `labelPermManageMedia`, `descPermManageMedia`,
  `descManageMediaSubtitle`. Generated files rebuilt with `flutter gen-l10n`.

### Docs
- `docs/security.md` §11: new `MANAGE_MEDIA` row; counts 12 → 13 (merged 13 → 14).
- `docs/release_process.md` §6: expected permissions 13 → 14 and the list.
- `docs/architecture.md`: `mediastore` channel row.
- `CLAUDE.md`, `AGENTS.md`: permission count and reason.

### Tests
- New `test/models/media/delete_confirm_info_test.dart`.
- `test/widgets/batch/batch_action_bar_test.dart`: no app dialog when Android will ask; app
  dialog (and Cancel deletes nothing) when it will not.
- `test/screens/settings/settings_screen_test.dart`: card hidden before Android 12; shows state
  and opens Android's page; Permissions screen shows the new section.
- `test/core/constants/app_permissions_test.dart`: counts the `special` kind.
- `test/services/media/fake_media_store_channel.dart`: fake for the two new methods.

`dart format`, `flutter analyze` (no issues) and `flutter test` (2,348 passed) were run.

## Change from the plan

- **Android 10 keeps the app dialog.** The plan said Android 10 asks by itself. While building
  it, the code showed that Android 10 asks only for photos the app did not create, and deletes the
  app's own files (such as edited copies) with no prompt. So `systemConfirmsDelete` is true only on
  Android 11+.
- No separate viewer widget test. The viewer and the selection bar use the same helper, which is
  covered by the batch bar tests.

## Not done / not checked

- Not run on a real phone. Please check on Android 12+: turn "Manage media" on, then delete, and
  confirm that only the app's dialog appears. Also check Android 14 with "selected photos only".
- Not built for release. Android lint might warn about `MANAGE_MEDIA`; the next build will show it.
- New Malayalam and Sanskrit text needs the owner's review. New terms:
  `മീഡിയ നിയന്ത്രണം` and `माध्यमप्रबन्धनम्` ("Manage media"), and `भवता सक्रियीकृताः` ("You turn
  these on") — **needs native-reader review**.
- Known edge: on Android 11+, if `createDeleteRequest` itself throws, the Kotlin code falls back
  to a direct delete with no prompt. Before this change the app dialog still came first; now it
  does not when Android was expected to ask. This is rare (bad URIs), but worth its own small fix.
- The "Ask before deleting" setting (`confirmDestructive`) is still not read by any delete flow.

## Security impact

Adds `MANAGE_MEDIA` (Android 12+). Off by default; only the user can turn it on. When on, the app's
own confirmation is always shown before a permanent delete. No network, no new package, no change
to storage scope. "All files access" is not added.
