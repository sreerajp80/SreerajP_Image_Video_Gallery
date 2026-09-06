import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_color_palette.dart';

void main() {
  group('TagColorPalette', () {
    test('holds twelve distinct, fully opaque colours', () {
      expect(TagColorPalette.colors.length, 12);
      expect(
        TagColorPalette.colors.toSet().length,
        TagColorPalette.colors.length,
      );
      for (final value in TagColorPalette.colors) {
        // A see-through tag chip would be unreadable on either theme.
        expect((value >> 24) & 0xFF, 0xFF, reason: 'colour must be opaque');
      }
    });

    test('contains reports palette membership', () {
      expect(TagColorPalette.contains(TagColorPalette.colors.first), isTrue);
      expect(TagColorPalette.contains(0xFF010203), isFalse);
    });

    test('the same name always gets the same colour', () {
      // Dart hashCode is not stable between runs, so this would fail if the
      // default colour were derived from it.
      expect(
        TagColorPalette.defaultColorFor('beach'),
        TagColorPalette.defaultColorFor('beach'),
      );
    });

    test('the default colour ignores case and spacing', () {
      expect(
        TagColorPalette.defaultColorFor(' Beach  Day '),
        TagColorPalette.defaultColorFor('beach day'),
      );
    });

    test('the default colour is always in the palette', () {
      for (final name in <String>['a', 'beach', 'family', 'receipts', 'കടൽ']) {
        expect(
          TagColorPalette.contains(TagColorPalette.defaultColorFor(name)),
          isTrue,
        );
      }
    });

    test('an empty name still gets a usable colour', () {
      expect(
        TagColorPalette.contains(TagColorPalette.defaultColorFor('   ')),
        isTrue,
      );
    });

    test('different names mostly get different colours', () {
      final names = <String>[
        'beach',
        'family',
        'work',
        'receipts',
        'travel',
        'food',
      ];
      final colors = names.map(TagColorPalette.defaultColorFor).toSet();

      // Not a promise of no collisions with twelve slots, but a stuck hash
      // returning one colour for everything would be caught here.
      expect(colors.length, greaterThan(2));
    });

    test('resolve keeps a palette colour and repairs anything else', () {
      final valid = TagColorPalette.colors[3];

      expect(TagColorPalette.resolve(valid, 'beach'), valid);
      // A colour stored by hand or by an older build is snapped back into the
      // palette rather than drawn as-is.
      expect(
        TagColorPalette.resolve(0xFF010203, 'beach'),
        TagColorPalette.defaultColorFor('beach'),
      );
      expect(
        TagColorPalette.resolve(null, 'beach'),
        TagColorPalette.defaultColorFor('beach'),
      );
    });
  });
}
