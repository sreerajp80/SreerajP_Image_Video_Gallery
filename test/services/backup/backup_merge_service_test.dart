import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_merge_service.dart';

const _service = BackupMergeService();

/// Predictable ids, so a plan can be asserted on exactly.
String _newId(String seed) => 'new_$seed';

BackupManifest get _manifest => const BackupManifest(
  payloadVersion: 1,
  schemaVersion: 2,
  appVersion: '1.0.0+1',
  createdAtMs: 1756584284000,
);

MediaItem _local({
  required String id,
  String path = '',
  String displayName = 'IMG.jpg',
  int size = 1000,
  DateTime? dateTaken,
  String? sha256,
  bool isFavorite = false,
  String? userNotes,
  String? address,
  double? latitude,
  double? longitude,
}) {
  return MediaItem(
    id: id,
    path: path.isEmpty ? '/storage/$id.jpg' : path,
    displayName: displayName,
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: size,
    dateAdded: DateTime(2026, 1, 1),
    dateModified: DateTime(2026, 1, 1),
    dateTaken: dateTaken,
    sha256Hash: sha256,
    isFavorite: isFavorite,
    userNotes: userNotes,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}

BackupMediaRecord _record({
  required String id,
  String path = '',
  String displayName = 'IMG.jpg',
  int sizeBytes = 1000,
  int? dateTakenMs,
  String? sha256,
  bool isFavorite = false,
  String? userNotes,
  String? address,
  double? latitude,
  double? longitude,
}) {
  return BackupMediaRecord(
    id: id,
    path: path.isEmpty ? '/storage/$id.jpg' : path,
    displayName: displayName,
    sizeBytes: sizeBytes,
    dateTakenMs: dateTakenMs,
    sha256: sha256,
    isFavorite: isFavorite,
    userNotes: userNotes,
    address: address,
    latitude: latitude,
    longitude: longitude,
  );
}

Album _album(
  String id,
  String name, {
  AlbumType type = AlbumType.virtualAlbum,
}) {
  return Album(
    id: id,
    name: name,
    albumType: type,
    dateCreated: DateTime(2026, 1, 1),
    dateModified: DateTime(2026, 1, 1),
  );
}

Tag _tag(String id, String name) => Tag(
  id: id,
  name: name,
  colorValue: 0xFF2196F3,
  dateCreated: DateTime(2026, 1, 1),
);

RestorePlan _plan({
  BackupPayload? payload,
  List<MediaItem> localMedia = const <MediaItem>[],
  List<Tag> localTags = const <Tag>[],
  List<Album> localAlbums = const <Album>[],
}) {
  return _service.buildPlan(
    payload: payload ?? BackupPayload(manifest: _manifest),
    localMedia: localMedia,
    localTags: localTags,
    localAlbums: localAlbums,
    newId: _newId,
  );
}

void main() {
  group('media matching — by id', () {
    test('matches a record to the local file with the same id', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'm1', isFavorite: true),
          ],
        ),
        localMedia: <MediaItem>[_local(id: 'm1')],
      );

      expect(plan.mediaMatches, hasLength(1));
      expect(plan.mediaMatches.single.localMediaId, 'm1');
      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byId);
      expect(plan.unmatchedMediaIds, isEmpty);
    });
  });

  group('media matching — by content digest', () {
    test('matches across devices when both sides know the hash', () {
      // The strongest cross-device route: MediaStore ids and paths both
      // differ on a new phone, but the bytes do not.
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(
              id: 'old_id',
              path: '/old/phone/IMG_1.jpg',
              displayName: 'IMG_1.jpg',
              sha256: 'deadbeef',
              isFavorite: true,
            ),
          ],
        ),
        localMedia: <MediaItem>[
          _local(
            id: 'new_id',
            path: '/new/phone/DCIM/Camera/IMG_1.jpg',
            displayName: 'IMG_1.jpg',
            sha256: 'deadbeef',
          ),
        ],
      );

      expect(plan.mediaMatches.single.localMediaId, 'new_id');
      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byHash);
    });

    test('a hash beats a path when the two disagree', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'r1', path: '/shared/IMG.jpg', sha256: 'aaa'),
          ],
        ),
        localMedia: <MediaItem>[
          _local(id: 'by_hash', path: '/moved/IMG.jpg', sha256: 'aaa'),
          _local(id: 'by_path', path: '/shared/IMG.jpg', sha256: 'bbb'),
        ],
      );

      expect(plan.mediaMatches.single.localMediaId, 'by_hash');
      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byHash);
    });

    test('an empty hash string is not treated as a hash', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'r1', path: '/p/a.jpg', sha256: ''),
          ],
        ),
        localMedia: <MediaItem>[_local(id: 'l1', path: '/p/a.jpg', sha256: '')],
      );

      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byPath);
    });
  });

  group('media matching — by path', () {
    test('matches the same absolute path after a reinstall', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'old_1', path: '/storage/emulated/0/DCIM/a.jpg'),
          ],
        ),
        localMedia: <MediaItem>[
          _local(id: 'fresh_1', path: '/storage/emulated/0/DCIM/a.jpg'),
        ],
      );

      expect(plan.mediaMatches.single.localMediaId, 'fresh_1');
      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byPath);
    });
  });

  group('media matching — by fingerprint', () {
    test('matches on name, size and capture time together', () {
      final taken = DateTime(2026, 5, 4, 12, 30);
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(
              id: 'old',
              path: '/old/IMG_9.jpg',
              displayName: 'IMG_9.jpg',
              sizeBytes: 3333,
              dateTakenMs: taken.millisecondsSinceEpoch,
            ),
          ],
        ),
        localMedia: <MediaItem>[
          _local(
            id: 'new',
            path: '/totally/different/IMG_9.jpg',
            displayName: 'IMG_9.jpg',
            size: 3333,
            dateTaken: taken,
          ),
        ],
      );

      expect(plan.mediaMatches.single.localMediaId, 'new');
      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byFingerprint);
    });

    test('is case-insensitive on the file name', () {
      final taken = DateTime(2026, 5, 4);
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(
              id: 'old',
              path: '/old/IMG_9.JPG',
              displayName: 'IMG_9.JPG',
              sizeBytes: 10,
              dateTakenMs: taken.millisecondsSinceEpoch,
            ),
          ],
        ),
        localMedia: <MediaItem>[
          _local(
            id: 'new',
            path: '/new/img_9.jpg',
            displayName: 'img_9.jpg',
            size: 10,
            dateTaken: taken,
          ),
        ],
      );

      expect(plan.mediaMatches.single.kind, RestoreMatchKind.byFingerprint);
    });

    test('a different size means a different photo', () {
      final taken = DateTime(2026, 5, 4);
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(
              id: 'old',
              path: '/old/IMG_9.jpg',
              displayName: 'IMG_9.jpg',
              sizeBytes: 10,
              dateTakenMs: taken.millisecondsSinceEpoch,
            ),
          ],
        ),
        localMedia: <MediaItem>[
          _local(
            id: 'new',
            path: '/new/IMG_9.jpg',
            displayName: 'IMG_9.jpg',
            size: 99999,
            dateTaken: taken,
          ),
        ],
      );

      expect(plan.mediaMatches, isEmpty);
      expect(plan.unmatchedMediaIds, <String>['old']);
    });
  });

  group('media matching — nothing is invented', () {
    test('a record with no local file is reported unmatched', () {
      // The app will not write a media row for a photo that is not on the
      // phone: that row would point at nothing and break every grid.
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'gone', path: '/deleted/x.jpg', displayName: 'x.jpg'),
          ],
        ),
        localMedia: <MediaItem>[_local(id: 'other', displayName: 'y.jpg')],
      );

      expect(plan.mediaMatches, isEmpty);
      expect(plan.unmatchedMediaIds, <String>['gone']);
      expect(plan.unmatchedCount, 1);
    });

    test('a local file is claimed by one record only', () {
      // Otherwise a burst of identical frames all match the same file and the
      // tags pile onto one photo instead of landing on each.
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(
              id: 'r1',
              path: '/p/a.jpg',
              displayName: 'a.jpg',
              sha256: 'same',
            ),
            _record(
              id: 'r2',
              path: '/p/b.jpg',
              displayName: 'b.jpg',
              sha256: 'same',
            ),
          ],
        ),
        localMedia: <MediaItem>[
          _local(
            id: 'only',
            path: '/p/a.jpg',
            displayName: 'a.jpg',
            sha256: 'same',
          ),
        ],
      );

      expect(plan.mediaMatches, hasLength(1));
      expect(plan.unmatchedMediaIds, <String>['r2']);
    });

    test('an empty archive plans nothing', () {
      final plan = _plan(localMedia: <MediaItem>[_local(id: 'a')]);
      expect(plan.isEmpty, isTrue);
      expect(plan.matchedCount, 0);
    });
  });

  group('tags', () {
    test('reuses a local tag with the same name, case-insensitively', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          tags: const <BackupTag>[
            BackupTag(
              id: 'old_family',
              name: 'Family',
              colorValue: 1,
              dateCreatedMs: 1,
            ),
          ],
        ),
        localTags: <Tag>[_tag('local_family', 'family')],
      );

      expect(plan.tagsToCreate, isEmpty);
      expect(plan.tagIdMap['old_family'], 'local_family');
    });

    test('creates a tag this device does not have', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          tags: const <BackupTag>[
            BackupTag(
              id: 'old_trip',
              name: 'Trip',
              colorValue: 1,
              dateCreatedMs: 1,
            ),
          ],
        ),
      );

      expect(plan.tagsToCreate.map((t) => t.name), <String>['Trip']);
      expect(plan.tagIdMap['old_trip'], 'new_trip');
    });

    test('creates a duplicated archive name only once', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          tags: const <BackupTag>[
            BackupTag(id: 'a', name: 'Trip', colorValue: 1, dateCreatedMs: 1),
            BackupTag(id: 'b', name: 'trip', colorValue: 2, dateCreatedMs: 2),
          ],
        ),
      );

      expect(plan.tagsToCreate, hasLength(1));
      expect(plan.tagIdMap['a'], plan.tagIdMap['b']);
    });

    test('skips a tag with a blank name', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          tags: const <BackupTag>[
            BackupTag(
              id: 'blank',
              name: '   ',
              colorValue: 1,
              dateCreatedMs: 1,
            ),
          ],
        ),
      );

      expect(plan.tagsToCreate, isEmpty);
      expect(plan.tagIdMap, isEmpty);
    });
  });

  group('albums', () {
    test('reuses a local virtual album with the same name', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          albums: const <BackupAlbum>[
            BackupAlbum(id: 'old', name: 'Best of 2026', dateCreatedMs: 1),
          ],
        ),
        localAlbums: <Album>[_album('local', 'best of 2026')],
      );

      expect(plan.albumsToCreate, isEmpty);
      expect(plan.albumIdMap['old'], 'local');
    });

    test('ignores device folders and smart albums when matching', () {
      // A folder called "Camera" must not stop a virtual album of the same
      // name being created: they are different kinds of thing.
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          albums: const <BackupAlbum>[
            BackupAlbum(id: 'old', name: 'Camera', dateCreatedMs: 1),
          ],
        ),
        localAlbums: <Album>[
          _album('folder', 'Camera', type: AlbumType.physicalFolder),
          _album('smart', 'Camera', type: AlbumType.smartVideos),
        ],
      );

      expect(plan.albumsToCreate, hasLength(1));
      expect(plan.albumIdMap['old'], 'new_camera');
    });
  });

  group('link counting', () {
    test('counts only links whose two ends both landed', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          tags: const <BackupTag>[
            BackupTag(id: 't1', name: 'Trip', colorValue: 1, dateCreatedMs: 1),
          ],
          albums: const <BackupAlbum>[
            BackupAlbum(id: 'a1', name: 'Best', dateCreatedMs: 1),
          ],
          tagLinks: const <BackupTagLink>[
            BackupTagLink(mediaId: 'here', tagId: 't1'),
            BackupTagLink(mediaId: 'gone', tagId: 't1'),
            BackupTagLink(mediaId: 'here', tagId: 'unknown_tag'),
          ],
          albumLinks: const <BackupAlbumLink>[
            BackupAlbumLink(albumId: 'a1', mediaId: 'here'),
            BackupAlbumLink(albumId: 'a1', mediaId: 'gone'),
            BackupAlbumLink(albumId: 'unknown_album', mediaId: 'here'),
          ],
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'here', displayName: 'here.jpg'),
            _record(id: 'gone', displayName: 'gone.jpg'),
          ],
        ),
        localMedia: <MediaItem>[
          _local(
            id: 'here',
            path: '/storage/here.jpg',
            displayName: 'here.jpg',
          ),
        ],
      );

      expect(plan.tagLinkCount, 1);
      expect(plan.albumLinkCount, 1);
    });
  });

  group('media updates — restore fills gaps, it never erases', () {
    test('counts a favourite the device does not have', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[_record(id: 'm', isFavorite: true)],
        ),
        localMedia: <MediaItem>[_local(id: 'm', isFavorite: false)],
      );

      expect(plan.mediaUpdateCount, 1);
    });

    test('does not count a favourite already set', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[_record(id: 'm', isFavorite: true)],
        ),
        localMedia: <MediaItem>[_local(id: 'm', isFavorite: true)],
      );

      expect(plan.mediaUpdateCount, 0);
    });

    test('an archive without a favourite never clears one on the device', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'm', isFavorite: false),
          ],
        ),
        localMedia: <MediaItem>[_local(id: 'm', isFavorite: true)],
      );

      expect(plan.mediaUpdateCount, 0);
    });

    test('an archived note fills an empty one', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'm', userNotes: 'note'),
          ],
        ),
        localMedia: <MediaItem>[_local(id: 'm')],
      );

      expect(plan.mediaUpdateCount, 1);
    });

    test('an archived note never overwrites one the device already has', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[_record(id: 'm', userNotes: 'old')],
        ),
        localMedia: <MediaItem>[_local(id: 'm', userNotes: 'newer note')],
      );

      expect(plan.mediaUpdateCount, 0);
    });

    test('counts a place and coordinates the device is missing', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[
            _record(id: 'm', address: 'Kochi', latitude: 9.9, longitude: 76.2),
          ],
        ),
        localMedia: <MediaItem>[_local(id: 'm')],
      );

      expect(plan.mediaUpdateCount, 1);
    });

    test('a matched record with nothing new counts as no update', () {
      final plan = _plan(
        payload: BackupPayload(
          manifest: _manifest,
          mediaRecords: <BackupMediaRecord>[_record(id: 'm')],
        ),
        localMedia: <MediaItem>[_local(id: 'm')],
      );

      expect(plan.matchedCount, 1);
      expect(plan.mediaUpdateCount, 0);
      expect(plan.isEmpty, isTrue);
    });
  });

  group('the plan never deletes', () {
    test('a local tag missing from the archive is left alone', () {
      // There is no delete list on RestorePlan at all. This test states the
      // guarantee so it cannot be added later without someone noticing.
      final plan = _plan(
        payload: BackupPayload(manifest: _manifest),
        localTags: <Tag>[_tag('keep_me', 'Keep')],
        localAlbums: <Album>[_album('keep_album', 'Keep')],
        localMedia: <MediaItem>[_local(id: 'keep_media')],
      );

      expect(plan.tagsToCreate, isEmpty);
      expect(plan.albumsToCreate, isEmpty);
      expect(plan.mediaUpdateCount, 0);
      expect(plan.isEmpty, isTrue);
    });
  });
}
