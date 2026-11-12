# Ghost media rows on Android 10, and two send-screen fixes

**Status:** completed

Follows `plans/20261111_141544_resend_selected_photos.md`, which allowed
re-sending in a manual send. Testing that change on a real phone found the
problems below.

## The issues

### A. A received photo fails to save ("1 file did not arrive")

Found on the receiving phone (Android 10):

1. The photo was received once, then deleted with a **file manager**. A file
   manager on Android 10 deletes the file directly on disk and does not tell
   Android's media list (MediaStore). The file is gone, but its MediaStore
   entry stays. This is a **ghost entry**. It stays until Android rescans
   that path.
2. When the photo is sent again, the app asks MediaStore to save a new photo
   with the same name in the same folder.
3. On Android 10, MediaStore picks the file path by checking **only the
   disk** (`FileUtils.buildUniqueFile`: `while (file.exists())`). The disk is
   free, so it picks the same path the ghost holds.
4. In MediaStore's database the path column is unique
   (`_data TEXT UNIQUE COLLATE NOCASE`). The second entry is refused, so the
   save fails and the file is reported as "did not arrive".

Proof on the phone: a test save with the same name was refused; a test save
with a different name in the same folder was accepted (then removed).

Ghosts are not only a transfer problem. They can show up in the gallery as
photos that no longer exist, and a file manager can make them at any time.

### B. The picker forgets what was sent

While a send runs, the screen replaces the picker with a progress view, so
the picker widget and its "sent in this session" list are thrown away. When
the picker comes back, the list is empty. The guard added by the previous
plan never worked. (The tests only covered the rule, not the screen.)

### C. The button says "Send the rest" after any send

It is chosen only by "has there been a send before". After a failed file is
retried, "the rest" is wrong.

### D. "This send: 1 files"

`bodySyncPlanThisSend` has no plural form in any of the three languages.

## What the source of Android 10 says about cleanup

Android 10's scanner (`ModernMediaScanner`), when asked to scan a path,
deletes database entries under that path that it did not find on disk
(`reconcileAndClean`; the file itself is never touched, `PARAM_DELETE_DATA`
is `false`). Asking it to scan a **missing single file** removes that file's
entry.

Trap: the match is `_data LIKE '<path>%'`. Scanning a **folder**
`.../Camera` would also match a sibling folder `.../Camera2`, whose entries
it did not walk, and drop them. So the plan scans **single missing files
only**, never folders.

## Plan for the fix

### Part A1 — Save that recovers from a ghost (receive side)

`android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`,
`publishThroughMediaStore`:

- If the insert is refused (returns null or throws) on Android 10:
  1. Ask Android to scan the target path
     (`MediaScannerConnection.scanFile`, waited on with a short timeout, on
     the worker thread). If the file is missing, Android drops the ghost.
  2. Try the insert once more with the same name.
  3. If still refused, try `name (1).ext` … `name (5).ext`.
  4. If all are refused, fail as today.
- Android 11 and newer: unchanged.

### Part A2 — Background ghost cleanup (Android 10 only) — REVISED

**Why revised:** the first version asked Android to rescan each missing
path. On the Android 10 phone this did **not** remove the ghost: not the
app's single-file scan, not Android's own "scan this file" signal, not a scan
of the whole folder. The path check itself worked (checked 3, missing 1).
The ghost's owner is our prod app (`owner_package_name`). On Android 10 an
app may delete MediaStore entries it owns without asking; deleting another
app's entry shows a system prompt for each file.

So ghosts are handled by owner:

| Ghost saved by | What the app does | Prompt? |
|---|---|---|
| This app (e.g. received files) | Deletes the MediaStore entry | No |
| Any other app | Hides it in the app's own index only | No |

1. **Delete our own** —
   `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`,
   `cleanStaleEntries` (already added) changes to: read `_id`, `_data` and
   `owner_package_name`; check `File(path).exists()`; for a missing file
   whose owner is this app, `contentResolver.delete(uri)`. Other owners are
   left alone. The rescan helper stays only for A1 (harmless there).
   Returns checked / missing / deleted / stopped. Daily, as already built.
