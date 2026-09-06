import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';

/// Works out what restoring an archive onto this device would do.
///
/// Pure: it takes the archive and the current contents of the database, and
/// gives back a plan. Nothing is written here, which is what lets the plan be
/// shown to the user before they commit to it, and what lets every matching
/// rule be unit tested without a database at all.
///
/// Two rules shape the whole class:
///
/// 1. **It only adds and updates.** There is no delete list. A restore cannot
///    take away a tag, an album, or a photo this device has and the archive
///    does not, because the user asked to bring something back, not to make
///    this phone identical to an old one.
///
/// 2. **It never invents a media row.** A record whose file is not on this
///    device is reported as unmatched and dropped. Writing a row for a photo
///    that is not there would put a broken tile in every grid that read it.
class BackupMergeService {
  const BackupMergeService();

  /// Builds the plan.
  ///
  /// [localMedia], [localTags] and [localAlbums] are what is on the device
  /// now. [newId] mints an id for anything that has to be created; it is a
  /// parameter so tests can make the output predictable.
  RestorePlan buildPlan({
    required BackupPayload payload,
    required List<MediaItem> localMedia,
    required List<Tag> localTags,
    required List<Album> localAlbums,
    required String Function(String seed) newId,
  }) {
    final mediaIdMap = _matchMedia(payload.mediaRecords, localMedia);
    final matches = payload.mediaRecords
        .where((r) => mediaIdMap.containsKey(r.id))
        .map(
          (r) => RestoreMediaMatch(
            localMediaId: mediaIdMap[r.id]!.localId,
            backupMediaId: r.id,
            kind: mediaIdMap[r.id]!.kind,
          ),
        )
        .toList(growable: false);

    final unmatched = payload.mediaRecords
        .where((r) => !mediaIdMap.containsKey(r.id))
        .map((r) => r.id)
        .toList(growable: false);

    final tagResult = _matchTags(payload.tags, localTags, newId);
    final albumResult = _matchAlbums(payload.albums, localAlbums, newId);

    // Links only count when both ends landed somewhere real.
    final localById = <String, MediaItem>{
      for (final item in localMedia) item.id: item,
    };

    var tagLinkCount = 0;
    for (final link in payload.tagLinks) {
      final localMediaId = mediaIdMap[link.mediaId]?.localId;
      final localTagId = tagResult.idMap[link.tagId];
      if (localMediaId != null && localTagId != null) tagLinkCount++;
    }

    var albumLinkCount = 0;
    for (final link in payload.albumLinks) {
      final localMediaId = mediaIdMap[link.mediaId]?.localId;
      final localAlbumId = albumResult.idMap[link.albumId];
      if (localMediaId != null && localAlbumId != null) albumLinkCount++;
    }

    // A media row only counts as an update when the archive would actually
    // change something. Reporting "412 photos updated" when 400 of them are
    // already exactly right would make the preview useless.
    var mediaUpdateCount = 0;
    for (final record in payload.mediaRecords) {
      final localId = mediaIdMap[record.id]?.localId;
      if (localId == null) continue;
      final local = localById[localId];
      if (local == null) continue;
      if (_wouldChange(record, local)) mediaUpdateCount++;
    }

    return RestorePlan(
      manifest: payload.manifest,
      tagsToCreate: tagResult.toCreate,
      tagIdMap: tagResult.idMap,
      albumsToCreate: albumResult.toCreate,
      albumIdMap: albumResult.idMap,
      mediaMatches: matches,
      unmatchedMediaIds: unmatched,
      tagLinkCount: tagLinkCount,
      albumLinkCount: albumLinkCount,
      mediaUpdateCount: mediaUpdateCount,
    );
  }

  /// Whether applying [record] to [local] would change anything.
  ///
  /// A note or a place already on the device is never blanked by an archive
  /// that has none: restore fills gaps, it does not erase. Favourite is the
  /// exception in one direction only — an archived favourite sets the mark,
  /// an archived non-favourite leaves an existing mark alone.
  static bool _wouldChange(BackupMediaRecord record, MediaItem local) {
    if (record.isFavorite && !local.isFavorite) return true;
    if (_fills(record.userNotes, local.userNotes)) return true;
    if (_fills(record.address, local.address)) return true;
    if (record.latitude != null && local.latitude == null) return true;
    if (record.longitude != null && local.longitude == null) return true;
    return false;
  }

  /// Whether the archive has text where the device has none.
  static bool _fills(String? incoming, String? existing) =>
      incoming != null &&
      incoming.isNotEmpty &&
      (existing == null || existing.isEmpty);

  // ------------------------------------------------------------------ media

  /// Ties each archive record to a local file, in order of confidence.
  ///
  /// Four routes, strongest first:
  ///
  /// 1. **Same id.** Right on the phone the backup came from, meaningless
  ///    anywhere else, so it is tried first and never trusted alone.
  /// 2. **Same SHA-256.** The strongest cross-device match there is. Only
  ///    available where the duplicate scan has already run.
  /// 3. **Same absolute path.** Good on the same phone after a reinstall.
  /// 4. **Same name, size and capture time.** The last resort. Two different
  ///    photos agreeing on all three is not something that happens by chance.
  ///
  /// A local file is claimed once. Without that, a burst of identical frames
  /// would all match the same record and the tags would land on one photo
  /// several times over instead of on each.
  static Map<String, ({String localId, RestoreMatchKind kind})> _matchMedia(
    List<BackupMediaRecord> records,
    List<MediaItem> localMedia,
  ) {
    final byId = <String, MediaItem>{};
    final byHash = <String, MediaItem>{};
    final byPath = <String, MediaItem>{};
    final byFingerprint = <String, MediaItem>{};

    for (final item in localMedia) {
      byId.putIfAbsent(item.id, () => item);
      if (item.path.isNotEmpty) byPath.putIfAbsent(item.path, () => item);
      final hash = item.sha256Hash;
      if (hash != null && hash.isNotEmpty) byHash.putIfAbsent(hash, () => item);
      byFingerprint.putIfAbsent(_fingerprintOf(item), () => item);
    }

    final claimed = <String>{};
    final out = <String, ({String localId, RestoreMatchKind kind})>{};

    for (final record in records) {
      final match = _matchOne(
        record,
        byId: byId,
        byHash: byHash,
        byPath: byPath,
        byFingerprint: byFingerprint,
        claimed: claimed,
      );
      if (match == null) continue;
      claimed.add(match.localId);
      out[record.id] = match;
    }
    return out;
  }

