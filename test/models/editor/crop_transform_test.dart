import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';

void main() {
  group('NormalizedRect', () {
    test('the full rectangle covers the whole image', () {
      expect(NormalizedRect.full.isFull, isTrue);
      expect(NormalizedRect.full.width, 1);
      expect(NormalizedRect.full.height, 1);
      expect(NormalizedRect.full.isValid, isTrue);
    });

    test('a backwards or outside rectangle is not valid', () {
      const backwards = NormalizedRect(
        left: 0.8,
        top: 0.1,
        right: 0.2,
        bottom: 0.9,
      );
      const outside = NormalizedRect(left: -0.1, top: 0, right: 1, bottom: 1);

      expect(backwards.isValid, isFalse);
      expect(outside.isValid, isFalse);
    });

    test('survives a round trip through a map', () {
      const rect = NormalizedRect(left: 0.1, top: 0.2, right: 0.7, bottom: 0.8);

      expect(NormalizedRect.fromMap(rect.toMap()), rect);
    });
  });

  group('CropAspectPreset', () {
    test('fixed shapes report their ratio', () {
      expect(CropAspectPreset.square.ratio, 1);
      expect(CropAspectPreset.ratio16x9.ratio, closeTo(16 / 9, 0.0001));
      expect(CropAspectPreset.ratio3x4.ratio, closeTo(3 / 4, 0.0001));
    });

    test('free and original have no ratio of their own', () {
      expect(CropAspectPreset.free.ratio, isNull);
      expect(CropAspectPreset.original.ratio, isNull);
    });

    test('an unknown stored name falls back to free', () {
      expect(CropAspectPreset.fromName('ratio5x4'), CropAspectPreset.free);
      expect(CropAspectPreset.fromName('square'), CropAspectPreset.square);
    });
  });

  group('PerspectiveSkew', () {
    test('no correction is the identity', () {
      expect(PerspectiveSkew.none.isIdentity, isTrue);
      expect(const PerspectiveSkew(topInset: 0.2).isIdentity, isFalse);
    });

    test('survives a round trip through a map', () {
      const skew = PerspectiveSkew(topInset: 0.1, rightInset: -0.05);
      expect(PerspectiveSkew.fromMap(skew.toMap()), skew);
    });
  });

  group('CropTransform', () {
    test('an untouched transform changes nothing', () {
      expect(CropTransform.identity.isIdentity, isTrue);
    });

    test('every field breaks the identity on its own', () {
      expect(const CropTransform(quarterTurns: 1).isIdentity, isFalse);
      expect(const CropTransform(straightenDegrees: 0.5).isIdentity, isFalse);
      expect(const CropTransform(flipHorizontal: true).isIdentity, isFalse);
      expect(const CropTransform(flipVertical: true).isIdentity, isFalse);
      expect(
        const CropTransform(
          perspective: PerspectiveSkew(bottomInset: 0.1),
        ).isIdentity,
        isFalse,
      );
      expect(
        const CropTransform(
          rect: NormalizedRect(left: 0.1, top: 0, right: 1, bottom: 1),
        ).isIdentity,
        isFalse,
      );
    });

    test('copyWith replaces only what it is given', () {
      const original = CropTransform(quarterTurns: 2, flipVertical: true);
      final updated = original.copyWith(straightenDegrees: 4);

      expect(updated.quarterTurns, 2);
      expect(updated.flipVertical, isTrue);
      expect(updated.straightenDegrees, 4);
    });

    test('survives a round trip through a map', () {
      const transform = CropTransform(
        rect: NormalizedRect(left: 0.05, top: 0.1, right: 0.9, bottom: 0.95),
        aspectPreset: CropAspectPreset.ratio16x9,
        quarterTurns: 3,
        straightenDegrees: -12.5,
        flipHorizontal: true,
        perspective: PerspectiveSkew(topInset: 0.2, leftInset: -0.1),
      );

      expect(CropTransform.fromMap(transform.toMap()), transform);
    });

    test('a map missing everything reads back as the identity', () {
      expect(
        CropTransform.fromMap(const <String, dynamic>{}),
        CropTransform.identity,
      );
    });
  });
}
