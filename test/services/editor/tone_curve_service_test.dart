import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_curve_service.dart';

void main() {
  const service = ToneCurveService();

  group('ToneCurveService cubic spline', () {
    test('linear curve produces an identity table', () {
      final table = service.buildTable(ToneCurve.linear);
      expect(table.length, 256);
      for (var i = 0; i < 256; i++) {
        expect(table[i], i);
      }
    });

    test('evaluates accurately through provided control points', () {
      const points = <CurvePoint>[
        CurvePoint(0, 0),
        CurvePoint(64, 100),
        CurvePoint(192, 150),
        CurvePoint(255, 255),
      ];

      // At exact knot locations, cubic spline matches target outputs (within rounding/float margin).
      expect(service.evaluate(points, 0).round(), 0);
      expect(service.evaluate(points, 64).round(), closeTo(100, 1));
      expect(service.evaluate(points, 192).round(), closeTo(150, 1));
      expect(service.evaluate(points, 255).round(), 255);
    });

    test(
      'smooth S-curve interpolation is continuous and monotonic for standard contrast',
      () {
        const sCurve = ToneCurve(<CurvePoint>[
          CurvePoint(0, 0),
          CurvePoint(64, 40),
          CurvePoint(192, 215),
          CurvePoint(255, 255),
        ]);
        final table = service.buildTable(sCurve);

        // Verify monotonicity (outputs should not jump backwards).
        for (var i = 1; i < 256; i++) {
          expect(table[i], greaterThanOrEqualTo(table[i - 1]));
        }

        // Shadows darkened, highlights lifted.
        expect(table[64], lessThan(64));
        expect(table[192], greaterThan(192));
      },
    );

    test(
      'outputs are always clamped between 0 and 255 even with extreme points',
      () {
        const extremePoints = <CurvePoint>[
          CurvePoint(0, 0),
          CurvePoint(20, 255),
          CurvePoint(50, 0),
          CurvePoint(255, 255),
        ];
        final table = service.buildTable(const ToneCurve(extremePoints));

        for (var i = 0; i < 256; i++) {
          expect(table[i], inInclusiveRange(0, 255));
        }
      },
    );

    test(
      'extrapolations before first point and after last point remain clamped flat',
      () {
        const partialCurve = <CurvePoint>[
          CurvePoint(50, 80),
          CurvePoint(200, 180),
        ];

        expect(service.evaluate(partialCurve, 10), 80);
        expect(service.evaluate(partialCurve, 250), 180);
      },
    );

    test('composing two tables chains the mappings correctly', () {
      // Invert table
      final invert = service.buildTable(
        const ToneCurve(<CurvePoint>[CurvePoint(0, 255), CurvePoint(255, 0)]),
      );

      // Compose invert with invert should return identity
      final roundTrip = service.compose(invert, invert);
      for (var i = 0; i < 256; i++) {
        expect(roundTrip[i], i);
      }
    });
  });
}
