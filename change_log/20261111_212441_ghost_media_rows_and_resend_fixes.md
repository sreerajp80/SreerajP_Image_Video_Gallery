# Ghost media rows on Android 10, and send-screen fixes

Implements plan: `plans/20261111_202642_ghost_media_rows_and_resend_fixes.md`
(part A2 as revised: delete our own ghosts, hide everyone else's).

## What changed

### A1 — A received photo is saved even when a ghost blocks its name

`android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`

- `publishThroughMediaStore` now calls `insertWithGhostRecovery`. If
  MediaStore refuses the insert on Android 10, it asks the scanner to look at
  the missing target path, tries again, then tries `name (1).ext` …
  `name (5).ext`. Android 11+ is unchanged.

### A2 — Ghost entries (Android 10 only)

- Kotlin `cleanStaleEntries` (new channel method): reads every image and video
  entry with its owner, checks `File(path).exists()`, and deletes the entry
  only when the file is missing **and** this app owns the entry (no prompt
  needed). Other apps' entries are left alone. Safety stop: if more than half
  the entries (and more than 20) look missing, nothing is done.
- Kotlin `queryMedia` rows carry `fileMissing` (Android 10 only).
- `lib/services/media/media_store_channel.dart` — `MediaStoreEntry.fileMissing`
  and the `cleanStaleEntries()` wrapper (returns 0 on any error).
- `lib/services/media/media_scanner_service.dart` — a `fileMissing` row is not
  indexed (counted as skipped), so the gallery hides it and a full pass removes
  an older copy. The same safety stop applies. The owner cleanup runs at most
  once per 24 hours before a scan, with full access only; if it removed
  anything, the scan goes straight to a full pass.
- `lib/services/media/stale_cleanup_store.dart` (new) — remembers the last
  cleanup time (`SharedPreferences`; a time only, not sensitive). Not named
  in the plan's file list; it keeps the scanner testable.
- `lib/core/constants/app_constants.dart` — the preference key and the 24-hour
  interval. Not named in the plan's file list.
- `lib/providers/media_providers.dart` — passes the store to the scanner.

### B — The session remembers what arrived

- `lib/models/sync/transfer_session_state.dart` — `deliveredIds` and
  `triedIds`. (The plan said "add to `==` and `hashCode`"; this class has
  neither, so only the constructor and `copyWith` changed.)
- `lib/services/sync/transfer_session_service.dart` — fills `triedIds` when a
  send starts and `deliveredIds` on each delivery.
- `lib/widgets/sync/send_picker_view.dart` — uses `state.deliveredIds`
  instead of its own list, which was lost every time the picker was rebuilt.
  A file that failed is offered again; one that arrived is not.

### C — Button text

- `SyncSelectionRules.isRest` (in `lib/core/domain/sync/sync_selection_rules.dart`)
  decides "Send the rest" vs "Send": "the rest" only for a follow-up send whose
  files were never tried in this pairing. Moved into the rules class so it can
  be unit tested.

### D — Plural

- `bodySyncPlanThisSend` is a plural in `app_en.arb`, `app_ml.arb`,
  `app_sa.arb` (generated files updated). The Sanskrit change needs the
  owner's review.

### Tests

- `test/services/media/media_scanner_service_test.dart` — cleanup runs once a
  day, records the time, forces a full pass after removing something, is
  skipped with limited access; ghost rows are not indexed and old copies go;
  the safety stop keeps everything when most rows look missing.
- `test/core/domain/sync/send_limit_rules_test.dart` — a failed file is
  offered again; the four button-text cases.
- `test/services/media/fake_media_store_channel.dart` — the new method and the
  `fileMissing` flag.

## Checks

- `flutter analyze`: no issues. `flutter test`: all tests pass.
- On an Android 10 phone (dev build):
  - **A1:** the photo blocked by a ghost arrived, saved as `… (1).jpg`. Passed.
  - **A2, delete our own:** a ghost owned by the dev app was removed with no
    prompt; a ghost owned by another package was left alone. Passed.
  - **A2, path check:** a real photo gives `exists = true`, a ghost `false`.
    Passed.
  - **A2, hide:** not verified on the phone, because of the separate bug
    below (nothing can be indexed there). Covered by unit tests only.
  - **B/C/D** on the sending phone: the retry showed "Send" (not "Send the
    rest") and "1 file". Confirmed by the owner.

## What the testing changed in the plan

The first A2 asked Android's scanner to rescan missing paths, based on the
Android 10 source. On the phone, neither a single-file scan nor a folder scan
removed the ghost. Hence the revised A2.

## Known gaps

- Android 9 and older: no ghost handling.
- Other apps' ghosts stay in Android's media list; only this app hides them.
- After an app restart on Android 10 with ghosts present, the first scan is a
  full pass (the skipped count is kept in memory only, as for unreadable rows
  today).

## Separate bug found (not fixed here)

On the Android 10 test phone, the app's database holds
`media_search_fts` as an **FTS5** virtual table, but that phone's SQLite has
no FTS5 module. Every insert into `media_items` fires a trigger that writes to
it and fails with `no such module: fts5`, so a fresh install indexes no
photos and the gallery stays empty. The FTS5 → FTS4 fallback in
`DatabaseHelper._createFtsTableAndTriggers` (older code, not part of this
change) did not stop the FTS5 table definition from being stored. Needs its
own plan.
