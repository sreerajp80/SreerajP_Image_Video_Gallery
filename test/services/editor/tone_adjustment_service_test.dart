import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_adjustment_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_curve_service.dart';

void main() {
  const curveService = ToneCurveService();
  const service = ToneAdjustmentService();

  group('ToneCurveService', () {
    test('the straight line maps every value to itself', () {
      final table = curveService.buildTable(ToneCurve.linear);

      expect(table[0], 0);
      expect(table[128], 128);
      expect(table[255], 255);
    });

    test('points are sorted, clamped, and de-duplicated', () {
      final cleaned = curveService.sanitize(const <CurvePoint>[
        CurvePoint(255, 300),
        CurvePoint(-20, -40),
        CurvePoint(128, 200),
      ]);

      expect(cleaned.first.input, 0);
      expect(cleaned.first.output, 0);
      expect(cleaned.last.input, 255);
      expect(cleaned.last.output, 255);
      expect(cleaned[1].input, 128);
    });

    test('a curve with too few usable points falls back to the line', () {
      final cleaned = curveService.sanitize(const <CurvePoint>[
        CurvePoint(10, 20),
      ]);

      expect(cleaned, ToneCurve.linear.points);
    });

    test('a NaN point is thrown away rather than breaking the table', () {
      final cleaned = curveService.sanitize(<CurvePoint>[
        const CurvePoint(0, 0),
        CurvePoint(double.nan, 100),
        const CurvePoint(255, 255),
      ]);

      expect(cleaned, hasLength(2));
    });

    test('a lifted middle point brightens the middle of the range', () {
      const curve = ToneCurve(<CurvePoint>[
        CurvePoint(0, 0),
        CurvePoint(128, 200),
        CurvePoint(255, 255),
      ]);
      final table = curveService.buildTable(curve);

      expect(table[128], greaterThan(150));
      // The two ends are pinned, so black stays black and white stays white.
      expect(table[0], 0);
      expect(table[255], 255);
    });

    test('values outside the shaped part are held flat', () {
      const points = <CurvePoint>[CurvePoint(50, 60), CurvePoint(200, 210)];

      expect(curveService.evaluate(points, 0), 60);
      expect(curveService.evaluate(points, 255), 210);
    });

    test('composing two tables runs one into the other', () {
      final invert = curveService.buildTable(
        const ToneCurve(<CurvePoint>[CurvePoint(0, 255), CurvePoint(255, 0)]),
      );
      final composed = curveService.compose(invert, invert);

      // Inverting twice is the same as doing nothing.
      expect(composed[0], closeTo(0, 2));
      expect(composed[255], closeTo(255, 2));
    });
  });

  group('ToneAdjustmentService sliders', () {
    test('exposure doubles the light at full positive', () {
      expect(service.applyExposure(100, 1), 200);
      expect(service.applyExposure(100, -1), 50);
      expect(service.applyExposure(100, 0), 100);
    });

    test('exposure never runs past white', () {
      expect(service.applyExposure(200, 1), 255);
    });

    test('contrast pivots around mid grey', () {
      // Mid grey is the pivot, so it does not move.
      expect(service.applyContrast(128, 0.5), 128);
      expect(service.applyContrast(200, 0.5), greaterThan(200));
      expect(service.applyContrast(50, 0.5), lessThan(50));
    });

    test('highlights only move the bright end', () {
      expect(service.applyHighlights(50, 1), 50);
      expect(service.applyHighlights(240, 1), greaterThan(240));
    });

    test('shadows only move the dark end', () {
      expect(service.applyShadows(200, 1), 200);
      expect(service.applyShadows(20, 1), greaterThan(20));
    });

    test('an out of range slider is pulled back rather than exploding', () {
      expect(service.applyExposure(100, 50), service.applyExposure(100, 1));
      expect(service.applyContrast(100, double.nan), 100);
    });
  });

  group('ToneAdjustmentService tables', () {
    test('neutral settings give the identity tables', () {
      final tables = service.buildTables(ToneAdjustments.neutral);

      expect(tables.isIdentity, isTrue);
      expect(tables.needsColorPass, isFalse);
    });

    test('warming the photo lifts red and drops blue', () {
      final tables = service.buildTables(const ToneAdjustments(temperature: 1));

      expect(tables.red[128], greaterThan(128));
      expect(tables.blue[128], lessThan(128));
      expect(tables.green[128], 128);
    });

    test('cooling the photo does the opposite', () {
      final tables = service.buildTables(
        const ToneAdjustments(temperature: -1),
      );

      expect(tables.red[128], lessThan(128));
      expect(tables.blue[128], greaterThan(128));
    });

    test('saturation and vibrance are carried for the per-pixel pass', () {
      final tables = service.buildTables(
        const ToneAdjustments(saturation: 0.4, vibrance: -0.2),
      );

      expect(tables.needsColorPass, isTrue);
      expect(tables.saturation, 0.4);
      expect(tables.vibrance, -0.2);
    });

    test('a curve is folded into the channel tables', () {
      final tables = service.buildTables(
        const ToneAdjustments(
          rgbCurve: ToneCurve(<CurvePoint>[
            CurvePoint(0, 0),
            CurvePoint(128, 200),
            CurvePoint(255, 255),
          ]),
        ),
      );

      expect(tables.red[128], greaterThan(150));
      expect(tables.green[128], greaterThan(150));
      expect(tables.blue[128], greaterThan(150));
    });
  });

  group('applyColor', () {
    test('nothing set leaves the pixel alone', () {
      expect(service.applyColor(10, 20, 30, 0, 0), <int>[10, 20, 30]);
    });

    test('full negative saturation makes the pixel grey', () {
      final result = service.applyColor(200, 100, 50, -1, 0);

      expect(result[0], result[1]);
      expect(result[1], result[2]);
    });

    test('positive saturation pushes colours further apart', () {
      final result = service.applyColor(200, 100, 50, 0.5, 0);

      expect(result[0] - result[2], greaterThan(150));
    });

    test('vibrance lifts a dull colour more than a vivid one', () {
      final grey = service.luminance(120, 118, 116);
      final dull = service.applyColor(120, 118, 116, 0, 1);
      final dullLift = (dull[0] - grey).abs();

      final vividGrey = service.luminance(250, 10, 10);
      final vivid = service.applyColor(250, 10, 10, 0, 1);
      final vividLift = (vivid[0] - vividGrey).abs();

      // The vivid pixel is already saturated, so vibrance barely touches it
      // relative to how far it could go.
      expect(dullLift / 4, lessThan(vividLift));
      expect(dull[0], isNot(120));
    });

    test('the result always stays inside 0 to 255', () {
      final result = service.applyColor(255, 0, 0, 1, 1);

      for (final channel in result) {
        expect(channel, inInclusiveRange(0, 255));
      }
    });
  });
}
