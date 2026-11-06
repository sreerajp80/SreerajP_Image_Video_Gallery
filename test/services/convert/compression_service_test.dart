import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/compression_service.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';

/// A small picture with some detail in it, so quality changes show up.
Uint8List samplePng({int width = 120, int height = 80}) {
  final image = img.Image(width: width, height: height);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      image.setPixelRgb(x, y, (x * 7) % 256, (y * 11) % 256, (x + y) % 256);
    }
  }
  return img.encodePng(image);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = CompressionService(
    conversionService: FormatConversionService(),
  );

  group('estimate', () {
    test('the reported size is the real encoded size', () async {
      final source = samplePng();
      const request = ConversionRequest();

      final estimate = await service.estimate(
        sourceBytes: source,
        request: request,
        originalBytes: source.length,
      );

      final encoded = FormatConversionService().convertSync(
        sourceBytes: source,
        request: request,
      );

      expect(estimate.bytes, encoded.bytes.length);
      expect(estimate.width, 120);
      expect(estimate.height, 80);
      expect(estimate.originalBytes, source.length);
    });

    test('a resize is reflected in the reported pixel size', () async {
      final source = samplePng(width: 400, height: 200);

      final estimate = await service.estimate(
        sourceBytes: source,
        request: const ConversionRequest(
          resize: ResizeSpec(mode: ResizeMode.longestSide, longestSide: 100),
        ),
        originalBytes: source.length,
      );

      expect(estimate.width, 100);
      expect(estimate.height, 50);
    });

    test('a corrupt picture reports a failure rather than a number', () async {
      final rubbish = Uint8List.fromList(List<int>.filled(32, 3));

      expect(
        () => service.estimate(
          sourceBytes: rubbish,
          request: const ConversionRequest(),
          originalBytes: rubbish.length,
        ),
        throwsA(isA<ConversionException>()),
      );
    });
  });
}
