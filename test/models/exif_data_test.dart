import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';

void main() {
  group('ExifData Domain Model', () {
    final testExif = ExifData(
      make: 'Sony',
      model: 'ILCE-7M4',
      lensModel: 'FE 24-70mm F2.8 GM',
      focalLength: 50.0,
      fNumber: 2.8,
      iso: 400,
      exposureTime: '1/500s',
      flash: 'No flash',
      whiteBalance: 'Auto',
      meteringMode: 'Pattern',
      latitude: 10.0261,
      longitude: 76.3125,
      altitude: 15.4,
      dateTimeOriginal: DateTime(2026, 8, 29, 9, 0, 0),
      software: 'v2.00',
      colorSpace: 'sRGB',
    );

    test('supports value equality', () {
      final duplicate = ExifData(
        make: 'Sony',
        model: 'ILCE-7M4',
        lensModel: 'FE 24-70mm F2.8 GM',
        focalLength: 50.0,
        fNumber: 2.8,
        iso: 400,
        exposureTime: '1/500s',
        flash: 'No flash',
        whiteBalance: 'Auto',
        meteringMode: 'Pattern',
        latitude: 10.0261,
        longitude: 76.3125,
        altitude: 15.4,
        dateTimeOriginal: DateTime(2026, 8, 29, 9, 0, 0),
        software: 'v2.00',
        colorSpace: 'sRGB',
      );

      expect(testExif, equals(duplicate));
      expect(testExif.hashCode, equals(duplicate.hashCode));
    });

    test('copyWith creates modified instance correctly', () {
      final modified = testExif.copyWith(iso: 800, model: 'ILCE-7RM5');
      expect(modified.iso, 800);
      expect(modified.model, 'ILCE-7RM5');
      expect(modified.make, 'Sony');
    });

    test('serialization roundtrip via toMap and fromMap', () {
      final map = testExif.toMap();
      final fromMap = ExifData.fromMap(map);
      expect(fromMap, equals(testExif));
    });

    test('toSearchableText concatenates non-empty attributes', () {
      final searchable = testExif.toSearchableText();
      expect(searchable, contains('Sony'));
      expect(searchable, contains('ILCE-7M4'));
      expect(searchable, contains('FE 24-70mm F2.8 GM'));
    });
  });
}
