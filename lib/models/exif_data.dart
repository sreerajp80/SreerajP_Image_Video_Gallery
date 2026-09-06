import 'package:flutter/foundation.dart';

/// Immutable domain model representing parsed EXIF / media metadata.
@immutable
class ExifData {
  /// Camera manufacturer (e.g. "Canon", "Sony", "Google").
  final String? make;

  /// Camera or device model (e.g. "Pixel 8 Pro", "ILCE-7M4").
  final String? model;

  /// Lens model name.
  final String? lensModel;

  /// Focal length in millimeters.
  final double? focalLength;

  /// Aperture F-number (e.g. 1.8, 2.8).
  final double? fNumber;

  /// ISO sensitivity rating.
  final int? iso;

  /// Shutter exposure time string (e.g. "1/250s").
  final String? exposureTime;

  /// Flash state description (e.g. "Flash fired", "No flash").
  final String? flash;

  /// White balance setting (e.g. "Auto", "Manual").
  final String? whiteBalance;

  /// Metering mode (e.g. "Pattern", "Center-weighted average").
  final String? meteringMode;

  /// GPS latitude in decimal degrees.
  final double? latitude;

  /// GPS longitude in decimal degrees.
  final double? longitude;

  /// GPS altitude in meters.
  final double? altitude;

  /// Original date/time the media was captured according to EXIF headers.
  final DateTime? dateTimeOriginal;

  /// Software or firmware version that processed the image.
  final String? software;

  /// Color space (e.g. "sRGB", "Display P3").
  final String? colorSpace;

  const ExifData({
    this.make,
    this.model,
    this.lensModel,
    this.focalLength,
    this.fNumber,
    this.iso,
    this.exposureTime,
    this.flash,
    this.whiteBalance,
    this.meteringMode,
    this.latitude,
    this.longitude,
    this.altitude,
    this.dateTimeOriginal,
    this.software,
    this.colorSpace,
  });

  /// Creates a copy of [ExifData] with the given fields replaced.
  ExifData copyWith({
    String? make,
    String? model,
    String? lensModel,
    double? focalLength,
    double? fNumber,
    int? iso,
    String? exposureTime,
    String? flash,
    String? whiteBalance,
    String? meteringMode,
    double? latitude,
    double? longitude,
    double? altitude,
    DateTime? dateTimeOriginal,
    String? software,
    String? colorSpace,
  }) {
    return ExifData(
      make: make ?? this.make,
      model: model ?? this.model,
      lensModel: lensModel ?? this.lensModel,
      focalLength: focalLength ?? this.focalLength,
      fNumber: fNumber ?? this.fNumber,
      iso: iso ?? this.iso,
      exposureTime: exposureTime ?? this.exposureTime,
      flash: flash ?? this.flash,
      whiteBalance: whiteBalance ?? this.whiteBalance,
      meteringMode: meteringMode ?? this.meteringMode,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      dateTimeOriginal: dateTimeOriginal ?? this.dateTimeOriginal,
      software: software ?? this.software,
      colorSpace: colorSpace ?? this.colorSpace,
    );
  }

  /// Converts this [ExifData] to a JSON-compatible map.
  Map<String, dynamic> toMap() {
    return {
      'make': make,
      'model': model,
      'lensModel': lensModel,
      'focalLength': focalLength,
      'fNumber': fNumber,
      'iso': iso,
      'exposureTime': exposureTime,
      'flash': flash,
      'whiteBalance': whiteBalance,
      'meteringMode': meteringMode,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'dateTimeOriginal': dateTimeOriginal?.toIso8601String(),
      'software': software,
      'colorSpace': colorSpace,
    };
  }

  /// Constructs an [ExifData] instance from a map.
  factory ExifData.fromMap(Map<String, dynamic> map) {
    return ExifData(
      make: map['make'] as String?,
      model: map['model'] as String?,
      lensModel: map['lensModel'] as String?,
      focalLength: (map['focalLength'] as num?)?.toDouble(),
      fNumber: (map['fNumber'] as num?)?.toDouble(),
      iso: map['iso'] as int?,
      exposureTime: map['exposureTime'] as String?,
      flash: map['flash'] as String?,
      whiteBalance: map['whiteBalance'] as String?,
      meteringMode: map['meteringMode'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      dateTimeOriginal: map['dateTimeOriginal'] != null
          ? DateTime.tryParse(map['dateTimeOriginal'] as String)
          : null,
      software: map['software'] as String?,
      colorSpace: map['colorSpace'] as String?,
    );
  }

  /// Generates a unified searchable string representing the EXIF camera/device metadata.
  String toSearchableText() {
    final tokens = <String>[];
    if (make != null && make!.isNotEmpty) tokens.add(make!);
    if (model != null && model!.isNotEmpty) tokens.add(model!);
    if (lensModel != null && lensModel!.isNotEmpty) tokens.add(lensModel!);
    if (software != null && software!.isNotEmpty) tokens.add(software!);
    return tokens.join(' ');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExifData &&
          runtimeType == other.runtimeType &&
          make == other.make &&
          model == other.model &&
          lensModel == other.lensModel &&
          focalLength == other.focalLength &&
          fNumber == other.fNumber &&
          iso == other.iso &&
          exposureTime == other.exposureTime &&
          flash == other.flash &&
          whiteBalance == other.whiteBalance &&
          meteringMode == other.meteringMode &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          altitude == other.altitude &&
          dateTimeOriginal == other.dateTimeOriginal &&
          software == other.software &&
          colorSpace == other.colorSpace;

  @override
  int get hashCode => Object.hash(
    make,
    model,
    lensModel,
    focalLength,
    fNumber,
    iso,
    exposureTime,
    flash,
    whiteBalance,
    meteringMode,
    latitude,
    longitude,
    altitude,
    dateTimeOriginal,
    software,
    colorSpace,
  );
}
