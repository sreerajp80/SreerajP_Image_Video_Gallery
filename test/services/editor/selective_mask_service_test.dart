import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/selective_mask_service.dart';

void main() {
  const service = SelectiveMaskService();

  group('SelectiveMaskService maskWeight', () {
    test('linear mask weight is 1.0 before start and 0.0 past end', () {
      const mask = SelectiveMask(
        id: 'lin_1',
        shape: MaskShape.linear,
        startPoint: NormalizedPoint(0.2, 0.5),
        endPoint: NormalizedPoint(0.8, 0.5),
        feather: 0.0,
      );

      // Left of start point (<= 0.2) should have full weight 1.0
      expect(service.maskWeight(mask, 0.1, 0.5), closeTo(1.0, 0.001));
      expect(service.maskWeight(mask, 0.2, 0.5), closeTo(1.0, 0.001));

      // Right of end point (>= 0.8) should have weight 0.0
      expect(service.maskWeight(mask, 0.8, 0.5), closeTo(0.0, 0.001));
      expect(service.maskWeight(mask, 0.9, 0.5), closeTo(0.0, 0.001));

      // Midpoint should be approximately 0.5
      expect(service.maskWeight(mask, 0.5, 0.5), closeTo(0.5, 0.05));
    });

    test(
      'radial mask weight is 1.0 near center and drops to 0.0 outside radius',
      () {
        const mask = SelectiveMask(
          id: 'rad_1',
          shape: MaskShape.radial,
          startPoint: NormalizedPoint(0.5, 0.5),
          endPoint: NormalizedPoint(0.8, 0.5), // radius = 0.3
          feather: 0.0,
        );

        // At center
        expect(service.maskWeight(mask, 0.5, 0.5), closeTo(1.0, 0.001));

        // Just inside radius (r = 0.2)
        expect(service.maskWeight(mask, 0.7, 0.5), closeTo(1.0, 0.001));

        // Far outside radius (r = 0.45)
        expect(service.maskWeight(mask, 0.95, 0.5), closeTo(0.0, 0.001));
      },
    );

    test('invert flag reverses weight completely', () {
      const normal = SelectiveMask(
        id: 'norm',
        shape: MaskShape.radial,
        startPoint: NormalizedPoint(0.5, 0.5),
        endPoint: NormalizedPoint(0.8, 0.5),
        invert: false,
      );
      const inverted = SelectiveMask(
        id: 'inv',
        shape: MaskShape.radial,
        startPoint: NormalizedPoint(0.5, 0.5),
        endPoint: NormalizedPoint(0.8, 0.5),
        invert: true,
      );

      final w1 = service.maskWeight(normal, 0.5, 0.5);
      final w2 = service.maskWeight(inverted, 0.5, 0.5);
      expect(w1 + w2, closeTo(1.0, 0.001));

      final wOut1 = service.maskWeight(normal, 0.95, 0.5);
      final wOut2 = service.maskWeight(inverted, 0.95, 0.5);
      expect(wOut1 + wOut2, closeTo(1.0, 0.001));
    });
  });

  group('SelectiveMaskService applyMasks', () {
    test('neutral mask does not modify image pixels', () {
      final image = img.Image(width: 2, height: 2);
      for (final p in image) {
        p
          ..r = 100
          ..g = 150
          ..b = 200;
      }

      service.applyMasks(image, const [SelectiveMask(id: 'neutral_1')]);

      for (final p in image) {
        expect(p.r, 100);
        expect(p.g, 150);
        expect(p.b, 200);
      }
    });

    test('positive exposure increases brightness inside mask region', () {
      final image = img.Image(width: 10, height: 10);
      for (final p in image) {
        p
          ..r = 50
          ..g = 50
          ..b = 50;
      }

      const mask = SelectiveMask(
        id: 'brighten_center',
        shape: MaskShape.radial,
        startPoint: NormalizedPoint(0.5, 0.5),
        endPoint: NormalizedPoint(0.9, 0.5),
        exposure: 1.0, // +1 stop (double brightness)
      );

      service.applyMasks(image, const [mask]);

      // Pixel near center (5, 5) should be brighter (~100)
      final center = image.getPixel(5, 5);
      expect(center.r, greaterThan(80));

      // Pixel in corner (0, 0) is far away and should remain close to 50
      final corner = image.getPixel(0, 0);
      expect(corner.r, lessThan(60));
    });
  });
}
