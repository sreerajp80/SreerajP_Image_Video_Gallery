# Change log — Mark Wi-Fi as optional hardware in the manifest

Implements plan: `plans/20261120_102125_wifi-feature-optional.md`

## What changed

- `android/app/src/main/AndroidManifest.xml`: added
  `<uses-feature android:name="android.hardware.wifi" android:required="false" />`
  right after the Wi-Fi permissions, with a comment. Play no longer treats the
  Wi-Fi permissions as "Wi-Fi hardware required", so the app can be installed on
  devices that do not report Wi-Fi.
- `docs/security.md` §11: one paragraph on why Wi-Fi hardware is optional, next
  to the existing note about `camera.any`.

No permission was added or removed (13 declared, 14 merged). No Dart change.

## Difference from the plan

None.

## Not done / not checked

- The release bundle has not been rebuilt. The owner sets the version to
  2.7.3+37 (Play does not accept version code 36 again), builds, checks the
  merged manifest, and uploads.

## Security impact

None. No permission change.
