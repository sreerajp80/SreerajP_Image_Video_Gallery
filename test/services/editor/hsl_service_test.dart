import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/editor/hsl_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/hsl_service.dart';

void main() {
  const service = HslService();

  group('HslService rangeWeight', () {
    test('center hue gives maximum weight of 1.0', () {
      expect(service.rangeWeight(0, HslColorRange.red), closeTo(1.0, 0.001));
      expect(
        service.rangeWeight(30, HslColorRange.orange),
        closeTo(1.0, 0.001),
      );
      expect(
        service.rangeWeight(60, HslColorRange.yellow),
        closeTo(1.0, 0.001),
      );
      expect(
        service.rangeWeight(120, HslColorRange.green),
        closeTo(1.0, 0.001),
      );
      expect(service.rangeWeight(180, HslColorRange.cyan), closeTo(1.0, 0.001));
      expect(service.rangeWeight(240, HslColorRange.blue), closeTo(1.0, 0.001));
      expect(
        service.rangeWeight(285, HslColorRange.purple),
        closeTo(1.0, 0.001),
      );
      expect(
        service.rangeWeight(330, HslColorRange.magenta),
        closeTo(1.0, 0.001),
      );
    });

    test('red range properly handles 360 wrap-around', () {
      // 355° is 5° away from 0° (within 15° half-width).
      expect(service.rangeWeight(355, HslColorRange.red), greaterThan(0.5));
      // 5° is also 5° away from 0°.
      expect(
        service.rangeWeight(355, HslColorRange.red),
        closeTo(service.rangeWeight(5, HslColorRange.red), 0.001),
      );
    });

    test('outside the band gives 0 weight', () {
      // Green center (120°) has 0 weight for red.
      expect(service.rangeWeight(120, HslColorRange.red), 0.0);
      // Blue center (240°) has 0 weight for yellow.
      expect(service.rangeWeight(240, HslColorRange.yellow), 0.0);
    });
  });

  group('HslService applyHsl', () {
    test('neutral adjustments leave the image untouched', () {
      final image = img.Image(width: 4, height: 4);
      for (final p in image) {
        p
          ..r = 200
          ..g = 100
          ..b = 50;
      }

      final result = service.applyHsl(image, HslAdjustments.neutral);
      for (final p in result) {
        expect(p.r, 200);
        expect(p.g, 100);
        expect(p.b, 50);
      }
    });

    test('boosting red saturation affects red pixels but not blue pixels', () {
      final image = img.Image(width: 2, height: 1);
      // Pixel 0: Pure red
      final p0 = image.getPixel(0, 0)
        ..r = 220
        ..g = 40
        ..b = 40;
      // Pixel 1: Pure blue
      final p1 = image.getPixel(1, 0)
        ..r = 40
        ..g = 40
        ..b = 220;

      final redBoost = HslAdjustments.neutral.copyWithChannel(
        HslColorRange.red,
        const HslChannelAdjustment(saturation: 0.8),
      );

      service.applyHsl(image, redBoost);

      // Blue pixel should be unmodified
      expect(p1.r, 40);
      expect(p1.g, 40);
      expect(p1.b, 220);

      // Red pixel should remain red, saturation increased
      expect(p0.r, greaterThanOrEqualTo(220));
      expect(p0.g, lessThanOrEqualTo(40));
    });

    test('achromatic pixels (greys) are not affected by hue shifts', () {
      final image = img.Image(width: 1, height: 1);
      final p = image.getPixel(0, 0)
        ..r = 128
        ..g = 128
        ..b = 128;

      final shift = HslAdjustments.neutral.copyWithChannel(
        HslColorRange.red,
        const HslChannelAdjustment(hue: 0.9),
      );

      service.applyHsl(image, shift);

      expect(p.r, 128);
      expect(p.g, 128);
      expect(p.b, 128);
    });
  });
}
