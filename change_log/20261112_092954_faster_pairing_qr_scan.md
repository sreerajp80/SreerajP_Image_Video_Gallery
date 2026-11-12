# Change log: Make the pairing QR scan focus and read faster

Implements plan: `plans/20261112_092622_faster_pairing_qr_scan.md`

## What changed

- `lib/widgets/sync/pairing_qr_scanner.dart`
  - The default camera resolution is now `ResolutionPreset.high` (1280x720)
    instead of `medium` (720x480). A pairing code can now be read from a
    normal distance, where the camera focuses quickly.
  - A tap on the preview asks the camera to focus and set exposure again at
    the centre of the frame. If the camera has no focus control, this is
    logged at debug level and nothing else happens.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/barcode/BarcodeChannelHandler.kt`
  - Live camera frames (`decodeLuminance`) now use one reused `QRCodeReader`:
    QR only, no `TRY_HARDER`, no search for more codes. Any `ReaderException`
    (not found, checksum, format) means "no code in this frame".
  - Still pictures (`decodeImageFile`) keep the full, thorough decode.
  - The `QR_ONLY` list is removed because nothing uses it now.
  - The size checks on camera bytes are unchanged.
- `lib/screens/sync/qr_sync_receive_screen.dart` (not in the plan's file
  list): removed `resolution: ResolutionPreset.high` and the `camera` import.
  The value is now the default, and `flutter analyze` reported it as
  redundant. The behaviour is the same.
- `test/widgets/sync/pairing_qr_scanner_test.dart`: a new test checks that the
  default resolution is `high`.

## Checks

- `dart format`: no changes.
- `flutter analyze`: no issues.
- `flutter test`: all tests pass.
- Not done yet: a Kotlin compile (Gradle build) and a manual scan on a real
  phone.
