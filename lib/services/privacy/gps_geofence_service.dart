import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/privacy/gps_fuzz_result.dart';

/// Service providing mathematical geodesy and GPS geofence shifting (location fuzzing).
///
/// Shifts embedded GPS coordinates by a randomized 2 to 5 km offset in a
/// random direction. This preserves regional geographic context (e.g. city or
/// district) while masking exact residential street addresses.
class GpsGeofenceService {
  /// Mean radius of Earth in kilometers.
  static const double earthRadiusKm = 6371.0088;

  final math.Random _random;

  GpsGeofenceService({math.Random? random}) : _random = random ?? math.Random();

  /// Calculates a randomized GPS shift for the given [latitude] and [longitude].
  ///
  /// The displacement [minDistanceKm] to [maxDistanceKm] defaults to 2.0–5.0 km.
  /// Generates a random bearing (0°–360°) and calculates the destination coordinate.
  GpsFuzzResult calculateFuzz({
    required double latitude,
    required double longitude,
    double minDistanceKm = 2.0,
    double maxDistanceKm = 5.0,
    double? fixedDistanceKm,
    double? fixedBearingDegrees,
  }) {
    final distanceKm =
        fixedDistanceKm ??
        (minDistanceKm +
            _random.nextDouble() * (maxDistanceKm - minDistanceKm));

    final bearingDeg = fixedBearingDegrees ?? (_random.nextDouble() * 360.0);
    final bearingRad = _toRadians(bearingDeg);

    final lat1Rad = _toRadians(latitude);
    final lon1Rad = _toRadians(longitude);
    final angularDistance = distanceKm / earthRadiusKm;

    final sinLat1 = math.sin(lat1Rad);
    final cosLat1 = math.cos(lat1Rad);
    final sinAngular = math.sin(angularDistance);
    final cosAngular = math.cos(angularDistance);

    final lat2Rad = math.asin(
      sinLat1 * cosAngular + cosLat1 * sinAngular * math.cos(bearingRad),
    );

    final lon2Rad =
        lon1Rad +
        math.atan2(
          math.sin(bearingRad) * sinAngular * cosLat1,
          cosAngular - sinLat1 * math.sin(lat2Rad),
        );

    final fuzzedLat = _toDegrees(lat2Rad);
    // Normalize longitude between -180 and +180
    final fuzzedLon = (_toDegrees(lon2Rad) + 540) % 360 - 180;

    final cardinal = getCardinalDirection(bearingDeg);

    return GpsFuzzResult(
      originalLatitude: latitude,
      originalLongitude: longitude,
      fuzzedLatitude: fuzzedLat,
      fuzzedLongitude: fuzzedLon,
      offsetDistanceKm: distanceKm,
      bearingDegrees: bearingDeg,
      cardinalDirection: cardinal,
    );
  }

  /// Calculates the great-circle Haversine distance between two coordinates in km.
  double distanceBetweenKm({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Converts a bearing in degrees to an 8-point compass cardinal direction.
  String getCardinalDirection(double bearingDegrees) {
    final normalized = (bearingDegrees % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'North';
    if (normalized < 67.5) return 'North-East';
    if (normalized < 112.5) return 'East';
    if (normalized < 157.5) return 'South-East';
    if (normalized < 202.5) return 'South';
    if (normalized < 247.5) return 'South-West';
    if (normalized < 292.5) return 'West';
    return 'North-West';
  }

  /// Short 2-letter compass code (e.g. "NE", "SW").
  String getCardinalCode(double bearingDegrees) {
    final normalized = (bearingDegrees % 360 + 360) % 360;
    if (normalized >= 337.5 || normalized < 22.5) return 'N';
    if (normalized < 67.5) return 'NE';
    if (normalized < 112.5) return 'E';
    if (normalized < 157.5) return 'SE';
    if (normalized < 202.5) return 'S';
    if (normalized < 247.5) return 'SW';
    if (normalized < 292.5) return 'W';
    return 'NW';
  }

  /// Modifies image [bytes] to overwrite the GPS EXIF tags with [fuzzResult].
  ///
  /// Returns the updated image bytes with fuzzed GPS coordinates embedded.
  Uint8List applyFuzzToImageBytes({
    required Uint8List bytes,
    required GpsFuzzResult fuzzResult,
  }) {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      final exif = img.decodeJpgExif(bytes) ?? img.ExifData();
      exif.gpsIfd.setGpsLocation(
        latitude: fuzzResult.fuzzedLatitude,
        longitude: fuzzResult.fuzzedLongitude,
      );

      decoded.exif = exif;
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 92));
    } catch (_) {
      return bytes;
    }
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
  double _toDegrees(double radians) => radians * (180.0 / math.pi);
}
