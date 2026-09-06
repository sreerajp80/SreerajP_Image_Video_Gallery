import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/services/media/exif_reader_service.dart';

/// Builds a tiny JPEG carrying the EXIF tags the details drawer shows.
///
/// Encoding a real file and reading it back is what makes this a genuine test
/// of the parser rather than of a hand-made structure.
Uint8List _jpegWithExif({bool withGps = true}) {
  final image = img.Image(width: 8, height: 8);
  final exif = image.exif;

  exif.imageIfd.make = 'TestCam';
  exif.imageIfd.model = 'Model X';
  exif.imageIfd.software = 'GalleryTest';

  exif.exifIfd[0x829A] = img.IfdValueRational(1, 250); // exposure time
  exif.exifIfd[0x829D] = img.IfdValueRational(18, 10); // f/1.8
  exif.exifIfd[0x8827] = img.IfdValueShort(400); // ISO
  exif.exifIfd[0x920A] = img.IfdValueRational(24, 1); // focal length
  exif.exifIfd[0x9209] = img.IfdValueShort(1); // flash fired
  exif.exifIfd[0xA403] = img.IfdValueShort(0); // auto white balance
  exif.exifIfd[0x9207] = img.IfdValueShort(5); // pattern metering
  exif.exifIfd[0xA001] = img.IfdValueShort(1); // sRGB
  exif.exifIfd[0x9003] = img.IfdValueAscii('2026:08:29 14:05:09');

  if (withGps) {
    exif.gpsIfd.setGpsLocation(latitude: 10.5, longitude: -76.25);
  }

  return img.encodeJpg(image);
}

void main() {
  const service = ExifReaderService();

  group('parseBytes', () {
    test('reads the camera, lens settings, and capture date', () {
      final data = service.parseBytes(_jpegWithExif());

      expect(data, isNotNull);
      expect(data!.make, 'TestCam');
      expect(data.model, 'Model X');
      expect(data.software, 'GalleryTest');
      expect(data.iso, 400);
      expect(data.fNumber, closeTo(1.8, 0.001));
      expect(data.focalLength, closeTo(24, 0.001));
      expect(data.exposureTime, '1/250s');
      expect(data.flash, 'Flash fired');
      expect(data.whiteBalance, 'Auto');
      expect(data.meteringMode, 'Pattern');
      expect(data.colorSpace, 'sRGB');
      expect(data.dateTimeOriginal, DateTime(2026, 8, 29, 14, 5, 9));
    });

    test('reads GPS coordinates, keeping the hemisphere sign', () {
      final data = service.parseBytes(_jpegWithExif());

      expect(data!.latitude, closeTo(10.5, 0.0001));
      expect(data.longitude, closeTo(-76.25, 0.0001));
    });

    test('returns null for bytes that are not an image', () {
      final junk = Uint8List.fromList(List<int>.generate(512, (i) => i % 256));
      expect(service.parseBytes(junk), isNull);
    });

    test('never throws on a truncated file', () {
      // EXIF sits at the front of a JPEG, so a file cut short may still yield
      // metadata. What matters is that a broken file never throws: the caller
      // gets either data or null.
      final full = _jpegWithExif();
      for (final keep in <int>[100, full.length ~/ 3, full.length - 8]) {
        final truncated = Uint8List.sublistView(full, 0, keep);
        expect(() => service.parseBytes(truncated), returnsNormally);
      }
    });

    test('returns null when the metadata block itself is cut off', () {
      final full = _jpegWithExif();
      final truncated = Uint8List.sublistView(full, 0, 40);
      expect(service.parseBytes(truncated), isNull);
    });

    test('returns null for an empty file', () {
      expect(service.parseBytes(Uint8List(0)), isNull);
    });
  });

  group('read', () {
    test('parses a small file without spawning an isolate', () async {
      final data = await service.read(_jpegWithExif());
      expect(data?.make, 'TestCam');
    });

    test('skips a file that is too small to hold any metadata', () async {
      expect(await service.read(Uint8List(10)), isNull);
    });
  });
}
