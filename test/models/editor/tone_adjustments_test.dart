import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';

void main() {
  group('ToneCurve', () {
    test('the straight line leaves a channel alone', () {
      expect(ToneCurve.linear.isLinear, isTrue);
    });

    test('a shaped curve is no longer linear', () {
      const curve = ToneCurve(<CurvePoint>[
        CurvePoint(0, 0),
        CurvePoint(128, 180),
        CurvePoint(255, 255),
      ]);

      expect(curve.isLinear, isFalse);
    });

    test('adding a point keeps the list sorted by input', () {
      final curve = ToneCurve.linear.withPoint(const CurvePoint(100, 140));

      expect(curve.points.map((p) => p.input), <double>[0, 100, 255]);
    });

    test('survives a round trip through a map', () {
      const curve = ToneCurve(<CurvePoint>[
        CurvePoint(0, 10),
        CurvePoint(255, 240),
      ]);

      expect(ToneCurve.fromMap(curve.toMap()), curve);
    });

    test('a map with no usable points reads back as the straight line', () {
      expect(
        ToneCurve.fromMap(const <String, dynamic>{'points': <dynamic>[]}),
        ToneCurve.linear,
      );
    });
  });

  group('ToneAdjustments', () {
    test('nothing moved means neutral', () {
      expect(ToneAdjustments.neutral.isNeutral, isTrue);
      expect(ToneAdjustments.neutral.hasCurves, isFalse);
    });

    test('one slider moved breaks neutral', () {
      expect(const ToneAdjustments(exposure: 0.1).isNeutral, isFalse);
      expect(const ToneAdjustments(saturation: -0.4).isNeutral, isFalse);
    });

    test('a shaped curve breaks neutral too', () {
      const adjustments = ToneAdjustments(
        redCurve: ToneCurve(<CurvePoint>[
          CurvePoint(0, 0),
          CurvePoint(120, 160),
          CurvePoint(255, 255),
        ]),
      );

      expect(adjustments.isNeutral, isFalse);
      expect(adjustments.hasCurves, isTrue);
    });

    test('copyWith replaces only what it is given', () {
      const original = ToneAdjustments(exposure: 0.5, contrast: -0.2);
      final updated = original.copyWith(vibrance: 0.3);

      expect(updated.exposure, 0.5);
      expect(updated.contrast, -0.2);
      expect(updated.vibrance, 0.3);
    });

    test('survives a round trip through a map', () {
      const adjustments = ToneAdjustments(
        exposure: 0.2,
        contrast: -0.1,
        highlights: 0.4,
        shadows: -0.3,
        temperature: 0.6,
        tint: -0.2,
        vibrance: 0.5,
        saturation: -0.4,
        rgbCurve: ToneCurve(<CurvePoint>[
          CurvePoint(0, 8),
          CurvePoint(255, 250),
        ]),
      );

      expect(ToneAdjustments.fromMap(adjustments.toMap()), adjustments);
    });

    test('an empty map reads back as neutral', () {
      expect(
        ToneAdjustments.fromMap(const <String, dynamic>{}),
        ToneAdjustments.neutral,
      );
    });
  });
}
