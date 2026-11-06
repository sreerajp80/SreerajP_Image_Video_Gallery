# Block device-to-device transfer of app data (G16)

**Status:** completed

## The issue

`android:allowBackup="false"` does not stop device-to-device transfer on Android 12 (API 31) and
above. The manifest has no `android:dataExtractionRules`. So when a user moves to a new phone, Android
may copy this app's private files to it.

This data would be at risk:

- The app database, including vault metadata (original file name, size, tags, notes). It is stored as
  plain text (`docs/security.md` §4).
- Settings and other files in private storage.

The vault's encrypted files would be copied too. Their key stays in the old phone's Android Keystore,
so a copy could not be opened. That is safe for privacy, but it could leave a vault on the new phone
that looks present and cannot be opened.

`docs/security.md` says this path is already closed. That is wrong and must be corrected.

Rules: release process template §6.4, store readiness §2.4, engineering standard §15.2.

## Files to change

| File | Change |
|---|---|
| `android/app/src/main/res/xml/data_extraction_rules.xml` | New. Excludes all app data from cloud backup and device transfer. |
| `android/app/src/main/AndroidManifest.xml` | Adds `android:dataExtractionRules`. Keeps `allowBackup` and `fullBackupContent` as they are. |
| `test/android/backup_rules_test.dart` | New. Fails if the rules or the manifest settings are removed. |
| `docs/security.md` | Corrects §10 and the §5, §12 (M8) and §13 lines. |
| `docs/release_process.md` | Adds the new setting to the checks in §6.4, §8 and §9A. |
| `CLAUDE.md`, `AGENTS.md` | Security rule also names `dataExtractionRules`. |
| `docs/known_gaps.md` | Moves G16 to resolved, and updates the counts. |
| `change_log/<timestamp>_block-device-transfer-g16.md` | New. |

## The plan for the fix

1. Add the rules file with both sections, `<cloud-backup>` and `<device-transfer>`. Each one excludes
   every app storage area: `root`, `file`, `database`, `sharedpref`, `external`, and their
   `device_` versions.
2. Point the manifest at the file:
   `android:dataExtractionRules="@xml/data_extraction_rules"`, with `tools:targetApi="31"`. Older
   Android ignores it and keeps using `allowBackup="false"` and `fullBackupContent="false"`.
3. Add a test that reads both files as text and checks that:
   - the manifest keeps all three settings;
   - both sections exist and exclude each storage area.
4. Correct the docs, and write the change log.

## Why exclude everything

The other choice is to exclude only sensitive files. I reject it, because a later feature could add a
new file that nobody remembers to exclude. Excluding everything stays safe by default.

**The cost:** after a phone move, the app starts empty: no albums, notes, settings or vault. Original
photos and videos in shared storage are not affected, because Android moves those separately. The
app's own encrypted backup archive stays the way to move app data (`docs/security.md` §14). If a user
never made an archive, vault items on the old phone are not carried over. This is correct for a
privacy app, but it should be stated in the Play listing or help text later. That text is not part of
this plan.

## How to check it

The user runs:

```bash
flutter analyze
```

```bash
flutter test
```

```bash
flutter build apk --flavor dev --debug
```

Then stop the Gradle daemons, as the global rules ask.

## Limits

- The test checks the files, not Android's behaviour. It proves the settings are present, not that a
  real transfer skips the data. A real check needs a phone transfer between two Android 12+ devices.
- Android reads these rules at transfer time and phone makers can add their own transfer tools. The
  rules cover the Android system path. They cannot promise anything about a rooted phone or a maker's
  tool that ignores them.
