import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_query.dart';

/// Turns what the user typed into a [SearchQuery], and a [SearchQuery] into a
/// safe SQLite FTS5 `MATCH` expression.
///
/// Every function here is pure: no database, no files, no platform. That is
/// deliberate, because this is the one place a user's raw text is allowed to
/// reach the query language, and it needs to be tested hard.
class SearchQueryParser {
  const SearchQueryParser();

  /// Prefixes the search box understands, all lower case.
  static const String tagPrefix = 'tag:';
  static const String typePrefix = 'type:';
  static const String placePrefix = 'place:';
  static const String cameraPrefix = 'camera:';
  static const String beforePrefix = 'before:';
  static const String afterPrefix = 'after:';

  /// Every prefix, so the UI can show them as hints.
  static const List<String> supportedPrefixes = <String>[
    tagPrefix,
    typePrefix,
    placePrefix,
    cameraPrefix,
    beforePrefix,
    afterPrefix,
  ];

  /// Breaks [rawText] into its parts.
  ///
  /// A word starting with a known prefix becomes a structured term. A word
  /// with an unknown prefix, or no prefix at all, is plain search text. A
  /// prefix with nothing after it is ignored, so a half-typed `tag:` does not
  /// suddenly narrow the results to nothing.
  SearchQuery parse(String rawText) {
    final textTerms = <String>[];
    final tagNames = <String>{};
    final mediaTypes = <MediaType>{};
    final placeTerms = <String>[];
    final cameraTerms = <String>[];
    DateTime? after;
    DateTime? before;

    for (final word in _splitWords(rawText)) {
      final lower = word.toLowerCase();

      if (lower.startsWith(tagPrefix)) {
        final value = word.substring(tagPrefix.length).trim();
        if (value.isNotEmpty) tagNames.add(value.toLowerCase());
        continue;
      }
      if (lower.startsWith(typePrefix)) {
        final type = _parseMediaType(word.substring(typePrefix.length));
        if (type != null) mediaTypes.add(type);
        continue;
      }
      if (lower.startsWith(placePrefix)) {
        final value = word.substring(placePrefix.length).trim();
        if (value.isNotEmpty) placeTerms.add(value);
        continue;
      }
      if (lower.startsWith(cameraPrefix)) {
        final value = word.substring(cameraPrefix.length).trim();
        if (value.isNotEmpty) cameraTerms.add(value);
        continue;
      }
      if (lower.startsWith(afterPrefix)) {
        final date = _parseDate(word.substring(afterPrefix.length));
        if (date != null) after = date;
        continue;
      }
      if (lower.startsWith(beforePrefix)) {
        final date = _parseDate(word.substring(beforePrefix.length));
        // An end date is inclusive of the whole day the user named.
        if (date != null) {
          before = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
        }
        continue;
      }

      textTerms.add(word);
    }

    return SearchQuery(
      rawText: rawText,
      textTerms: textTerms,
      tagNames: tagNames,
      mediaTypes: mediaTypes,
      placeTerms: placeTerms,
      cameraTerms: cameraTerms,
      after: after,
      before: before,
    );
  }

  /// Builds the FTS5 `MATCH` string for [query], or null when the query has
  /// no text to search for.
  ///
  /// Every word is wrapped in double quotes so that FTS5 reads it as a plain
  /// string and not as an operator. A user typing `AND`, `OR`, `NOT`, `NEAR`,
  /// `*`, `^`, `(`, or `"` therefore searches for those characters instead of
  /// changing the shape of the query. The trailing `*` sits outside the
  /// quotes, which is the one place a wildcard is allowed, and gives the
  /// prefix matching a search box is expected to have.
  String? buildMatchExpression(SearchQuery query) {
    final terms = query.allTextTerms;
    if (terms.isEmpty) return null;

    final quoted = <String>[];
    for (final term in terms) {
      final escaped = escapeTerm(term);
      if (escaped != null) quoted.add(escaped);
    }
    if (quoted.isEmpty) return null;

    // Space between terms is an implicit AND in FTS5: every word must appear
    // somewhere in the row, which is what a search box normally means.
    return quoted.join(' ');
  }

  /// Escapes one word for FTS5, or returns null when nothing usable is left.
  ///
  /// Inner double quotes are doubled, which is how a quote is escaped inside
  /// an FTS5 string.
  String? escapeTerm(String term) {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return null;

    // FTS5 splits on anything that is not a word character anyway, so a term
    // made only of punctuation would produce an empty string and a syntax
    // error. Drop it instead.
    if (!_hasWordCharacter(trimmed)) return null;

    final escaped = trimmed.replaceAll('"', '""');
    return '"$escaped"*';
  }

  /// Splits raw text on whitespace, dropping empty pieces.
  List<String> _splitWords(String rawText) {
    return rawText
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  /// Reads a `type:` value. Accepts a few friendly spellings.
  MediaType? _parseMediaType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'photo':
      case 'photos':
      case 'image':
      case 'images':
        return MediaType.image;
      case 'video':
      case 'videos':
      case 'movie':
        return MediaType.video;
      case 'gif':
      case 'gifs':
        return MediaType.gif;
      case 'raw':
      case 'rawimage':
        return MediaType.rawImage;
      case 'svg':
        return MediaType.svg;
      default:
        return null;
    }
  }

  /// Reads a `YYYY-MM-DD` date, or null when it is not a real one.
  ///
  /// The parts are checked against the date that comes back, because both
  /// `DateTime.parse` and the `DateTime` constructor quietly roll an
  /// out-of-range value over: `2026-13-99` would otherwise become a date in
  /// 2027 and silently filter out most of the library. A nonsense date has to
  /// be ignored, not guessed at.
  DateTime? _parseDate(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);

    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static final RegExp _wordCharacter = RegExp(r'[\p{L}\p{N}]', unicode: true);

  bool _hasWordCharacter(String value) => _wordCharacter.hasMatch(value);
}
