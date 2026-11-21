# Plan — One release build script with SHA-256 checksums

**Status:** completed

## The issue

1. `flutter build apk` writes a `.sha1` file next to every APK. Flutter's own tool does
   this after Gradle ends (`flutter_tools/lib/src/android/gradle.dart`), and it has no option
   for SHA-256. SHA-1 is weak and is not what we want to publish.
2. `flutter build appbundle` writes no checksum at all. The `.aab.sha256` so far was made by
   hand.
3. After each build the files are renamed by hand (for example
   `SreerajP_ImgVid_Gallery-arm64-v2.8.0_38-prod-release.apk`). Hand renaming has already
   gone wrong: one APK is named `x85_64` instead of `x86_64`, and one has the wrong version
   (`v2.9.0_38`).

## The fix

Add one PowerShell script, `tool/build_release.ps1`, that does the whole prod release
build in a fixed order:

1. **Options**
   - `-Target apk` (split APKs, one per ABI) or `-Target aab` (App Bundle). Required.
   - `-Name <base name>`. Optional, default `SreerajP_ImgVid_Gallery`.
2. **Read the version** from the `version:` line in `pubspec.yaml` (for `2.8.0+38`:
   version `2.8.0`, build `38`). Stop with a clear message if the line is missing or malformed.
3. **Build** with the documented release flags:
   - APK: `flutter build apk --flavor prod --release --obfuscate
     --split-debug-info=build/symbols/android-prod-<version>/ --split-per-abi`
   - AAB: `flutter build appbundle --flavor prod --release --obfuscate
     --split-debug-info=build/symbols/android-prod-<version>/`
   - Stop if the build fails (non-zero exit code). Nothing is renamed or hashed then.
4. **Rename** each output in its own output folder:
   - APK (`build/app/outputs/flutter-apk/`):
     `app-prod-<abi>-release.apk` → `<Name>-<short abi>-v<version>_<build>-prod-release.apk`.
     Short ABI names: `arm64-v8a` → `arm64`, `armeabi-v7a` → `armeabi`, `x86_64` → `x86_64`.
     These match the names used so far.
   - AAB (`build/app/outputs/bundle/prodRelease/`):
     `app-prod-release.aab` → `<Name>-v<version>_<build>-prod-release.aab`.
   - If a file with the new name already exists (a rebuild of the same version), it is
     replaced, and the script prints that it did so.
5. **Delete the `.sha1` files** that Flutter wrote for this build.
6. **Write `<file>.sha256`** next to each renamed file. Content: lower-case hash, two spaces,
   file name (`<hash>  <file name>`). This is the standard `sha256sum` format, so anyone
   can check it with `sha256sum -c` on Linux, or compare it with `Get-FileHash` on Windows.
7. **Print a summary**: each final file, its size and its SHA-256.
8. **Stop Gradle daemons** (`android\gradlew --stop`), as the global build rule asks.

The script only writes inside `build/`. It does not touch `key.properties` or the keystore;
Gradle still reads those as before.

## Files to change

| File | Change |
|---|---|
| `tool/build_release.ps1` | New. The script above |
| `docs/release_process.md` | §8 build commands: use the script for prod releases; explain the file names, the `.sha256` format and how to check it. Keep the raw `flutter build` commands as "what the script runs". Release checklist: add "`.sha256` file shipped with each APK / AAB" |
| `change_log/<timestamp>_release-build-script-sha256.md` | New change log |

No app code, no Dart tests (the script is build tooling, not app code). No change to
`android/app/build.gradle.kts`.

## Security impact

Build tooling only. No new permission, dependency or network use. The script never reads or
prints signing secrets. Publishing SHA-256 instead of SHA-1 makes the direct-APK checksum
stronger for people who download it.

## How to check

You run `.\tool\build_release.ps1 -Target apk` and `.\tool\build_release.ps1 -Target aab`,
then confirm that:
- the renamed files appear with no `.sha1` left for this build;
- `Get-FileHash <file>` matches the hash in each `.sha256` file;
- no `GradleDaemon` / `KotlinCompileDaemon` Java process is left.

## Not in this plan

- Old files from earlier builds in `build/` (the `x85_64` and `v2.9.0_38` names, old `.sha1`
  files) are left alone. You can delete them yourself, or `flutter clean` clears them.
