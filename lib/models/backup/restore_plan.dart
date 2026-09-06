import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';

/// How a backup record was matched to a file on this device.
enum RestoreMatchKind {
  /// Same media id. Almost always the same phone.
  byId,

  /// Same content digest. The strongest cross-device match there is.
  byHash,

  /// Same absolute path.
  byPath,

  /// Same name, size and capture time. The last resort, and good enough:
  /// two different photos agreeing on all three is not something that
  /// happens by accident.
  byFingerprint,
}

/// One media record paired with the local file it will be applied to.
@immutable
class RestoreMediaMatch {
  /// Media id on this device.
  final String localMediaId;

  /// Media id the archive used.
  final String backupMediaId;

  /// How the two were tied together.
  final RestoreMatchKind kind;

  const RestoreMediaMatch({
    required this.localMediaId,
    required this.backupMediaId,
    required this.kind,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestoreMediaMatch &&
          runtimeType == other.runtimeType &&
          localMediaId == other.localMediaId &&
          backupMediaId == other.backupMediaId &&
          kind == other.kind;

  @override
  int get hashCode => Object.hash(localMediaId, backupMediaId, kind);
}

/// What a restore is going to do, worked out before anything is written.
///
/// The whole point of building this first is that the user gets to see the
/// counts and say no. It is also why the plan only ever adds and updates:
/// there is no "delete" list, and a restore cannot take away a tag, an album
/// or a photo that this device has and the archive does not.
@immutable
class RestorePlan {
  /// Header of the archive the plan came from.
  final BackupManifest manifest;

  /// Tags that do not exist here yet and will be created.
  final List<BackupTag> tagsToCreate;

  /// Backup tag id to the local tag id it will use.
  ///
  /// Covers both the tags already here (matched by name, case-insensitively)
  /// and the ones about to be created.
  final Map<String, String> tagIdMap;

  /// Albums that do not exist here yet and will be created.
  final List<BackupAlbum> albumsToCreate;

  /// Backup album id to the local album id it will use.
  final Map<String, String> albumIdMap;

  /// Media records that found a home on this device.
  final List<RestoreMediaMatch> mediaMatches;

  /// Backup media ids no local file could be found for.
  ///
  /// Their tags, album places and notes are dropped. This is the honest
  /// outcome: the app will not invent a media row for a photo that is not on
  /// the phone, because that row would point at nothing and break every grid
  /// that read it.
  final List<String> unmatchedMediaIds;

  /// Tag links that will be written, in local ids.
  final int tagLinkCount;

  /// Album places that will be written, in local ids.
  final int albumLinkCount;

  /// Media rows whose favourite, notes or place will change.
  final int mediaUpdateCount;

  const RestorePlan({
    required this.manifest,
    this.tagsToCreate = const <BackupTag>[],
    this.tagIdMap = const <String, String>{},
    this.albumsToCreate = const <BackupAlbum>[],
    this.albumIdMap = const <String, String>{},
    this.mediaMatches = const <RestoreMediaMatch>[],
    this.unmatchedMediaIds = const <String>[],
    this.tagLinkCount = 0,
    this.albumLinkCount = 0,
    this.mediaUpdateCount = 0,
  });

  /// Whether applying this plan would change nothing.
  bool get isEmpty =>
      tagsToCreate.isEmpty &&
      albumsToCreate.isEmpty &&
      tagLinkCount == 0 &&
      albumLinkCount == 0 &&
      mediaUpdateCount == 0;

  /// How many archive records found a local file.
  int get matchedCount => mediaMatches.length;

  /// How many did not.
  int get unmatchedCount => unmatchedMediaIds.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestorePlan &&
          runtimeType == other.runtimeType &&
          manifest == other.manifest &&
          listEquals(tagsToCreate, other.tagsToCreate) &&
          mapEquals(tagIdMap, other.tagIdMap) &&
          listEquals(albumsToCreate, other.albumsToCreate) &&
          mapEquals(albumIdMap, other.albumIdMap) &&
          listEquals(mediaMatches, other.mediaMatches) &&
          listEquals(unmatchedMediaIds, other.unmatchedMediaIds) &&
          tagLinkCount == other.tagLinkCount &&
          albumLinkCount == other.albumLinkCount &&
          mediaUpdateCount == other.mediaUpdateCount;

  @override
  int get hashCode => Object.hash(
    manifest,
    Object.hashAll(tagsToCreate),
    Object.hashAll(tagIdMap.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(albumsToCreate),
    Object.hashAll(albumIdMap.entries.map((e) => Object.hash(e.key, e.value))),
    Object.hashAll(mediaMatches),
    Object.hashAll(unmatchedMediaIds),
    tagLinkCount,
    albumLinkCount,
    mediaUpdateCount,
  );
}
