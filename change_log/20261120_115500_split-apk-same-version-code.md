# Change log — Split APKs use the same version code as the Play bundle

Implements plan: `plans/20261120_113908_split-apk-same-version-code.md`

## What changed

- `android/gradle.properties`: added `force-version-code-ignoring-abi=true` with a comment.
  This is Flutter's own switch. With it, `--split-per-abi` no longer adds 1000 / 2000 / 4000
  per ABI, so every split APK gets the plain build number from `pubspec.yaml`, the same as
  the Play bundle.
- `docs/release_process.md`:
  - §9 (split APK build): says all split APKs now share the bundle's version code, and how
    to check it (`aapt2 dump badging` or APK Analyzer).
  - §12 (Distribution Channels): explains why both channels must share one version code.
  - §8 (Release Checklist, Artifact Validation): new item to check the split APK version code.

No Dart code, permission or test change.

## Why

A test phone had 2.7.1 from a direct split APK (version code 1034). Play's 2.7.4 is code 37,
so Play saw it as older and offered no update. The phone had to be uninstalled, which deletes
the app's private data.

## Difference from the plan

The `gradle.properties` comment says "Flutter 3.50.1 has this switch" instead of naming a
lowest Flutter version, because the exact version that added the switch was not checked.

## Not done / not checked

- No build was run. The owner builds a split APK and checks that its version code equals the
  `pubspec.yaml` build number (expected `37` for `2.7.4+37`), then runs `android\gradlew --stop`.
- The note for the guidelines owner in the plan (warn about the ABI offset in
  `flutter_build_flavors_guide.md`) is not done; that folder is read-only here.

## Security impact

Build config only in `android/`. No permission, network, storage or signing change.
