import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';

void main() {
  const service = CropTransformService();
  const landscape = PixelSize(4000, 3000);
  const square = PixelSize(1000, 1000);

  group('ratioFor', () {
    test('the original preset takes its ratio from the image', () {
      expect(
        service.ratioFor(CropAspectPreset.original, landscape),
        closeTo(4 / 3, 0.0001),
      );
    });

    test('free has no ratio at all', () {
      expect(service.ratioFor(CropAspectPreset.free, landscape), isNull);
    });

    test('an image with no size gives no original ratio', () {
      expect(
        service.ratioFor(CropAspectPreset.original, const PixelSize(0, 0)),
        isNull,
      );
    });
  });

  group('clampRect', () {
    test('a rectangle inside the image is left alone', () {
      const rect = NormalizedRect(left: 0.1, top: 0.2, right: 0.8, bottom: 0.9);

      expect(service.clampRect(rect), rect);
    });

    test('edges dragged outside the image are pulled back in', () {
      final clamped = service.clampRect(
        const NormalizedRect(left: -0.4, top: -0.2, right: 1.6, bottom: 1.3),
      );

      expect(clamped, NormalizedRect.full);
    });

    test(
      'a handle dragged past the opposite edge is swapped, not inverted',
      () {
        final clamped = service.clampRect(
          const NormalizedRect(left: 0.8, top: 0.7, right: 0.2, bottom: 0.1),
        );

        expect(clamped.left, closeTo(0.2, 0.0001));
        expect(clamped.right, closeTo(0.8, 0.0001));
        expect(clamped.top, closeTo(0.1, 0.0001));
        expect(clamped.bottom, closeTo(0.7, 0.0001));
      },
    );

    test('a box collapsed to nothing is grown to the minimum', () {
      final clamped = service.clampRect(
        const NormalizedRect(left: 0.5, top: 0.5, right: 0.5, bottom: 0.5),
      );

      expect(
        clamped.width,
        greaterThanOrEqualTo(AppConstants.editorMinCropFraction - 0.0001),
      );
      expect(
        clamped.height,
        greaterThanOrEqualTo(AppConstants.editorMinCropFraction - 0.0001),
      );
      expect(clamped.isValid, isTrue);
    });

    test('a collapsed box at the far edge grows inward, not off the image', () {
      final clamped = service.clampRect(
        const NormalizedRect(left: 1, top: 1, right: 1, bottom: 1),
      );

      expect(clamped.right, lessThanOrEqualTo(1));
      expect(clamped.bottom, lessThanOrEqualTo(1));
      expect(clamped.isValid, isTrue);
    });

    test('a NaN edge does not produce a broken rectangle', () {
      final clamped = service.clampRect(
        NormalizedRect(left: double.nan, top: 0, right: 1, bottom: 1),
      );

      expect(clamped.isValid, isTrue);
    });
  });

  group('applyAspectRatio', () {
    test('a square shape on a square image gives a square box', () {
      final shaped = service.applyAspectRatio(NormalizedRect.full, 1, square);

      expect(shaped.width, closeTo(shaped.height, 0.0001));
    });

    test('the shaped box stays inside the image', () {
      final shaped = service.applyAspectRatio(
        NormalizedRect.full,
        16 / 9,
        const PixelSize(1000, 2000),
      );

      expect(shaped.left, greaterThanOrEqualTo(0));
      expect(shaped.top, greaterThanOrEqualTo(0));
      expect(shaped.right, lessThanOrEqualTo(1.0001));
      expect(shaped.bottom, lessThanOrEqualTo(1.0001));
    });

    test('the centre of the box does not move', () {
      const rect = NormalizedRect(left: 0.2, top: 0.2, right: 0.8, bottom: 0.8);
      final shaped = service.applyAspectRatio(rect, 1, square);

      expect((shaped.left + shaped.right) / 2, closeTo(0.5, 0.0001));
      expect((shaped.top + shaped.bottom) / 2, closeTo(0.5, 0.0001));
    });

    test('no ratio just clamps the box', () {
      const rect = NormalizedRect(left: 0.1, top: 0.1, right: 0.5, bottom: 0.5);

      expect(service.applyAspectRatio(rect, null, square), rect);
    });
  });

  group('toPixelRect', () {
    test('the full rectangle covers every pixel', () {
      final rect = service.toPixelRect(NormalizedRect.full, landscape);

      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 4000);
      expect(rect.height, 3000);
    });

    test('a half rectangle lands on the right pixels', () {
      final rect = service.toPixelRect(
        const NormalizedRect(left: 0.25, top: 0.5, right: 0.75, bottom: 1),
        landscape,
      );

      expect(rect.left, 1000);
      expect(rect.top, 1500);
      expect(rect.width, 2000);
      expect(rect.height, 1500);
    });

    test('the result never runs past the edge of the image', () {
      final rect = service.toPixelRect(
        const NormalizedRect(left: 0.99, top: 0.99, right: 1, bottom: 1),
        const PixelSize(10, 10),
      );

      expect(rect.right, lessThanOrEqualTo(10));
      expect(rect.bottom, lessThanOrEqualTo(10));
      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
    });
  });

  group('rotation helpers', () {
    test('the straighten angle is held inside the slider range', () {
      expect(service.clampStraighten(90), 45);
      expect(service.clampStraighten(-90), -45);
      expect(service.clampStraighten(double.nan), 0);
      expect(service.clampStraighten(12.5), 12.5);
    });

    test('quarter turns wrap around in both directions', () {
      expect(service.normalizeQuarterTurns(4), 0);
      expect(service.normalizeQuarterTurns(5), 1);
      expect(service.normalizeQuarterTurns(-1), 3);
      expect(service.normalizeQuarterTurns(-5), 3);
    });

    test('a quarter turn swaps width and height', () {
      expect(
        service.sizeAfterQuarterTurns(landscape, 1),
        const PixelSize(3000, 4000),
      );
      expect(service.sizeAfterQuarterTurns(landscape, 2), landscape);
    });

    test('a tilt needs a bigger bounding box', () {
      final bounds = service.boundsAfterRotation(square, 45);

      expect(bounds.width, greaterThan(square.width));
      expect(bounds.height, greaterThan(square.height));
    });

    test('no tilt needs no extra room', () {
      expect(service.boundsAfterRotation(landscape, 0), landscape);
    });
  });

  group('largestInnerRect', () {
    test('with no tilt it is the whole image', () {
      final rect = service.largestInnerRect(landscape, 0);

      expect(rect.left, 0);
      expect(rect.top, 0);
      expect(rect.width, 4000);
      expect(rect.height, 3000);
    });

    test('a tilted image loses area but keeps a usable box', () {
      final rect = service.largestInnerRect(square, 20);

      expect(rect.width, greaterThan(0));
      expect(rect.height, greaterThan(0));
      expect(rect.width, lessThan(square.width));
    });

    test('the box fits inside the rotated bounds', () {
      const angle = 30.0;
      final bounds = service.boundsAfterRotation(landscape, angle);
      final rect = service.largestInnerRect(landscape, angle);

      expect(rect.right, lessThanOrEqualTo(bounds.width));
      expect(rect.bottom, lessThanOrEqualTo(bounds.height));
    });
  });

  group('perspective', () {
    test('insets are held inside the supported range', () {
      final clamped = service.clampPerspective(
        const PerspectiveSkew(topInset: 5, leftInset: -5),
      );

      expect(clamped.topInset, AppConstants.editorPerspectiveMaxInset);
      expect(clamped.leftInset, -AppConstants.editorPerspectiveMaxInset);
    });

    test('a NaN inset becomes no correction', () {
      final clamped = service.clampPerspective(
        PerspectiveSkew(topInset: double.nan),
      );

      expect(clamped.topInset, 0);
    });

    test('no correction gives the four real corners', () {
      final corners = service.perspectiveCorners(
        PerspectiveSkew.none,
        const PixelSize(100, 50),
      );

      expect(corners[0], <double>[0, 0]);
      expect(corners[1], <double>[100, 0]);
      expect(corners[2], <double>[100, 50]);
      expect(corners[3], <double>[0, 50]);
    });

    test('a top inset pulls the two top corners inward', () {
      final corners = service.perspectiveCorners(
        const PerspectiveSkew(topInset: 0.1),
        const PixelSize(100, 50),
      );

      expect(corners[0][0], closeTo(10, 0.0001));
      expect(corners[1][0], closeTo(90, 0.0001));
      // The bottom edge is untouched.
      expect(corners[3][0], closeTo(0, 0.0001));
    });
  });
}
