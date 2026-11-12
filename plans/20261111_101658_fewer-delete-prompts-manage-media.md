# Fewer delete prompts, and optional "Manage media" access

**Status:** completed

## Issue

"Delete permanently" from the selection bar or the media viewer asks **three** times on
Android 11 and newer:

1. The delete choice sheet (Move to trash / Delete permanently). This is the real choice.
2. The app's own dialog "Delete permanently?" (`_deletePermanently` in
   `lib/widgets/batch/batch_action_bar.dart`, `confirmViewerDeletePermanently` in
   `lib/widgets/viewer/viewer_dialogs.dart`).
3. Android's own dialog ("Allow Drishya to delete 9 photos?"). Android shows it because of
   `MediaStore.createDeleteRequest` (Android 11+) or `RecoverableSecurityException`
   (Android 10). The app cannot hide it unless it holds "Manage media".

Dialog 2 repeats dialog 3, so it is the extra one. On Android 9 and older Android shows nothing,
so dialog 2 is the only check after the sheet there and must stay.

The owner also wants the optional "Manage media" special access (Android 12+). When the user
turns it on, Android stops showing dialog 3 for deletes. Then dialog 2 must come back, so a
permanent delete never happens on a single tap (hard rule 4).

Checked while planning: the photo editor always saves a **new copy** and never writes over the
original (`lib/services/editor/editor_save_service.dart`), so editing never triggers Android's
dialog today. "Manage media" only affects: Delete permanently, Secure delete, and the vault's
"shred originals". The app does **not** hold "All files access" (`MANAGE_EXTERNAL_STORAGE`), and
this plan does not add it.

## The rule

After the delete choice sheet, there is always **exactly one** more confirmation:

| Android version | "Manage media" | Who asks after the sheet |
|---|---|---|
| 9 and older | — (does not exist) | App dialog |
| 10, 11 | — (does not exist) | Android dialog |
| 12 and newer | Off | Android dialog |
| 12 and newer | On | App dialog |

In code: show the app dialog when `systemConfirmsDelete == false`.
`systemConfirmsDelete` = `SDK >= 29 && !(SDK >= 31 && MediaStore.canManageMedia(context))`.

Safe fallback: if the check fails or is unsure, treat it as `false` and show the app dialog. The
worst case is then one extra dialog, never zero.

Not changed:
- The trash screen. It has no choice sheet, so its own dialog plus Android's is already two
  steps. With "Manage media" on, its own dialog is the one check left. Good either way.
- The vault "shred originals" flow. It already has its own confirmation in the import sheet.
- Secure delete keeps its flow; the same rule decides dialog 2 for it.

## Plan

### Android side
1. `android/app/src/main/AndroidManifest.xml`: add
   `<uses-permission android:name="android.permission.MANAGE_MEDIA" />` with a comment.
   It only has an effect on Android 12+. It is not a runtime prompt; the user turns it on in
   system settings.
2. `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`: two new
   channel methods.
   - `deleteConfirmInfo` → `{ systemConfirmsDelete: Boolean, manageMediaSupported: Boolean,
     manageMediaGranted: Boolean }`.
   - `openManageMediaSettings` → opens `Settings.ACTION_REQUEST_MANAGE_MEDIA` for this app
     (Android 12+). Falls back to the app's settings page if that screen is missing.
   The delete code itself does not change: with "Manage media" on, Android approves
   `createDeleteRequest` / `createWriteRequest` without showing anything.

### Dart side
3. `lib/services/media/media_store_channel.dart`: add `deleteConfirmInfo()` and
   `openManageMediaSettings()` to the interface, the real channel and the fake used in tests.
   New small immutable model `lib/models/media/delete_confirm_info.dart`. Any error → the safe
   fallback above.
4. `lib/providers/media_providers.dart` (or the file that owns the media-store provider):
   `deleteConfirmInfoProvider`, a `FutureProvider` refreshed when the app comes back to the
   front (the user may have just changed the setting).