  static ({String localId, RestoreMatchKind kind})? _matchOne(
    BackupMediaRecord record, {
    required Map<String, MediaItem> byId,
    required Map<String, MediaItem> byHash,
    required Map<String, MediaItem> byPath,
    required Map<String, MediaItem> byFingerprint,
    required Set<String> claimed,
  }) {
    final candidates = <(MediaItem?, RestoreMatchKind)>[
      (byId[record.id], RestoreMatchKind.byId),
      (
        record.sha256 == null || record.sha256!.isEmpty
            ? null
            : byHash[record.sha256!],
        RestoreMatchKind.byHash,
      ),
      (
        record.path.isEmpty ? null : byPath[record.path],
        RestoreMatchKind.byPath,
      ),
      (
        byFingerprint[_recordFingerprint(record)],
        RestoreMatchKind.byFingerprint,
      ),
    ];

    for (final (item, kind) in candidates) {
      if (item == null) continue;
      if (claimed.contains(item.id)) continue;
      return (localId: item.id, kind: kind);
    }
    return null;
  }

  /// Name, size and capture time, joined. Case-folded on the name because
  /// MediaStore and the file system do not always agree about it.
  static String _fingerprintOf(MediaItem item) =>
      '${item.displayName.toLowerCase()}|${item.size}|'
      '${item.dateTaken?.millisecondsSinceEpoch ?? 0}';

  static String _recordFingerprint(BackupMediaRecord record) =>
      '${record.displayName.toLowerCase()}|${record.sizeBytes}|'
      '${record.dateTakenMs ?? 0}';

  // ------------------------------------------------------------------- tags

  /// Matches archive tags to local ones by name, and lists the rest.
  ///
  /// Name, not id, and case-insensitively: a "Family" tag on the old phone
  /// and a "family" tag on this one are the same tag as far as the person
  /// using them is concerned, and making a second one would be wrong.
  static ({List<BackupTag> toCreate, Map<String, String> idMap}) _matchTags(
    List<BackupTag> archiveTags,
    List<Tag> localTags,
    String Function(String seed) newId,
  ) {
    final localByName = <String, Tag>{
      for (final tag in localTags) tag.name.trim().toLowerCase(): tag,
    };

    final toCreate = <BackupTag>[];
    final idMap = <String, String>{};
    final takenNames = <String>{...localByName.keys};

    for (final archiveTag in archiveTags) {
      final key = archiveTag.name.trim().toLowerCase();
      if (key.isEmpty) continue;

      final existing = localByName[key];
      if (existing != null) {
        idMap[archiveTag.id] = existing.id;
        continue;
      }
      // An archive holding the same name twice creates it once.
      if (!takenNames.add(key)) {
        final already = toCreate.firstWhere(
          (t) => t.name.trim().toLowerCase() == key,
        );
        idMap[archiveTag.id] = idMap[already.id]!;
        continue;
      }

      final mintedId = newId(key);
      idMap[archiveTag.id] = mintedId;
      toCreate.add(archiveTag);
    }

    return (
      toCreate: List.unmodifiable(toCreate),
      idMap: Map.unmodifiable(idMap),
    );
  }

  // ----------------------------------------------------------------- albums

  /// Matches archive albums to local virtual albums by name.
  ///
  /// Only virtual albums are considered. A device folder is the file system
  /// and a smart album is a rule computed fresh, so neither is something a
  /// restore could put back or should collide with.
  static ({List<BackupAlbum> toCreate, Map<String, String> idMap}) _matchAlbums(
    List<BackupAlbum> archiveAlbums,
    List<Album> localAlbums,
    String Function(String seed) newId,
  ) {
    final localByName = <String, Album>{
      for (final album in localAlbums)
        if (album.albumType == AlbumType.virtualAlbum)
          album.name.trim().toLowerCase(): album,
    };

    final toCreate = <BackupAlbum>[];
    final idMap = <String, String>{};
    final takenNames = <String>{...localByName.keys};

    for (final archiveAlbum in archiveAlbums) {
      final key = archiveAlbum.name.trim().toLowerCase();
      if (key.isEmpty) continue;

      final existing = localByName[key];
      if (existing != null) {
        idMap[archiveAlbum.id] = existing.id;
        continue;
      }
      if (!takenNames.add(key)) {
        final already = toCreate.firstWhere(
          (a) => a.name.trim().toLowerCase() == key,
        );
        idMap[archiveAlbum.id] = idMap[already.id]!;
        continue;
      }

      final mintedId = newId(key);
      idMap[archiveAlbum.id] = mintedId;
      toCreate.add(archiveAlbum);
    }

    return (
      toCreate: List.unmodifiable(toCreate),
      idMap: Map.unmodifiable(idMap),
    );
  }
}
