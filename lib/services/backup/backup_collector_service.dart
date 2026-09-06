import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_constants.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';

/// Gathers everything a backup archive holds.
///
/// Reads the database and gives back one [BackupPayload]. It writes nothing
/// and encrypts nothing: turning the payload into a file is the backup
/// service's job, and keeping the two apart means the contents of an archive
/// can be checked without a password or a file picker anywhere in sight.
class BackupCollectorService {
  final MediaDao _mediaDao;
  final TagDao _tagDao;
  final AlbumDao _albumDao;

  BackupCollectorService({
    required MediaDao mediaDao,
    required TagDao tagDao,
    required AlbumDao albumDao,
  }) : _mediaDao = mediaDao,
       _tagDao = tagDao,
       _albumDao = albumDao;

  /// Builds the payload.
  ///
  /// [appVersion] goes into the manifest so a restore can say which build
  /// wrote the file. [now] is a parameter so a test can pin the timestamp.
  Future<BackupPayload> collect({
    required String appVersion,
    DateTime? now,
  }) async {
    final tags = await _collectTags();
    final albums = await _collectAlbums();

    final rows = await _mediaDao.getBackupRecords();
    final allById = <String, BackupMediaRecord>{};
    for (final row in rows) {
      final record = _recordFrom(row);
      if (record.id.isNotEmpty) allById[record.id] = record;
    }

    final keptTagIds = <String>{for (final t in tags) t.id};
    final keptAlbumIds = <String>{for (final a in albums) a.id};

    // Links come first, because they decide which media records the archive
    // has to carry. A photo with no note and no favourite is still worth a
    // record if it sits in an album: without one the album membership has
    // nothing to hang on, and the album would restore empty. Getting this
    // the wrong way round would silently lose exactly what most people make
    // a backup for.
    final tagLinks = <BackupTagLink>[];
    final linkedMediaIds = <String>{};
    for (final link in await _tagDao.getAllMediaTagLinks()) {
      if (!allById.containsKey(link.mediaId)) continue;
      if (!keptTagIds.contains(link.tagId)) continue;
      tagLinks.add(BackupTagLink(mediaId: link.mediaId, tagId: link.tagId));
      linkedMediaIds.add(link.mediaId);
    }

    final albumLinks = <BackupAlbumLink>[];
    for (final link in await _albumDao.getAllAlbumMediaLinks()) {
      if (!allById.containsKey(link.mediaId)) continue;
      if (!keptAlbumIds.contains(link.albumId)) continue;
      albumLinks.add(
        BackupAlbumLink(
          albumId: link.albumId,
          mediaId: link.mediaId,
          position: link.position,
        ),
      );
      linkedMediaIds.add(link.mediaId);
    }

    // Keep a record when it carries something the user made, or when a link
    // needs it as an anchor. Everything else is pure identity and restores to
    // nothing, so leaving it out costs the user no information and keeps the
    // archive small.
    final mediaRecords = <BackupMediaRecord>[
      for (final record in allById.values)
        if (record.hasUserData)
          record
        else if (linkedMediaIds.contains(record.id))
          record,
    ];

    return BackupPayload(
      manifest: BackupManifest(
        payloadVersion: BackupSerializer.payloadVersion,
        schemaVersion: DatabaseConstants.schemaVersion,
        appVersion: appVersion,
        createdAtMs: (now ?? DateTime.now()).millisecondsSinceEpoch,
        tagCount: tags.length,
        albumCount: albums.length,
        mediaRecordCount: mediaRecords.length,
      ),
      tags: List.unmodifiable(tags),
      albums: List.unmodifiable(albums),
      tagLinks: List.unmodifiable(tagLinks),
      albumLinks: List.unmodifiable(albumLinks),
      mediaRecords: List.unmodifiable(mediaRecords),
    );
  }

  Future<List<BackupTag>> _collectTags() async {
    final tags = await _tagDao.getAllTags();
    return tags
        .map(
          (tag) => BackupTag(
            id: tag.id,
            name: tag.name,
            colorValue: tag.colorValue,
            description: tag.description,
            dateCreatedMs: tag.dateCreated.millisecondsSinceEpoch,
          ),
        )
        .toList(growable: false);
  }

  /// Only virtual albums.
  ///
  /// A device folder is the file system and a smart album is a rule computed
  /// fresh every time, so neither is something a restore could put back. The
  /// user made the virtual albums, and those are what an archive owes them.
  Future<List<BackupAlbum>> _collectAlbums() async {
    final albums = await _albumDao.getAlbumsByType(AlbumType.virtualAlbum);
    return albums
        .map(
          (album) => BackupAlbum(
            id: album.id,
            name: album.name,
            coverMediaId: album.coverMediaId,
            isPinned: album.isPinned,
            sortOrder: album.sortOrder,
            dateCreatedMs: album.dateCreated.millisecondsSinceEpoch,
          ),
        )
        .toList(growable: false);
  }

  /// Turns one database row into a record.
  ///
  /// Only the user-owned columns plus what a restore needs to find the same
  /// file again. Width, height, duration and the perceptual hashes are all
  /// facts a rescan works out on its own, so carrying them would only make
  /// the archive bigger and let it go stale.
  static BackupMediaRecord _recordFrom(Map<String, Object?> row) {
    return BackupMediaRecord(
      id: row[DatabaseConstants.colId] as String? ?? '',
      path: row[DatabaseConstants.colMediaPath] as String? ?? '',
      displayName: row[DatabaseConstants.colMediaDisplayName] as String? ?? '',
      sizeBytes:
          (row[DatabaseConstants.colMediaSizeBytes] as num?)?.toInt() ?? 0,
      dateTakenMs: (row[DatabaseConstants.colMediaDateTaken] as num?)?.toInt(),
      sha256: row[DatabaseConstants.colMediaSha256Hash] as String?,
      isFavorite:
          ((row[DatabaseConstants.colMediaIsFavorite] as num?)?.toInt() ?? 0) ==
          1,
      userNotes: row[DatabaseConstants.colMediaUserNotes] as String?,
      address: row[DatabaseConstants.colMediaAddress] as String?,
      latitude: (row[DatabaseConstants.colMediaLatitude] as num?)?.toDouble(),
      longitude: (row[DatabaseConstants.colMediaLongitude] as num?)?.toDouble(),
    );
  }
}
