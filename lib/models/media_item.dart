import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';

/// Categories of media files supported by the gallery.
enum MediaType {
  image,
  video,
  gif,
  rawImage,
  svg;

  /// Helper to convert string to enum safely.
  static MediaType fromString(String value) {
    return MediaType.values.firstWhere(
      (e) => e.name.toLowerCase() == value.toLowerCase(),
      orElse: () => MediaType.image,
    );
  }
}

/// Immutable core domain model representing an image or video in the gallery.
@immutable
class MediaItem {
  /// Unique persistent identifier (MediaStore ID or generated UUID).
  final String id;

  /// Absolute file system path to the media file.
  final String path;

  /// Content URI for scoped storage access on Android.
  final String? uri;

  /// Base filename including extension (e.g. "IMG_20260829_090000.jpg").
  final String displayName;

  /// Categorized media type (image, video, gif, rawImage, svg).
  final MediaType mediaType;

  /// Standard MIME type string (e.g. "image/jpeg", "video/mp4").
  final String mimeType;

  /// File size in bytes.
  final int size;

  /// Timestamp when the file was discovered or added to the device.
  final DateTime dateAdded;

  /// Timestamp when the file was last modified on disk.
  final DateTime dateModified;

  /// Captured date/time from EXIF metadata or MediaStore.
  final DateTime? dateTaken;

  /// Video duration in milliseconds (null for still images).
  final int? durationMs;

  /// Pixel width.
  final int? width;

  /// Pixel height.
  final int? height;

  /// Orientation in degrees (0, 90, 180, 270).
  final int orientation;

  /// Whether the user marked this media item as a favorite.
  final bool isFavorite;

  /// Whether this media is moved into the encrypted private vault.
  final bool isVaulted;

  /// Whether this media item is currently in trash/recycle bin.
  final bool isTrash;

  /// Embedded EXIF / camera metadata.
  final ExifData? exifData;

  /// List of assigned custom tag names or tag IDs.
  final List<String> tags;

  /// User-written markdown notes attached to this media item.
  final String? userNotes;

  /// SHA-256 cryptographic hash of the file bytes for exact duplicate matching.
  final String? sha256Hash;

  /// 64-bit perceptual hash (pHash/dHash) for visual similarity matching.
  final String? pHash;

  /// GPS Latitude coordinates.
  final double? latitude;

  /// GPS Longitude coordinates.
  final double? longitude;

  /// Reverse geocoded human-readable location address string.
  final String? address;

  const MediaItem({
    required this.id,
    required this.path,
    this.uri,
    required this.displayName,
    required this.mediaType,
    required this.mimeType,
    required this.size,
    required this.dateAdded,
    required this.dateModified,
    this.dateTaken,
    this.durationMs,
    this.width,
    this.height,
    this.orientation = 0,
    this.isFavorite = false,
    this.isVaulted = false,
    this.isTrash = false,
    this.exifData,
    this.tags = const <String>[],
    this.userNotes,
    this.sha256Hash,
    this.pHash,
    this.latitude,
    this.longitude,
    this.address,
  });

  /// The effective chronological sort date (dateTaken if available, else dateModified).
  DateTime get effectiveDate => dateTaken ?? dateModified;

  /// Whether this media item is a video.
  bool get isVideo => mediaType == MediaType.video;

  /// Whether this media item is an image or animated format.
  bool get isImage =>
      mediaType == MediaType.image ||
      mediaType == MediaType.gif ||
      mediaType == MediaType.rawImage ||
      mediaType == MediaType.svg;

  /// Creates a copy of [MediaItem] with updated properties.
  MediaItem copyWith({
    String? id,
    String? path,
    String? uri,
    String? displayName,
    MediaType? mediaType,
    String? mimeType,
    int? size,
    DateTime? dateAdded,
    DateTime? dateModified,
    DateTime? dateTaken,
    int? durationMs,
    int? width,
    int? height,
    int? orientation,
    bool? isFavorite,
    bool? isVaulted,
    bool? isTrash,
    ExifData? exifData,
    List<String>? tags,
    String? userNotes,
    String? sha256Hash,
    String? pHash,
    double? latitude,
    double? longitude,
    String? address,
  }) {
    return MediaItem(
      id: id ?? this.id,
      path: path ?? this.path,
      uri: uri ?? this.uri,
      displayName: displayName ?? this.displayName,
      mediaType: mediaType ?? this.mediaType,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      dateAdded: dateAdded ?? this.dateAdded,
      dateModified: dateModified ?? this.dateModified,
      dateTaken: dateTaken ?? this.dateTaken,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      orientation: orientation ?? this.orientation,
      isFavorite: isFavorite ?? this.isFavorite,
      isVaulted: isVaulted ?? this.isVaulted,
      isTrash: isTrash ?? this.isTrash,
      exifData: exifData ?? this.exifData,
      tags: tags ?? this.tags,
      userNotes: userNotes ?? this.userNotes,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      pHash: pHash ?? this.pHash,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
    );
  }

