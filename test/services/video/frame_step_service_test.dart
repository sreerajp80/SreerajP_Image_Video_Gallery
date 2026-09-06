import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/video/frame_step_service.dart';

void main() {
  const service = FrameStepService();
  const duration = Duration(seconds: 10);

  group('frame stepping', () {
    test('moves one frame forward', () {
      final result = service.nextFrame(
        position: const Duration(seconds: 1),
        duration: duration,
      );
      expect(result.inMilliseconds, 1000 + AppConstants.frameStepMs);
    });

    test('moves one frame back', () {
      final result = service.previousFrame(
        position: const Duration(seconds: 1),
        duration: duration,
      );
      expect(result.inMilliseconds, 1000 - AppConstants.frameStepMs);
    });

    test('never runs off the end of the clip', () {
      expect(
        service.nextFrame(position: duration, duration: duration),
        duration,
      );
    });

    test('never runs before the start of the clip', () {
      expect(
        service.previousFrame(position: Duration.zero, duration: duration),
        Duration.zero,
      );
    });
  });

  group('skipping', () {
    test('jumps ten seconds by default', () {
      final result = service.skipForward(
        position: const Duration(seconds: 5),
        duration: const Duration(minutes: 2),
      );
      expect(result, const Duration(seconds: 15));
    });

    test('clamps a skip to the clip bounds', () {
      expect(
        service.skipForward(
          position: const Duration(seconds: 5),
          duration: duration,
        ),
        duration,
      );
      expect(
        service.skipBackward(
          position: const Duration(seconds: 5),
          duration: duration,
        ),
        Duration.zero,
      );
    });
  });

  group('canStep', () {
    test('is false for a clip of unknown length', () {
      expect(service.canStep(Duration.zero), isFalse);
    });

    test('is true for a real clip', () {
      expect(service.canStep(duration), isTrue);
    });
  });

  test('a step on an uninitialised player lands at the start', () {
    expect(
      service.nextFrame(
        position: const Duration(seconds: 3),
        duration: Duration.zero,
      ),
      Duration.zero,
    );
  });
}
