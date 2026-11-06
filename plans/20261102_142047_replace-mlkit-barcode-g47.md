# Replace the closed-source ML Kit barcode reader (G47)

**Status:** completed

> Done (option B1): [change_log/20261102_143549_replace-mlkit-barcode-g47.md](../change_log/20261102_143549_replace-mlkit-barcode-g47.md). The Android build and phone checks in §5 are still to be run by the owner.

**Date:** 2026-11-02
**Gap:** G47 in [docs/known_gaps.md](../docs/known_gaps.md) (release blocker)
**Part of:** [plans/20261102_131432_strict-guideline-adherence.md](20261102_131432_strict-guideline-adherence.md)

**Security impact:** this changes a dependency that touches the camera and reads untrusted input
(codes in photos and the pairing QR code). It removes a closed-source Google binary, which also
removes a part of the app whose data collection was never reviewed. It adds two Flutter plugins
(`camera`, `image_picker`) as transitive dependencies. Each can add Android permissions, which
must be checked in the merged manifest. The new package has a URL-reading function that the
app must never call; a test will guard this. No permission is added on purpose, and the
`LocalAddressRules` / local-network rules do not change.

---

## 1. What the issue is

`mobile_scanner` 5.2.3 reads barcodes with Google ML Kit on Android
(`com.google.mlkit:barcode-scanning`). ML Kit is a closed-source binary, which breaks hard rule 1
("open source only"). The project already refused ML Kit for OCR for this reason
([docs/dependencies.md](../docs/dependencies.md)). Because of it:
- the About screen line "All libraries used are open source" is untrue;
- `docs/security.md` §1.1 has its only `open` line.

The current `mobile_scanner` (7.5.0, checked 2026-11-02) still uses ML Kit on Android in both its
bundled and unbundled modes. Upgrading does not help.

The app uses it in two places:

| Use | Where | What it needs |
|---|---|---|
| Codes in a still photo (in-image scanner) | `MobileScannerImageDecoder` in `lib/services/scan/image_scan_service.dart`, behind the `BarcodeImageDecoder` interface | Every common format, from a file path |
| Pairing QR code, live camera | `sync_send_screen.dart` (`MobileScanner` widget) | QR only; the typed code is already the fallback |

## 2. Options I checked (facts from pub.dev and GitHub, 2026-11-02)

| Option | What it is | For | Against |
|---|---|---|---|
| **A. `flutter_zxing` 3.1.0** (recommended) | MIT. Wraps zxing-cpp (Apache-2.0) through FFI. Gives still-image decoding and a live camera widget. Released 2026-09-26; needs Flutter ≥ 3.41, Android API 23+, which match this app. | One package covers both uses. zxing-cpp reads damaged codes well and covers more formats than ML Kit (QR, Micro QR, Data Matrix, Aztec, PDF417, EAN/UPC, Code 128 and more). The camera comes from the official `camera` plugin, whose Android side is AndroidX CameraX + Guava only: no Play Services, no ML Kit, no network library. | It adds the `camera`, `image_picker` and `image` packages (`image` is already used). It has one main maintainer (136 stars). It contains `readBarcodeImageUrl`, which fetches through Flutter's `NetworkAssetBundle`. That is not a new HTTP library, and Flutter itself already has this ability (`NetworkImage`), but the app must never call it. |
| B. Own Kotlin code with ZXing Java core (`com.google.zxing:core`, Apache-2.0) | A small method channel for still images, plus CameraX and a platform view for the live scan. | No new Flutter packages and no URL path at all. | About 300–500 lines of new native code to write and keep up, including the camera preview. The Java ZXing project is in maintenance mode and reads damaged codes less well. |
| C. Pairing by photo only | Keep the still-image decoder from A or B. Pairing opens the system camera app to take one photo instead of a live preview. | The app could drop the `CAMERA` permission entirely. | Worse to use: take a photo, confirm, then decode. Some phones have no camera app; the typed code still works there. |

**(Original recommendation, now withdrawn — see §2A.)** My recommendation was A. It is the smallest change that fully meets hard rule 1. The one real
downside, the unused URL function, can be guarded by a test. I am fairly sure A is right. B is the
choice if you want zero extra plugins, at the cost of more native code you own. C is worth it only
if dropping the camera permission matters more to you than an easy pairing flow.

## 2A. Found during work: option A breaks a hard rule

Option A was approved, and `flutter pub get` was run. The lock file then held the `http` package.
It comes from `image_picker`, a direct dependency of `flutter_zxing`:
`image_picker_platform_interface` and `file_selector_platform_interface` both depend on `http`.
`CLAUDE.md` blocks `http` even as a transitive dependency. This is the same reason
`package_info_plus` was removed on 2026-09-26.

My first check read only `flutter_zxing`'s direct dependencies, not the whole tree. That was my
mistake. Both `pubspec.yaml` and `pubspec.lock` were put back exactly as before; nothing else had
changed.

The `camera` plugin alone is clean. Its full tree is `camera_android_camerax`,
`camera_platform_interface`, `cross_file`, `stream_transform`, `meta` and `web`, with no `http`.
On Android it uses only AndroidX CameraX and Guava.

## 2B. New recommendation: option B1

**B1 = the official `camera` plugin for the live preview + ZXing Java core in Kotlin for all
decoding.**

| Part | What | License |
|---|---|---|
| Decoder | `com.google.zxing:core` 3.5.3, the original ZXing library. Pure Java, no dependencies of its own | Apache-2.0 |
| Camera | `camera` (Flutter team), Android side `camera_android_camerax` (CameraX) | BSD-3-Clause; CameraX Apache-2.0 |

