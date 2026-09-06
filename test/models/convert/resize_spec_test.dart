import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';

void main() {
  group('isIdentity', () {
    test('the default spec changes nothing', () {
      expect(ResizeSpec.original.isIdentity, isTrue);
    });

    test('a percent of exactly 100 changes nothing', () {
      const spec = ResizeSpec(mode: ResizeMode.percent, percent: 100);
      expect(spec.isIdentity, isTrue);
    });

    test('any other percent does change something', () {
      const spec = ResizeSpec(mode: ResizeMode.percent, percent: 50);
      expect(spec.isIdentity, isFalse);
    });

    test('a longest side is never an identity', () {
      const spec = ResizeSpec(mode: ResizeMode.longestSide, longestSide: 800);
      expect(spec.isIdentity, isFalse);
    });
  });

  group('copyWith', () {
    test('only the named fields change', () {
      const original = ResizeSpec(
        mode: ResizeMode.exact,
        width: 800,
        height: 600,
        keepAspect: false,
      );

      final changed = original.copyWith(width: 1024);

      expect(changed.width, 1024);
      expect(changed.height, 600);
      expect(changed.mode, ResizeMode.exact);
      expect(changed.keepAspect, isFalse);
    });
  });

  group('serialisation', () {
    test('a spec survives a round trip through a map', () {
      const original = ResizeSpec(
        mode: ResizeMode.longestSide,
        longestSide: 1440,
        width: 100,
        height: 200,
        percent: 55,
        keepAspect: false,
      );

      expect(ResizeSpec.fromMap(original.toMap()), original);
    });

    test('a map missing everything gives the defaults', () {
      expect(ResizeSpec.fromMap(<String, dynamic>{}), ResizeSpec.original);
    });

    test('an unknown mode name falls back to no resize', () {
      final spec = ResizeSpec.fromMap(<String, dynamic>{'mode': 'stretchy'});
      expect(spec.mode, ResizeMode.none);
    });
  });

  group('equality', () {
    test('two specs with the same values are equal', () {
      const a = ResizeSpec(mode: ResizeMode.percent, percent: 40);
      const b = ResizeSpec(mode: ResizeMode.percent, percent: 40);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
