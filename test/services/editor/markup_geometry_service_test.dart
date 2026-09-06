import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/markup_geometry_service.dart';

void main() {
  const service = MarkupGeometryService();
  const size = PixelSize(1000, 500);

  group('coordinate conversion', () {
    test('a normalised point becomes the right pixel', () {
      expect(
        service.toPixel(const NormalizedPoint(0.5, 0.5), size),
        const PixelPoint(500, 250),
      );
    });

    test('a point past the edge is pulled back inside the image', () {
      final point = service.toPixel(const NormalizedPoint(2, -1), size);

      expect(point.x, lessThan(size.width));
      expect(point.x, greaterThanOrEqualTo(0));
      expect(point.y, 0);
    });

    test('pixels convert back to fractions', () {
      expect(
        service.toNormalized(500, 250, 1000, 500),
        const NormalizedPoint(0.5, 0.5),
      );
    });

    test(
      'a zero sized canvas gives the origin instead of dividing by zero',
      () {
        expect(service.toNormalized(10, 10, 0, 0), const NormalizedPoint(0, 0));
      },
    );
  });

  group('sizes', () {
    test('stroke width is measured against the shorter side', () {
      // The shorter side is 500, so 0.02 of it is 10 pixels.
      expect(service.strokeWidthInPixels(0.02, size), 10);
    });

    test('a stroke is never thinner than one pixel', () {
      expect(service.strokeWidthInPixels(0.00001, size), 1);
    });

    test('font size is measured the same way and has a floor', () {
      expect(service.fontSizeInPixels(0.1, size), 50);
      expect(service.fontSizeInPixels(0.0001, size), 8);
    });
  });

  group('bounds', () {
    test('shape corners are put in order whichever way it was dragged', () {
      final bounds = service.shapeBounds(
        const NormalizedPoint(0.8, 0.9),
        const NormalizedPoint(0.2, 0.1),
      );

      expect(bounds.left, closeTo(0.2, 0.0001));
      expect(bounds.top, closeTo(0.1, 0.0001));
      expect(bounds.right, closeTo(0.8, 0.0001));
      expect(bounds.bottom, closeTo(0.9, 0.0001));
    });

    test('a stroke reports the box that holds every point', () {
      const stroke = DoodleStroke(
        id: 'd1',
        colorArgb: 0xFFFFFFFF,
        points: <NormalizedPoint>[
          NormalizedPoint(0.3, 0.6),
          NormalizedPoint(0.1, 0.2),
          NormalizedPoint(0.7, 0.4),
        ],
      );

      final bounds = service.strokeBounds(stroke);

      expect(bounds.left, closeTo(0.1, 0.0001));
      expect(bounds.top, closeTo(0.2, 0.0001));
      expect(bounds.right, closeTo(0.7, 0.0001));
      expect(bounds.bottom, closeTo(0.6, 0.0001));
    });

    test('a stroke with no points falls back to the whole image', () {
      const empty = DoodleStroke(
        id: 'd1',
        colorArgb: 0xFFFFFFFF,
        points: <NormalizedPoint>[],
      );

      expect(service.strokeBounds(empty), isNotNull);
    });
  });

  group('arrow heads', () {
    test('an arrow gets two barbs behind its tip', () {
      final barbs = service.arrowHeadPoints(
        const NormalizedPoint(0.1, 0.5),
        const NormalizedPoint(0.9, 0.5),
        size,
        4,
      );

      expect(barbs, hasLength(2));
      // Both barbs sit behind the tip along the line.
      for (final barb in barbs) {
        expect(barb.x, lessThan(900));
      }
    });

    test('a drag that went nowhere has no arrow head', () {
      final barbs = service.arrowHeadPoints(
        const NormalizedPoint(0.5, 0.5),
        const NormalizedPoint(0.5, 0.5),
        size,
        4,
      );

      expect(barbs, isEmpty);
    });
  });

  group('isDrawable', () {
    test('a stroke needs at least two points', () {
      const single = DoodleStroke(
        id: 'd1',
        colorArgb: 0xFFFFFFFF,
        points: <NormalizedPoint>[NormalizedPoint(0.5, 0.5)],
      );
      final pair = single.withPoint(const NormalizedPoint(0.6, 0.6));

      expect(service.isDrawable(single), isFalse);
      expect(service.isDrawable(pair), isTrue);
    });

    test('a rectangle dragged nowhere draws nothing', () {
      const flat = ShapeAnnotation(
        id: 's1',
        colorArgb: 0xFFFFFFFF,
        shape: ShapeKind.rectangle,
        start: NormalizedPoint(0.5, 0.5),
        end: NormalizedPoint(0.5, 0.5),
      );

      expect(service.isDrawable(flat), isFalse);
    });

    test('a line only needs length in one direction', () {
      const horizontal = ShapeAnnotation(
        id: 's1',
        colorArgb: 0xFFFFFFFF,
        shape: ShapeKind.line,
        start: NormalizedPoint(0.1, 0.5),
        end: NormalizedPoint(0.9, 0.5),
      );

      expect(service.isDrawable(horizontal), isTrue);
    });

    test('empty text draws nothing', () {
      const blank = TextAnnotation(
        id: 't1',
        colorArgb: 0xFFFFFFFF,
        text: '   ',
        position: NormalizedPoint(0.1, 0.1),
      );

      expect(service.isDrawable(blank), isFalse);
      expect(service.isDrawable(blank.copyWith(text: 'hello')), isTrue);
    });
  });
}
