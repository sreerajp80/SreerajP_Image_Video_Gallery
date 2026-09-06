import 'package:flutter/foundation.dart';

/// Categories of albums (physical device directories, virtual collections, or dynamic smart albums).
enum AlbumType {
  physicalFolder,
  virtualAlbum,
  smartFavorites,
  smartVideos,
  smartGifs,
  smartRaw,
  smartPanoramas,
  smartRecentlyAdded,
  smartTrash;

  /// Helper to convert string to enum safely.
  static AlbumType fromString(String value) {
    return AlbumType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => AlbumType.virtualAlbum,
    );
  }

  /// Whether this is a dynamic smart album automatically computed from metadata.
  bool get isSmartAlbum =>
      this == AlbumType.smartFavorites ||
      this == AlbumType.smartVideos ||
      this == AlbumType.smartGifs ||
      this == AlbumType.smartRaw ||
      this == AlbumType.smartPanoramas ||
      this == AlbumType.smartRecentlyAdded ||
      this == AlbumType.smartTrash;
}

/// Immutable domain model representing a photo/video album or device folder.
@immutable
class Album {
  /// Unique identifier (folder path for physical folders, UUID for virtual albums).
  final String id;

  /// Display name of the album or directory.
  final String name;

  /// Type of album.
  final AlbumType albumType;

  /// Relative directory path on device storage (e.g. "DCIM/Camera", "Pictures/Screenshots").
  final String? relativeFolderPath;

  /// ID of the media item chosen as the album thumbnail cover.
  final String? coverMediaId;

  /// Local path to the cover image.
  final String? coverPath;

  /// Total number of media items contained within this album.
  final int itemCount;

  /// Creation timestamp.
  final DateTime dateCreated;

  /// Last modification timestamp.
  final DateTime dateModified;

  /// Whether this album is pinned to the top of the album grid.
  final bool isPinned;

  /// Custom sort order index.
  final int sortOrder;

  const Album({
    required this.id,
    required this.name,
    required this.albumType,
    this.relativeFolderPath,
    this.coverMediaId,
    this.coverPath,
    this.itemCount = 0,
    required this.dateCreated,
    required this.dateModified,
    this.isPinned = false,
    this.sortOrder = 0,
  });

  /// Creates a copy of [Album] with updated properties.
  Album copyWith({
    String? id,
    String? name,
    AlbumType? albumType,
    String? relativeFolderPath,
    String? coverMediaId,
    String? coverPath,
    int? itemCount,
    DateTime? dateCreated,
    DateTime? dateModified,
    bool? isPinned,
    int? sortOrder,
  }) {
    return Album(
      id: id ?? this.id,
      name: name ?? this.name,
      albumType: albumType ?? this.albumType,
      relativeFolderPath: relativeFolderPath ?? this.relativeFolderPath,
      coverMediaId: coverMediaId ?? this.coverMediaId,
      coverPath: coverPath ?? this.coverPath,
      itemCount: itemCount ?? this.itemCount,
      dateCreated: dateCreated ?? this.dateCreated,
      dateModified: dateModified ?? this.dateModified,
      isPinned: isPinned ?? this.isPinned,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Converts this [Album] to a database-ready map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'album_type': albumType.name,
      'relative_folder_path': relativeFolderPath,
      'cover_media_id': coverMediaId,
      'cover_path': coverPath,
      'item_count': itemCount,
      'date_created': dateCreated.millisecondsSinceEpoch,
      'date_modified': dateModified.millisecondsSinceEpoch,
      'is_pinned': isPinned ? 1 : 0,
      'sort_order': sortOrder,
    };
  }

  /// Constructs an [Album] from a database row or map.
  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'] as String,
      name: map['name'] as String,
      albumType: AlbumType.fromString(
        (map['album_type'] ?? map['albumType'] ?? 'virtualAlbum') as String,
      ),
      relativeFolderPath:
          (map['relative_folder_path'] ?? map['relativeFolderPath']) as String?,
      coverMediaId: (map['cover_media_id'] ?? map['coverMediaId']) as String?,
      coverPath: (map['cover_path'] ?? map['coverPath']) as String?,
      itemCount: (map['item_count'] ?? map['itemCount'] ?? 0) as int,
      dateCreated: map['date_created'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date_created'] as int)
          : DateTime.parse(map['date_created'].toString()),
      dateModified: map['date_modified'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date_modified'] as int)
          : DateTime.parse(map['date_modified'].toString()),
      isPinned: map['is_pinned'] == 1 || map['isPinned'] == true,
      sortOrder: (map['sort_order'] ?? map['sortOrder'] ?? 0) as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Album &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          albumType == other.albumType &&
          relativeFolderPath == other.relativeFolderPath &&
          coverMediaId == other.coverMediaId &&
          coverPath == other.coverPath &&
          itemCount == other.itemCount &&
          dateCreated == other.dateCreated &&
          dateModified == other.dateModified &&
          isPinned == other.isPinned &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    albumType,
    relativeFolderPath,
    coverMediaId,
    coverPath,
    itemCount,
    dateCreated,
    dateModified,
    isPinned,
    sortOrder,
  );
}
