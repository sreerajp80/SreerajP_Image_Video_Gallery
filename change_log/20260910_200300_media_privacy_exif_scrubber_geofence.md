# Media Privacy, EXIF Scrubber, GPS Geofence Shifter & Forensic Inspector

**Plan:** `plans/20260910_195200_media_privacy_exif_scrubber_geofence.md`

## What changed

Implemented Section 3.9 features from `docs/feature_improvements_and_standout_features.md`:

1. **One-Tap EXIF Metadata Stripper**
   - Built a lossless pure Dart byte-stream metadata stripper for JPEG, PNG, and WebP in `ExifScrubberService`.
   - Strips APP1 (EXIF, XMP), APP13 (Photoshop/IPTC), and COM comment markers from JPEG without re-encoding image pixels, preserving APP2 ICC profiles.
   - Strips ancillary chunks (`eXIf`, `tEXt`, `zTXt`, `iTXt`) from PNG files and `EXIF`/`XMP ` RIFF chunks from WebP files.
   - Added selective tag redaction for granular sanitization (GPS only, camera serials, lens specs, timestamps, user comments).
   - Added `PrivacyScrubOptions` model supporting full, location-only, and balanced sanitization presets.

2. **GPS Geofence Shifter (Location Fuzzing)**
   - Created `GpsGeofenceService` implementing spherical geodesy (haversine formulas) to calculate randomized 2–5 km (or 1–10 km configurable) geographic offsets.
   - Calculates true bearing and cardinal compass direction (N, NE, E, SE, S, SW, W, NW).
   - Generates non-destructive fuzzed images rewriting EXIF GPS IFD tags (`GPSLatitudeRef`, `GPSLatitude`, `GPSLongitudeRef`, `GPSLongitude`, `GPSDateStamp`, `GPSTimeStamp`).
   - Added live preview card showing original vs fuzzed coordinates, displacement distance, bearing direction, and fuzz radius.

3. **Forensic Lens & Sensor Inspector**
   - Created `ForensicInspectorService` analyzing optical, sensor, shutter, exposure, and hardware serial metadata tags.
   - Calculates 35mm equivalent focal length and sensor crop factor.
   - Classifies sensor formats (Full Frame, APS-C, Micro Four Thirds, 1-inch, Medium Format, Smartphone).
   - Calculates hyperfocal distance and formats signed rational exposure bias values (EV).
   - Parses shutter actuation release counts from MakerNote tags.
   - Built `ForensicInspectorSheet` displaying organized cards for optics, sensor, shutter & color, and hardware identifiers.

4. **UI Integration & Sharing Workflows**
   - Created `MediaPrivacySheet` modal bottom sheet with tabbed interface:
     - Privacy Audit banner analyzing active privacy risks (GPS, serials, timestamps).
     - One-Tap EXIF Stripper tab with "Strip & Share" and "Save to Gallery" actions.
     - GPS Geofence Shifter tab with fuzz radius selector chips, live coordinate preview card, "Fuzz & Share", and "Save to Gallery".
   - Integrated privacy action button in fullscreen viewer top bar (`Icons.shield_outlined`) and overflow popup menu.
   - Added "Media Privacy & EXIF" summary card and "Inspect Lens & Sensor Forensics" button in `MediaDetailsSheet`.
   - Added native offline file sharing via `ShareService` and Android `FileProvider` (`ACTION_SEND`).

5. **Localization**
   - Added complete English (`app_en.arb`) and Malayalam (`app_ml.arb`) localizations for all new privacy, geofence, and forensic inspection strings.

## Files changed

### New Files
- `lib/models/privacy/privacy_scrub_options.dart`
- `lib/models/privacy/gps_fuzz_result.dart`
- `lib/models/privacy/forensic_metadata.dart`
- `lib/services/privacy/exif_scrubber_service.dart`
- `lib/services/privacy/gps_geofence_service.dart`
- `lib/services/privacy/forensic_inspector_service.dart`
- `lib/services/platform/share_service.dart`
- `lib/providers/privacy_providers.dart`
- `lib/widgets/privacy/media_privacy_sheet.dart`
- `lib/widgets/privacy/forensic_inspector_sheet.dart`
- `android/app/src/main/res/xml/provider_paths.xml`
- `test/services/privacy/exif_scrubber_service_test.dart`
- `test/services/privacy/gps_geofence_service_test.dart`
- `test/services/privacy/forensic_inspector_service_test.dart`

### Modified Files
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt`
- `lib/screens/viewer/media_viewer_screen.dart`
- `lib/widgets/viewer/media_details_sheet.dart`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_ml.arb`
- `docs/feature_improvements_and_standout_features.md`

## Verification

- `flutter analyze`: 0 issues found across all files.
- `flutter test test/services/privacy/`: 13 privacy unit tests passed.
- `flutter test`: 1893 total tests passed.
- `dart format .`: all files cleanly formatted.
