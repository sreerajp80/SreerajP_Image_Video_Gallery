import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/providers/video_tools_providers.dart';

void main() {
  group('GifOptionsNotifier', () {
    test('a short clip is used whole', () {
      final notifier = GifOptionsNotifier(clipDurationMs: 4000);
      addTearDown(notifier.dispose);

      expect(notifier.state.range.startMs, 0);
      expect(notifier.state.range.endMs, 4000);
    });

    test('a long clip is cut to the GIF limit', () {
      final notifier = GifOptionsNotifier(
        clipDurationMs: AppConstants.gifMaxDurationMs * 3,
      );
      addTearDown(notifier.dispose);

      expect(notifier.state.range.endMs, AppConstants.gifMaxDurationMs);
    });

    test('stores frame rate, size, loop and range', () {
      final notifier = GifOptionsNotifier(clipDurationMs: 4000);
      addTearDown(notifier.dispose);

      notifier
        ..setFrameRate(12)
        ..setMaxSide(320)
        ..setLoop(false)
        ..setRange(const TrimRange(startMs: 1000, endMs: 2000));

      expect(notifier.state.frameRate, 12);
      expect(notifier.state.maxSide, 320);
      expect(notifier.state.loop, isFalse);
      expect(notifier.state.range.startMs, 1000);
    });
  });

  group('TrimRangeNotifier', () {
    late TrimRangeNotifier notifier;

    setUp(() => notifier = TrimRangeNotifier(clipDurationMs: 10000));
    tearDown(() => notifier.dispose());

    test('starts on the whole clip', () {
      expect(notifier.state.startMs, 0);
      expect(notifier.state.endMs, 10000);
    });

    test('the start never passes the end', () {
      notifier.setEnd(5000);
      notifier.setStart(9000);

      expect(notifier.state.startMs, 5000 - AppConstants.trimMinDurationMs);
    });

    test('the end never comes before the start or after the clip', () {
      notifier.setStart(4000);
      notifier.setEnd(100);
      expect(notifier.state.endMs, 4000 + AppConstants.trimMinDurationMs);

      notifier.setEnd(99999);
      expect(notifier.state.endMs, 10000);
    });

    test('a negative start is held at zero', () {
      notifier.setStart(-50);
      expect(notifier.state.startMs, 0);
    });

    test('reset goes back to the whole clip', () {
      notifier
        ..setStart(3000)
        ..reset();

      expect(notifier.state.startMs, 0);
      expect(notifier.state.endMs, 10000);
    });
  });
}