2. **Hide everyone else's** — in the same Kotlin file, `queryMedia` adds
   `fileMissing: true` to a row on Android 10 when `File(path).exists()` is
   false. `lib/services/media/media_store_channel.dart` reads it into
   `MediaStoreEntry`. `lib/services/media/media_scanner_service.dart`
   `_indexPass` does not index such rows (counted as skipped, so the quick
   scan count check still matches). A ghost already in the index is then
   not "seen" by a full pass and is removed by the existing
   `deleteMediaItemsMissingFrom`. Android's entry stays; only our gallery
   stops showing it.
3. **Safety stop** for both: if more than half of the rows (and more than
   20) look missing, nothing is deleted and nothing is hidden. That points to
   a storage problem (for example a removed SD card).
4. Since the daily job may now delete only our own ghosts, "cleaned > 0"
   still forces a full pass (built already).
5. Tests: scanner skips `fileMissing` rows and removes them from the index;
   safety stop keeps them when most rows look missing; the existing daily
   tests stay.

Other Android versions: unchanged (no `fileMissing`, no deletes). Android
11+ keeps MediaStore in step itself. Android 9 and older: not covered.

### Part B — Remember delivered files in the session, not the widget

- `lib/models/sync/transfer_session_state.dart` — add
  `Set<String> deliveredIds` (ids of files the other phone now holds: every
  acknowledged file and every file it said it already has) and
  `Set<String> triedIds` (ids put in any send this session). Both in
  `copyWith`, `==`, `hashCode`.
- `lib/services/sync/transfer_session_service.dart` — add to `triedIds` when
  a send starts; add to `deliveredIds` in `onDelivered`. Cleared on a new
  pairing.
- `lib/widgets/sync/send_picker_view.dart` — remove the local
  `_sentThisSession`; pass `state.deliveredIds` as `sentThisSession`.
  A file that **failed** is not in `deliveredIds`, so it is offered again,
  which is what the user wants.

### Part C — Button text

`send_picker_view.dart`: "Send the rest" only when it is a follow-up send
**and** none of the files in this send were tried before (`triedIds`).
Otherwise "Send". A retry of a failed file shows "Send".

### Part D — Plural

`bodySyncPlanThisSend` becomes a plural (`=1{…1 file…} other{…}`) in
`lib/l10n/app_en.arb`, `app_ml.arb`, `app_sa.arb`; run `flutter gen-l10n`.
The Sanskrit change needs the owner's review.

### Tests

- `test/services/sync/` (existing session service tests, or a new file):
  `deliveredIds` grows on delivery, a failed file is not added, `triedIds`
  is set at send start.
- `test/services/media/`: the scanner runs the cleanup at most once a day,
  and forces a full pass when it cleaned something.
- The Kotlin parts have no unit tests in this project; they are checked on
  the Android 10 phone (below).

### Check on the phone (Android 10)

1. Rebuild and install the dev build on the Android 10 phone.
2. Send the same photo again **without** removing the ghost first: it should
   arrive (Part A1).
3. Make a new ghost (send a photo, delete it with the file manager), open
   the app: the cleanup should remove it from the gallery (Part A2).
4. Check the button text and that a delivered file is not offered again.

Then `dart format .`, `flutter analyze`, `flutter test`, stop the Gradle
daemons, and write the change log.

## Files to change

- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- `lib/services/media/media_store_channel.dart`
- `lib/services/media/media_scanner_service.dart`
- `lib/models/sync/transfer_session_state.dart`
- `lib/services/sync/transfer_session_service.dart`
- `lib/widgets/sync/send_picker_view.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_ml.arb`, `lib/l10n/app_sa.arb`
  (+ generated `lib/l10n/generated/*`)
- `test/services/media/fake_media_store_channel.dart`
- new or changed tests under `test/services/media/` and `test/services/sync/`

## Security impact

Storage: on Android 10 the app deletes MediaStore entries **it owns** whose
file it has proved is missing, and hides other missing entries in its own
index. It never deletes or writes a user file, and never touches another
app's entry. No new permission (reading
uses the existing media read permission; `MediaScannerConnection` needs
none). The save retry uses a new file name only inside the app's own
`Drishya Sync` folder. No network change.

## Risks

- A wrong "missing" answer would drop a real photo's entry from MediaStore
  (the file stays on disk and comes back on Android's next scan). The
  safety stop above guards against a mass mistake. The path check was
  proven on one Android 10 phone (Xiaomi); other makers were not tested.
- The daily sweep checks every path once. A path check is cheap (no file is
  opened), and it runs on the background worker thread.
