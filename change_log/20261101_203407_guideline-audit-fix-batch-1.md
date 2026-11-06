# Guideline audit fixes, batch 1

Implements [plans/20261101_202921_guideline-audit-fix-batch-1.md](../plans/20261101_202921_guideline-audit-fix-batch-1.md).

## What changed

**Links from other apps**
- New `android/app/src/main/kotlin/in/sreerajp/imgvidgal/media/IncomingUriRules.kt`. It allows
  `content://` except this app's file provider, and `file://` only outside the app's data folders,
  using the canonical path. Everything else is refused, and so is any link it cannot check.
- `IntentChannelHandler.kt`: a refused "open with" link returns `null`.
- `MediaStoreChannelHandler.kt`: `readBytes` and `loadThumbnail` return `null` for a refused link.

**WAL**
- `lib/repositories/database/database_helper.dart`: sets WAL with `rawQuery`. A failure now logs a
  warning instead of being hidden.
- No code copies the database file directly. `deleteDatabaseFile` uses the factory's own delete, and
  nothing in `lib/` calls it.

**Tests**
- New `test/repositories/database/database_migration_test.dart`: v1 upgrade, v1 with no search
  table, v2 with a search table, and an upgraded database compared with a fresh one.
- `test/repositories/database/database_helper_test.dart`: a WAL test on a database file.

**Signing**
- `android/app/build.gradle.kts`: `assembleProdRelease` and `bundleProdRelease` stop at the start if
  `key.properties`, a required value, or the keystore file is missing.

**Randomness**
- `lib/services/privacy/gps_geofence_service.dart`: defaults to `Random.secure()`.
  `test/services/privacy/gps_geofence_service_test.dart` needed no change.

**Format**
- `album_dao.dart`, `media_dao.dart` and `tag_dao.dart`: format only.

**Docs**
- `docs/security.md`: the link rule and secure randomness.
- `docs/known_gaps.md`: corrected the `Random()` claim, recorded results, added G31–G46.

## Test results

- `dart format`: no changes needed.
- `flutter analyze`: clean.
- `flutter test`: all 1,990 pass (5 new).

## Not verified

- No Android build was run, so the Kotlin and Gradle changes have **not been compiled**.
- The link rule has not been tried on a phone.
- WAL has not been confirmed on a phone. The new test runs on desktop SQLite, where the old
  `execute` call also works, so it guards the result but does not prove the Android fix.
- The signing check has not been run.

## Found during this work

The v3 migration does not add existing rows when it creates a missing search table (G45). This is
from reading the code. The plan said to report a migration bug and not fix it, so it is unchanged.
