# Guideline audit fixes, batch 1

**Status:** completed

## What the issue is

An audit against `docs/guidelines` on 2026-11-01 found problems that `docs/known_gaps.md` does not
list. This plan fixes the five about safety and data, plus one format failure. It also records the
remaining findings so they are not lost.

| # | Problem | Rule |
|---|---|---|
| 1 | A link from another app is not checked. A `file://` link can point at this app's private files, and `readBytes` opens it. | Standard §15.1 (input from outside) |
| 2 | WAL mode is set with `execute`, which the standard says fails on Android. An empty `catch` hides the failure. | Standard §13.2, §11.2 |
| 3 | No test covers a database upgrade. | Standard §13.1; `CLAUDE.md` testing rules |
| 4 | A prod release builds unsigned if `key.properties` is missing. | Flavors guide, Android signing |
| 5 | GPS blurring uses `math.Random()`. | Standard §15.1 (randomness) |
| 6 | Three DAO files are not formatted. | Standard §16.1, §23.1 |

## Files to be changed

**New**
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/IncomingUriRules.kt`
- `test/repositories/database/database_migration_test.dart`

**Changed**
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/MediaStoreChannelHandler.kt`
- `android/app/build.gradle.kts`
- `lib/repositories/database/database_helper.dart`
- `lib/repositories/database/album_dao.dart` (format only)
- `lib/repositories/database/media_dao.dart` (format only)
- `lib/repositories/database/tag_dao.dart` (format only)
- `lib/services/privacy/gps_geofence_service.dart`
- `test/repositories/database/database_helper_test.dart`
- `test/services/privacy/gps_geofence_service_test.dart` (only if the new default needs it)
- `docs/security.md`
- `docs/known_gaps.md`

## The plan for the fix

### 1. Check links from other apps

Add `IncomingUriRules`, one small Kotlin object with one rule:

- `content://` is allowed, except this app's own `.fileprovider` authority.
- `file://` is allowed only if its canonical path (with `..` and symbolic links resolved) is
  outside the app's data folders: `dataDir`, plus the internal and external files and cache folders.
- Every other scheme is refused.

Use it in two places:

- `extractMediaIntentData`: a refused link returns `null`, so the viewer never opens it. This also
  covers video playback, which does not go through `readBytes`.
- `handleReadBytes` and `handleLoadThumbnail`: a refused link returns `null`, the same as a missing
  file. This is the second layer of defence.

**Why not block all `file://` links?** `publishFile` returns a `file://` link on Android 9 and
below (`Uri.fromFile`, `MediaStoreChannelHandler.kt:634`). minSdk is 24, so blocking them would
break saved files on those phones. The real danger is private files, so the rule targets that.

**Accepted limit:** a refused link opens the app with nothing shown, and no message. Showing an
error for a failed "open with" is audit item 8, which is left for a later batch.

### 2. Make WAL work, and stop hiding failure

In `_onConfigure`, use `rawQuery('PRAGMA journal_mode=WAL;')`. Replace the empty `catch` with
`AppLogger.warning`, because the app still works without WAL. The log holds no user data.

Add a test that opens a database file on disk and checks that `PRAGMA journal_mode` returns `wal`.

**Risk:** real phones will start using WAL, which adds `-wal` and `-shm` files beside the database.
The backup format is JSON and does not copy the database file. Implementation must search for any
code that copies or deletes that file directly and confirm it is safe.

### 3. Test database upgrades

New test file, using `sqflite_common_ffi` and a database file in a temp folder. Each test builds
the old schema by hand, adds rows, opens through `DatabaseHelper`, and checks the result:

- v1 to v3: the vault thumbnail IV column exists and is null on old rows; old rows are kept.
- v1 to v3 with no search table: the search table and triggers are created.
- v2 to v3 with the search table already there: nothing is changed or lost.
- An upgraded database has the same tables and columns as a fresh install.

This task only adds tests. If a test finds a real migration bug, I will stop and tell you. The fix
needs its own approval, because shipped migrations are append-only.

### 4. Stop unsigned prod releases

Add a `gradle.taskGraph.whenReady` check in `build.gradle.kts`. If the build includes
`assembleProdRelease` or `bundleProdRelease`, and `key.properties` is missing or lacks a required
value, it stops with a clear `GradleException`.

This differs from the guide's `doFirst` example. `assemble` runs only after packaging, so that
example fails after a full build. The guide itself allows a configuration-time check. Dev builds
and prod debug builds are not affected.

### 5. Use secure randomness

Change the default in `GpsGeofenceService` to `math.Random.secure()`. Keep the optional `random`
parameter so tests can still pass their own.

### 6. Format

Run `dart format` on the three DAO files only. No logic changes.

### 7. Update the docs

- `docs/security.md`: record the new link rule in the platform controls, and the secure randomness.
- `docs/known_gaps.md`: correct the wrong "no `Random()`" line and record the analyze and test
  results. Add each remaining audit finding as a new gap: error logging, exception rules, silent
  "open with" failure, screen reader support, touch targets, memory pressure and `cacheWidth`,
  hard-coded text, `CHECK` constraints, version pins, lint rules, large files, the permission
  count, plan status words and unused ARB keys.

## How it will be tested

Claude runs: `dart format`, `flutter analyze`, `flutter test`.

You run, because these need your machine or a phone:

1. Build check: temporarily rename `android/key.properties`, run
   `flutter build apk --flavor prod --release`, expect a clear failure, and restore the file. Then
   run the same build and expect it to work. Afterwards stop the Gradle daemons.
2. Dev flavor, on a phone: open a photo and a video from a file manager and from another app. Both
   should open.
3. Dev flavor, on a phone: use `adb` to send a VIEW intent with a `file://` link to a file in this
   app's data folder. It must not show the file.
4. Confirm WAL on a dev build: `adb shell run-as` on the app, and look for the `-wal` file beside
   the database.

## Not in this plan

- The other audit findings, which are recorded in `docs/known_gaps.md` for later batches.
- The existing release blockers: G9, G17, G18, G19, G20, G24.
- Any change to `docs/guidelines` (read-only submodule).
- Git commits, unless you ask.
