import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';

void main() {
  group('SelectiveMask', () {
    test('default mask has neutral adjustments', () {
      const mask = SelectiveMask(id: 'mask_1');
      expect(mask.isNeutral, isTrue);
      expect(mask.shape, MaskShape.linear);
      expect(mask.feather, 0.3);
      expect(mask.invert, isFalse);
      expect(mask.exposure, 0);
      expect(mask.contrast, 0);
      expect(mask.temperature, 0);
      expect(mask.blur, 0);
    });

    test('non-zero adjustment breaks neutral', () {
      const mask = SelectiveMask(id: 'mask_1', exposure: 0.5);
      expect(mask.isNeutral, isFalse);
    });

    test('copyWith updates specified properties', () {
      const mask = SelectiveMask(id: 'mask_1');
      final updated = mask.copyWith(
        shape: MaskShape.radial,
        exposure: -0.3,
        feather: 0.5,
        invert: true,
      );

      expect(updated.id, 'mask_1');
      expect(updated.shape, MaskShape.radial);
      expect(updated.exposure, -0.3);
      expect(updated.feather, 0.5);
      expect(updated.invert, isTrue);
    });

    test('round trip serialization through map', () {
      const mask = SelectiveMask(
        id: 'mask_abc',
        shape: MaskShape.radial,
        startPoint: NormalizedPoint(0.4, 0.4),
        endPoint: NormalizedPoint(0.8, 0.8),
        feather: 0.6,
        invert: true,
        exposure: 0.4,
        contrast: -0.2,
        temperature: 0.1,
        blur: 0.7,
      );

      final map = mask.toMap();
      final restored = SelectiveMask.fromMap(map);
      expect(restored, mask);
      expect(restored.id, 'mask_abc');
      expect(restored.shape, MaskShape.radial);
      expect(restored.startPoint.x, 0.4);
      expect(restored.endPoint.y, 0.8);
      expect(restored.blur, 0.7);
    });

    test('fromMap with missing optional fields falls back safely', () {
      final restored = SelectiveMask.fromMap(const <String, dynamic>{
        'id': 'fallback_mask',
      });

      expect(restored.id, 'fallback_mask');
      expect(restored.shape, MaskShape.linear);
      expect(restored.isNeutral, isTrue);
    });
  });

  group('MaskShape', () {
    test('fromName parses names with fallback to linear', () {
      expect(MaskShape.fromName('radial'), MaskShape.radial);
      expect(MaskShape.fromName('linear'), MaskShape.linear);
      expect(MaskShape.fromName('unknown'), MaskShape.linear);
    });
  });
}
