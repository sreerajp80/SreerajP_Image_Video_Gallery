import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';

/// A dynamic album defined by a rule rather than by stored membership.
///
/// Nothing about a smart album is written to the database. It is a filter plus
/// a name, evaluated fresh every time it is opened, so starring a photo makes
/// Favourites correct at once with no bookkeeping that could fall out of step.
@immutable
class SmartAlbum {
  /// Which smart album this is.
  final AlbumType albumType;

  /// Stable key used in the `/albums/auto/:type` route.
  ///
  /// Kept separate from the enum name so the enum can be renamed later without
  /// breaking a route the user may have come back to.
  final String key;

  /// The filter that selects this album's items.
  final FilterOptions filter;

  /// Whether the rule needs a second pass in Dart after the database query.
  ///
  /// Two of the rules — panoramas and recently added — are not plain column
  /// tests, so the repository narrows them further once the rows are back.
  final bool needsPostFilter;

  const SmartAlbum({
    required this.albumType,
    required this.key,
    required this.filter,
    this.needsPostFilter = false,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmartAlbum &&
          runtimeType == other.runtimeType &&
          albumType == other.albumType &&
          key == other.key &&
          filter == other.filter &&
          needsPostFilter == other.needsPostFilter;

  @override
  int get hashCode => Object.hash(albumType, key, filter, needsPostFilter);
}
