import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/services/privacy/gps_geofence_service.dart';

void main() {
  final service = GpsGeofenceService();

  group('GpsGeofenceService', () {
    test('calculates randomized fuzz within specified 2-5 km bounds', () {
      const originalLat = 9.9312; // Kochi, Kerala
      const originalLon = 76.2673;

      for (var i = 0; i < 20; i++) {
        final result = service.calculateFuzz(
          latitude: originalLat,
          longitude: originalLon,
          minDistanceKm: 2.0,
          maxDistanceKm: 5.0,
        );

        // Verify distance falls within 2.0 and 5.0 km
        expect(result.offsetDistanceKm, greaterThanOrEqualTo(2.0));
        expect(result.offsetDistanceKm, lessThanOrEqualTo(5.0));

        // Verify bearing falls within 0 and 360 degrees
        expect(result.bearingDegrees, greaterThanOrEqualTo(0.0));
        expect(result.bearingDegrees, lessThan(360.0));

        // Verify coordinates changed
        expect(result.fuzzedLatitude, isNot(equals(originalLat)));
        expect(result.fuzzedLongitude, isNot(equals(originalLon)));

        // Verify actual haversine distance matches the result's offsetDistanceKm
        final actualDist = service.distanceBetweenKm(
          lat1: originalLat,
          lon1: originalLon,
          lat2: result.fuzzedLatitude,
          lon2: result.fuzzedLongitude,
        );
        expect(actualDist, closeTo(result.offsetDistanceKm, 0.05));
      }
    });

    test('deterministic offset with fixed distance and bearing', () {
      const lat = 37.7749; // San Francisco
      const lon = -122.4194;
      const distance = 4.0;
      const bearing = 90.0; // Due East

      final result = service.calculateFuzz(
        latitude: lat,
        longitude: lon,
        fixedDistanceKm: distance,
        fixedBearingDegrees: bearing,
      );

      expect(result.cardinalDirection, 'East');
      expect(result.offsetDistanceKm, distance);
      expect(result.bearingDegrees, bearing);

      // Traveling east from (37.7749, -122.4194) increases longitude, keeps latitude almost same
      expect(result.fuzzedLatitude, closeTo(lat, 0.01));
      expect(result.fuzzedLongitude, greaterThan(lon));

      final dist = service.distanceBetweenKm(
        lat1: lat,
        lon1: lon,
        lat2: result.fuzzedLatitude,
        lon2: result.fuzzedLongitude,
      );
      expect(dist, closeTo(distance, 0.01));
    });

    test('cardinal compass direction mappings', () {
      expect(service.getCardinalDirection(0), 'North');
      expect(service.getCardinalDirection(45), 'North-East');
      expect(service.getCardinalDirection(90), 'East');
      expect(service.getCardinalDirection(135), 'South-East');
      expect(service.getCardinalDirection(180), 'South');
      expect(service.getCardinalDirection(225), 'South-West');
      expect(service.getCardinalDirection(270), 'West');
      expect(service.getCardinalDirection(315), 'North-West');
      expect(service.getCardinalDirection(360), 'North');
    });

    test('writes updated GPS coordinates into image bytes', () {
      final image = img.Image(width: 16, height: 16);
      img.fill(image, color: img.ColorRgb8(0, 128, 255));
      final jpgBytes = img.encodeJpg(image);

      final fuzz = service.calculateFuzz(
        latitude: 10.0,
        longitude: 20.0,
        fixedDistanceKm: 3.0,
        fixedBearingDegrees: 45.0,
      );

      final updatedBytes = service.applyFuzzToImageBytes(
        bytes: jpgBytes,
        fuzzResult: fuzz,
      );

      expect(updatedBytes, isNotEmpty);
      final decodedExif = img.decodeJpgExif(updatedBytes);
      expect(decodedExif, isNotNull);
      expect(!decodedExif!.gpsIfd.isEmpty, isTrue);
    });
  });
}
