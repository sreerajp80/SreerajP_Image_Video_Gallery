import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/redaction_service.dart';

/// Builds a white picture with a small sharp black square inside it.
///
/// The square sits well inside the area the tests redact, and there is white
/// around it, so blurring or pixelating that area has to spread the black
/// outward onto pixels that started pure white.
img.Image buildTestImage() {
  final image = img.Image(width: 100, height: 100, numChannels: 4);
  img.fill(image, color: img.ColorRgba8(255, 255, 255, 255));
  img.fillRect(
    image,
    x1: 18,
    y1: 18,
    x2: 30,
    y2: 30,
    color: img.ColorRgba8(0, 0, 0, 255),
  );
  return image;
}

void main() {
  const service = RedactionService();
  const region = NormalizedRect(left: 0.1, top: 0.1, right: 0.4, bottom: 0.4);

  // The blur and pixelate tests use a wider area, because both effects scale
  // with the size of the area: a tiny patch gets a tiny radius.
  const wideRegion = NormalizedRect(
    left: 0.1,
    top: 0.1,
    right: 0.9,
    bottom: 0.9,
  );

  group('strength maths', () {
    test('a stronger setting gives a bigger blur radius', () {
      const size = PixelSize(400, 400);
      final weak = service.blurRadiusFor(0, size);
      final strong = service.blurRadiusFor(1, size);

      expect(strong, greaterThan(weak));
    });

    test('the blur radius stays inside the supported range', () {
      final huge = service.blurRadiusFor(1, const PixelSize(8000, 8000));

      expect(huge, lessThanOrEqualTo(AppConstants.editorMaxBlurRadius));
      expect(huge, greaterThanOrEqualTo(2));
    });

    test('the pixelate block stays inside the supported range', () {
      final huge = service.pixelateBlockFor(1, const PixelSize(8000, 8000));

      expect(huge, lessThanOrEqualTo(AppConstants.editorMaxPixelateBlock));
      expect(huge, greaterThanOrEqualTo(2));
    });

    test('a NaN strength is treated as the middle setting', () {
      const size = PixelSize(400, 400);

      expect(
        service.blurRadiusFor(double.nan, size),
        service.blurRadiusFor(0.5, size),
      );
    });
  });

  group('blackout', () {
    test('the area is painted solid and nothing else changes', () {
      final image = buildTestImage();
      final result = service.apply(
        image,
        const RedactionRegion(
          id: 'r1',
          rect: region,
          mode: RedactionMode.blackout,
          colorArgb: 0xFFFF0000,
        ),
        const PixelSize(100, 100),
      );

      final inside = result.getPixel(20, 20);
      expect(inside.r, 255);
      expect(inside.g, 0);
      expect(inside.b, 0);

      // A pixel well outside the area is untouched.
      final outside = result.getPixel(80, 80);
      expect(outside.r, 255);
      expect(outside.g, 255);
      expect(outside.b, 255);
    });
  });

  group('blur', () {
    test('the sharp edge inside the area is softened', () {
      final image = buildTestImage();
      // This pixel starts pure white, just outside the black square but well
      // inside the redacted area, so a blur has to grey it.
      expect(image.getPixel(16, 24).r, 255);

      final result = service.apply(
        image,
        const RedactionRegion(
          id: 'r1',
          rect: wideRegion,
          mode: RedactionMode.blur,
          strength: 1,
        ),
        const PixelSize(100, 100),
      );

      expect(result.getPixel(16, 24).r, lessThan(255));
      // The middle of the square is no longer pure black either.
      expect(result.getPixel(24, 24).r, greaterThan(0));
    });
  });

  group('pixelate', () {
    test('the area is replaced with blocks of averaged colour', () {
      final image = buildTestImage();
      final result = service.apply(
        image,
        const RedactionRegion(
          id: 'r1',
          rect: wideRegion,
          mode: RedactionMode.pixelate,
          strength: 1,
        ),
        const PixelSize(100, 100),
      );

      // The white pixels around the square have taken on the block colour.
      expect(result.getPixel(16, 24).r, lessThan(255));
    });
  });

  group('applyAll', () {
    test('with no regions the picture comes back untouched', () {
      final image = buildTestImage();
      final result = service.applyAll(image, const <RedactionRegion>[]);

      expect(identical(result, image), isTrue);
    });

    test('several regions are all applied', () {
      final image = buildTestImage();
      final result = service.applyAll(image, const <RedactionRegion>[
        RedactionRegion(
          id: 'r1',
          rect: NormalizedRect(left: 0, top: 0, right: 0.3, bottom: 0.3),
          mode: RedactionMode.blackout,
        ),
        RedactionRegion(
          id: 'r2',
          rect: NormalizedRect(left: 0.6, top: 0.6, right: 0.9, bottom: 0.9),
          mode: RedactionMode.blackout,
        ),
      ]);

      expect(result.getPixel(5, 5).r, 0);
      expect(result.getPixel(70, 70).r, 0);
      // The strip between the two is still white.
      expect(result.getPixel(50, 50).r, 255);
    });

    test('a region dragged off the edge is handled, not fatal', () {
      final image = buildTestImage();

      expect(
        () => service.applyAll(image, const <RedactionRegion>[
          RedactionRegion(
            id: 'r1',
            rect: NormalizedRect(left: 0.9, top: 0.9, right: 2, bottom: 2),
          ),
        ]),
        returnsNormally,
      );
    });
  });

  group('colorFromArgb', () {
    test('the channels come out in the right places', () {
      final color = RedactionService.colorFromArgb(0x80102030);

      expect(color.a, 0x80);
      expect(color.r, 0x10);
      expect(color.g, 0x20);
      expect(color.b, 0x30);
    });
  });
}
