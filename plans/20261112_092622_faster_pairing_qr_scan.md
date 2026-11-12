# Plan: Make the pairing QR scan focus and read faster

**Status:** completed

## The issue

On the pairing scan the user has to move the phone up and down before the
preview gets sharp. When it is sharp, it still takes a while to read the code.

Two causes were found in the code:

1. **Low camera resolution.** `PairingQrScanner` defaults to
   `ResolutionPreset.medium`. On Android (CameraX) that is at most 720x480.
   At this size the QR is too small to read from a normal distance. So the
   user holds the phone close, and close range is where phone cameras focus
   slowest. Focus mode itself is fine: CameraX already uses continuous
   auto-focus by default. There is no way to ask it to focus again.
2. **Heavy decoding on every live frame.** `BarcodeChannelHandler.decodeAll()`
   runs every camera frame through `GenericMultipleBarcodeReader` with
   `TRY_HARDER`. Both are meant for still photos. `TRY_HARDER` scans more rows
   of the image. The multiple-code reader searches the picture again around a
   code it already found. `QrFrameGate` drops new frames while one decode is
   running, so a slow decode means fewer sharp frames get checked.

## Files to change

- `lib/widgets/sync/pairing_qr_scanner.dart`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/barcode/BarcodeChannelHandler.kt`
- `test/widgets/sync/pairing_qr_scanner_test.dart`

## The fix

1. **Higher default resolution.** Change the default in `PairingQrScanner`
   from `ResolutionPreset.medium` to `ResolutionPreset.high` (1280x720). Update
   the doc comment. The QR becomes readable from a normal distance (about
   20–30 cm), where focus is quick. All three callers (`sync_send_screen.dart`,
   `qr_sync_send_screen.dart`, `qr_sync_receive_screen.dart`) then use `high`.
   The receive screen already did.
2. **Tap to focus again.** Wrap the preview in a `GestureDetector`. A tap
   calls `setFocusPoint` and `setExposurePoint` at the centre of the frame,
   where the user aims the code. Errors are caught and logged at debug level
   (some cameras have no focus control). The tap uses the centre, not the
   tapped spot. Mapping a tap through the cropped, rotated preview is easy to
   get wrong. The centre is where the code is anyway. No new text is added.
3. **Lighter live decode.** In `decodeLuminance` only, use a single
   `QRCodeReader` (QR only, no `TRY_HARDER`, no multiple-code reader). Make
   one reader in the handler and reuse it. This is safe because decoding runs
   on one worker thread. `decodeImageFile` (still photos) keeps the full,
   thorough decode. The channel API and the Dart side stay the same.
4. **Tests.** Add a widget test that checks the scanner's default resolution
   is `high`. The tests for `QrFrameGate` and `BarcodeChannel` stay as they
   are.

## Downsides (honest)

- A 720p frame has about 2.7 times the pixels of 480p, so each decode is
  bigger. The lighter decode should more than make up for this, but it is not
  measured. Please check on a real phone.
- Without `TRY_HARDER`, a very poor frame (tilted, low light) may be missed.
  The next frame comes within about 30–100 ms, so this costs little.
- It uses a bit more battery while the pairing screen is open.

## Security impact

The camera and the decoder are touched. No new permission, package or
network use. Camera bytes are still checked against their size before they
are read. Pairing codes are still checked by the screen before they are
accepted.

## Checks

`dart format .`, `flutter analyze`, `flutter test`, then a manual scan on a
real phone with the dev flavor.