  /// Converts this [MediaItem] into a database-ready map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'uri': uri,
      'display_name': displayName,
      'media_type': mediaType.name,
      'mime_type': mimeType,
      'size_bytes': size,
      'date_added': dateAdded.millisecondsSinceEpoch,
      'date_modified': dateModified.millisecondsSinceEpoch,
      'date_taken': dateTaken?.millisecondsSinceEpoch,
      'duration_ms': durationMs,
      'width': width,
      'height': height,
      'orientation': orientation,
      'is_favorite': isFavorite ? 1 : 0,
      'is_vaulted': isVaulted ? 1 : 0,
      'is_trash': isTrash ? 1 : 0,
      'exif_json': exifData != null ? jsonEncode(exifData!.toMap()) : null,
      'user_notes': userNotes,
      'sha256_hash': sha256Hash,
      'p_hash': pHash,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    };
  }

  /// Constructs a [MediaItem] from a SQLite query row or JSON map.
  factory MediaItem.fromMap(
    Map<String, dynamic> map, {
    List<String> tags = const <String>[],
  }) {
    ExifData? parsedExif;
    final rawExif = map['exif_json'] ?? map['exifData'];
    if (rawExif is String && rawExif.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawExif);
        if (decoded is Map<String, dynamic>) {
          parsedExif = ExifData.fromMap(decoded);
        }
      } catch (_) {}
    } else if (rawExif is Map<String, dynamic>) {
      parsedExif = ExifData.fromMap(rawExif);
    }

    final rawTags = map['tags'];
    List<String> combinedTags = List<String>.from(tags);
    if (rawTags is List) {
      combinedTags = rawTags.map((e) => e.toString()).toList();
    }

    return MediaItem(
      id: map['id'] as String,
      path: map['path'] as String,
      uri: map['uri'] as String?,
      displayName: (map['display_name'] ?? map['displayName']) as String,
      mediaType: MediaType.fromString(
        (map['media_type'] ?? map['mediaType'] ?? 'image') as String,
      ),
      mimeType: (map['mime_type'] ?? map['mimeType']) as String,
      size: (map['size_bytes'] ?? map['size']) as int,
      dateAdded: map['date_added'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date_added'] as int)
          : DateTime.parse(map['date_added'].toString()),
      dateModified: map['date_modified'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['date_modified'] as int)
          : DateTime.parse(map['date_modified'].toString()),
      dateTaken: map['date_taken'] != null
          ? (map['date_taken'] is int
                ? DateTime.fromMillisecondsSinceEpoch(map['date_taken'] as int)
                : DateTime.tryParse(map['date_taken'].toString()))
          : null,
      durationMs: (map['duration_ms'] ?? map['durationMs']) as int?,
      width: map['width'] as int?,
      height: map['height'] as int?,
      orientation: (map['orientation'] as int?) ?? 0,
      isFavorite: map['is_favorite'] == 1 || map['isFavorite'] == true,
      isVaulted: map['is_vaulted'] == 1 || map['isVaulted'] == true,
      isTrash: map['is_trash'] == 1 || map['isTrash'] == true,
      exifData: parsedExif,
      tags: combinedTags,
      userNotes: (map['user_notes'] ?? map['userNotes']) as String?,
      sha256Hash: (map['sha256_hash'] ?? map['sha256Hash']) as String?,
      pHash: (map['p_hash'] ?? map['pHash']) as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      address: map['address'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path &&
          uri == other.uri &&
          displayName == other.displayName &&
          mediaType == other.mediaType &&
          mimeType == other.mimeType &&
          size == other.size &&
          dateAdded == other.dateAdded &&
          dateModified == other.dateModified &&
          dateTaken == other.dateTaken &&
          durationMs == other.durationMs &&
          width == other.width &&
          height == other.height &&
          orientation == other.orientation &&
          isFavorite == other.isFavorite &&
          isVaulted == other.isVaulted &&
          isTrash == other.isTrash &&
          exifData == other.exifData &&
          listEquals(tags, other.tags) &&
          userNotes == other.userNotes &&
          sha256Hash == other.sha256Hash &&
          pHash == other.pHash &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          address == other.address;

  @override
  int get hashCode => Object.hash(
    id,
    path,
    uri,
    displayName,
    mediaType,
    mimeType,
    size,
    dateAdded,
    dateModified,
    dateTaken,
    durationMs,
    width,
    height,
    orientation,
    isFavorite,
    isVaulted,
    isTrash,
    exifData,
    Object.hashAll(tags),
    userNotes,
  );
}
