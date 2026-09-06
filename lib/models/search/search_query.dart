import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// A search the user typed, broken into the parts the database understands.
///
/// The raw text is kept so the search box and the recent list can show
/// exactly what was typed. Everything else is what
/// `SearchQueryParser` made of it.
@immutable
class SearchQuery {
  /// The text the user typed, untouched.
  final String rawText;

  /// Words that were not part of a `prefix:` term. These go to FTS5.
  final List<String> textTerms;

  /// Tag names from `tag:` terms. Matched by name, not by id.
  final Set<String> tagNames;

  /// Media kinds from `type:` terms.
  final Set<MediaType> mediaTypes;

  /// Place words from `place:` terms.
  final List<String> placeTerms;

  /// Camera words from `camera:` terms.
  final List<String> cameraTerms;

  /// Only items captured on or after this instant.
  final DateTime? after;

  /// Only items captured on or before this instant.
  final DateTime? before;

  const SearchQuery({
    this.rawText = '',
    this.textTerms = const <String>[],
    this.tagNames = const <String>{},
    this.mediaTypes = const <MediaType>{},
    this.placeTerms = const <String>[],
    this.cameraTerms = const <String>[],
    this.after,
    this.before,
  });

  /// True when the query asks for nothing at all.
  bool get isEmpty =>
      textTerms.isEmpty &&
      tagNames.isEmpty &&
      mediaTypes.isEmpty &&
      placeTerms.isEmpty &&
      cameraTerms.isEmpty &&
      after == null &&
      before == null;

  bool get isNotEmpty => !isEmpty;

  /// True when any part of the query needs the full-text index.
  ///
  /// Tag names, media kinds, and dates are answered by plain columns, so a
  /// query made only of those never touches FTS5.
  bool get needsFullTextSearch =>
      textTerms.isNotEmpty || placeTerms.isNotEmpty || cameraTerms.isNotEmpty;

  /// Every word that will be sent to the full-text index, in order.
  List<String> get allTextTerms => <String>[
    ...textTerms,
    ...placeTerms,
    ...cameraTerms,
  ];

  SearchQuery copyWith({
    String? rawText,
    List<String>? textTerms,
    Set<String>? tagNames,
    Set<MediaType>? mediaTypes,
    List<String>? placeTerms,
    List<String>? cameraTerms,
    DateTime? after,
    DateTime? before,
  }) {
    return SearchQuery(
      rawText: rawText ?? this.rawText,
      textTerms: textTerms ?? this.textTerms,
      tagNames: tagNames ?? this.tagNames,
      mediaTypes: mediaTypes ?? this.mediaTypes,
      placeTerms: placeTerms ?? this.placeTerms,
      cameraTerms: cameraTerms ?? this.cameraTerms,
      after: after ?? this.after,
      before: before ?? this.before,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          runtimeType == other.runtimeType &&
          rawText == other.rawText &&
          listEquals(textTerms, other.textTerms) &&
          setEquals(tagNames, other.tagNames) &&
          setEquals(mediaTypes, other.mediaTypes) &&
          listEquals(placeTerms, other.placeTerms) &&
          listEquals(cameraTerms, other.cameraTerms) &&
          after == other.after &&
          before == other.before;

  @override
  int get hashCode => Object.hash(
    rawText,
    Object.hashAll(textTerms),
    Object.hashAll(tagNames),
    Object.hashAll(mediaTypes),
    Object.hashAll(placeTerms),
    Object.hashAll(cameraTerms),
    after,
    before,
  );
}