5. `lib/widgets/batch/batch_action_bar.dart` and `lib/screens/viewer/media_viewer_screen.dart`:
   before showing dialog 2, read the provider. If Android will ask, skip dialog 2 and go straight
   to the delete.
6. `lib/screens/settings/safety_settings_screen.dart`: on Android 12+ only, a new card
   "Delete without Android's prompt" showing On / Off. Tapping it opens the system screen. A
   short note under it says the app will then ask once itself. On older Android the card is
   hidden.
7. `lib/core/constants/app_permissions.dart` and `lib/models/settings/app_permission_info.dart`:
   add the `MANAGE_MEDIA` entry (minApi 31) with a new `AppPermissionKind.special` ("You turn it
   on in system settings"). Update the Permissions screen to show that kind.
8. `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb`: new keys for the card title, its
   subtitle, the On/Off text, the permission row name and reason, and the `special` kind label.
   Real Malayalam and Sanskrit text; the Sanskrit needs the owner's review. Run
   `flutter gen-l10n`.

### Docs
9. `docs/security.md` §11: add the `MANAGE_MEDIA` row; "12" → "13", merged "13" → "14".
10. `CLAUDE.md`, `AGENTS.md`: same count change and a one-line reason.
11. `docs/release_process.md` §6: expected permissions 13 → 14 and the list.
12. `docs/architecture.md`: one line on the delete-confirm rule, if it lists the delete flow.

### Tests
13. `test/widgets/batch/…` and `test/screens/viewer/…`: with `systemConfirmsDelete = true`
    there is no app dialog; with `false` there is.
14. `test/services/media/…`: the fallback when the channel call fails.
15. `test/core/constants/app_permissions_test.dart`: passes with the new manifest entry.
16. `test/screens/settings/…`: the card shows only when supported, and shows On/Off.
17. Run `dart format .`, `flutter analyze`, `flutter test`.

## Files to change

- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- `lib/models/media/delete_confirm_info.dart` (new)
- `lib/services/media/media_store_channel.dart`
- `lib/providers/` media-store provider file
- `lib/widgets/batch/batch_action_bar.dart`
- `lib/screens/viewer/media_viewer_screen.dart`
- `lib/screens/settings/safety_settings_screen.dart`
- `lib/screens/settings/permissions_settings_screen.dart`
- `lib/core/constants/app_permissions.dart`
- `lib/models/settings/app_permission_info.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, `lib/l10n/app_sa.arb` (+ generated files)
- `docs/security.md`, `docs/release_process.md`, `docs/architecture.md`, `CLAUDE.md`, `AGENTS.md`
- Tests listed above

## Security impact

Adds one permission, `MANAGE_MEDIA` (Android 12+). It is off by default and only the user can
turn it on, in system settings. When it is on, Android no longer shows its own prompt before the
app deletes or writes over a photo, so the app's own confirmation becomes the only check. This
plan makes sure that check is always shown in that case. No network, no new package, no change
to storage scope. "All files access" is not added.

## Risks and open points

- Android's docs say "Manage media" only takes effect when the app also has media read access.
  On Android 14 with "selected photos only" it may not apply. The rule uses the live
  `canManageMedia` answer, so the worst case is two prompts, never zero. Needs a check on a real
  Android 12+ phone.
- I believe Google Play needs no declaration form for `MANAGE_MEDIA` (unlike "All files
  access"). Fairly sure, not certain. Check the Play Console warnings on the next upload.
- The existing "Ask one more time before a delete" setting (`confirmDestructive`) is stored but
  not read by any delete flow today. Out of scope here; worth its own small plan.
- Another plan (`plans/20261111_101028_overflow-menu-inside-albums.md`) is `in_progress`. It
  touches different files, so there is no overlap.

## Change during implementation

Android 10 keeps the app's own dialog: it deletes the app's own files with no prompt, so it does
not count as "Android asks". `systemConfirmsDelete` is true only on Android 11+. See
`change_log/20261111_102923_fewer-delete-prompts-manage-media.md`.
