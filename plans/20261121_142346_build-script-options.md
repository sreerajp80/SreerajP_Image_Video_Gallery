# Plan — Build script options for flavor, mode, split, obfuscate and symbols

**Status:** completed

Builds on: [plans/20261121_141647_release-build-script-sha256.md](20261121_141647_release-build-script-sha256.md)

## The issue

`tool/build_release.ps1` always builds `--flavor prod --release --obfuscate
--split-debug-info=... [--split-per-abi]`. The owner wants to choose these flags:
`--flavor`, `--release` / `--debug`, `--split-per-abi`, `--obfuscate` and
`--split-debug-info`.

These cannot be passed straight through to `flutter build`. The script must *know* them,
because the flavor and mode decide:
- where Flutter puts the output (`flutter-apk/app[-<abi>]-<flavor>-<mode>.apk`,
  `bundle/<flavor><Mode>/app-<flavor>-<mode>.aab`);
- what the final file name says (today it always says `prod-release`, which would be wrong for
  a dev or debug build).

So they become named script options.

## Version

The script already reads the version the same way as the owner's command:
`2.8.0` from `version: 2.8.0+38` gives `build/symbols/android-prod-2.8.0/`, exactly as today.
It also reads the build number (`38`), which the file name needs. One small difference stays:
the owner's line accepts a version with no `+<build>`; the script stops with a clear message
then, because the file name and Play both need the build number. No change here.

## The fix — new options

| Option | Values | Default | Becomes |
|---|---|---|---|
| `-Target` | `apk`, `aab` | required | `flutter build apk` / `appbundle` |
| `-Flavor` | `prod`, `dev` | `prod` | `--flavor <value>` |
| `-Mode` | `release`, `profile`, `debug` | `release` | `--release` / `--profile` / `--debug` |
| `-NoSplit` | switch | off (so APKs are split) | leaves out `--split-per-abi`; one universal APK. Ignored for `aab` |
| `-NoObfuscate` | switch | off (so obfuscated) | leaves out `--obfuscate` and `--split-debug-info` |
| `-SymbolsDir` | path | `aab`: `build/symbols/android-<flavor>-<version>/` (as today); `apk`: `build/symbols/android-<flavor>-<version>-apk/` (new, see below) | `--split-debug-info=<value>` |
| `-Name` | text | **none — required** (owner's request, added after approval: the script is meant to be reused in other apps, so no app name is built in) | file base name |

Rules the script enforces, with a clear message:
- **prod + release must be obfuscated.** `-NoObfuscate` with `-Flavor prod -Mode release` is
  refused (`docs/release_process.md` §6.1: every production build must use `--obfuscate` and
  `--split-debug-info`).
- **debug is never obfuscated.** In `-Mode debug` the script leaves out `--obfuscate` and
  `--split-debug-info` itself (Flutter does not support them in debug), and says so.
  `-SymbolsDir` with debug or `-NoObfuscate` is refused, since it would be ignored.

Final file names now carry the real flavor and mode:
- split APK: `<Name>-<abi>-v<version>_<build>-<flavor>-<mode>.apk`
- universal APK (`-NoSplit`): `<Name>-v<version>_<build>-<flavor>-<mode>.apk`
- AAB: `<Name>-v<version>_<build>-<flavor>-<mode>.aab`

For the default (`prod`, `release`, split) the names are exactly the same as today.

**Own symbols folder for APKs (owner's request, added after approval).** Today the split APK
build and the AAB build of the same version both write to `build/symbols/android-prod-<version>/`,
so whichever runs second overwrites the other's symbols. The two builds are separate
compiles, so the AAB's crash stack traces may not decode with the APK's symbols. APK builds
now default to `build/symbols/android-<flavor>-<version>-apk/`; AAB builds keep today's
folder. This is the one deliberate change to today's default behaviour.
Everything else stays as it is: delete old Flutter outputs first, stop on build failure,
rename, delete `.sha1`, write `.sha256`, summary, `gradlew --stop`.

Examples:
```powershell
.\tool\build_release.ps1 -Name SreerajP_ImgVid_Gallery -Target aab   # same as today
.\tool\build_release.ps1 -Name MyApp -Target apk -Flavor dev -Mode debug  # dev debug split APKs
.\tool\build_release.ps1 -Name MyApp -Target apk -NoSplit                 # one universal prod APK
.\tool\build_release.ps1 -Name MyApp -Target apk -Flavor dev -NoObfuscate # dev release, readable stack traces
```

## Files to change

| File | Change |
|---|---|
| `tool/build_release.ps1` | New options and rules above; output paths and names from flavor and mode |
| `docs/release_process.md` | §9 script section: the options table, the rules, the examples |
| `change_log/<timestamp>_build-script-options.md` | New change log |

## Not in this plan

- A free "pass anything else to flutter" option (for example `--dart-define`). Not asked for;
  can be added later with a refused-flags list.

## Security impact

Build tooling only. No new permission, dependency or network use. The prod release
obfuscation rule is now enforced by the script instead of only written in the docs.

## How to check

Same throwaway-copy test as last time, with a stand-in `flutter` that writes files the way
Flutter does, for: default apk and aab, dev debug apk, `-NoSplit`, and the two refused cases.
Then the owner runs one real build.
