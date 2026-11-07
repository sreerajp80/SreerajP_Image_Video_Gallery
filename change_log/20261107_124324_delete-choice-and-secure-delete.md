# Change log — Delete choice (trash or permanent) and secure delete

Implements: `plans/20261107_122146_delete-choice-and-secure-delete.md`

## What changed for the user

- **One Delete button** in the viewer (bottom bar and menu) and in the selection bar. It opens a
  sheet: **Move to trash** (first, safe) or **Delete permanently** (red). Picking "Move to trash"
  no longer asks a second time; the snackbar still offers Undo. "Delete permanently" still asks
  for confirmation.
- **Settings → Safety → Secure delete** (off by default). When on, permanent deletes from the
  gallery and every delete from the trash write over each file before removing it. A note under
  the switch says vault deletes are always secure.
- The snackbar after a permanent delete says what really happened: how many were deleted, how many
  were securely deleted, how many could not be written over first, and how many could not be
  deleted.
- **Vault:** no behaviour change. Deleting from the vault was already a shred every time; a test
  now locks that in.
- **Bug fix:** the vault import's "shred the original" now works on Android 11+. It used to open
  the public file by its path, which Android 11+ refuses for a file the app did not create, so the
  original stayed. It now goes through MediaStore, in one call for the whole set.
- **Bug fix:** on Android 9 and older, "Delete permanently" used to report success even when
  nothing was deleted. It now reports the real result, and the app holds the write permission it
  needs there.

## Security impact

- Declares `WRITE_EXTERNAL_STORAGE` with `maxSdkVersion="28"` (was removed). Declared permissions
  11 → 12, merged 12 → 13. Android 10+ never sees it.
- New native method `secureDeleteMedia`. It writes only to the content URIs the user just chose to
  delete, and only after Android's write prompt (Android 10+). If the user refuses, nothing is
  touched.
- No network, no new package.

## Files

Native

