import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Which part of an item the search text was found in.
///
/// Used only to show a small hint under a result tile, so the user can see
/// why a photo came back when the match was not in its name.
enum SearchMatchField { displayName, tags, notes, exif, address, filter }

/// One item a search returned, with the reason it matched.
@immutable
class SearchResult {
  /// The item itself.
  final MediaItem item;

  /// Where the text was found. `filter` means the item matched only the
  /// structured filters, with no text search involved.
  final SearchMatchField matchField;

  const SearchResult({required this.item, required this.matchField});

  SearchResult copyWith({MediaItem? item, SearchMatchField? matchField}) {
    return SearchResult(
      item: item ?? this.item,
      matchField: matchField ?? this.matchField,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchResult &&
          runtimeType == other.runtimeType &&
          item == other.item &&
          matchField == other.matchField;

  @override
  int get hashCode => Object.hash(item, matchField);
}
