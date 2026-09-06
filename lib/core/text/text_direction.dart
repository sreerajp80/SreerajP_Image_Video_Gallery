import 'package:flutter/widgets.dart' show TextDirection;

/// Works out which way a piece of text should flow.
///
/// The app ships in English and Malayalam, and both read left to right. This
/// is not about those two. It is about the text the app does not control: a
/// note somebody typed, a line the offline reader pulled out of a photo, the
/// payload of a scanned code. Any of those can hold Arabic or Hebrew, and a
/// right-to-left line laid out left to right reads backwards.
///
/// The rule is the simple one from the Unicode bidirectional algorithm: find
/// the first character that has a direction of its own, and use it. Digits,
/// spaces, punctuation, symbols and emoji have no direction of their own, so
/// they are skipped rather than counted. That matters: a note opening with a
/// number, a bullet, or a smiley must still take its direction from the first
/// real word.
///
/// Returns `null` when the text has no directional character at all — an
/// empty string, only spaces, only digits. The caller should then keep
/// whatever direction it already had, because there is nothing to go on.
TextDirection? detectTextDirection(String text) {
  for (final int rune in text.runes) {
    if (_isNeutral(rune)) continue;
    if (_isRightToLeft(rune)) return TextDirection.rtl;
    if (_isLeftToRight(rune)) return TextDirection.ltr;
  }
  return null;
}

/// Whether [rune] carries no direction of its own.
///
/// Checked first, so a symbol that happens to sit inside a letter range
/// cannot decide the direction of a whole paragraph.
bool _isNeutral(int rune) {
  return rune < 0x0041 || // space, digits, ASCII punctuation
      (rune >= 0x005B && rune <= 0x0060) || // [ \ ] ^ _ `
      (rune >= 0x007B && rune <= 0x00BF) || // { | } ~ and Latin-1 symbols
      (rune >= 0x2000 && rune <= 0x20CF) || // punctuation, marks, currency
      (rune >= 0x2190 && rune <= 0x2BFF) || // arrows, maths, symbols, shapes
      (rune >= 0x1F000 && rune <= 0x1FAFF); // emoji and pictographs
}

/// Whether [rune] is a right-to-left letter.
///
/// Covers the scripts that are written right to left and are likely to turn
/// up in a photo or a note: Hebrew, Arabic, Syriac, Thaana, plus the Arabic
/// supplement, extended, and presentation blocks.
bool _isRightToLeft(int rune) {
  return (rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
      (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
      (rune >= 0x0700 && rune <= 0x074F) || // Syriac
      (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
      (rune >= 0x0780 && rune <= 0x07BF) || // Thaana
      (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
      (rune >= 0xFB1D && rune <= 0xFDFF) || // Hebrew & Arabic presentation
      (rune >= 0xFE70 && rune <= 0xFEFF); // Arabic presentation forms
}

/// Whether [rune] is a left-to-right letter.
///
/// Everything that is a letter and is not in one of the right-to-left blocks
/// above: Latin, Greek, Cyrillic, Devanagari, Malayalam, Tamil, the CJK
/// range, and the rest.
bool _isLeftToRight(int rune) {
  return (rune >= 0x0041 && rune <= 0x058F) || // Latin, Greek, Cyrillic
      (rune >= 0x0900 && rune <= 0xFB1C) || // Indic, CJK, and the rest
      (rune >= 0xFF00 && rune <= 0xFFEF); // halfwidth and fullwidth forms
}
