import 'package:characters/characters.dart';

/// How far one OCR result is from the correct text.
///
/// Used by the OCR accuracy tool only; it is not part of the app.
class ErrorRate {
  /// Character error rate: edits needed, divided by the length of the
  /// correct text. 0 is perfect.
  final double cer;

  /// Word error rate, the same measure on words.
  final double wer;

  /// Length of the correct text in characters (grapheme clusters).
  final int truthCharacters;

  /// Length of the correct text in words.
  final int truthWords;

  const ErrorRate({
    required this.cer,
    required this.wer,
    required this.truthCharacters,
    required this.truthWords,
  });
}

/// Measures the error rate of [result] against [truth].
///
/// Both texts should already be normalised. Characters are counted as
/// grapheme clusters, the units a reader sees, so a Malayalam conjunct such
/// as `ക്ഷ` is one character, not three code points. One misread conjunct is
/// one mistake.
ErrorRate measureErrorRate({required String truth, required String result}) {
  final truthChars = truth.characters.toList(growable: false);
  final resultChars = result.characters.toList(growable: false);
  final truthWords = _words(truth);
  final resultWords = _words(result);

  return ErrorRate(
    cer: _rate(
      editDistance(truthChars, resultChars),
      truthChars.length,
      resultChars.length,
    ),
    wer: _rate(
      editDistance(truthWords, resultWords),
      truthWords.length,
      resultWords.length,
    ),
    truthCharacters: truthChars.length,
    truthWords: truthWords.length,
  );
}

/// The fewest single-unit insertions, deletions and substitutions that turn
/// [a] into [b] (Levenshtein distance).
int editDistance(List<String> a, List<String> b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  // Two rows are enough; the full table is never needed.
  var previous = List<int>.generate(b.length + 1, (i) => i);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      final delete = previous[j] + 1;
      final insert = current[j - 1] + 1;
      final replace = previous[j - 1] + cost;
      var best = delete < insert ? delete : insert;
      if (replace < best) best = replace;
      current[j] = best;
    }
    final swap = previous;
    previous = current;
    current = swap;
  }

  return previous[b.length];
}

List<String> _words(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const <String>[];
  return trimmed.split(RegExp(r'\s+'));
}

/// Edits divided by the correct length.
///
/// When the correct text is empty, any output at all is fully wrong (1.0)
/// and no output is fully right (0.0), rather than a division by zero.
double _rate(int edits, int truthLength, int resultLength) {
  if (truthLength == 0) return resultLength == 0 ? 0 : 1;
  return edits / truthLength;
}
