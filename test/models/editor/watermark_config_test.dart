import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';

void main() {
  group('WatermarkConfig', () {
    test('the default draws nothing', () {
      expect(WatermarkConfig.none.isNone, isTrue);
    });

    test('text mode with no text draws nothing', () {
      expect(
        const WatermarkConfig(mode: WatermarkMode.text, text: '   ').isNone,
        isTrue,
      );
      expect(
        const WatermarkConfig(mode: WatermarkMode.text, text: 'x').isNone,
        isFalse,
      );
    });

    test('logo mode with no file draws nothing', () {
      expect(const WatermarkConfig(mode: WatermarkMode.logo).isNone, isTrue);
      expect(
        const WatermarkConfig(
          mode: WatermarkMode.logo,
          logoPath: 'logo.png',
        ).isNone,
        isFalse,
      );
    });

    test('a fully see-through watermark draws nothing', () {
      expect(
        const WatermarkConfig(mode: WatermarkMode.timestamp, opacity: 0).isNone,
        isTrue,
      );
    });

    test('the logo path can be cleared explicitly', () {
      const config = WatermarkConfig(
        mode: WatermarkMode.logo,
        logoPath: 'logo.png',
      );

      expect(config.copyWith(clearLogoPath: true).logoPath, isNull);
      // Without the flag, copyWith keeps the old value.
      expect(config.copyWith(opacity: 0.5).logoPath, 'logo.png');
    });

    test('survives a round trip through a map', () {
      const config = WatermarkConfig(
        mode: WatermarkMode.text,
        text: 'Sreeraj',
        position: WatermarkPosition.topCenter,
        opacity: 0.4,
        scale: 0.09,
        margin: 0.02,
        colorArgb: 0xFF00FF00,
      );

      expect(WatermarkConfig.fromMap(config.toMap()), config);
    });

    test('its description does not leak the watermark text', () {
      const config = WatermarkConfig(
        mode: WatermarkMode.text,
        text: 'private name',
      );

      expect(config.toString(), isNot(contains('private name')));
    });

    test('an unknown stored position falls back to the bottom right', () {
      expect(
        WatermarkPosition.fromName('somewhere'),
        WatermarkPosition.bottomRight,
      );
    });
  });

  group('FilterPreset', () {
    test('no preset and zero strength both mean nothing to do', () {
      expect(FilterPreset.none.isNone, isTrue);
      expect(
        const FilterPreset(id: FilterPresetId.vivid, intensity: 0).isNone,
        isTrue,
      );
      expect(const FilterPreset(id: FilterPresetId.vivid).isNone, isFalse);
    });

    test('survives a round trip through a map', () {
      const preset = FilterPreset(id: FilterPresetId.vintage, intensity: 0.65);

      expect(FilterPreset.fromMap(preset.toMap()), preset);
    });

    test('an unknown stored preset falls back to none', () {
      expect(FilterPresetId.fromName('polaroid'), FilterPresetId.none);
    });
  });

  group('RedactionRegion', () {
    test('survives a round trip through a map', () {
      const region = RedactionRegion(
        id: 'r1',
        rect: NormalizedRect(left: 0.1, top: 0.2, right: 0.6, bottom: 0.7),
        mode: RedactionMode.blackout,
        strength: 0.9,
        colorArgb: 0xFF102030,
      );

      expect(RedactionRegion.fromMap(region.toMap()), region);
    });

    test('an unknown stored mode falls back to blur', () {
      expect(RedactionMode.fromName('scramble'), RedactionMode.blur);
    });
  });
}
