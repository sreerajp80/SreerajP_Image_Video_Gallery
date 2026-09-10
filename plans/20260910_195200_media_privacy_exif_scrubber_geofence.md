# Plan: Media Privacy, EXIF Scrubber & Geofence Shifting

**Status:** Completed

## Summary

Implement the three privacy and optical metadata features described in Section 3.9 of the specifications:

1. **One-Tap EXIF Metadata Stripper** — Cleanly strip GPS coordinates, camera serial numbers, lens specifications, and date stamps before sharing or exporting. Provides both instant lossless stripping (without pixel re-encoding) and granular scrubbing controls, with direct integration to Android's offline system share sheet and gallery publishing.
2. **GPS Geofence Shifter (Location Fuzzing)** — An innovative privacy tool that adds a randomized 2–5 km offset to embedded GPS coordinates within the same city or region. Protects home and exact street addresses while keeping regional travel context intact.
3. **Forensic Lens & Sensor Inspector** — Detailed metadata inspector displaying sensor crop factor, focal length 35mm equivalent, shutter actuation count, exposure bias, and color profile for enthusiast photographers and archivists.

## Files to Change

### New Files
- `lib/models/privacy/privacy_scrub_options.dart` — Granular configuration for EXIF metadata stripping.
- `lib/models/privacy/gps_fuzz_result.dart` — Data model for fuzzed coordinates, offset distance, and compass heading.
- `lib/models/privacy/forensic_metadata.dart` — Deep technical metadata model (crop factor, sensor format, 35mm equiv, exposure bias, shutter count, hyperfocal distance, color profile).
- `lib/services/privacy/exif_scrubber_service.dart` — Lossless byte-level EXIF stripper for JPEG, PNG, and WebP, plus selective tag scrubbers.
- `lib/services/privacy/gps_geofence_service.dart` — Mathematical geodesy calculations for randomized 2–5 km location fuzzing and bearing detection.
- `lib/services/privacy/forensic_inspector_service.dart` — Deep optical and sensor forensic analysis engine.
- `lib/services/platform/share_service.dart` — Safe offline platform bridge to Android system share sheet.
- `lib/providers/privacy_providers.dart` — Riverpod providers for scrubber, geofence fuzzer, forensic inspector, and share services.
- `lib/widgets/privacy/media_privacy_sheet.dart` — Bottom sheet providing One-Tap Stripper and GPS Geofence Shifter.
- `lib/widgets/privacy/forensic_inspector_sheet.dart` — Comprehensive forensic dashboard modal sheet.
- `android/app/src/main/res/xml/provider_paths.xml` — Secure file provider paths for offline sharing.
- `test/services/privacy/exif_scrubber_service_test.dart` — Automated tests for lossless stripping and selective sanitization.
- `test/services/privacy/gps_geofence_service_test.dart` — Automated tests for 2–5 km distance bounds and geodesy calculations.
- `test/services/privacy/forensic_inspector_service_test.dart` — Automated tests for crop factor, 35mm equiv, exposure bias, and hyperfocal metrics.

### Modified Files
- `android/app/src/main/AndroidManifest.xml` — Register `FileProvider` for safe offline file sharing.
- `android/app/src/main/kotlin/in/sreerajp/imgvidgal/tools/IntentChannelHandler.kt` — Add `shareFile` method using `ACTION_SEND` intent.
- `lib/widgets/viewer/media_details_sheet.dart` — Integrate Forensic Inspector summary card and Media Privacy launch buttons.
- `lib/screens/viewer/media_viewer_screen.dart` — Add Privacy & EXIF Scrubber to the viewer overflow menu and share actions.
- `lib/l10n/app_en.arb` — Add user-visible English strings for privacy scrubber, geofence shifter, and forensic inspector.
- `lib/l10n/app_ml.arb` — Add user-visible Malayalam strings.

## Issue

Photos taken on mobile devices and cameras embed sensitive metadata including exact home GPS coordinates, camera/lens serial numbers, and personal timestamps. When sharing media, users unknowingly leak private locations. Additionally, the gallery lacks advanced optical forensics (sensor crop factor, 35mm equivalent focal length, exposure bias, shutter actuation count, color profiles) desired by photography enthusiasts.

## Fix

1. Build a pure Dart lossless EXIF scrubber that strips metadata segments without recompressing image pixels, preserving 100% original image quality while eliminating location and device fingerprints.
2. Build a GPS geofence shifter using spherical geodesy to offset embedded coordinates by 2–5 km in a randomized direction, allowing safe public sharing while keeping general travel context.
3. Build a forensic lens and sensor inspector computing crop factors, 35mm equivalents, exposure bias, hyperfocal distances, and color spaces.
4. Integrate native offline sharing via Android's `FileProvider` and `ACTION_SEND` without adding any third-party network or closed-source libraries.
5. Surface these controls seamlessly in the fullscreen viewer and media details sheet with full English and Malayalam localization.
