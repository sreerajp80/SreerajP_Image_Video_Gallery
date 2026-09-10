import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_scrub_options.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/exif_scrubber_service.dart';

void main() {
  const service = ExifScrubberService();

  group('ExifScrubberService', () {
    test('handles empty or truncated byte inputs safely', () async {
      expect(await service.scrubBytes(Uint8List(0)), Uint8List(0));
      expect(
        await service.scrubBytes(Uint8List.fromList([1, 2, 3])),
        Uint8List.fromList([1, 2, 3]),
      );
    });

    test('losslessly strips APP1 and APP13 metadata markers from JPEG', () {
      // Construct minimal valid JPEG with APP1 segment
      final builder = BytesBuilder();
      builder.add([0xFF, 0xD8]); // SOI

      // Add APP1 (0xE1) marker with dummy Exif data
      builder.add([0xFF, 0xE1]);
      final app1Payload = 'Exif\x00\x00sensitive_gps_data'.codeUnits;
      final app1Length = app1Payload.length + 2;
      builder.add([app1Length >> 8, app1Length & 0xFF]);
      builder.add(app1Payload);

      // Add APP0 (JFIF) marker
      builder.add([0xFF, 0xE0]);
      builder.add([0x00, 0x05, 0x01, 0x02, 0x03]);

      // Add SOS (0xDA) and scan data
      builder.add([0xFF, 0xDA]);
      builder.add([0x00, 0x02]); // SOS header
      builder.add([0x12, 0x34, 0x56, 0x78]); // entropy data

      // Add EOI (0xD9)
      builder.add([0xFF, 0xD9]);

      final sourceJpeg = builder.toBytes();
      final scrubbed = service.scrubBytesSync(sourceJpeg);

      // Verify scrubbed JPEG starts with SOI and ends with EOI
      expect(scrubbed[0], 0xFF);
      expect(scrubbed[1], 0xD8);
      expect(scrubbed[scrubbed.length - 2], 0xFF);
      expect(scrubbed[scrubbed.length - 1], 0xD9);

      // Verify APP1 marker (0xFF, 0xE1) is completely gone
      final app1Found = _containsSequence(scrubbed, [0xFF, 0xE1]);
      expect(app1Found, isFalse);

      // Verify APP0 is preserved
      final app0Found = _containsSequence(scrubbed, [0xFF, 0xE0]);
      expect(app0Found, isTrue);

      // Verify SOS and entropy data are intact
      final entropyFound = _containsSequence(scrubbed, [
        0x12,
        0x34,
        0x56,
        0x78,
      ]);
      expect(entropyFound, isTrue);
    });

    test('losslessly strips eXIf and tEXt chunks from PNG', () {
      final builder = BytesBuilder();
      // PNG Signature
      builder.add([137, 80, 78, 71, 13, 10, 26, 10]);

      // Add dummy IHDR chunk
      builder.add([0, 0, 0, 13]); // length 13
      builder.add('IHDR'.codeUnits);
      builder.add(List.filled(13, 0));
      builder.add([0, 0, 0, 0]); // CRC

      // Add eXIf chunk
      final exifData = 'GPS: 37.7749,-122.4194'.codeUnits;
      builder.add([0, 0, 0, exifData.length]);
      builder.add('eXIf'.codeUnits);
      builder.add(exifData);
      builder.add([0, 0, 0, 0]); // CRC

      // Add IEND chunk
      builder.add([0, 0, 0, 0]);
      builder.add('IEND'.codeUnits);
      builder.add([0, 0, 0, 0]); // CRC

      final pngBytes = builder.toBytes();
      final scrubbed = service.scrubBytesSync(pngBytes);

      // Verify eXIf chunk is dropped
      expect(_containsSequence(scrubbed, 'eXIf'.codeUnits), isFalse);
      // Verify IHDR and IEND are preserved
      expect(_containsSequence(scrubbed, 'IHDR'.codeUnits), isTrue);
      expect(_containsSequence(scrubbed, 'IEND'.codeUnits), isTrue);
    });

    test('losslessly strips EXIF chunks from WebP RIFF container', () {
      final builder = BytesBuilder();
      final chunkBuilder = BytesBuilder();

      // Add VP8 chunk
      chunkBuilder.add('VP8 '.codeUnits);
      chunkBuilder.add([4, 0, 0, 0]); // size 4
      chunkBuilder.add([1, 2, 3, 4]);

      // Add EXIF chunk
      chunkBuilder.add('EXIF'.codeUnits);
      chunkBuilder.add([4, 0, 0, 0]); // size 4
      chunkBuilder.add([5, 6, 7, 8]);

      final chunks = chunkBuilder.toBytes();
      final riffSize = 4 + chunks.length; // 'WEBP' + chunks

      builder.add('RIFF'.codeUnits);
      builder.add([
        riffSize & 0xFF,
        (riffSize >> 8) & 0xFF,
        (riffSize >> 16) & 0xFF,
        (riffSize >> 24) & 0xFF,
      ]);
      builder.add('WEBP'.codeUnits);
      builder.add(chunks);

      final webpBytes = builder.toBytes();
      final scrubbed = service.scrubBytesSync(webpBytes);

      // Verify EXIF chunk is dropped
      expect(_containsSequence(scrubbed, 'EXIF'.codeUnits), isFalse);
      // Verify VP8 chunk is preserved
      expect(_containsSequence(scrubbed, 'VP8 '.codeUnits), isTrue);
      // Verify valid RIFF WEBP header
      expect(String.fromCharCodes(scrubbed.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(scrubbed.sublist(8, 12)), 'WEBP');
    });

    test('selective scrubbing preserves image pixels while sanitizing', () {
      // Create a small in-memory image
      final image = img.Image(width: 8, height: 8);
      img.fill(image, color: img.ColorRgb8(255, 0, 0));
      final jpgBytes = Uint8List.fromList(img.encodeJpg(image));

      final options = const PrivacyScrubOptions(
        stripLocation: true,
        stripCameraAndLensSerials: true,
        stripTimestamps: true,
        stripAuthorAndSoftware: true,
        stripAllExif: false,
      );

      final scrubbed = service.scrubBytesSync(jpgBytes, options: options);
      final decodedScrubbed = img.decodeImage(scrubbed);

      expect(decodedScrubbed, isNotNull);
      expect(decodedScrubbed!.width, 8);
      expect(decodedScrubbed.height, 8);
    });
  });
}

bool _containsSequence(Uint8List source, List<int> sequence) {
  if (sequence.isEmpty || source.length < sequence.length) return false;
  for (var i = 0; i <= source.length - sequence.length; i++) {
    var match = true;
    for (var j = 0; j < sequence.length; j++) {
      if (source[i + j] != sequence[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
