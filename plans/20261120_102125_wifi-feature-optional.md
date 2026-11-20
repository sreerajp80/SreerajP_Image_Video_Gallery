# Plan — Mark Wi-Fi as optional hardware in the manifest

**Status:** completed

## The issue

Play Console blocked release `SreerajP_ImgVid_Gallery-v2.7.3_36` from review with:
"Required hardware feature declarations are restricting your app's
availability — `android.hardware.wifi` affects Phone, Tablet, Desktop and
Android XR users."

The manifest never names `android.hardware.wifi`. Play adds it by itself: an app
that asks for `ACCESS_WIFI_STATE` or `CHANGE_WIFI_STATE` is treated as
*requiring* Wi-Fi hardware, unless the manifest says otherwise. Devices that do
not report Wi-Fi hardware then cannot install the app at all.

The app does not need Wi-Fi to work. Only two features use it:
- Device-to-device transfer: when there is no local network address,
  `NetworkInterfaceService` returns null and the transfer screen already shows its
  "no Wi-Fi" state (`Icons.wifi_off_outlined` in `sync_home_screen.dart`).
- The in-image scanner's "add Wi-Fi network" action: Android simply has no
  network to suggest to.

The camera is already handled the same way (`android:required="false"` for
`camera`, `camera.autofocus`, `camera.any`). Wi-Fi was missed.

## The fix

`android/app/src/main/AndroidManifest.xml`: next to the Wi-Fi permissions, add

```xml
<uses-feature
    android:name="android.hardware.wifi"
    android:required="false" />
```

with a short comment, like the camera block. No Dart change. No permission is
added or removed (still 13 declared, 14 merged).

`docs/security.md` §11 (permissions table): add one line saying Wi-Fi hardware
is declared optional and why.

## Version

Version code 36 is already uploaded to Play, and Play never accepts the same
version code twice. The fixed bundle needs a new code. Proposal: **2.7.3+37**
(same version name, so the release notes stay the same; release name
`SreerajP_ImgVid_Gallery-v2.7.3_37`). The owner changes `pubspec.yaml` and the
generated version files with their usual release steps; this plan does not.

## Files to change

- `android/app/src/main/AndroidManifest.xml`
- `docs/security.md`

## How to check

Owner runs the prod release bundle build, then checks the merged manifest
(`build/app/intermediates/merged_manifest/prodRelease/.../AndroidManifest.xml`)
contains `android.hardware.wifi` with `required="false"`. In Play Console, the
new bundle's "Required hardware features" should no longer list Wi-Fi.
`android\gradlew --stop` after the build.

## Security impact

None. No permission change. It only stops Play from hiding the app on devices
without Wi-Fi hardware; Wi-Fi features still check for a local address in code.
