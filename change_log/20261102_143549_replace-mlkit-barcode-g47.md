# Change log — replace the closed-source ML Kit barcode reader (G47)

**Plan:** [plans/20261102_142047_replace-mlkit-barcode-g47.md](../plans/20261102_142047_replace-mlkit-barcode-g47.md) (option B1)
**Date:** 2026-11-02

`mobile_scanner` read codes with Google ML Kit on Android, which is a closed-source binary (hard
rule 1). It is gone:
- codes are now read by **ZXing core** (Apache-2.0) in Kotlin;
- the pairing camera uses the official **`camera`** plugin (CameraX).

The app no longer contains any closed-source library, and it gains no network code.

---

## What happened along the way

- **Option A (`flutter_zxing`) was approved first, then stopped at `flutter pub get`.**
  - It pulled the blocked `http` package in through `image_picker`.
  - The owner then asked what `http` was for there. The answer: only the web build of
    `image_picker_platform_interface` uses it (`http.readBytes`), so it never runs on Android.
  - `flutter_zxing` also has its own `readBarcodeImageUrl`, which fetches over the network.
  - Under the owner's rule "no unnecessary internet", option B1 was chosen and approved.
- `pubspec.yaml` and `pubspec.lock` were restored exactly, checked byte for byte, before B1 began.

## What changed

**Dependencies**
- `pubspec.yaml`: `mobile_scanner` removed, `camera: 0.12.2` added and pinned exactly.
- The lock file gained:
  - `camera`, `camera_android_camerax`, `camera_avfoundation`, `camera_platform_interface`,
    `camera_web`;
  - `cross_file`, `stream_transform`.
- The **whole** lock file was checked: there is no blocked package anywhere.
- `android/app/build.gradle.kts`: new `dependencies` block with
  `implementation("com.google.zxing:core:3.5.3")`.

**Kotlin**
- New `barcode/BarcodeChannelHandler.kt`, registered and disposed in `MainActivity`, on channel
  `in.sreerajp.imgvidgal/barcode`.
- `decodeImageFile(path)` reads every common format from a still picture:
  - it checks that the file is readable and refuses anything over 64 MB;
  - it decodes a bitmap scaled to at most 2,000 px;
  - it uses ZXing's multiple-barcode reader.
- `decodeLuminance(bytes, width, height, rowStride)` reads QR codes in one camera frame's
  brightness plane. The sizes are checked against the byte length before any byte is read.
- All decoding runs on one background thread. Failures come back as error codes (`unreadable`,
  `too_large`, `decode_failed`, `invalid_arguments`) and are never thrown.

**Dart**
- New `lib/services/scan/barcode_channel.dart`:
  - `BarcodeChannel`, which turns ZXing's `QR_CODE` into `qrCode` and drops malformed entries;
  - `BarcodeDecodeException`, under `FeatureException`.
- `ZxingImageDecoder` replaces `MobileScannerImageDecoder` behind the same `BarcodeImageDecoder`
  interface. `ImageScanService` and everything above it did not change.
- New `barcodeChannelProvider` in `scan_providers.dart`.
- New `lib/widgets/sync/pairing_qr_scanner.dart`:
  - `PairingQrScanner` owns the camera, with `enableAudio: false`, the YUV format and the back
    lens;
  - it releases the camera when the app goes to the background or the widget leaves the screen;
  - `QrFrameGate` decodes one frame at a time, drops frames while busy, and stops at the first
    code the screen accepts.
- `sync_send_screen.dart`:
  - uses `PairingQrScanner`, and `_onCode` returns whether the code was a pairing code;
  - the manual start/stop calls are gone, because the camera goes with the widget when the user
    switches to typing;
  - the error panel and the "type the code" fallback are unchanged.

**Manifest**
- `RECORD_AUDIO` and `WRITE_EXTERNAL_STORAGE`, which the camera plugin adds, are removed with
  `tools:node="remove"`.
- The plugin's `camera.any` feature is marked not required, so phones without a camera can still
  install the app.
- The app's own permission list (11) is unchanged.

**Tests**
- New `test/services/scan/barcode_channel_test.dart`: format mapping, malformed entries, empty
  result, typed errors, frame arguments.
- New `test/widgets/sync/pairing_qr_scanner_test.dart`: the frame gate (first code wins, busy
  frames dropped, failures skipped), and the error panel with no camera or a camera error.
- New `test/tool/dependency_policy_test.dart`. It fails on:
  - any blocked package anywhere in `pubspec.lock`;
  - `mobile_scanner` in `pubspec.yaml`;
  - ML Kit, Play Services or Firebase in the Gradle file;
  - any remote-fetch API in `lib/` (`NetworkAssetBundle`, `NetworkImage`, `Image.network`,
    `HttpClient(`, `readBarcodeImageUrl`).

  The last check was added while the work was done. It turns "no unnecessary internet" into a test.

**Docs**
- `docs/dependencies.md`: the `camera` row; a new Android libraries table (ZXing); and why
  `mobile_scanner` was removed and `flutter_zxing` rejected.
- `docs/architecture.md`: the plugins line and the `barcode` channel row.
- `docs/security.md`: §1.1 third-party line → `verified`; §11 notes the removed camera permissions.
- `docs/release_process.md`: the 16 KB check list.
- `docs/implementation_progress.md`: a note on the old Phase 12 item.
- `docs/known_gaps.md`: G47 resolved; 21 gaps open, 5 of them release blockers.

## Files

**Created:**
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/barcode/BarcodeChannelHandler.kt`
- `lib/services/scan/barcode_channel.dart`
- `lib/widgets/sync/pairing_qr_scanner.dart`
- the three test files above

**Changed:**
- Build: `pubspec.yaml`, `pubspec.lock`, `android/app/build.gradle.kts`,
  `android/app/src/main/AndroidManifest.xml`,
  `android/app/src/main/kotlin/in/sreerajp/imgvidgal/MainActivity.kt`
- Code: `lib/core/constants/app_constants.dart`, `lib/services/scan/image_scan_service.dart`,
  `lib/providers/scan_providers.dart`, `lib/screens/sync/sync_send_screen.dart`
- The six docs listed above

## Check results

- `flutter pub get`: clean. No blocked package anywhere in `pubspec.lock`.
- `dart format --set-exit-if-changed lib test`: 553 files, 0 changed.
- `flutter analyze`: no issues.
- `flutter test`: all 2,058 tests pass (2,042 before; 16 new).

**Not checked:**
- **No Android build was run.** The Kotlin handler, the ZXing Gradle dependency and the manifest
  changes have not been compiled, and the merged manifest has not been read.
- On a phone:
  - reading a QR code and an EAN barcode from a saved photo;
  - pairing two phones by camera;
  - refusing the camera and typing the code.
- Decoding quality compared with ML Kit.
- APK size change.
