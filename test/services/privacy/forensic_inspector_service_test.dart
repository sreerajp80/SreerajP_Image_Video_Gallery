import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/services/privacy/forensic_inspector_service.dart';

void main() {
  const service = ForensicInspectorService();

  group('ForensicInspectorService', () {
    test('handles empty or corrupt byte inputs gracefully', () async {
      final emptyResult = await service.inspectBytes(Uint8List(0));
      expect(emptyResult.hasForensicData, isFalse);

      final shortResult = await service.inspectBytes(
        Uint8List.fromList([1, 2, 3, 4]),
      );
      expect(shortResult.hasForensicData, isFalse);
    });

    test(
      'extracts optical metrics, crop factor, and sensor classification',
      () {
        final image = img.Image(width: 16, height: 16);
        img.fill(image, color: img.ColorRgb8(100, 150, 200));

        final exif = img.ExifData();
        final subExif = exif.exifIfd;

        // Lens: 35mm actual, 52.5mm in 35mm film equiv -> 1.5x crop (APS-C)
        subExif.data[0x920A] = img.IfdValueRational(35, 1); // FocalLength
        subExif.data[0xA405] = img.IfdValueShort(53); // FocalLengthIn35mmFilm
        subExif.data[0x829D] = img.IfdValueRational(28, 10); // f/2.8
        subExif.data[0x9204] = img.IfdValueRational(
          7,
          10,
        ); // ExposureBias +0.7 EV
        subExif.data[0xA001] = img.IfdValueShort(1); // ColorSpace: sRGB
        subExif.data[0xA431] = img.IfdValueAscii(
          'BODY-SERIAL-998822',
        ); // BodySerialNumber
        subExif.data[0xA434] = img.IfdValueAscii(
          'FE 35mm F1.4 GM',
        ); // LensModel

        image.exif = exif;
        final jpgBytes = Uint8List.fromList(img.encodeJpg(image));
        final forensic = service.inspectBytesSync(jpgBytes);

        expect(forensic.physicalFocalLength, 35.0);
        expect(forensic.focalLength35mm, 53.0);
        expect(forensic.cropFactor, closeTo(1.51, 0.05));
        expect(forensic.sensorFormat, contains('APS-C'));
        expect(forensic.exposureBiasString, '+0.7 EV');
        expect(forensic.colorProfile, 'sRGB');
        expect(forensic.bodySerialNumber, 'BODY-SERIAL-998822');
        expect(forensic.lensModel, 'FE 35mm F1.4 GM');
        expect(forensic.hyperfocalDistanceMeters, isNotNull);
        expect(forensic.hyperfocalDistanceMeters!, greaterThan(0));
      },
    );

    test('classifies Full Frame sensors when crop factor is ~1.0x', () {
      final image = img.Image(width: 16, height: 16);
      final exif = img.ExifData();
      final subExif = exif.exifIfd;

      // 50mm actual, 50mm in 35mm film -> 1.0x Full Frame
      subExif.data[0x920A] = img.IfdValueRational(50, 1);
      subExif.data[0xA405] = img.IfdValueShort(50);
      subExif.data[0x829D] = img.IfdValueRational(18, 10); // f/1.8

      image.exif = exif;
      final jpgBytes = Uint8List.fromList(img.encodeJpg(image));
      final forensic = service.inspectBytesSync(jpgBytes);

      expect(forensic.cropFactor, 1.0);
      expect(forensic.sensorFormat, 'Full Frame (35mm)');
    });

    test('formats zero and negative exposure compensation correctly', () {
      final image = img.Image(width: 8, height: 8);
      final exif = img.ExifData();
      final subExif = exif.exifIfd;

      subExif.data[0x9204] = img.IfdValueRational(-10, 10); // -1.0 EV
      image.exif = exif;
      final bytesNeg = Uint8List.fromList(img.encodeJpg(image));
      final forensicNeg = service.inspectBytesSync(bytesNeg);
      expect(forensicNeg.exposureBiasString, '-1.0 EV');

      subExif.data[0x9204] = img.IfdValueRational(0, 10); // 0 EV
      image.exif = exif;
      final bytesZero = Uint8List.fromList(img.encodeJpg(image));
      final forensicZero = service.inspectBytesSync(bytesZero);
      expect(forensicZero.exposureBiasString, '0 EV');
    });
  });
}
