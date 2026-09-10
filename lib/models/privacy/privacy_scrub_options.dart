import 'package:flutter/foundation.dart';

/// Configuration options controlling what EXIF and metadata to strip from media.
@immutable
class PrivacyScrubOptions {
  /// Strip GPS coordinates, altitude, and location timestamps.
  final bool stripLocation;

  /// Strip camera body serial number, lens serial number, and hardware IDs.
  final bool stripCameraAndLensSerials;

  /// Strip capture date, digitization date, and timestamp offset headers.
  final bool stripTimestamps;

  /// Strip software name, processing tool, artist, and copyright tags.
  final bool stripAuthorAndSoftware;

  /// Completely remove all EXIF, XMP, and IPTC segments.
  final bool stripAllExif;

  const PrivacyScrubOptions({
    this.stripLocation = true,
    this.stripCameraAndLensSerials = true,
    this.stripTimestamps = true,
    this.stripAuthorAndSoftware = true,
    this.stripAllExif = true,
  });

  /// Preset that scrubs every trace of metadata for maximum privacy.
  static const PrivacyScrubOptions fullScrub = PrivacyScrubOptions(
    stripLocation: true,
    stripCameraAndLensSerials: true,
    stripTimestamps: true,
    stripAuthorAndSoftware: true,
    stripAllExif: true,
  );

  /// Preset that removes location coordinates while preserving camera specs and date.
  static const PrivacyScrubOptions locationOnly = PrivacyScrubOptions(
    stripLocation: true,
    stripCameraAndLensSerials: false,
    stripTimestamps: false,
    stripAuthorAndSoftware: false,
    stripAllExif: false,
  );

  /// Preset that removes hardware serial numbers and location while keeping camera model.
  static const PrivacyScrubOptions privacyBalanced = PrivacyScrubOptions(
    stripLocation: true,
    stripCameraAndLensSerials: true,
    stripTimestamps: false,
    stripAuthorAndSoftware: true,
    stripAllExif: false,
  );

  PrivacyScrubOptions copyWith({
    bool? stripLocation,
    bool? stripCameraAndLensSerials,
    bool? stripTimestamps,
    bool? stripAuthorAndSoftware,
    bool? stripAllExif,
  }) {
    return PrivacyScrubOptions(
      stripLocation: stripLocation ?? this.stripLocation,
      stripCameraAndLensSerials:
          stripCameraAndLensSerials ?? this.stripCameraAndLensSerials,
      stripTimestamps: stripTimestamps ?? this.stripTimestamps,
      stripAuthorAndSoftware:
          stripAuthorAndSoftware ?? this.stripAuthorAndSoftware,
      stripAllExif: stripAllExif ?? this.stripAllExif,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrivacyScrubOptions &&
          runtimeType == other.runtimeType &&
          stripLocation == other.stripLocation &&
          stripCameraAndLensSerials == other.stripCameraAndLensSerials &&
          stripTimestamps == other.stripTimestamps &&
          stripAuthorAndSoftware == other.stripAuthorAndSoftware &&
          stripAllExif == other.stripAllExif;

  @override
  int get hashCode => Object.hash(
    stripLocation,
    stripCameraAndLensSerials,
    stripTimestamps,
    stripAuthorAndSoftware,
    stripAllExif,
  );
}
