/// Makes two texts comparable before their error rate is measured.
///
/// Used by the OCR accuracy tool only; it is not part of the app. The aim is
/// to count reading mistakes, not differences that look the same on screen:
/// spacing, line endings, and Malayalam letters that Unicode allows to be
/// written in more than one way.
///
/// It never changes a letter into a different letter.
class TextNormaliser {
  const TextNormaliser();

  static const String _virama = '\u0D4D';
  static const String _zwj = '\u200D';
  static const String _zwnj = '\u200C';

  /// Old chillu spelling (consonant + virama + zero-width joiner) to the
  /// single chillu letter. Both look the same; only one matches in search.
  static const Map<String, String> _chillu = <String, String>{
    '\u0D23$_virama$_zwj': '\u0D7A', // ണ് → ൺ
    '\u0D28$_virama$_zwj': '\u0D7B', // ന് → ൻ
    '\u0D30$_virama$_zwj': '\u0D7C', // ര് → ർ
    '\u0D32$_virama$_zwj': '\u0D7D', // ല് → ൽ
    '\u0D33$_virama$_zwj': '\u0D7E', // ള് → ൾ
    '\u0D15$_virama$_zwj': '\u0D7F', // ക് → ൿ
  };

  /// Two-part vowel signs to the single sign Unicode composes them into.
  static const Map<String, String> _vowelSigns = <String, String>{
    '\u0D46\u0D3E': '\u0D4A', // െ + ാ → ൊ
    '\u0D47\u0D3E': '\u0D4B', // േ + ാ → ോ
    '\u0D46\u0D57': '\u0D4C', // െ + ൗ → ൌ
  };

  static final RegExp _spaces = RegExp(r'\s+');

  /// Returns [text] in the form used for comparison.
  ///
  /// Line breaks become spaces, because where Tesseract breaks a line is a
  /// layout detail, not a reading mistake.
  String normalise(String text) {
    var result = text;

    _chillu.forEach((from, to) => result = result.replaceAll(from, to));
    _vowelSigns.forEach((from, to) => result = result.replaceAll(from, to));

    // Whatever joiners are left change nothing that the comparison cares
    // about, and Tesseract adds or drops them freely.
    result = result.replaceAll(_zwj, '').replaceAll(_zwnj, '');

    return result.replaceAll(_spaces, ' ').trim();
  }
}
