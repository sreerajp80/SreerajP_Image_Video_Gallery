import 'package:flutter/foundation.dart';

/// One media file's user-owned metadata, as stored in a backup archive.
///
/// Deliberately not a whole [MediaItem]. Width, height, duration, MIME type
/// and the perceptual hashes are all facts about the file that a rescan can
/// work out again on any device, so putting them in the archive would only
/// make it bigger and let it go stale. What is kept is what the user made and
/// a scan cannot recover: the favourite mark, the notes, the place name, and
/// the edited capture date.
///
/// The identity fields ([path], [displayName], [sizeBytes], [dateTakenMs],
/// [sha256]) are there to find the same file again on restore, not to be
/// restored themselves. Nothing in this record ever overwrites a path.
@immutable
class BackupMediaRecord {
  /// The media id on the device the backup came from.
  ///
  /// First choice for matching, and usually right when restoring onto the
  /// same phone. Useless across devices, where MediaStore hands out its own
  /// ids, which is why the other three routes exist.
  final String id;

  /// Absolute path the file had when the backup was made.
  final String path;

  /// Base filename with extension.
  final String displayName;

  /// File size in bytes.
  final int sizeBytes;

  /// Capture time in milliseconds since the epoch, or null if unknown.
  final int? dateTakenMs;

  /// Content digest, when one had already been computed.
  ///
  /// Null for a library the duplicate scan has never run over. When present
  /// it is the strongest cross-device match there is, so it is tried first.
  final String? sha256;

  // ---- the parts that are actually restored ----

  /// Whether the user marked the file a favourite.
  final bool isFavorite;

  /// The user's own note text.
  final String? userNotes;

  /// Reverse-geocoded place name the user or the app attached.
  final String? address;

  final double? latitude;
  final double? longitude;

  const BackupMediaRecord({
    required this.id,
    required this.path,
    required this.displayName,
    required this.sizeBytes,
    this.dateTakenMs,
    this.sha256,
    this.isFavorite = false,
    this.userNotes,
    this.address,
    this.latitude,
    this.longitude,
  });

  /// Whether this record carries anything worth restoring.
  ///
  /// A file with no favourite mark, no note and no place is pure identity, so
  /// the collector leaves it out and the archive stays small.
  bool get hasUserData =>
      isFavorite ||
      (userNotes != null && userNotes!.isNotEmpty) ||
      (address != null && address!.isNotEmpty) ||
      latitude != null ||
      longitude != null;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'path': path,
    'displayName': displayName,
    'sizeBytes': sizeBytes,
    if (dateTakenMs != null) 'dateTakenMs': dateTakenMs,
    if (sha256 != null) 'sha256': sha256,
    'isFavorite': isFavorite,
    if (userNotes != null) 'userNotes': userNotes,
    if (address != null) 'address': address,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  /// Reads one record, tolerating a field it has never seen.
  ///
  /// An archive written by a later version must not make an older build
  /// throw: unknown keys are ignored, and a missing optional key falls back.
  factory BackupMediaRecord.fromJson(Map<String, dynamic> json) {
    return BackupMediaRecord(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      dateTakenMs: (json['dateTakenMs'] as num?)?.toInt(),
      sha256: json['sha256'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      userNotes: json['userNotes'] as String?,
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupMediaRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path &&
          displayName == other.displayName &&
          sizeBytes == other.sizeBytes &&
          dateTakenMs == other.dateTakenMs &&
          sha256 == other.sha256 &&
          isFavorite == other.isFavorite &&
          userNotes == other.userNotes &&
          address == other.address &&
          latitude == other.latitude &&
          longitude == other.longitude;

  @override
  int get hashCode => Object.hash(
    id,
    path,
    displayName,
    sizeBytes,
    dateTakenMs,
    sha256,
    isFavorite,
    userNotes,
    address,
    latitude,
    longitude,
  );
}
