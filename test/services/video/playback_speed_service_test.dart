import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/video/playback_speed_service.dart';

void main() {
  const service = PlaybackSpeedService();

  test('the ladder runs from a quarter speed to double speed', () {
    expect(PlaybackSpeedService.speeds.first, 0.25);
    expect(PlaybackSpeedService.speeds.last, 2.0);
    expect(service.minSpeed, 0.25);
    expect(service.maxSpeed, 2.0);
  });

  group('nearest', () {
    test('keeps a speed that is already on the ladder', () {
      expect(service.nearest(1.5), 1.5);
    });

    test('snaps an in-between value to the closest step', () {
      expect(service.nearest(0.9), 1.0);
      expect(service.nearest(1.6), 1.5);
    });

    test('snaps values outside the ladder to the ends', () {
      expect(service.nearest(0.01), 0.25);
      expect(service.nearest(9.0), 2.0);
    });

    test('falls back to normal speed for a broken value', () {
      expect(service.nearest(double.nan), 1.0);
    });
  });

  group('stepping', () {
    test('moves one step at a time', () {
      expect(service.faster(1.0), 1.25);
      expect(service.slower(1.0), 0.75);
    });

    test('stops at the ends instead of going past them', () {
      expect(service.faster(2.0), 2.0);
      expect(service.slower(0.25), 0.25);
      expect(service.canGoFaster(2.0), isFalse);
      expect(service.canGoSlower(0.25), isFalse);
      expect(service.canGoFaster(1.0), isTrue);
      expect(service.canGoSlower(1.0), isTrue);
    });
  });

  group('label', () {
    test('drops the decimal part of a whole speed', () {
      expect(service.label(1.0), '1x');
      expect(service.label(2.0), '2x');
    });

    test('keeps the decimal part of a fractional speed', () {
      expect(service.label(0.25), '0.25x');
      expect(service.label(1.75), '1.75x');
    });
  });
}
