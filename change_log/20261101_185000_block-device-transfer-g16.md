# Block device-to-device transfer of app data (G16)

Implements plan: `plans/20261101_184328_block-device-transfer-g16.md`

## What changed

- Added `android/app/src/main/res/xml/data_extraction_rules.xml`. It excludes every app storage area
  from cloud backup and device transfer.
- `android/app/src/main/AndroidManifest.xml` now sets `android:dataExtractionRules`, with
  `tools:targetApi="31"`. `allowBackup` and `fullBackupContent` are unchanged.
- Added `test/android/backup_rules_test.dart`.
- `docs/security.md`: corrected the wrong statement in §10, and updated §5, §12 (M8) and §13.
- `docs/release_process.md`: added the setting to §6.4, §8 and §9A.
- `CLAUDE.md` and `AGENTS.md`: the security rule now names the setting.
- `docs/known_gaps.md`: moved G16 to resolved, and updated the counts.

## Effect for users

After a phone move the app starts empty. Shared photos and videos are not affected. The encrypted
`.gallerybak` backup is the way to move app data. Help or store text should say this; that text is
not part of this change.

## Not verified

- The new test, `flutter analyze` and the debug build have not been run. They are with the user.
- No real transfer between two Android 12+ phones has been tested.
- Nothing was committed.
