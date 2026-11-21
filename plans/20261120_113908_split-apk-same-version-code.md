# Plan — Give split APKs the same version code as the Play bundle

**Status:** completed

## The issue

`flutter build apk --split-per-abi` gives each split APK a different version code. Flutter
adds a fixed amount per ABI to the build number from `pubspec.yaml`:

| ABI | Added | 2.7.1+34 became |
|---|---|---|
| `armeabi-v7a` | 1000 | 1034 |
| `arm64-v8a` | 2000 | 2034 |
| `x86_64` | 4000 | 4034 |

The Play App Bundle has no such offset, so 2.7.4+37 is version code **37** on Play.

Android and Play compare only the version code. A phone that had a direct split APK
(for example 2.7.1 = 1034) sees Play's 2.7.4 (= 37) as an *older* version. Play shows no
update and Android blocks it as a downgrade. This happened on a test phone; the only fix
there was to uninstall, which deletes the app's private data (vault, albums, settings).

`docs/release_process.md` §12 lists direct split APKs as a public channel signed with the
same key as Play, so any real user of that channel would hit the same wall.

## Current state of installs

Only the owner's own phones ever had direct APKs. All of them now run 2.7.4 (code 37) from
Play. So no "jump" of the Play version code is needed — there is no sideloaded install with
a higher code left to catch up with.

## The fix

Flutter 3.50.1 has its own switch for this: the Gradle property
`force-version-code-ignoring-abi`. When it is `true` and the version code is set in the
Gradle DSL (ours is: `versionCode = flutter.versionCode` in `android/app/build.gradle.kts`),
Flutter skips the ABI offset and every split APK gets the plain version code from
`pubspec.yaml` — the same number as the Play bundle.

1. `android/gradle.properties`: add `force-version-code-ignoring-abi=true`, with a short
   comment saying why (split APKs and the Play bundle must share one version code, so a
   phone can move between the two channels in either direction by a normal update).
   - Putting it in `gradle.properties` means it applies to every build. Nobody has to
     remember a `-P` flag on the command line.
2. `docs/release_process.md`:
   - In the split APK build step, note that every split APK now has the same version code
     as the bundle, and how to check it.
   - In §12 (Distribution Channels), add one line: both channels use the same version code
     for the same release, so a direct-APK user can later take a Play update (and the other
     way round) as long as the signing key is the same.
   - Add a "check the version code" step to the release checklist.

No Dart code changes. No test changes (this is build config only; there is no Dart code
to test).

### Why this and not a Gradle `onVariants` override

An override in `build.gradle.kts` would also work, but it is our own code that copies a
job Flutter already offers as a supported switch. The property is one line and is removed
just as easily.

## Files to change

- `android/gradle.properties`
- `docs/release_process.md`

## Not changed

- `docs/guidelines/flutter_build_flavors_guide.md` (read-only submodule). It describes
  `--split-per-abi` output but does not mention the version-code offset. A note for the
  guideline owner is listed below; the submodule is not edited.

## Risks and downsides

- **Older Flutter ignores the property silently.** `pubspec.yaml` allows Flutter 3.41+.
  If a Flutter version without this switch builds the app, the offset comes back with no
  error. The project and CI both use 3.50.1, and the new checklist step (check the version
  code of a built split APK) would catch it.
- **All split APKs share one code.** That is fine for direct download, because a phone
  installs only one ABI's APK. It would matter only if several APKs were uploaded to Play
  itself, which this project does not do (Play gets a bundle).
- **Signing key still matters.** A direct APK and a Play install can only update each
  other if Play's app signing key is the same as `gallery-release.jks`. This plan does not
  change that; it only removes the version-code clash.

## How to check (owner runs)

```powershell
flutter build apk --flavor prod --release --split-per-abi
```

Then read the version code of one split APK, for example with the Android SDK's
`aapt2 dump badging <apk>` or Android Studio's APK Analyzer. Expected: `versionCode='37'`
(not 1037 / 2037 / 4037). After the build, run `android\gradlew --stop` as usual.

## Security impact

Touches a platform folder (`android/`) for build config only. No permission, network,
storage or signing change.

## Note for the guideline owner (not part of this change)

`flutter_build_flavors_guide.md` could warn that `--split-per-abi` adds 1000/2000/4000 to
the version code, so split APKs and a Play bundle of the same release clash, and suggest
`force-version-code-ignoring-abi=true` in `android/gradle.properties`.
