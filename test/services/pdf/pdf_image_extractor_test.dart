import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';
import 'package:in_sreerajp_imgvidgal/services/pdf/pdf_image_extractor.dart';

import 'pdf_test_files.dart';

const _extractor = PdfImageExtractor();

Uint8List _bytes(String source) => Uint8List.fromList(latin1.encode(source));

void main() {
  group('whole-file refusals', () {
    test('a file that is not a PDF is refused', () {
      final result = _extractor.extract(_bytes('hello, I am a text file'));
      expect(result.isRefused, isTrue);
      expect(result.refusal, PdfRefusalReason.notAPdf);
    });

    test('an empty file is refused', () {
      expect(
        _extractor.extract(Uint8List(0)).refusal,
        PdfRefusalReason.notAPdf,
      );
    });

    test('a PDF with a header but no objects is refused as unreadable', () {
      expect(
        _extractor.extract(_bytes('%PDF-1.7\n%%EOF\n')).refusal,
        PdfRefusalReason.unreadable,
      );
    });

    // An encrypted file is refused rather than opened with the empty owner
    // password, which most readers would quietly do.
    test('an encrypted file is refused, and no image comes out', () {
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 1 /Height 1 '
            '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /DCTDecode',
        stream: PdfTestFiles.tinyJpeg(),
        encrypted: true,
      );

      final result = _extractor.extract(file);
      expect(result.refusal, PdfRefusalReason.encrypted);
      expect(result.entries, isEmpty);
    });
  });

  group('JPEG images are copied straight out', () {
    test('the bytes come back byte for byte, as a jpg', () {
      final jpeg = PdfTestFiles.tinyJpeg();
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 1 /Height 1 '
            '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /DCTDecode',
        stream: jpeg,
      );

      final result = _extractor.extract(file);
      expect(result.isRefused, isFalse);
      expect(result.extractable, hasLength(1));

      final entry = result.extractable.single;
      expect(entry.format, PdfImageFormat.jpeg);
      expect(entry.bytes, jpeg);
      expect(entry.suggestedFileName, endsWith('.jpg'));
      expect(entry.width, 1);
      expect(entry.height, 1);
    });

    test('a filter written as an array is read', () {
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 1 /Height 1 '
            '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter [/DCTDecode]',
        stream: PdfTestFiles.tinyJpeg(),
      );
      expect(_extractor.extract(file).extractable, hasLength(1));
    });

    test('a JPEG that was then zipped is unzipped first', () {
      final jpeg = PdfTestFiles.tinyJpeg();
      final zipped = Uint8List.fromList(ZLibEncoder().convert(jpeg));

      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 1 /Height 1 '
            '/BitsPerComponent 8 /ColorSpace /DeviceRGB '
            '/Filter [/FlateDecode /DCTDecode]',
        stream: zipped,
      );

      final entry = _extractor.extract(file).extractable.single;
      expect(entry.format, PdfImageFormat.jpeg);
      expect(entry.bytes, jpeg);
    });
  });

  group('zipped pixels are re-encoded as PNG', () {
    test('an RGB image comes out as a readable PNG of the right size', () {
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 4 /Height 3 '
            '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /FlateDecode',
        stream: PdfTestFiles.flateRgb(4, 3),
      );

      final entry = _extractor.extract(file).extractable.single;
      expect(entry.format, PdfImageFormat.png);
      expect(entry.suggestedFileName, endsWith('.png'));

      final decoded = img.decodePng(entry.bytes!);
      expect(decoded, isNotNull);
      expect(decoded!.width, 4);
      expect(decoded.height, 3);

      final pixel = decoded.getPixel(0, 0);
      expect(pixel.r, 200);
      expect(pixel.g, 100);
      expect(pixel.b, 50);
    });

    test('a grey image comes out as grey pixels', () {
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
            '/BitsPerComponent 8 /ColorSpace /DeviceGray /Filter /FlateDecode',
        stream: PdfTestFiles.flateGray(2, 2),
      );

      final entry = _extractor.extract(file).extractable.single;
      final decoded = img.decodePng(entry.bytes!);
      expect(decoded!.getPixel(1, 1).r, 128);
    });

    test('an ICCBased colour space with three components is read as RGB', () {
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
            '/BitsPerComponent 8 /ColorSpace [/ICCBased 8 0 R] '
            '/Filter /FlateDecode',
        stream: PdfTestFiles.flateRgb(2, 2),
      );

      // The profile object the colour space points at.
      final withProfile = Uint8List.fromList(<int>[
        ...file,
        ...latin1.encode('8 0 obj\n<< /N 3 >>\nendobj\n'),
      ]);

      expect(_extractor.extract(withProfile).extractable, hasLength(1));
    });

    test('unzipped raw pixels are read too', () {
      final pixels = Uint8List.fromList(List<int>.filled(2 * 2 * 3, 77));
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
            '/BitsPerComponent 8 /ColorSpace /DeviceRGB',
        stream: pixels,
      );

      final entry = _extractor.extract(file).extractable.single;
      expect(img.decodePng(entry.bytes!)!.getPixel(0, 0).r, 77);
    });
  });

  group('images that cannot be extracted are still listed', () {
    PdfImageEntry firstEntry(String dictionary, List<int> stream) {
      final result = _extractor.extract(
        PdfTestFiles.withImage(dictionary: dictionary, stream: stream),
      );
      expect(result.entries, hasLength(1));
      return result.entries.single;
    }

    test('an unsupported filter is named, not silently dropped', () {
      for (final filter in <String>[
        'JPXDecode',
        'JBIG2Decode',
        'CCITTFaxDecode',
        'LZWDecode',
        'RunLengthDecode',
      ]) {
        final entry = firstEntry(
          '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
          '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /$filter',
          <int>[1, 2, 3, 4],
        );
        expect(entry.isExtractable, isFalse, reason: filter);
        expect(entry.skipReason, PdfImageSkipReason.unsupportedFilter);
        expect(entry.filter, filter);
      }
    });

    test('an unsupported colour space is named', () {
      final entry = firstEntry(
        '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
        '/BitsPerComponent 8 /ColorSpace /DeviceCMYK /Filter /FlateDecode',
        PdfTestFiles.flateRgb(2, 2),
      );
      expect(entry.skipReason, PdfImageSkipReason.unsupportedColorSpace);
      expect(entry.colorSpace, 'DeviceCMYK');
    });

    test('a bit depth other than eight is skipped', () {
      final entry = firstEntry(
        '/Type /XObject /Subtype /Image /Width 8 /Height 8 '
        '/BitsPerComponent 1 /ColorSpace /DeviceGray /Filter /FlateDecode',
        PdfTestFiles.flateGray(8, 8),
      );
      expect(entry.skipReason, PdfImageSkipReason.unsupportedBitDepth);
    });

    test('an image with no size is skipped as malformed', () {
      final entry = firstEntry(
        '/Type /XObject /Subtype /Image /BitsPerComponent 8 '
        '/ColorSpace /DeviceRGB /Filter /FlateDecode',
        PdfTestFiles.flateRgb(2, 2),
      );
      expect(entry.skipReason, PdfImageSkipReason.malformed);
    });

    test('a stream too short for the size it claims is malformed', () {
      final entry = firstEntry(
        '/Type /XObject /Subtype /Image /Width 100 /Height 100 '
        '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /FlateDecode',
        PdfTestFiles.flateRgb(2, 2),
      );
      expect(entry.skipReason, PdfImageSkipReason.malformed);
    });

    test('bytes that are not really zipped fail to decode, not to crash', () {
      final entry = firstEntry(
        '/Type /XObject /Subtype /Image /Width 2 /Height 2 '
        '/BitsPerComponent 8 /ColorSpace /DeviceRGB /Filter /FlateDecode',
        <int>[0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x11],
      );
      expect(entry.skipReason, PdfImageSkipReason.decodeFailed);
    });
  });

  group('caps hold against a hostile file', () {
    test('a declared pixel count past the cap allocates nothing', () {
      // 100000 x 100000 is ten billion pixels. The claim is refused on sight.
      final file = PdfTestFiles.withImage(
        dictionary:
            '/Type /XObject /Subtype /Image /Width 100000 '
            '/Height 100000 /BitsPerComponent 8 /ColorSpace /DeviceRGB '
            '/Filter /FlateDecode',
        stream: <int>[1, 2, 3],
      );

      final entry = _extractor.extract(file).entries.single;
      expect(entry.skipReason, PdfImageSkipReason.tooLarge);
    });

    test('a file past the size cap is refused before it is parsed', () {
      final huge = Uint8List(AppConstants.pdfExtractMaxFileBytes + 1);
      expect(_extractor.extract(huge).refusal, PdfRefusalReason.fileTooLarge);
    });
  });

  group('several images', () {
    test('each image object is found, in file order', () {
      final builder = BytesBuilder();
      builder.add(latin1.encode('%PDF-1.7\n'));

      for (var number = 1; number <= 3; number++) {
        builder.add(
          latin1.encode(
            '$number 0 obj\n<< /Type /XObject /Subtype /Image /Width 2 '
            '/Height 2 /BitsPerComponent 8 /ColorSpace /DeviceGray '
            '/Filter /FlateDecode /Length ${PdfTestFiles.flateGray(2, 2).length} '
            '>>\nstream\n',
          ),
        );
        builder.add(PdfTestFiles.flateGray(2, 2));
        builder.add(latin1.encode('\nendstream\nendobj\n'));
      }
      builder.add(latin1.encode('trailer\n<< /Size 4 >>\n%%EOF\n'));

      final result = _extractor.extract(builder.toBytes());
      expect(result.entries, hasLength(3));
      expect(result.extractable, hasLength(3));
      expect(result.entries.map((entry) => entry.objectNumber), <int>[1, 2, 3]);
    });

    test('a PDF with no images at all reads clean and empty', () {
      final file = _bytes(
        '%PDF-1.7\n1 0 obj\n<< /Type /Catalog >>\nendobj\n'
        'trailer\n<< /Root 1 0 R >>\n%%EOF\n',
      );

      final result = _extractor.extract(file);
      expect(result.isRefused, isFalse);
      expect(result.isEmpty, isTrue);
    });

    test('a non-image stream is passed over', () {
      final file = PdfTestFiles.withImage(
        dictionary: '/Type /XObject /Subtype /Form',
        stream: <int>[1, 2, 3],
      );
      expect(_extractor.extract(file).entries, isEmpty);
    });
  });

  test('random bytes with a PDF header never throw', () {
    final random = Uint8List.fromList(<int>[
      ...latin1.encode('%PDF-1.7\n'),
      ...List<int>.generate(8192, (index) => (index * 91) % 256),
    ]);
    expect(() => _extractor.extract(random), returnsNormally);
  });
}
