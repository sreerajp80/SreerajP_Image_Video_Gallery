# Change log — Build script options for flavor, mode, split, obfuscate and symbols

Implements plan: [plans/20261121_142346_build-script-options.md](../plans/20261121_142346_build-script-options.md)

Builds on: [change_log/20261121_141924_release-build-script-sha256.md](20261121_141924_release-build-script-sha256.md)

## What changed

| File | Change |
|---|---|
| `tool/build_release.ps1` | New options `-Flavor` (`prod`/`dev`), `-Mode` (`release`/`profile`/`debug`), `-NoSplit`, `-NoObfuscate`, `-SymbolsDir`. `-Name` is now required, with no app name built in, so the script can be reused in other apps. Output folders and file names follow the flavor and mode (`<Name>-[<abi>-]v<version>_<build>-<flavor>-<mode>.<ext>`). Refuses `-NoObfuscate` for a prod release, and `-SymbolsDir` when the build is not obfuscated. Leaves out `--obfuscate` / `--split-debug-info` itself for debug builds. Prints the symbols folder to archive |
| `docs/release_process.md` | §9 script section: required `-Name`, options table, rules, examples, file names for each kind of build. §6.1 and §9 step 9: archive both symbols folders. Raw split APK commands now use the `-apk` symbols folder |

## Changes to today's default behaviour

- `-Name` must now be passed (`-Name SreerajP_ImgVid_Gallery` for this app). Owner's request.
- Split APK builds now write debug symbols to `build/symbols/android-<flavor>-<version>-apk/`
  instead of sharing the App Bundle's folder. Before, whichever build ran second overwrote the
  other's symbols. Owner's choice.
- Everything else with default options is the same: the same `flutter build` flags and the
  same file names as before.

## Security impact

Build tooling only. No new permission, dependency or network use. The prod release
obfuscation rule is now enforced by the script, not only written in the docs.

## Checks done

Ran the script in Windows PowerShell 5.1 in a throwaway copy of the repo, with a stand-in
`flutter` that logs its arguments and writes files the way Flutter does. Parse-checked in
PowerShell 7 too.

| Case | Result |
|---|---|
| default `apk` / `aab` | Same flags as before (APK symbols now in the `-apk` folder); same file names; `.sha256` written; no `.sha1` left |
| `-Flavor dev -Mode debug` apk | No `--obfuscate`, message shown; `...-dev-debug.apk` names |
| `-NoSplit` | No `--split-per-abi`; one `<Name>-v2.8.0_38-prod-release.apk` |
| `-Flavor dev -NoObfuscate` aab | No obfuscate flags; `bundle/devRelease/...-dev-release.aab` |
| `-Mode profile -SymbolsDir ...` aab | Custom symbols path used; `bundle/prodProfile/` |
| `-NoObfuscate` on prod release | Refused, exit 1, Flutter not run |
| `-SymbolsDir` with debug | Refused, exit 1, Flutter not run |
| `-NoSplit` with aab | Message, ignored |
| no `-Name` | PowerShell refuses: missing mandatory parameter |

Not yet done: a real build with the signing key. The owner runs that.
