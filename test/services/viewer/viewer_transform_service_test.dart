import 'dart:math' as math;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/viewer_transform.dart';
import 'package:in_sreerajp_imgvidgal/services/viewer/viewer_transform_service.dart';

void main() {
  const service = ViewerTransformService();

  group('clampScale', () {
    test('keeps a normal zoom unchanged', () {
      expect(service.clampScale(2.5), 2.5);
    });

    test('pulls values back inside the supported range', () {
      expect(service.clampScale(0.2), AppConstants.viewerMinScale);
      expect(service.clampScale(50), AppConstants.viewerMaxScale);
    });

    test('falls back to the fitted size for a broken value', () {
      expect(service.clampScale(double.nan), AppConstants.viewerMinScale);
      expect(service.clampScale(double.infinity), AppConstants.viewerMinScale);
    });
  });

  group('doubleTapTargetScale', () {
    test('zooms in from the fitted size', () {
      expect(
        service.doubleTapTargetScale(1.0),
        AppConstants.viewerDoubleTapScale,
      );
    });

    test('zooms back out when already zoomed', () {
      expect(service.doubleTapTargetScale(3.0), AppConstants.viewerMinScale);
    });
  });

  group('zoomMatrix', () {
    test('returns the identity when the target is the fitted size', () {
      final matrix = service.zoomMatrix(
        targetScale: 1.0,
        focalPoint: const Offset(100, 100),
        viewportSize: const Size(400, 800),
      );
      expect(service.scaleOf(matrix), 1.0);
    });

    test('scales by the requested amount', () {
      final matrix = service.zoomMatrix(
        targetScale: 2.0,
        focalPoint: const Offset(100, 200),
        viewportSize: const Size(400, 800),
      );
      expect(service.scaleOf(matrix), closeTo(2.0, 0.0001));
    });

    test('keeps the tapped point in place', () {
      const focal = Offset(100, 200);
      final matrix = service.zoomMatrix(
        targetScale: 2.0,
        focalPoint: focal,
        viewportSize: const Size(400, 800),
      );

      // The point under the finger must map back onto itself.
      final transformed = MatrixUtils.transformPoint(matrix, focal);
      expect(transformed.dx, closeTo(focal.dx, 0.0001));
      expect(transformed.dy, closeTo(focal.dy, 0.0001));
    });
  });

  group('rotation', () {
    test('steps right and left by ninety degrees', () {
      expect(service.rotateRight(0), 90);
      expect(service.rotateRight(270), 0);
      expect(service.rotateLeft(0), 270);
      expect(service.rotateLeft(90), 0);
    });

    test('normalizes any angle onto a quarter turn', () {
      expect(service.normalizeRotation(450), 90);
      expect(service.normalizeRotation(-90), 270);
      expect(service.normalizeRotation(46), 90);
    });

    test('converts to radians', () {
      expect(service.rotationRadians(180), closeTo(math.pi, 0.0001));
      expect(service.rotationRadians(0), 0);
    });

    test('knows when width and height swap', () {
      expect(service.isQuarterTurned(90), isTrue);
      expect(service.isQuarterTurned(270), isTrue);
      expect(service.isQuarterTurned(0), isFalse);
      expect(service.isQuarterTurned(180), isFalse);
    });

    test('quarterTurns returns 0, 1, 2, or 3 clockwise turns', () {
      expect(service.quarterTurns(0), 0);
      expect(service.quarterTurns(90), 1);
      expect(service.quarterTurns(180), 2);
      expect(service.quarterTurns(270), 3);
      expect(service.quarterTurns(360), 0);
      expect(service.quarterTurns(-90), 3);
    });
  });

  group('dismiss', () {
    test('only starts on a downward drag of an unzoomed page', () {
      const atRest = ViewerTransform.initial;
      const zoomed = ViewerTransform(scale: 2.4);

      expect(service.canStartDismiss(atRest, const Offset(0, 12)), isTrue);
      expect(service.canStartDismiss(atRest, const Offset(0, -12)), isFalse);
      expect(service.canStartDismiss(zoomed, const Offset(0, 12)), isFalse);
    });

    test('reports progress between zero and one', () {
      expect(service.dismissProgress(0), 0);
      expect(
        service.dismissProgress(AppConstants.viewerDismissDistance / 2),
        closeTo(0.5, 0.0001),
      );
      expect(service.dismissProgress(10000), 1.0);
    });

    test('fades the backdrop and shrinks the page as the drag grows', () {
      expect(service.backdropOpacity(0), 1.0);
      expect(service.dismissScale(0), 1.0);

      final farOpacity = service.backdropOpacity(
        AppConstants.viewerDismissDistance,
      );
      final farScale = service.dismissScale(AppConstants.viewerDismissDistance);
      expect(farOpacity, lessThan(1.0));
      expect(farScale, lessThan(1.0));
    });

    test('closes on a long drag or a fast flick', () {
      expect(
        service.shouldDismissOnRelease(
          dismissOffset: AppConstants.viewerDismissDistance,
          velocityPixelsPerSecond: 0,
        ),
        isTrue,
      );
      expect(
        service.shouldDismissOnRelease(
          dismissOffset: 20,
          velocityPixelsPerSecond: 1500,
        ),
        isTrue,
      );
    });

    test('stays open on a short slow drag, and on no drag at all', () {
      expect(
        service.shouldDismissOnRelease(
          dismissOffset: 20,
          velocityPixelsPerSecond: 100,
        ),
        isFalse,
      );
      expect(
        service.shouldDismissOnRelease(
          dismissOffset: 0,
          velocityPixelsPerSecond: 5000,
        ),
        isFalse,
      );
    });
  });
}
