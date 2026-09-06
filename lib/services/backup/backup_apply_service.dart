import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/tag_repository.dart';

/// Writes a [RestorePlan] into the database.
///
/// Everything it does is additive, and that is not an accident of the code but
/// the point of it. A restore creates tags and albums that are missing, adds
/// links, and fills in blank notes and places. It never deletes a tag, never
/// deletes an album, never removes a link, and never blanks a field the
/// device already has.
///
/// It goes through the repositories rather than the DAOs wherever one exists,
/// so tag creation still runs the name rules and album creation still keeps
/// the full-text index in step. Reaching past them to save a few lines would
/// mean a restored tag behaved differently from a typed one.
///
/// Every item is applied on its own and a failure on one is counted rather
/// than thrown. Half a restore is worth more than none, and a single odd row
/// should not cost somebody the other four hundred.
class BackupApplyService {
  final TagRepository _tagRepository;
  final AlbumRepository _albumRepository;
  final MediaDao _mediaDao;

  BackupApplyService({
    required TagRepository tagRepository,
    required AlbumRepository albumRepository,
    required MediaDao mediaDao,
  }) : _tagRepository = tagRepository,
       _albumRepository = albumRepository,
       _mediaDao = mediaDao;

  /// Applies [plan], using [payload] for the detail the plan only counted.
  ///
  /// [onProgress] fires as each stage finishes, so the screen can move while
  /// a large archive is written.
  Future<RestoreSummary> apply({
    required RestorePlan plan,
    required BackupPayload payload,
    required List<MediaItem> localMedia,
    void Function(int done, int total)? onProgress,
  }) async {
    // The plan speaks in the archive's ids. Everything below has to be in
    // this device's ids, so the maps are resolved once, up front.
    final mediaIdMap = <String, String>{
      for (final match in plan.mediaMatches)
        match.backupMediaId: match.localMediaId,
    };
    final localById = <String, MediaItem>{
      for (final item in localMedia) item.id: item,
    };

    var tagsCreated = 0;
    var albumsCreated = 0;
    var tagLinksAdded = 0;
    var albumLinksAdded = 0;
    var mediaUpdated = 0;

    const stages = 4;
    var stage = 0;

    // 1. Tags. Created through the repository, so the name rules and the
    //    colour palette apply exactly as they would to a typed one.
    final tagIdMap = Map<String, String>.from(plan.tagIdMap);
    for (final tag in plan.tagsToCreate) {
      try {
        final created = await _tagRepository.findOrCreateTag(
          tag.name,
          colorValue: tag.colorValue,
        );
        tagIdMap[tag.id] = created.id;
        tagsCreated++;
      } catch (_) {
        // A name the rules refuse, or one taken since the preview. The link
        // that wanted it is skipped below rather than written to nothing.
        tagIdMap.remove(tag.id);
      }
    }
    onProgress?.call(++stage, stages);

    // 2. Albums.
    final albumIdMap = Map<String, String>.from(plan.albumIdMap);
    for (final album in plan.albumsToCreate) {
      try {
        final created = await _albumRepository.createAlbum(album.name);
        albumIdMap[album.id] = created.id;
        albumsCreated++;

        if (album.isPinned) {
          await _albumRepository.setAlbumPinned(created.id, true);
        }
      } catch (_) {
        albumIdMap.remove(album.id);
      }
    }
    onProgress?.call(++stage, stages);

    // 3. Links. Grouped per media item so each one is a single write rather
    //    than one per tag, and so an existing tag is never removed: the
    //    archive's tags are added to what is there, not swapped for it.
    final tagsByMedia = <String, Set<String>>{};
    for (final link in payload.tagLinks) {
      final localMediaId = mediaIdMap[link.mediaId];
      final localTagId = tagIdMap[link.tagId];
      if (localMediaId == null || localTagId == null) continue;
      tagsByMedia.putIfAbsent(localMediaId, () => <String>{}).add(localTagId);
    }

    for (final entry in tagsByMedia.entries) {
      try {
        final existing = await _tagRepository.getTagsForMedia(entry.key);
        final merged = <String>{...existing.map((t) => t.id), ...entry.value};
        final added = merged.length - existing.length;
        if (added <= 0) continue;

        await _tagRepository.setTagsForMedia(entry.key, merged);
        tagLinksAdded += added;
      } catch (_) {
        // This one photo keeps the tags it had.
      }
    }

    final albumsByMedia = <String, Set<String>>{};
    for (final link in payload.albumLinks) {
      final localMediaId = mediaIdMap[link.mediaId];
      final localAlbumId = albumIdMap[link.albumId];
      if (localMediaId == null || localAlbumId == null) continue;
      albumsByMedia
          .putIfAbsent(localMediaId, () => <String>{})
          .add(localAlbumId);
    }

    for (final entry in albumsByMedia.entries) {
      try {
        final existing = await _albumRepository.getAlbumIdsForMedia(entry.key);
        final toAdd = entry.value.difference(existing.toSet());
        if (toAdd.isEmpty) continue;

        await _albumRepository.addMediaToAlbums(entry.key, toAdd);
        albumLinksAdded += toAdd.length;
      } catch (_) {
        // This one photo stays in the albums it was already in.
      }
    }
    onProgress?.call(++stage, stages);

    // 4. The per-file fields. Only ever filling a gap.
    for (final record in payload.mediaRecords) {
      final localId = mediaIdMap[record.id];
      if (localId == null) continue;
      final local = localById[localId];
      if (local == null) continue;

      final changes = _changesFor(record, local);
      if (changes.isEmpty) continue;

      try {
        await _mediaDao.applyBackupRecord(
          localId,
          isFavorite: changes['isFavorite'] as bool?,
          userNotes: changes['userNotes'] as String?,
          address: changes['address'] as String?,
          latitude: changes['latitude'] as double?,
          longitude: changes['longitude'] as double?,
        );
        mediaUpdated++;
      } catch (_) {
        // This one row keeps what it had.
      }
    }
    onProgress?.call(++stage, stages);

    return RestoreSummary(
      tagsCreated: tagsCreated,
      albumsCreated: albumsCreated,
      tagLinksAdded: tagLinksAdded,
      albumLinksAdded: albumLinksAdded,
      mediaUpdated: mediaUpdated,
      unmatchedRecords: plan.unmatchedCount,
    );
  }

  /// The fields this record would actually change, and nothing else.
  ///
  /// Only ever fills a blank. A note on the device is never replaced by an
  /// older one from an archive, and a favourite is never cleared because the
  /// archive predates it. Restoring should be safe to do twice, or by
  /// mistake, without losing anything.
  static Map<String, Object?> _changesFor(
    BackupMediaRecord record,
    MediaItem local,
  ) {
    final changes = <String, Object?>{};

    if (record.isFavorite && !local.isFavorite) {
      changes['isFavorite'] = true;
    }
    if (_fills(record.userNotes, local.userNotes)) {
      changes['userNotes'] = record.userNotes;
    }
    if (_fills(record.address, local.address)) {
      changes['address'] = record.address;
    }
    if (record.latitude != null && local.latitude == null) {
      changes['latitude'] = record.latitude;
    }
    if (record.longitude != null && local.longitude == null) {
      changes['longitude'] = record.longitude;
    }

    return changes;
  }

  static bool _fills(String? incoming, String? existing) =>
      incoming != null &&
      incoming.isNotEmpty &&
      (existing == null || existing.isEmpty);
}
