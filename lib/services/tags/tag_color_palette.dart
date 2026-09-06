import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';

/// The colours a tag can be.
///
/// A fixed palette rather than a free colour wheel, for three reasons: the
/// chips stay readable on both the light and the dark theme, tags across the
/// library look like one set, and a stored colour is always one the app can
/// draw. Pure data, so it is checked by a test rather than by eye.
class TagColorPalette {
  const TagColorPalette._();

  /// The twelve choices, as 32-bit ARGB values.
  ///
  /// These are the Material 400-level tones, which carry white text on a dark
  /// theme and dark text on a light one without any of them washing out.
  static const List<int> colors = <int>[
    0xFFEF5350, // red
    0xFFEC407A, // pink
    0xFFAB47BC, // purple
    0xFF7E57C2, // deep purple
    0xFF5C6BC0, // indigo
    0xFF42A5F5, // blue
    0xFF26A69A, // teal
    0xFF66BB6A, // green
    0xFF9CCC65, // light green
    0xFFFFCA28, // amber
    0xFFFF7043, // deep orange
    0xFF8D6E63, // brown
  ];

  /// True when [colorValue] is one of the palette colours.
  static bool contains(int colorValue) => colors.contains(colorValue);

  /// The colour a new tag called [name] starts with.
  ///
  /// Picked from the name itself, so the same name always gets the same
  /// colour and two different tags rarely land on one. The user can still
  /// change it afterwards.
  static int defaultColorFor(String name) {
    final normalized = TagNameRules.normalize(name).toLowerCase();
    if (normalized.isEmpty) return colors.first;

    // A small FNV-1a hash. Dart's own `hashCode` is not promised to be stable
    // between runs, and a tag changing colour on restart would look like a
    // bug, so the mixing is done here.
    var hash = 0x811c9dc5;
    for (final unit in normalized.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return colors[hash % colors.length];
  }

  /// Snaps [colorValue] to a palette colour, falling back on the name.
  ///
  /// Used when reading a tag stored by an older build, or by hand, so the UI
  /// never has to draw a colour that is not in the set.
  static int resolve(int? colorValue, String name) {
    if (colorValue != null && contains(colorValue)) return colorValue;
    return defaultColorFor(name);
  }
}
