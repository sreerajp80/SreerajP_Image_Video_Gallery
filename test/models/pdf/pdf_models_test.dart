import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_image_entry.dart';

PdfImageEntry _usable(int number) => PdfImageEntry(
  objectNumber: number,
  width: 10,
  height: 20,
  bytes: Uint8List.fromList(<int>[1, 2, 3]),
  format: PdfImageFormat.png,
);

const _skipped = PdfImageEntry.skipped(
  objectNumber: 99,
  width: 5,
  height: 5,
  reason: PdfImageSkipReason.unsupportedFilter,
);

void main() {
  group('PdfImageFormat', () {
    test('each format names its extension and type', () {
      expect(PdfImageFormat.jpeg.extension, 'jpg');
      expect(PdfImageFormat.jpeg.mimeType, 'image/jpeg');
      expect(PdfImageFormat.png.extension, 'png');
      expect(PdfImageFormat.png.mimeType, 'image/png');
    });
  });

  group('PdfImageEntry', () {
    test('an entry with bytes can be extracted', () {
      final entry = _usable(4);
      expect(entry.isExtractable, isTrue);
      expect(entry.byteCount, 3);
      expect(entry.skipReason, isNull);
    });

    test('a skipped entry has no bytes and carries its reason', () {
      expect(_skipped.isExtractable, isFalse);
      expect(_skipped.byteCount, 0);
      expect(_skipped.skipReason, PdfImageSkipReason.unsupportedFilter);
    });

    test('an entry with empty bytes is not extractable', () {
      final empty = PdfImageEntry(
        objectNumber: 1,
        width: 1,
        height: 1,
        bytes: Uint8List(0),
      );
      expect(empty.isExtractable, isFalse);
    });

    test('the suggested name uses the object number and format', () {
      expect(_usable(7).suggestedFileName, 'pdf_image_7.png');
      expect(
        _usable(7).copyWith(format: PdfImageFormat.jpeg).suggestedFileName,
        'pdf_image_7.jpg',
      );
    });

    test('equality covers the size and the reason', () {
      expect(_usable(1), _usable(1));
      expect(_usable(1), isNot(_usable(2)));
      expect(_usable(1), isNot(_usable(1).copyWith(width: 11)));
    });
  });

  group('PdfExtractionResult', () {
    final result = PdfExtractionResult(
      entries: <PdfImageEntry>[_usable(1), _skipped, _usable(2)],
    );

    test('extractable and skipped split the entries', () {
      expect(result.extractable, hasLength(2));
      expect(result.skipped, hasLength(1));
      expect(result.entries, hasLength(3));
    });

    test('a read file is not refused', () {
      expect(result.isRefused, isFalse);
      expect(result.refusal, isNull);
    });

    // "This file was refused" and "this file held no pictures" are different
    // things, and the screen says something different for each.
    test('a refused file is not the same as an empty one', () {
      const refused = PdfExtractionResult.refused(PdfRefusalReason.encrypted);
      const empty = PdfExtractionResult();

      expect(refused.isRefused, isTrue);
      expect(refused.isEmpty, isTrue);
      expect(empty.isRefused, isFalse);
      expect(empty.isEmpty, isTrue);
    });

    test('a refused file carries no entries', () {
      const refused = PdfExtractionResult.refused(PdfRefusalReason.notAPdf);
      expect(refused.entries, isEmpty);
      expect(refused.extractable, isEmpty);
    });

    test('truncation is reported separately from the count', () {
      const truncated = PdfExtractionResult(wasTruncated: true);
      expect(truncated.wasTruncated, isTrue);
      expect(truncated.isRefused, isFalse);
    });
  });
}
