import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/gif_export_options.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';

void main() {
  group('effective values', () {
    test('a frame rate inside the offered range is used as it is', () {
      const options = GifExportOptions(frameRate: 12);
      expect(options.effectiveFrameRate, 12);
    });

    test('a frame rate outside the offered range is pulled back', () {
      expect(
        const GifExportOptions(frameRate: 1).effectiveFrameRate,
        AppConstants.gifFrameRates.first,
      );
      expect(
        const GifExportOptions(frameRate: 999).effectiveFrameRate,
        AppConstants.gifFrameRates.last,
      );
    });

    test('a size outside the offered range is pulled back', () {
      expect(
        const GifExportOptions(maxSide: 10).effectiveMaxSide,
        AppConstants.gifSizeChoices.first,
      );
      expect(
        const GifExportOptions(maxSide: 4000).effectiveMaxSide,
        AppConstants.gifSizeChoices.last,
      );
    });
  });

  group('frameDelayMs', () {
    test('the gap between frames follows the frame rate', () {
      expect(const GifExportOptions(frameRate: 10).frameDelayMs, 100);
      expect(const GifExportOptions(frameRate: 20).frameDelayMs, 50);
    });
  });

  group('copyWith', () {
    test('only the named field changes', () {
      const original = GifExportOptions(
        frameRate: 10,
        maxSide: 320,
        range: TrimRange(startMs: 0, endMs: 5000),
        loop: true,
      );

      final changed = original.copyWith(loop: false);

      expect(changed.loop, isFalse);
      expect(changed.frameRate, 10);
      expect(changed.maxSide, 320);
      expect(changed.range, original.range);
    });

    test('two option sets with the same values are equal', () {
      const a = GifExportOptions(frameRate: 8);
      const b = GifExportOptions(frameRate: 8);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
