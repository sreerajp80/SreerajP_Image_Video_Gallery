import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/viewer_transform.dart';

void main() {
  group('ViewerTransform', () {
    test('starts fitted, unrotated, and not being dragged', () {
      const transform = ViewerTransform.initial;

      expect(transform.scale, 1.0);
      expect(transform.rotationDegrees, 0);
      expect(transform.dismissOffset, 0);
      expect(transform.isAtRest, isTrue);
      expect(transform.isDismissing, isFalse);
    });

    test('is no longer at rest once zoomed in', () {
      expect(const ViewerTransform(scale: 1.4).isAtRest, isFalse);
      // A hair over 1.0 still counts as fitted, so floating point noise from a
      // pinch does not block paging.
      expect(const ViewerTransform(scale: 1.00005).isAtRest, isTrue);
    });

    test('knows when a dismiss drag is running', () {
      expect(const ViewerTransform(dismissOffset: 12).isDismissing, isTrue);
    });

    test('copyWith replaces only what it is given', () {
      const original = ViewerTransform(scale: 2, rotationDegrees: 90);
      final updated = original.copyWith(dismissOffset: 30);

      expect(updated.scale, 2);
      expect(updated.rotationDegrees, 90);
      expect(updated.dismissOffset, 30);
    });

    test('two transforms with the same values are equal', () {
      const a = ViewerTransform(scale: 2, rotationDegrees: 180);
      const b = ViewerTransform(scale: 2, rotationDegrees: 180);
      const c = ViewerTransform(scale: 2, rotationDegrees: 90);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}
