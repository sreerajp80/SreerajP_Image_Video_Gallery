import 'package:flutter/foundation.dart';

/// Deep forensic optical, hardware, and sensor metadata for a media item.
@immutable
class ForensicMetadata {
  /// Sensor crop factor relative to 35mm full frame (e.g. 1.0 for FF, 1.5 for APS-C, 2.0 for MFT).
  final double? cropFactor;

  /// Human-readable sensor format name (e.g. "Full Frame (1.0x)", "APS-C (1.5x)").
  final String? sensorFormat;

  /// Focal length in 35mm equivalent millimeters (e.g. 24 mm, 50 mm, 85 mm).
  final double? focalLength35mm;

  /// Physical focal length of the optical lens in millimeters (e.g. 6.9 mm, 35 mm).
  final double? physicalFocalLength;

  /// Estimated or calculated hyperfocal distance in meters.
  final double? hyperfocalDistanceMeters;

  /// Shutter actuation (lifetime release) count reported by camera hardware MakerNotes.
  final int? shutterActuations;

  /// Exposure bias / exposure compensation in EV units (e.g. 0.0, +0.7, -1.3).
  final double? exposureBias;

  /// Formatted exposure compensation string (e.g. "+0.7 EV", "0 EV").
  final String? exposureBiasString;

  /// Color profile / space name (e.g. "sRGB", "Display P3", "Adobe RGB (1998)").
  final String? colorProfile;

  /// Camera body serial number if embedded by hardware.
  final String? bodySerialNumber;

  /// Lens model name.
  final String? lensModel;

  /// Lens manufacturer / make.
  final String? lensMake;

  /// Lens serial number.
  final String? lensSerialNumber;

  /// Lens specification range (e.g. "24-70mm f/2.8").
  final String? lensSpecification;

  /// Exposure program (e.g. "Manual", "Aperture priority", "Shutter priority").
  final String? exposureProgram;

  /// Metering mode (e.g. "Spot", "Multi-segment", "Center-weighted").
  final String? meteringMode;

  /// Image sensor method (e.g. "One-chip color area sensor").
  final String? sensingMethod;

  /// Scene capture type (e.g. "Standard", "Landscape", "Portrait", "Night").
  final String? sceneCaptureType;

  /// Light source or white balance preset.
  final String? lightSource;

  /// Digital zoom magnification ratio (1.0 = none).
  final double? digitalZoomRatio;

  /// Detailed flash status including strobe return light detection.
  final String? flashDetails;

  const ForensicMetadata({
    this.cropFactor,
    this.sensorFormat,
    this.focalLength35mm,
    this.physicalFocalLength,
    this.hyperfocalDistanceMeters,
    this.shutterActuations,
    this.exposureBias,
    this.exposureBiasString,
    this.colorProfile,
    this.bodySerialNumber,
    this.lensModel,
    this.lensMake,
    this.lensSerialNumber,
    this.lensSpecification,
    this.exposureProgram,
    this.meteringMode,
    this.sensingMethod,
    this.sceneCaptureType,
    this.lightSource,
    this.digitalZoomRatio,
    this.flashDetails,
  });

  /// Whether any high-value forensic metrics are available.
  bool get hasForensicData =>
      cropFactor != null ||
      focalLength35mm != null ||
      shutterActuations != null ||
      exposureBias != null ||
      colorProfile != null ||
      bodySerialNumber != null ||
      lensSerialNumber != null ||
      lensSpecification != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForensicMetadata &&
          runtimeType == other.runtimeType &&
          cropFactor == other.cropFactor &&
          sensorFormat == other.sensorFormat &&
          focalLength35mm == other.focalLength35mm &&
          physicalFocalLength == other.physicalFocalLength &&
          hyperfocalDistanceMeters == other.hyperfocalDistanceMeters &&
          shutterActuations == other.shutterActuations &&
          exposureBias == other.exposureBias &&
          exposureBiasString == other.exposureBiasString &&
          colorProfile == other.colorProfile &&
          bodySerialNumber == other.bodySerialNumber &&
          lensModel == other.lensModel &&
          lensMake == other.lensMake &&
          lensSerialNumber == other.lensSerialNumber &&
          lensSpecification == other.lensSpecification &&
          exposureProgram == other.exposureProgram &&
          meteringMode == other.meteringMode &&
          sensingMethod == other.sensingMethod &&
          sceneCaptureType == other.sceneCaptureType &&
          lightSource == other.lightSource &&
          digitalZoomRatio == other.digitalZoomRatio &&
          flashDetails == other.flashDetails;

  @override
  int get hashCode => Object.hashAll([
    cropFactor,
    sensorFormat,
    focalLength35mm,
    physicalFocalLength,
    hyperfocalDistanceMeters,
    shutterActuations,
    exposureBias,
    exposureBiasString,
    colorProfile,
    bodySerialNumber,
    lensModel,
    lensMake,
    lensSerialNumber,
    lensSpecification,
    exposureProgram,
    meteringMode,
    sensingMethod,
    sceneCaptureType,
    lightSource,
    digitalZoomRatio,
    flashDetails,
  ]);
}
