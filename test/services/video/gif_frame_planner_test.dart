import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';
import 'package:in_sreerajp_imgvidgal/services/video/gif_frame_planner.dart';

void main() {
  const planner = GifFramePlanner();

  group('plan', () {
    test('frames are spaced by the chosen frame rate', () {
      final times = planner.plan(
        options: const GifExportOptions(
          frameRate: 10,
          range: TrimRange(startMs: 0, endMs: 500),
        ),
        clipDurationMs: 5000,
      );

      expect(times, <int>[0, 100, 200, 300, 400]);
    });

    test('planning starts at the chosen start time', () {
      final times = planner.plan(
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 1000, endMs: 1600),
        ),
        clipDurationMs: 5000,
      );

      expect(times.first, 1000);
      expect(times, <int>[1000, 1200, 1400]);
    });

    test('a range running past the clip is cut at the clip end', () {
      final times = planner.plan(
        options: const GifExportOptions(
          frameRate: 10,
          range: TrimRange(startMs: 0, endMs: 999999),
        ),
        clipDurationMs: 300,
      );

      expect(times, <int>[0, 100, 200]);
    });

    test('an end of zero means the whole clip', () {
      final times = planner.plan(
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 0, endMs: 0),
        ),
        clipDurationMs: 600,
      );

      expect(times, <int>[0, 200, 400]);
    });

    test('the frame count never runs past the cap', () {
      final times = planner.plan(
        options: const GifExportOptions(
          frameRate: 20,
          range: TrimRange(startMs: 0, endMs: 60000),
        ),
        clipDurationMs: 60000,
      );

      expect(times.length, AppConstants.gifMaxFrames);
    });

    test('a very long range is cut to the longest slice allowed', () {
      final times = planner.plan(
        options: const GifExportOptions(
          frameRate: 5,
          range: TrimRange(startMs: 0, endMs: 120000),
        ),
        clipDurationMs: 120000,
      );

      expect(times.last, lessThan(AppConstants.gifMaxDurationMs));
    });

    test('a clip with no length plans nothing', () {
      final times = planner.plan(
        options: const GifExportOptions(),
        clipDurationMs: 0,
      );

      expect(times, isEmpty);
    });

    test('a slice with no length still gives one frame', () {
      final times = planner.plan(
        options: const GifExportOptions(
          range: TrimRange(startMs: 2000, endMs: 2000),
        ),
        clipDurationMs: 5000,
      );

      expect(times, <int>[2000]);
    });
  });

  group('frameCount and isCapped', () {
    test('the count matches the plan', () {
      const options = GifExportOptions(
        frameRate: 10,
        range: TrimRange(startMs: 0, endMs: 1000),
      );

      expect(
        planner.frameCount(options: options, clipDurationMs: 5000),
        planner.plan(options: options, clipDurationMs: 5000).length,
      );
    });

    test('a short selection is not reported as capped', () {
      expect(
        planner.isCapped(
          options: const GifExportOptions(
            frameRate: 5,
            range: TrimRange(startMs: 0, endMs: 1000),
          ),
          clipDurationMs: 5000,
        ),
        isFalse,
      );
    });

    test('an over-long selection is reported as capped', () {
      expect(
        planner.isCapped(
          options: const GifExportOptions(
            frameRate: 5,
            range: TrimRange(startMs: 0, endMs: 120000),
          ),
          clipDurationMs: 120000,
        ),
        isTrue,
      );
    });
  });
}
