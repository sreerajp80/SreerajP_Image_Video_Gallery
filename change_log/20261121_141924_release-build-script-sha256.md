# Change log — One release build script with SHA-256 checksums

Implements plan: [plans/20261121_141647_release-build-script-sha256.md](../plans/20261121_141647_release-build-script-sha256.md)

## Why

`flutter build apk` writes a SHA-1 file next to each APK and has no SHA-256 option.
`flutter build appbundle` writes no checksum at all. The files were also renamed by hand,
which had already produced a wrong ABI name (`x85_64`) and a wrong version in one name.

## What changed

| File | Change |
|---|---|
| `tool/build_release.ps1` | New. `-Target apk` or `-Target aab`, optional `-Name` (default `SreerajP_ImgVid_Gallery`). Reads the version from `pubspec.yaml`, runs the documented prod release `flutter build`, renames the outputs to `<Name>-[<abi>-]v<version>_<build>-prod-release.<ext>`, deletes Flutter's `.sha1` files, writes `<file>.sha256` (`<lower-case hash>  <file name>`, UTF-8 without BOM), prints a summary, and runs `gradlew --stop` |
| `docs/release_process.md` | §9 steps and build commands now use the script; explains the names, the `.sha256` format and how to check it on Windows and Linux. Raw `flutter build` commands kept as "what the script runs"; fixed the documented APK output path. §8 checklist and §14 evidence now ask for the `.sha256` files |

## Design notes

- The SHA-256 step is in the script, not in Gradle. Flutter writes the `.sha1` after Gradle
  ends, so Gradle cannot remove it, and hashing in Gradle would hash the old names.
- Before building, the script deletes any old Flutter-named output, so a stale file from an
  earlier build can never be renamed and hashed as this build.
- If `flutter build` fails, nothing is renamed or hashed, and the script exits with an error.
- No change to app code, Gradle files or signing. The script never reads `key.properties`.

## Security impact

Build tooling only. No new permission, dependency or network use. Direct-download APKs now
come with a SHA-256 checksum instead of SHA-1.

## Checks done

- Ran the script in a throwaway copy of the repo with a stand-in `flutter` command that writes
  files the way Flutter does, in both PowerShell 7 and Windows PowerShell 5.1:
  - `-Target apk`: three renamed APKs (`armeabi`, `arm64`, `x86_64`), each with a `.sha256`,
    and no `.sha1` left.
  - `-Target aab`: renamed AAB with its `.sha256`.
  - Rebuild of the same version: old files replaced, with a message.
  - Hash in the `.sha256` file matches `Get-FileHash`; file has no BOM.
  - Failed build: stops with "Nothing was renamed or hashed" and exit code 1.
- Not yet done: a real prod build with the signing key. The owner runs that.
