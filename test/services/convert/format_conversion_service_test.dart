import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_request.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/format_conversion_service.dart';

/// A small solid picture with a known size, encoded as PNG.
Uint8List samplePng({int width = 40, int height = 20, int alpha = 255}) {
  final image = img.Image(width: width, height: height, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(200, 100, 50, alpha));
  return img.encodePng(image);
}

void main() {
  final service = FormatConversionService();

  group('decode', () {
    test('a real picture decodes to its own size', () {
      final image = service.decode(samplePng());

      expect(image.width, 40);
      expect(image.height, 20);
    });

    test('empty bytes are refused with a plain exception', () {
      expect(
        () => service.decode(Uint8List(0)),
        throwsA(isA<ConversionException>()),
      );
    });

    test('rubbish bytes are refused rather than crashing', () {
      final rubbish = Uint8List.fromList(List<int>.filled(64, 7));

      expect(
        () => service.decode(rubbish),
        throwsA(isA<ConversionException>()),
      );
    });
  });

  group('convertSync', () {
    test('a PNG becomes a real JPEG', () {
      final result = service.convertSync(
        sourceBytes: samplePng(),
        request: const ConversionRequest(format: ImageOutputFormat.jpeg),
      );

      expect(result.width, 40);
      expect(result.height, 20);
      // JPEG files always begin with these two bytes.
      expect(result.bytes[0], 0xFF);
      expect(result.bytes[1], 0xD8);
    });

    test('a picture becomes a real BMP', () {
      final result = service.convertSync(
        sourceBytes: samplePng(),
        request: const ConversionRequest(format: ImageOutputFormat.bmp),
      );

      // BMP files always begin with "BM".
      expect(result.bytes[0], 0x42);
      expect(result.bytes[1], 0x4D);
    });

    test('a picture becomes a real PNG', () {
      final result = service.convertSync(
        sourceBytes: samplePng(),
        request: const ConversionRequest(format: ImageOutputFormat.png),
      );

      expect(result.bytes.sublist(1, 4), <int>[0x50, 0x4E, 0x47]);
    });

    test('the resize is applied before the encode', () {
      final result = service.convertSync(
        sourceBytes: samplePng(width: 400, height: 200),
        request: const ConversionRequest(
          format: ImageOutputFormat.jpeg,
          resize: ResizeSpec(mode: ResizeMode.longestSide, longestSide: 100),
        ),
      );

      expect(result.width, 100);
      expect(result.height, 50);
    });

    test('a lower quality makes a smaller JPEG', () {
      final source = samplePng(width: 200, height: 200);

      final high = service.convertSync(
        sourceBytes: source,
        request: const ConversionRequest(
          format: ImageOutputFormat.jpeg,
          quality: 95,
        ),
      );
      final low = service.convertSync(
        sourceBytes: source,
        request: const ConversionRequest(
          format: ImageOutputFormat.jpeg,
          quality: 20,
        ),
      );

      expect(low.bytes.length, lessThan(high.bytes.length));
    });

    test('WEBP is refused here, because only Android can write it', () {
      expect(
        () => service.convertSync(
          sourceBytes: samplePng(),
          request: const ConversionRequest(format: ImageOutputFormat.webp),
        ),
        throwsA(isA<ConversionException>()),
      );
    });
  });

  group('flattenOntoWhite', () {
    test('a see-through picture loses its alpha channel', () {
      final decoded = service.decode(samplePng(alpha: 0));
      expect(decoded.hasAlpha, isTrue);

      final flattened = service.flattenOntoWhite(decoded);

      expect(flattened.hasAlpha, isFalse);
      expect(flattened.width, decoded.width);
      expect(flattened.height, decoded.height);
    });

    test('a clear pixel comes out white rather than black', () {
      final decoded = service.decode(samplePng(alpha: 0));
      final flattened = service.flattenOntoWhite(decoded);
      final pixel = flattened.getPixel(0, 0);

      expect(pixel.r.round(), 255);
      expect(pixel.g.round(), 255);
      expect(pixel.b.round(), 255);
    });

    test('preparing for JPEG flattens automatically', () {
      final prepared = service.prepare(
        sourceBytes: samplePng(alpha: 0),
        request: const ConversionRequest(format: ImageOutputFormat.jpeg),
      );

      expect(prepared.hasAlpha, isFalse);
    });

    test('preparing for PNG keeps the see-through pixels', () {
      final prepared = service.prepare(
        sourceBytes: samplePng(alpha: 0),
        request: const ConversionRequest(format: ImageOutputFormat.png),
      );

      expect(prepared.hasAlpha, isTrue);
    });
  });

  group('toRawPixels', () {
    test('the pixel buffer is four bytes per pixel', () {
      final image = service.decode(samplePng(width: 10, height: 5));
      final pixels = service.toRawPixels(image);

      expect(pixels.width, 10);
      expect(pixels.height, 5);
      expect(pixels.rgba.length, 10 * 5 * 4);
    });
  });
}