How it works:

- **Still photos:**
  - A new Kotlin method `decodeImageFile(path)` on a new `in.sreerajp.imgvidgal/barcode` channel
    loads the file, downscaled to at most 2,000 px on the longest side, and runs ZXing's
    multiple-barcode reader.
  - It returns `[{value, format}]`, so `BarcodeImageDecoder` and everything above it stays the same.
- **Pairing camera:**
  - `CameraPreview` from the `camera` plugin shows the picture.
  - Frames come from `startImageStream`. Only the Y (brightness) plane of one frame at a time goes
    to a Kotlin method `decodeLuminance(bytes, width, height, rowStride)`, with QR only.
  - Frames that arrive while one is being decoded are dropped, so the phone is never flooded.
  - The `_handled` guard, the camera-error panel and the "type the code" fallback stay.

Compared with A, the decoder is ZXing Java instead of zxing-cpp. It is somewhat weaker on badly
damaged codes, but it is the same family of decoder, and QR codes on a phone screen are an easy
case. Compared with the earlier B, the `camera` plugin removes the hardest part, the camera preview
in Kotlin.

How sure I am: fairly sure. The one thing a test on the PC cannot show is decoding quality on
real photos. That needs your phone test.

## 3. Plan for the fix (option B1)

1. **Dependencies:**
   - `pubspec.yaml`: remove `mobile_scanner`; add `camera`, pinned exactly to the version `pub get`
     picks today.
   - `android/app/build.gradle.kts`: add `implementation("com.google.zxing:core:3.5.3")`.
   - Check the whole `pubspec.lock`, not just the direct dependencies, for every package on the
     `CLAUDE.md` blocked list.
2. **Kotlin:**
   - New `BarcodeChannelHandler.kt` (`barcode/` package), registered in `MainActivity`.
     - `decodeImageFile`: checks the path is a readable file and refuses files above a size limit;
       decodes a downscaled bitmap. Never throws across the channel: errors return a typed error
       code.
     - `decodeLuminance`: checks that the byte length matches `rowStride × height` before using it,
       because it is untrusted input from the platform.
   - Decoding runs on a background thread, never the main thread.
3. **Dart:**
   - `ZxingImageDecoder` (channel-backed) replaces `MobileScannerImageDecoder`.
   - New `PairingQrScanner` widget (`lib/widgets/sync/`), using `camera` + the channel, replaces
     `MobileScanner` in `sync_send_screen.dart`.
   - The camera is released when the screen pauses or closes, as today.
4. **Manifest:**
   - After one build, read the merged manifest.
   - Remove anything `camera` adds that the app does not need (it may add `RECORD_AUDIO`), with
     `tools:node="remove"`.
   - The list must match `docs/security.md` §11. If something cannot be removed, I stop and ask
     you.
5. **Tests:**
   - Channel-decoder tests with a fake channel (format mapping, errors, "found nothing" vs
     "failed").
   - Widget test of the pairing scanner's "first good code wins" and error panel, with a fake
     camera.
   - A source test that `android/app/build.gradle.kts` has no `mlkit` or `gms` dependency, and that
     `pubspec.yaml` has no `mobile_scanner`.
   - `test/tool/dependency_policy_test.dart`: `pubspec.lock` holds no blocked package (`http`,
     `dio`, `firebase*`, `google_mlkit*`, `supabase*`, `connectivity*`). This would have caught
     option A at once.
   - The Kotlin decoding itself cannot run in `flutter test`. It is checked by your phone test.
6. **Docs:**
   - `docs/dependencies.md`: remove `mobile_scanner`; add `camera`, `camera_android_camerax` and
     ZXing core, each with license and reason.
   - `docs/security.md`: §1.1 third-party line → `verified`; §3.1; §20; §11 if the manifest
     changes.
   - `docs/known_gaps.md`: G47 resolved.

## 4. Files to change

`pubspec.yaml`, `pubspec.lock`, `android/app/build.gradle.kts`,
new `android/app/src/main/kotlin/in/sreerajp/imgvidgal/barcode/BarcodeChannelHandler.kt`,
`android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt`,
`android/app/src/main/AndroidManifest.xml` (only if step 4 finds extras),
`lib/core/constants/app_constants.dart` (channel name, limits),
`lib/services/scan/image_scan_service.dart`, `lib/providers/scan_providers.dart`,
new `lib/services/scan/barcode_channel.dart`, new `lib/widgets/sync/pairing_qr_scanner.dart`,
`lib/screens/sync/sync_send_screen.dart`, tests listed above, `docs/dependencies.md`,
`docs/security.md`, `docs/known_gaps.md`.

## 5. How it will be checked

- `flutter pub get`, `dart format`, `flutter analyze`, `flutter test`.
- **One Android build, which you run** (it compiles the Kotlin and the new Gradle dependency):
  - read the merged manifest's permissions;
  - check that `gradlew :app:dependencies` has no `mlkit` or `gms`;
  - stop the Gradle daemons afterwards.
- **On a phone, also you:**
  - scan a QR code and an EAN barcode from a saved photo;
  - pair two phones by camera;
  - deny the camera and check that typing the code still works.

## 6. Risks

- **ZXing Java may miss a few damaged codes** that ML Kit read. Only a phone test shows this.
- **More of our own code** (about 150 lines of Kotlin and 150 of Dart) than option A would have
  needed. In return, there is no forked or single-maintainer package.
- **Frames from `camera` arrive as YUV.** Only the Y plane is sent, and only one frame at a time.
  If decoding is slow on old phones, the scanner checks fewer frames per second; it does not
  stall.
