/// Tidies the raw text a reader gives back.
///
/// Pure. Tesseract's output is usable but ragged: trailing spaces on most
/// lines, runs of blank lines where the page had a gap, and the odd line of
/// stray marks read out of a photo's noise.
///
/// The rule throughout is to tidy, never to rewrite. Reading order is kept
/// exactly, no word is corrected, and nothing is dropped that could be real
/// text. What the user copies must be what was on the page.
class OcrTextCleaner {
  const OcrTextCleaner();

  /// Cleans [raw] and returns the tidied text.
  String clean(String raw) => cleanLines(raw).join('\n');

  /// Cleans [raw] and returns it as lines, with blank ones dropped.
  List<String> cleanLines(String raw) {
    if (raw.trim().isEmpty) return const <String>[];

    final out = <String>[];

    for (final line in raw.replaceAll('\r\n', '\n').split('\n')) {
      final tidied = _tidy(line);
      if (tidied.isEmpty) continue;
      if (_isNoise(tidied)) continue;
      out.add(tidied);
    }

    return out;
  }

  /// Collapses runs of spaces and trims the ends of one line.
  ///
  /// Inner spacing is collapsed because Tesseract pads columns out with them,
  /// and a wall of spaces in the middle of a sentence is not something the
  /// page actually had.
  String _tidy(String line) {
    return line
        // Zero-width marks carry no meaning and are invisible in the text
        // the user copies, so they go before anything else is measured.
        .replaceAll(RegExp('[\u200B-\u200D\uFEFF]'), '')
        // Non-breaking and other exotic spaces read as plain ones.
        .replaceAll(RegExp('[\u00A0\u2000-\u200A\u202F\u205F\u3000]'), ' ')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  /// Whether a line is stray marks rather than text.
  ///
  /// Deliberately cautious: only a short line made entirely of the characters
  /// Tesseract invents out of specks and edges is dropped. A line with any
  /// letter or digit in it is kept, however odd it looks, because a wrongly
  /// dropped line is a line the user cannot get back.
  bool _isNoise(String line) {
    if (line.length > 3) return false;
    return !RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(line);
  }
}
