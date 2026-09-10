import 'package:flutter/foundation.dart';

/// The result of applying a GPS geofence shift (location fuzzing) to coordinates.
@immutable
class GpsFuzzResult {
  /// The un-fuzzed, original latitude in decimal degrees.
  final double originalLatitude;

  /// The un-fuzzed, original longitude in decimal degrees.
  final double originalLongitude;

  /// The shifted/fuzzed latitude in decimal degrees.
  final double fuzzedLatitude;

  /// The shifted/fuzzed longitude in decimal degrees.
  final double fuzzedLongitude;

  /// The offset distance in kilometers (e.g. 3.45 km).
  final double offsetDistanceKm;

  /// The bearing in degrees (0° = North, 90° = East, 180° = South, 270° = West).
  final double bearingDegrees;

  /// Human-readable cardinal compass direction (e.g. "NE", "North-East").
  final String cardinalDirection;

  const GpsFuzzResult({
    required this.originalLatitude,
    required this.originalLongitude,
    required this.fuzzedLatitude,
    required this.fuzzedLongitude,
    required this.offsetDistanceKm,
    required this.bearingDegrees,
    required this.cardinalDirection,
  });

  /// Short summary string describing the displacement.
  String get summary =>
      '${offsetDistanceKm.toStringAsFixed(1)} km $cardinalDirection';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GpsFuzzResult &&
          runtimeType == other.runtimeType &&
          originalLatitude == other.originalLatitude &&
          originalLongitude == other.originalLongitude &&
          fuzzedLatitude == other.fuzzedLatitude &&
          fuzzedLongitude == other.fuzzedLongitude &&
          offsetDistanceKm == other.offsetDistanceKm &&
          bearingDegrees == other.bearingDegrees &&
          cardinalDirection == other.cardinalDirection;

  @override
  int get hashCode => Object.hash(
    originalLatitude,
    originalLongitude,
    fuzzedLatitude,
    fuzzedLongitude,
    offsetDistanceKm,
    bearingDegrees,
    cardinalDirection,
  );
}
