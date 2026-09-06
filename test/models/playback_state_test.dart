import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/playback_state.dart';

void main() {
  group('PlaybackState', () {
    test('starts empty, stopped, and without an error', () {
      const state = PlaybackState.initial;

      expect(state.isInitialized, isFalse);
      expect(state.isPlaying, isFalse);
      expect(state.hasError, isFalse);
      expect(state.isReady, isFalse);
      expect(state.position, Duration.zero);
      expect(state.speed, 1.0);
    });

    test('is ready only once loaded and free of errors', () {
      const loaded = PlaybackState(isInitialized: true);
      const failed = PlaybackState(
        isInitialized: true,
        error: PlaybackError.unsupportedFormat,
      );

      expect(loaded.isReady, isTrue);
      expect(failed.isReady, isFalse);
      expect(failed.hasError, isTrue);
    });

    group('progress', () {
      test('is the position as a fraction of the clip', () {
        const state = PlaybackState(
          position: Duration(seconds: 30),
          duration: Duration(minutes: 1),
        );
        expect(state.progress, closeTo(0.5, 0.0001));
      });

      test('is zero for a clip of unknown length', () {
        expect(const PlaybackState().progress, 0);
      });

      test('never goes above one, even past the end', () {
        const state = PlaybackState(
          position: Duration(seconds: 90),
          duration: Duration(minutes: 1),
        );
        expect(state.progress, 1.0);
      });
    });

    group('remaining', () {
      test('counts down to the end of the clip', () {
        const state = PlaybackState(
          position: Duration(seconds: 20),
          duration: Duration(seconds: 60),
        );
        expect(state.remaining, const Duration(seconds: 40));
      });

      test('is never negative', () {
        const state = PlaybackState(
          position: Duration(seconds: 90),
          duration: Duration(seconds: 60),
        );
        expect(state.remaining, Duration.zero);
      });
    });

    test('copyWith replaces only what it is given', () {
      const original = PlaybackState(isInitialized: true, speed: 1.5);
      final updated = original.copyWith(isPlaying: true);

      expect(updated.isInitialized, isTrue);
      expect(updated.speed, 1.5);
      expect(updated.isPlaying, isTrue);
    });

    test('two states with the same values are equal', () {
      const a = PlaybackState(
        isInitialized: true,
        position: Duration(seconds: 2),
      );
      const b = PlaybackState(
        isInitialized: true,
        position: Duration(seconds: 2),
      );
      const c = PlaybackState(
        isInitialized: true,
        position: Duration(seconds: 3),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
