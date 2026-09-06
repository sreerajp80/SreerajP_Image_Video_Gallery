import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/watermark_service.dart';

void main() {
  const service = WatermarkService();
  const size = PixelSize(1000, 500);

  group('formatTimestamp', () {
    final date = DateTime(2026, 8, 29, 14, 5, 9);

    test('fills in the default pattern', () {
      expect(
        service.formatTimestamp(date, 'yyyy-MM-dd HH:mm'),
        '2026-08-29 14:05',
      );
    });

    test('supports seconds and other orderings', () {
      expect(
        service.formatTimestamp(date, 'dd/MM/yyyy HH:mm:ss'),
        '29/08/2026 14:05:09',
      );
    });

    test('an empty pattern falls back to the default', () {
      expect(service.formatTimestamp(date, '   '), '2026-08-29 14:05');
    });
  });

  group('resolveText', () {
    test('text mode uses the typed text, trimmed', () {
      expect(
        service.resolveText(
          const WatermarkConfig(mode: WatermarkMode.text, text: '  hi  '),
        ),
        'hi',
      );
    });

    test('timestamp mode uses the photo date when there is one', () {
      final text = service.resolveText(
        const WatermarkConfig(mode: WatermarkMode.timestamp),
        captureDate: DateTime(2020, 1, 2, 3, 4),
      );

      expect(text, '2020-01-02 03:04');
    });

    test('logo and none modes have no text', () {
      expect(
        service.resolveText(const WatermarkConfig(mode: WatermarkMode.logo)),
        isEmpty,
      );
      expect(service.resolveText(WatermarkConfig.none), isEmpty);
    });
  });

  group('sizes', () {
    test('height is measured against the shorter side', () {
      // The shorter side is 500, so a scale of 0.1 is 50 pixels.
      expect(service.heightInPixels(0.1, size), 50);
    });

    test('an absurd scale is pulled back into range', () {
      expect(service.heightInPixels(50, size), lessThanOrEqualTo(250));
    });

    test('the margin is measured the same way', () {
      expect(service.marginInPixels(0.02, size), 10);
    });

    test('a logo keeps its own proportions', () {
      final result = service.logoSize(
        logoNativeSize: const PixelSize(200, 100),
        targetHeight: 50,
      );

      expect(result.width, 100);
      expect(result.height, 50);
    });

    test('a logo with no size does not divide by zero', () {
      final result = service.logoSize(
        logoNativeSize: const PixelSize(0, 0),
        targetHeight: 50,
      );

      expect(result.width, 1);
      expect(result.height, 1);
    });
  });

  group('placement', () {
    WatermarkPlacement place(WatermarkPosition position) => service.placement(
      config: WatermarkConfig(position: position, margin: 0.02),
      imageSize: size,
      contentWidth: 200,
      contentHeight: 40,
    );

    test('the bottom right corner sits a margin in from both edges', () {
      final placement = place(WatermarkPosition.bottomRight);

      expect(placement.right, 1000 - 10);
      expect(placement.bottom, 500 - 10);
    });

    test('the top left corner sits a margin in from both edges', () {
      final placement = place(WatermarkPosition.topLeft);

      expect(placement.left, 10);
      expect(placement.top, 10);
    });

    test('a centred stamp is centred on that axis', () {
      final placement = place(WatermarkPosition.center);

      expect(placement.left, (1000 - 200) ~/ 2);
      expect(placement.top, (500 - 40) ~/ 2);
    });

    test('every position keeps the stamp inside the photo', () {
      for (final position in WatermarkPosition.values) {
        final placement = place(position);

        expect(placement.left, greaterThanOrEqualTo(0));
        expect(placement.top, greaterThanOrEqualTo(0));
        expect(placement.right, lessThanOrEqualTo(size.width));
        expect(placement.bottom, lessThanOrEqualTo(size.height));
      }
    });

    test(
      'a stamp bigger than the photo is trimmed rather than overflowing',
      () {
        final placement = service.placement(
          config: const WatermarkConfig(),
          imageSize: size,
          contentWidth: 5000,
          contentHeight: 5000,
        );

        expect(placement.width, size.width);
        expect(placement.height, size.height);
        expect(placement.left, 0);
        expect(placement.top, 0);
      },
    );
  });

  group('alphaFor', () {
    test('opacity becomes an alpha from 0 to 255', () {
      expect(service.alphaFor(1), 255);
      expect(service.alphaFor(0), 0);
      expect(service.alphaFor(0.5), 128);
    });

    test('a NaN opacity is treated as fully solid', () {
      expect(service.alphaFor(double.nan), 255);
    });
  });
}
