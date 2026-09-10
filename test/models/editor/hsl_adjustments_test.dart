import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/hsl_adjustments.dart';

void main() {
  group('HslChannelAdjustment', () {
    test('default adjustment is neutral', () {
      const adj = HslChannelAdjustment();
      expect(adj.isNeutral, isTrue);
      expect(adj.hue, 0);
      expect(adj.saturation, 0);
      expect(adj.luminance, 0);
    });

    test('non-zero values break neutral', () {
      expect(const HslChannelAdjustment(hue: 0.2).isNeutral, isFalse);
      expect(const HslChannelAdjustment(saturation: -0.5).isNeutral, isFalse);
      expect(const HslChannelAdjustment(luminance: 0.1).isNeutral, isFalse);
    });

    test('copyWith updates specified fields', () {
      const adj = HslChannelAdjustment(hue: 0.1, saturation: 0.2);
      final updated = adj.copyWith(saturation: 0.8, luminance: -0.3);
      expect(updated.hue, 0.1);
      expect(updated.saturation, 0.8);
      expect(updated.luminance, -0.3);
    });

    test('round trip serialization through map', () {
      const adj = HslChannelAdjustment(
        hue: 0.35,
        saturation: -0.2,
        luminance: 0.4,
      );
      final map = adj.toMap();
      final restored = HslChannelAdjustment.fromMap(map);
      expect(restored, adj);
    });
  });

  group('HslAdjustments', () {
    test('neutral has no changes', () {
      expect(HslAdjustments.neutral.isNeutral, isTrue);
      expect(
        HslAdjustments.neutral.adjustmentFor(HslColorRange.red),
        HslChannelAdjustment.neutral,
      );
    });

    test('copyWithChannel sets adjustment and breaks neutral', () {
      final adjustments = HslAdjustments.neutral.copyWithChannel(
        HslColorRange.blue,
        const HslChannelAdjustment(hue: 0.5),
      );
      expect(adjustments.isNeutral, isFalse);
      expect(adjustments.adjustmentFor(HslColorRange.blue).hue, 0.5);
      expect(adjustments.adjustmentFor(HslColorRange.red).isNeutral, isTrue);
    });

    test('resetting a channel to neutral removes it', () {
      final modified = HslAdjustments.neutral.copyWithChannel(
        HslColorRange.green,
        const HslChannelAdjustment(saturation: 0.7),
      );
      expect(modified.isNeutral, isFalse);

      final reset = modified.copyWithChannel(
        HslColorRange.green,
        HslChannelAdjustment.neutral,
      );
      expect(reset.isNeutral, isTrue);
    });

    test('round trip serialization through map', () {
      final adjustments = HslAdjustments.neutral
          .copyWithChannel(
            HslColorRange.red,
            const HslChannelAdjustment(hue: -0.2, saturation: 0.4),
          )
          .copyWithChannel(
            HslColorRange.cyan,
            const HslChannelAdjustment(luminance: -0.5),
          );

      final map = adjustments.toMap();
      final restored = HslAdjustments.fromMap(map);
      expect(restored, adjustments);
      expect(restored.adjustmentFor(HslColorRange.red).saturation, 0.4);
      expect(restored.adjustmentFor(HslColorRange.cyan).luminance, -0.5);
    });

    test('fromMap with empty map returns neutral', () {
      expect(
        HslAdjustments.fromMap(const <String, dynamic>{}),
        HslAdjustments.neutral,
      );
    });
  });

  group('HslColorRange', () {
    test('fromName parses valid names and falls back to red', () {
      expect(HslColorRange.fromName('blue'), HslColorRange.blue);
      expect(HslColorRange.fromName('magenta'), HslColorRange.magenta);
      expect(HslColorRange.fromName('unknown'), HslColorRange.red);
    });
  });
}
