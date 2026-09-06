import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_gesture_service.dart';

void main() {
  const service = VideoGestureService();
  const surface = Size(400, 800);

  group('classify', () {
    test('a sideways drag seeks', () {
      expect(
        service.classify(
          startPosition: const Offset(200, 400),
          delta: const Offset(12, 2),
          surfaceSize: surface,
        ),
        VideoGestureKind.seek,
      );
    });

    test('a vertical drag on the left half changes brightness', () {
      expect(
        service.classify(
          startPosition: const Offset(50, 400),
          delta: const Offset(1, -10),
          surfaceSize: surface,
        ),
        VideoGestureKind.brightness,
      );
    });

    test('a vertical drag on the right half changes volume', () {
      expect(
        service.classify(
          startPosition: const Offset(350, 400),
          delta: const Offset(1, -10),
          surfaceSize: surface,
        ),
        VideoGestureKind.volume,
      );
    });

    test('a still finger and an empty surface mean nothing', () {
      expect(
        service.classify(
          startPosition: const Offset(200, 400),
          delta: Offset.zero,
          surfaceSize: surface,
        ),
        VideoGestureKind.none,
      );
      expect(
        service.classify(
          startPosition: const Offset(200, 400),
          delta: const Offset(0, 10),
          surfaceSize: Size.zero,
        ),
        VideoGestureKind.none,
      );
    });
  });

  group('applyLevelDrag', () {
    test('dragging up raises the level', () {
      final result = service.applyLevelDrag(
        currentLevel: 0.5,
        deltaY: -AppConstants.videoLevelDragReferencePx / 2,
      );
      expect(result, closeTo(1.0, 0.0001));
    });

    test('dragging down lowers the level', () {
      final result = service.applyLevelDrag(
        currentLevel: 0.5,
        deltaY: AppConstants.videoLevelDragReferencePx / 2,
      );
      expect(result, closeTo(0.0, 0.0001));
    });

    test('never leaves the zero to one range', () {
      expect(service.applyLevelDrag(currentLevel: 1.0, deltaY: -5000), 1.0);
      expect(service.applyLevelDrag(currentLevel: 0.0, deltaY: 5000), 0.0);
    });

    test('survives a broken value', () {
      expect(
        service.applyLevelDrag(currentLevel: 0.4, deltaY: double.nan),
        0.4,
      );
      expect(service.clampLevel(double.nan), 0);
    });
  });

  group('applySeekDrag', () {
    const duration = Duration(minutes: 1);

    test('a full reference drag crosses the whole clip', () {
      final result = service.applySeekDrag(
        position: Duration.zero,
        duration: duration,
        deltaX: AppConstants.videoSeekDragReferencePx,
      );
      expect(result, duration);
    });

    test('dragging left moves the playhead back', () {
      final result = service.applySeekDrag(
        position: const Duration(seconds: 30),
        duration: duration,
        deltaX: -AppConstants.videoSeekDragReferencePx / 2,
      );
      expect(result, const Duration(seconds: 0));
    });

    test('caps how far one drag can jump in a long clip', () {
      final result = service.applySeekDrag(
        position: Duration.zero,
        duration: const Duration(hours: 3),
        deltaX: AppConstants.videoSeekDragReferencePx,
      );
      expect(
        result.inMilliseconds,
        lessThanOrEqualTo(AppConstants.videoSeekDragMaxMs),
      );
    });

    test('does nothing on a clip of unknown length', () {
      expect(
        service.applySeekDrag(
          position: Duration.zero,
          duration: Duration.zero,
          deltaX: 200,
        ),
        Duration.zero,
      );
    });
  });

  group('positionForFraction', () {
    test('maps a fraction onto the clip', () {
      expect(
        service.positionForFraction(
          fraction: 0.5,
          duration: const Duration(seconds: 20),
        ),
        const Duration(seconds: 10),
      );
    });

    test('clamps a fraction outside zero to one', () {
      expect(
        service.positionForFraction(
          fraction: 3,
          duration: const Duration(seconds: 20),
        ),
        const Duration(seconds: 20),
      );
      expect(
        service.positionForFraction(
          fraction: -1,
          duration: const Duration(seconds: 20),
        ),
        Duration.zero,
      );
    });
  });

  group('formatDuration', () {
    test('shows minutes and seconds for a short clip', () {
      expect(service.formatDuration(const Duration(seconds: 5)), '0:05');
      expect(
        service.formatDuration(const Duration(minutes: 3, seconds: 7)),
        '3:07',
      );
    });

    test('adds hours for a long clip', () {
      expect(
        service.formatDuration(
          const Duration(hours: 1, minutes: 2, seconds: 3),
        ),
        '1:02:03',
      );
    });

    test('shows zero for a negative value', () {
      expect(service.formatDuration(const Duration(seconds: -5)), '0:00');
    });
  });
}
