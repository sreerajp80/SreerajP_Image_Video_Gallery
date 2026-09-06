import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// One row of the albums grid, whatever kind of album it came from.
///
/// The grid draws virtual albums, device folders, and smart albums side by
/// side, but the three are stored in completely different ways: a virtual album
/// is a database row, a folder is derived from file paths, and a smart album is
/// only a rule. Giving the grid one shape to draw keeps that difference out of
/// the widget layer entirely.
@immutable
class AlbumSummary {
  /// Stable identifier.
  ///
  /// The album id for a virtual album, the directory path for a device folder,
  /// and the route key for a smart album.
  final String id;

  /// Name shown under the cover.
  ///
  /// Smart albums carry their key here instead; only the screen knows how to
  /// translate a smart album's name, because the name comes from
  /// [AppLocalizations] and this layer must not touch the UI.
  final String name;

  /// Which kind of album this is.
  final AlbumType albumType;

  /// Directory path, set only for a device folder.
  final String? folderPath;

  /// How many items the album holds.
  final int itemCount;

  /// The item whose thumbnail is drawn as the cover, or null when the album is
  /// empty or its chosen cover has since gone.
  final MediaItem? coverItem;

  const AlbumSummary({
    required this.id,
    required this.name,
    required this.albumType,
    this.folderPath,
    this.itemCount = 0,
    this.coverItem,
  });

  /// Whether the album has nothing in it.
  bool get isEmpty => itemCount == 0;

  /// Whether the name needs translating by the screen rather than showing as is.
  bool get needsLocalizedName => albumType.isSmartAlbum;

  AlbumSummary copyWith({
    String? id,
    String? name,
    AlbumType? albumType,
    String? folderPath,
    int? itemCount,
    MediaItem? coverItem,
    bool clearCover = false,
  }) {
    return AlbumSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      albumType: albumType ?? this.albumType,
      folderPath: folderPath ?? this.folderPath,
      itemCount: itemCount ?? this.itemCount,
      coverItem: clearCover ? null : (coverItem ?? this.coverItem),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlbumSummary &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          albumType == other.albumType &&
          folderPath == other.folderPath &&
          itemCount == other.itemCount &&
          coverItem == other.coverItem;

  @override
  int get hashCode =>
      Object.hash(id, name, albumType, folderPath, itemCount, coverItem);
}
