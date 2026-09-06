import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/video/trim_range.dart';

void main() {
  group('durationMs', () {
    test('the length is the gap between the two handles', () {
      const range = TrimRange(startMs: 1000, endMs: 4000);
      expect(range.durationMs, 3000);
    });

    test('a backwards range reports no length rather than a negative one', () {
      const range = TrimRange(startMs: 4000, endMs: 1000);
      expect(range.durationMs, 0);
    });
  });

  group('isValid', () {
    test('a range at least as long as the minimum is usable', () {
      const range = TrimRange(
        startMs: 0,
        endMs: AppConstants.trimMinDurationMs,
      );
      expect(range.isValid, isTrue);
    });

    test('a range shorter than the minimum is not usable', () {
      const range = TrimRange(
        startMs: 0,
        endMs: AppConstants.trimMinDurationMs - 1,
      );
      expect(range.isValid, isFalse);
    });

    test('a negative start is not usable', () {
      const range = TrimRange(startMs: -10, endMs: 5000);
      expect(range.isValid, isFalse);
    });
  });

  group('whole', () {
    test('it covers the entire clip', () {
      final range = TrimRange.whole(12000);

      expect(range.startMs, 0);
      expect(range.endMs, 12000);
      expect(range.coversAll(12000), isTrue);
    });

    test(
      'a negative duration gives an empty range rather than a broken one',
      () {
        final range = TrimRange.whole(-5);

        expect(range.startMs, 0);
        expect(range.endMs, 0);
      },
    );
  });

  group('copyWith and equality', () {
    test('only the named field changes', () {
      const original = TrimRange(startMs: 100, endMs: 900);
      final changed = original.copyWith(endMs: 1500);

      expect(changed.startMs, 100);
      expect(changed.endMs, 1500);
    });

    test('two ranges with the same handles are equal', () {
      const a = TrimRange(startMs: 1, endMs: 2);
      const b = TrimRange(startMs: 1, endMs: 2);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
