import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';

/// A link between one media file and one tag, as stored in an archive.
///
/// Held by the ids the source device used. Restore translates both ends
/// through the match tables rather than trusting either id, which is why this
/// stays a plain pair and carries no names.
@immutable
class BackupTagLink {
  final String mediaId;
  final String tagId;

  const BackupTagLink({required this.mediaId, required this.tagId});

  Map<String, dynamic> toJson() => <String, dynamic>{
    'mediaId': mediaId,
    'tagId': tagId,
  };

  factory BackupTagLink.fromJson(Map<String, dynamic> json) => BackupTagLink(
    mediaId: json['mediaId'] as String? ?? '',
    tagId: json['tagId'] as String? ?? '',
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupTagLink &&
          runtimeType == other.runtimeType &&
          mediaId == other.mediaId &&
          tagId == other.tagId;

  @override
  int get hashCode => Object.hash(mediaId, tagId);
}

/// One media file's place inside one virtual album.
@immutable
class BackupAlbumLink {
  final String albumId;
  final String mediaId;

  /// Where the item sits in the album's own order.
  final int position;

  const BackupAlbumLink({
    required this.albumId,
    required this.mediaId,
    this.position = 0,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'albumId': albumId,
    'mediaId': mediaId,
    'position': position,
  };

  factory BackupAlbumLink.fromJson(Map<String, dynamic> json) =>
      BackupAlbumLink(
        albumId: json['albumId'] as String? ?? '',
        mediaId: json['mediaId'] as String? ?? '',
        position: (json['position'] as num?)?.toInt() ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupAlbumLink &&
          runtimeType == other.runtimeType &&
          albumId == other.albumId &&
          mediaId == other.mediaId &&
          position == other.position;

  @override
  int get hashCode => Object.hash(albumId, mediaId, position);
}

/// A tag as stored in an archive.
///
/// Only the parts the user set. `itemCount` is left out on purpose: it is
/// derived from the links, and carrying it would let the archive disagree
/// with itself.
@immutable
class BackupTag {
  final String id;
  final String name;
  final int colorValue;
  final String? description;
  final int dateCreatedMs;

  const BackupTag({
    required this.id,
    required this.name,
    required this.colorValue,
    this.description,
    required this.dateCreatedMs,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'colorValue': colorValue,
    if (description != null) 'description': description,
    'dateCreatedMs': dateCreatedMs,
  };

  factory BackupTag.fromJson(Map<String, dynamic> json) => BackupTag(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    colorValue: (json['colorValue'] as num?)?.toInt() ?? 0xFF2196F3,
    description: json['description'] as String?,
    dateCreatedMs: (json['dateCreatedMs'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupTag &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          colorValue == other.colorValue &&
          description == other.description &&
          dateCreatedMs == other.dateCreatedMs;

  @override
  int get hashCode =>
      Object.hash(id, name, colorValue, description, dateCreatedMs);
}

/// A virtual album as stored in an archive.
///
/// Only virtual albums are backed up. Device folders are the file system, and
/// smart albums are a rule computed fresh every time, so neither is anything
/// a restore could meaningfully put back.
@immutable
class BackupAlbum {
  final String id;
  final String name;
  final String? coverMediaId;
  final bool isPinned;
  final int sortOrder;
  final int dateCreatedMs;

  const BackupAlbum({
    required this.id,
    required this.name,
    this.coverMediaId,
    this.isPinned = false,
    this.sortOrder = 0,
    required this.dateCreatedMs,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    if (coverMediaId != null) 'coverMediaId': coverMediaId,
    'isPinned': isPinned,
    'sortOrder': sortOrder,
    'dateCreatedMs': dateCreatedMs,
  };

  factory BackupAlbum.fromJson(Map<String, dynamic> json) => BackupAlbum(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    coverMediaId: json['coverMediaId'] as String?,
    isPinned: json['isPinned'] as bool? ?? false,
    sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
    dateCreatedMs: (json['dateCreatedMs'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupAlbum &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          coverMediaId == other.coverMediaId &&
          isPinned == other.isPinned &&
          sortOrder == other.sortOrder &&
          dateCreatedMs == other.dateCreatedMs;

  @override
  int get hashCode =>
      Object.hash(id, name, coverMediaId, isPinned, sortOrder, dateCreatedMs);
}

/// Everything one archive holds.
///
/// The archive is metadata, not media. `docs/Project_Idea.md` asks for tags,
/// virtual albums, metadata edits, notes and favourites, and those are what is
/// here. Photo bytes move device to device through the transfer feature, which
/// is the tool built for that job.
@immutable
class BackupPayload {
  final BackupManifest manifest;
  final List<BackupTag> tags;
  final List<BackupAlbum> albums;
  final List<BackupTagLink> tagLinks;
  final List<BackupAlbumLink> albumLinks;
  final List<BackupMediaRecord> mediaRecords;

  const BackupPayload({
    required this.manifest,
    this.tags = const <BackupTag>[],
    this.albums = const <BackupAlbum>[],
    this.tagLinks = const <BackupTagLink>[],
    this.albumLinks = const <BackupAlbumLink>[],
    this.mediaRecords = const <BackupMediaRecord>[],
  });

  /// Whether there is nothing worth writing out.
  bool get isEmpty =>
      tags.isEmpty &&
      albums.isEmpty &&
      tagLinks.isEmpty &&
      albumLinks.isEmpty &&
      mediaRecords.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupPayload &&
          runtimeType == other.runtimeType &&
          manifest == other.manifest &&
          listEquals(tags, other.tags) &&
          listEquals(albums, other.albums) &&
          listEquals(tagLinks, other.tagLinks) &&
          listEquals(albumLinks, other.albumLinks) &&
          listEquals(mediaRecords, other.mediaRecords);

  @override
  int get hashCode => Object.hash(
    manifest,
    Object.hashAll(tags),
    Object.hashAll(albums),
    Object.hashAll(tagLinks),
    Object.hashAll(albumLinks),
    Object.hashAll(mediaRecords),
  );
}
