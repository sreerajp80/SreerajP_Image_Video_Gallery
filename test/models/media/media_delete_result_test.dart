import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_delete_result.dart';

void main() {
  group('MediaDeleteOutcome.fromPlatform', () {
    test('reads the known words', () {
      expect(
        MediaDeleteOutcome.fromPlatform('overwritten'),
        MediaDeleteOutcome.overwritten,
      );
      expect(
        MediaDeleteOutcome.fromPlatform('deleted'),
        MediaDeleteOutcome.deleted,
      );
      expect(
        MediaDeleteOutcome.fromPlatform('failed'),
        MediaDeleteOutcome.failed,
      );
    });

    test('anything unknown is a failure, never a success', () {
      expect(MediaDeleteOutcome.fromPlatform(null), MediaDeleteOutcome.failed);
      expect(MediaDeleteOutcome.fromPlatform(1), MediaDeleteOutcome.failed);
      expect(
        MediaDeleteOutcome.fromPlatform('gone'),
        MediaDeleteOutcome.failed,
      );
    });
  });

  group('MediaDeleteResult.fromOutcomes', () {
    test('counts each outcome', () {
      final result = MediaDeleteResult.fromOutcomes(<MediaDeleteOutcome>[
        MediaDeleteOutcome.overwritten,
        MediaDeleteOutcome.deleted,
        MediaDeleteOutcome.failed,
        MediaDeleteOutcome.overwritten,
      ], secure: true);

      expect(result.deleted, 3);
      expect(result.overwritten, 2);
      expect(result.failed, 1);
      expect(result.notOverwritten, 1);
      expect(result.anyDeleted, isTrue);
    });

    test('a plain delete never reports files as not overwritten', () {
      final result = MediaDeleteResult.fromOutcomes(<MediaDeleteOutcome>[
        MediaDeleteOutcome.deleted,
      ], secure: false);

      expect(result.notOverwritten, 0);
    });
  });
}