- `android/app/src/main/AndroidManifest.xml` — `WRITE_EXTERNAL_STORAGE` up to API 28.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/SecureOverwrite.kt` — new; the shared
  overwrite loop (file or file descriptor).
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt` —
  `secureDeleteMedia` (Android 11+ write request, Android 10 per-file prompt, Android 9 and older
  with the write permission); honest result for the old delete on Android 9 and older; write
  permission requested with the read permission on Android 9 and older.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/vault/VaultChannelHandler.kt` — uses the
  shared overwrite loop.

Dart

- `lib/models/media/media_delete_result.dart` — new result model and per-file outcome.
- `lib/services/media/media_store_channel.dart` — `secureDeleteMedia`.
- `lib/repositories/media_repository.dart` — `deletePermanently(items, secure:)` returns a
  `MediaDeleteResult`; only rows whose file is gone leave the database.
- `lib/models/settings/app_settings.dart`, `lib/providers/settings_providers.dart` —
  `secureDelete` setting.
- `lib/providers/trash_providers.dart` — reads the setting; `emptyTrash`, `deletePermanently` and
  new `deleteItems` return a `MediaDeleteResult`.
- `lib/providers/viewer_providers.dart` — `deletePermanently` for the viewer.
- `lib/services/vault/vault_import_service.dart`, `lib/providers/vault_providers.dart` — shred
  originals through MediaStore, in one call after all imports.
- `lib/core/constants/app_constants.dart` — `secureDeletePasses`.
- `lib/core/constants/app_permissions.dart` — `WRITE_EXTERNAL_STORAGE` moved from "removed" to
  "you allow these", up to API 28.
- `lib/widgets/common/delete_choice_sheet.dart` — new choice sheet and result message.
- `lib/widgets/viewer/viewer_app_bar.dart`, `viewer_bottom_bar.dart`,
  `lib/screens/viewer/media_viewer_screen.dart` — Delete opens the sheet.
- `lib/widgets/viewer/viewer_dialogs.dart` — removed the now-unused move-to-trash dialog.
- `lib/widgets/batch/batch_action_bar.dart` — Delete opens the sheet; permanent delete of the
  selection.
- `lib/screens/trash/trash_screen.dart` — result messages.
- `lib/screens/settings/safety_settings_screen.dart` — Secure delete switch and vault note.
- `lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb` (+ generated) — 15 new keys; new text for
  `descPermWriteStorage`.

Tests

- New: `test/models/media/media_delete_result_test.dart`,
  `test/widgets/common/delete_choice_sheet_test.dart`.
- Updated: `test/models/settings/app_settings_test.dart`,
  `test/repositories/media_repository_test.dart`, `test/providers/trash_providers_test.dart`,
  `test/services/vault/vault_export_service_test.dart` (vault delete always shreds),
  `test/services/vault/vault_import_service_test.dart` (originals go through MediaStore),
  `test/services/vault/fake_vault_channel.dart`, `test/services/media/fake_media_store_channel.dart`,
  `test/widgets/batch/batch_action_bar_test.dart`.

Docs

- `docs/security.md` — §6.2 vault-always-shred rule, MediaStore shred, gallery Secure delete and
  its limit; §11 counts and table; review checklist.
- `docs/architecture.md`, `docs/release_process.md`, `CLAUDE.md`, `AGENTS.md` — permission counts
  (12 declared, 13 merged).

## Differences from the plan

- **No new `BatchAction.deletePermanently`.** The batch runner works one file at a time, which
  would mean one Android prompt per photo. Instead the selection bar's Delete calls
  `TrashController.deleteItems` once for the whole selection. Fewer changes, and one prompt.
- The old dialog `confirmViewerMoveToTrash` was removed (the sheet replaces it). Its two ARB keys
  (`titleViewerTrashConfirm`, `bodyViewerTrashConfirm`) are now unused and were left in place.

## Checks

- `flutter gen-l10n`, `dart format`, `flutter analyze` — no issues.
- `flutter test` — all 2288 tests pass.
- `flutter build apk --flavor dev --debug` — builds; the Kotlin side compiles.
- Emulator check (Android API 37, test photos owned by another app, all throwaway copies):
  - Viewer Delete → Move to trash: moved, Undo offered, no extra dialog. Pass.
  - Viewer Delete → Delete permanently, Secure delete off: app confirm, then Android's "delete"
    prompt; file gone; "1 item deleted for good." Pass.
  - Same with Secure delete on: one Android "modify" prompt only (no second delete prompt was
    needed); file gone; "1 item securely deleted." Pass.
  - Empty trash, Secure delete on, **Deny** at the prompt: file untouched, stays in trash,
    "Nothing was deleted." Pass. Then **Allow**: file gone, "1 item securely deleted." Pass.
  - Selection of 2 → Delete → Delete permanently: one prompt for both ("modify 2 photos?"),
    both gone, selection cleared, "2 items securely deleted." Pass.
  - No app errors in the log.
- **Not checked:** Android 9 and 10 (no such emulator here), the vault import "shred the
  original" path, and a big video.

## Found during the device check (not fixed here)

- **"Undo" snackbar covers the viewer's Delete button.** In this Flutter version a snackbar with
  an action stays until tapped or swiped. The viewer's "Moved to trash / Undo" snackbar follows
  into the next viewer and sits over the Delete button, so a tap meant for Delete can press Undo
  and take the last item back out of the trash. Happened once during testing. The snackbar
  existed before this change; dropping the extra trash dialog makes it easier to hit.
- The choice sheet says "You can restore **it** from the trash" even for several items.

## Known limits

- Android 10 asks once per file for a secure delete; Android has no batch prompt there.
- A batch "Move to vault" with "shred the original" still imports one item per call, so on
  Android 11+ it asks once per photo. The vault screen's own import sheet asks once for the set.
- New Malayalam and Sanskrit text needs the owner's review before release.
