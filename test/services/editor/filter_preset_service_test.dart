import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/filter_preset_service.dart';

void main() {
  const service = FilterPresetService();

  group('FilterPresetService', () {
    test('every preset in the enum has a definition', () {
      for (final id in FilterPresetId.values) {
        expect(service.definitionFor(id), isNotNull);
      }
    });

    test('the none preset changes nothing', () {
      expect(service.definitionFor(FilterPresetId.none).isNeutral, isTrue);
    });

    test('every other preset actually does something', () {
      for (final id in FilterPresetId.values) {
        if (id == FilterPresetId.none) continue;
        expect(
          service.definitionFor(id).isNeutral,
          isFalse,
          reason: '${id.name} should change the photo',
        );
      }
    });

    test('mono drains the colour, sepia drains it and tints it', () {
      expect(service.definitionFor(FilterPresetId.mono).monochrome, isTrue);

      final sepia = service.definitionFor(FilterPresetId.sepia);
      expect(sepia.monochrome, isTrue);
      expect(sepia.tintStrength, greaterThan(0));
    });

    test('warm and cool pull the temperature opposite ways', () {
      final warm = service.definitionFor(FilterPresetId.warm);
      final cool = service.definitionFor(FilterPresetId.cool);

      expect(warm.adjustments.temperature, greaterThan(0));
      expect(cool.adjustments.temperature, lessThan(0));
    });

    test('full strength gives the preset exactly as defined', () {
      final resolved = service.resolve(
        const FilterPreset(id: FilterPresetId.vivid),
      );

      expect(
        resolved.adjustments,
        service.definitionFor(FilterPresetId.vivid).adjustments,
      );
    });

    test('half strength gives half the effect', () {
      final full = service.definitionFor(FilterPresetId.vivid);
      final half = service.resolve(
        const FilterPreset(id: FilterPresetId.vivid, intensity: 0.5),
      );

      expect(
        half.adjustments.contrast,
        closeTo(full.adjustments.contrast / 2, 0.0001),
      );
      expect(
        half.adjustments.vibrance,
        closeTo(full.adjustments.vibrance / 2, 0.0001),
      );
    });

    test('zero strength is the same as no filter', () {
      final resolved = service.resolve(
        const FilterPreset(id: FilterPresetId.sepia, intensity: 0),
      );

      expect(resolved.isNeutral, isTrue);
    });

    test('the mono strength follows the intensity slider', () {
      expect(
        service.monochromeStrength(
          const FilterPreset(id: FilterPresetId.mono, intensity: 0.4),
        ),
        closeTo(0.4, 0.0001),
      );
      // A preset that is not monochrome never drains colour.
      expect(
        service.monochromeStrength(
          const FilterPreset(id: FilterPresetId.vivid),
        ),
        0,
      );
    });

    test('an out of range intensity is pulled back into 0 to 1', () {
      final resolved = service.resolve(
        const FilterPreset(id: FilterPresetId.vivid, intensity: 5),
      );

      expect(
        resolved.adjustments.contrast,
        service.definitionFor(FilterPresetId.vivid).adjustments.contrast,
      );
    });
  });
}
