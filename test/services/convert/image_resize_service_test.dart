import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/image_resize_service.dart';

void main() {
  const service = ImageResizeService();

  group('ResizeMode.none', () {
    test('the picture keeps its own size', () {
      final size = service.resolve(
        sourceWidth: 4000,
        sourceHeight: 3000,
        spec: ResizeSpec.original,
      );

      expect(size, const TargetSize(4000, 3000));
    });
  });

  group('ResizeMode.longestSide', () {
    test('a landscape picture is scaled by its width', () {
      final size = service.resolve(
        sourceWidth: 4000,
        sourceHeight: 2000,
        spec: const ResizeSpec(mode: ResizeMode.longestSide, longestSide: 1000),
      );

      expect(size, const TargetSize(1000, 500));
    });

    test('a portrait picture is scaled by its height', () {
      final size = service.resolve(
        sourceWidth: 2000,
        sourceHeight: 4000,
        spec: const ResizeSpec(mode: ResizeMode.longestSide, longestSide: 1000),
      );

      expect(size, const TargetSize(500, 1000));
    });

    test('a longest side below the floor is pulled up', () {
      final size = service.resolve(
        sourceWidth: 4000,
        sourceHeight: 4000,
        spec: const ResizeSpec(mode: ResizeMode.longestSide, longestSide: 1),
      );

      expect(size.width, AppConstants.convertMinLongestSide);
      expect(size.height, AppConstants.convertMinLongestSide);
    });

    test('a longest side above the ceiling is pulled down', () {
      final size = service.resolve(
        sourceWidth: 100,
        sourceHeight: 100,
        spec: const ResizeSpec(
          mode: ResizeMode.longestSide,
          longestSide: 999999,
        ),
      );

      expect(size.width, AppConstants.convertMaxLongestSide);
    });
  });

  group('ResizeMode.percent', () {
    test('half the size halves both sides', () {
      final size = service.resolve(
        sourceWidth: 1000,
        sourceHeight: 600,
        spec: const ResizeSpec(mode: ResizeMode.percent, percent: 50),
      );

      expect(size, const TargetSize(500, 300));
    });

    test('a percent above the allowed maximum is pulled back', () {
      final size = service.resolve(
        sourceWidth: 100,
        sourceHeight: 100,
        spec: const ResizeSpec(mode: ResizeMode.percent, percent: 10000),
      );

      expect(size.width, 100 * AppConstants.convertMaxPercent ~/ 100);
    });

    test('a tiny picture never shrinks below one pixel', () {
      final size = service.resolve(
        sourceWidth: 3,
        sourceHeight: 3,
        spec: const ResizeSpec(
          mode: ResizeMode.percent,
          percent: AppConstants.convertMinPercent,
        ),
      );

      expect(size.width, greaterThanOrEqualTo(1));
      expect(size.height, greaterThanOrEqualTo(1));
    });
  });

  group('ResizeMode.exact', () {
    test('with the shape kept the picture fits inside the box', () {
      final size = service.resolve(
        sourceWidth: 2000,
        sourceHeight: 1000,
        spec: const ResizeSpec(mode: ResizeMode.exact, width: 800, height: 800),
      );

      // The wide picture touches the width first, so it stays half as tall.
      expect(size, const TargetSize(800, 400));
    });

    test('with the shape dropped the exact numbers are used', () {
      final size = service.resolve(
        sourceWidth: 2000,
        sourceHeight: 1000,
        spec: const ResizeSpec(
          mode: ResizeMode.exact,
          width: 800,
          height: 800,
          keepAspect: false,
        ),
      );

      expect(size, const TargetSize(800, 800));
    });
  });

  group('changesSize', () {
    test('a spec that produces the same size reports no change', () {
      expect(
        service.changesSize(
          sourceWidth: 640,
          sourceHeight: 480,
          spec: ResizeSpec.original,
        ),
        isFalse,
      );
    });

    test('a spec that produces a different size reports a change', () {
      expect(
        service.changesSize(
          sourceWidth: 640,
          sourceHeight: 480,
          spec: const ResizeSpec(mode: ResizeMode.percent, percent: 50),
        ),
        isTrue,
      );
    });
  });

  group('fitWithin', () {
    test('a picture already small enough is left alone', () {
      expect(service.fitWithin(300, 200, 800), const TargetSize(300, 200));
    });

    test('a larger picture is scaled down keeping its shape', () {
      expect(service.fitWithin(1600, 800, 800), const TargetSize(800, 400));
    });

    test('a zero-sized picture gives at least one pixel', () {
      final size = service.fitWithin(0, 0, 800);
      expect(size.width, 1);
      expect(size.height, 1);
    });
  });
}
