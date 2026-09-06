import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_media_record.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/backup_payload.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';

BackupManifest _manifest({int payloadVersion = 1}) => BackupManifest(
  payloadVersion: payloadVersion,
  schemaVersion: 2,
  appVersion: '1.0.0+1',
  createdAtMs: 1756584284000,
  tagCount: 2,
  albumCount: 1,
  mediaRecordCount: 2,
);

BackupPayload _fullPayload() => BackupPayload(
  manifest: _manifest(),
  tags: const <BackupTag>[
    BackupTag(
      id: 'tag_family',
      name: 'Family',
      colorValue: 0xFF2196F3,
      description: 'people',
      dateCreatedMs: 1700000000000,
    ),
    BackupTag(
      id: 'tag_trip',
      name: 'Trip',
      colorValue: 0xFF4CAF50,
      dateCreatedMs: 1700000001000,
    ),
  ],
  albums: const <BackupAlbum>[
    BackupAlbum(
      id: 'album_best',
      name: 'Best of 2026',
      coverMediaId: 'media_1',
      isPinned: true,
      sortOrder: 3,
      dateCreatedMs: 1700000002000,
    ),
  ],
  tagLinks: const <BackupTagLink>[
    BackupTagLink(mediaId: 'media_1', tagId: 'tag_family'),
    BackupTagLink(mediaId: 'media_2', tagId: 'tag_trip'),
  ],
  albumLinks: const <BackupAlbumLink>[
    BackupAlbumLink(albumId: 'album_best', mediaId: 'media_1', position: 0),
    BackupAlbumLink(albumId: 'album_best', mediaId: 'media_2', position: 1),
  ],
  mediaRecords: const <BackupMediaRecord>[
    BackupMediaRecord(
      id: 'media_1',
      path: '/storage/emulated/0/DCIM/Camera/IMG_1.jpg',
      displayName: 'IMG_1.jpg',
      sizeBytes: 2048000,
      dateTakenMs: 1690000000000,
      sha256: 'abc123',
      isFavorite: true,
      userNotes: 'the good one',
      address: 'Kochi',
      latitude: 9.9312,
      longitude: 76.2673,
    ),
    BackupMediaRecord(
      id: 'media_2',
      path: '/storage/emulated/0/DCIM/Camera/IMG_2.jpg',
      displayName: 'IMG_2.jpg',
      sizeBytes: 1024000,
    ),
  ],
);

void main() {
  const serializer = BackupSerializer();

  group('BackupSerializer round trip', () {
    test('a full payload comes back exactly as it went in', () {
      final original = _fullPayload();
      final decoded = serializer.decode(serializer.encode(original));

      expect(decoded.manifest, original.manifest);
      expect(decoded.tags, original.tags);
      expect(decoded.albums, original.albums);
      expect(decoded.tagLinks, original.tagLinks);
      expect(decoded.albumLinks, original.albumLinks);
      expect(decoded.mediaRecords, original.mediaRecords);
    });

    test('keeps every field of a media record, nulls included', () {
      final decoded = serializer.decode(serializer.encode(_fullPayload()));
      final rich = decoded.mediaRecords.first;
      final bare = decoded.mediaRecords.last;

      expect(rich.isFavorite, isTrue);
      expect(rich.userNotes, 'the good one');
      expect(rich.address, 'Kochi');
      expect(rich.latitude, closeTo(9.9312, 1e-9));
      expect(rich.longitude, closeTo(76.2673, 1e-9));
      expect(rich.sha256, 'abc123');

      expect(bare.isFavorite, isFalse);
      expect(bare.userNotes, isNull);
      expect(bare.address, isNull);
      expect(bare.latitude, isNull);
      expect(bare.sha256, isNull);
      expect(bare.dateTakenMs, isNull);
    });

    test('keeps album positions, which are the album order', () {
      final decoded = serializer.decode(serializer.encode(_fullPayload()));
      expect(decoded.albumLinks.map((l) => l.position), <int>[0, 1]);
    });

    test('an empty payload round trips', () {
      final empty = BackupPayload(manifest: _manifest());
      final decoded = serializer.decode(serializer.encode(empty));

      expect(decoded.isEmpty, isTrue);
      expect(decoded.manifest, empty.manifest);
    });

    test('non-Latin text survives', () {
      final payload = BackupPayload(
        manifest: _manifest(),
        tags: const <BackupTag>[
          BackupTag(
            id: 't1',
            name: 'കുടുംബം',
            colorValue: 0xFF000000,
            dateCreatedMs: 1,
          ),
        ],
      );
      final decoded = serializer.decode(serializer.encode(payload));
      expect(decoded.tags.single.name, 'കുടുംബം');
    });
  });

  group('BackupSerializer tolerates a newer archive', () {
    test('ignores a field it has never seen', () {
      // An archive written by a later build must not make this one throw.
      final body =
          jsonDecode(serializer.encode(_fullPayload())) as Map<String, dynamic>;
      body['somethingFromTheFuture'] = <String, dynamic>{'a': 1};
      (body['tags'] as List).first['futureTagField'] = 'ignored';

      final decoded = serializer.decode(jsonEncode(body));
      expect(decoded.tags.first.name, 'Family');
      expect(decoded.mediaRecords, hasLength(2));
    });

    test('skips a list entry that is not an object', () {
      // One malformed row loses that row, not the whole archive. Someone
      // restoring after a device failure is not helped by all-or-nothing.
      final body =
          jsonDecode(serializer.encode(_fullPayload())) as Map<String, dynamic>;
      (body['tags'] as List).add('not an object');
      (body['tags'] as List).add(42);

      final decoded = serializer.decode(jsonEncode(body));
      expect(decoded.tags, hasLength(2));
    });

    test('treats a missing list as an empty one', () {
      final decoded = serializer.decode(
        jsonEncode(<String, dynamic>{'manifest': _manifest().toJson()}),
      );

      expect(decoded.tags, isEmpty);
      expect(decoded.albums, isEmpty);
      expect(decoded.tagLinks, isEmpty);
      expect(decoded.albumLinks, isEmpty);
      expect(decoded.mediaRecords, isEmpty);
    });

    test('fills in a missing optional field rather than throwing', () {
      final decoded = serializer.decode(
        jsonEncode(<String, dynamic>{
          'manifest': _manifest().toJson(),
          'mediaRecords': <dynamic>[
            <String, dynamic>{'id': 'only_an_id'},
          ],
        }),
      );

      final record = decoded.mediaRecords.single;
      expect(record.id, 'only_an_id');
      expect(record.path, '');
      expect(record.sizeBytes, 0);
      expect(record.isFavorite, isFalse);
    });
  });

  group('BackupSerializer refuses what it cannot read', () {
    test('refuses text that is not JSON', () {
      expect(
        () => serializer.decode('not json at all'),
        throwsA(isA<BackupSerializerException>()),
      );
    });

    test('refuses JSON that is not an object', () {
      expect(
        () => serializer.decode('[1, 2, 3]'),
        throwsA(isA<BackupSerializerException>()),
      );
      expect(
        () => serializer.decode('"a string"'),
        throwsA(isA<BackupSerializerException>()),
      );
    });

    test('refuses a body with no manifest', () {
      expect(
        () => serializer.decode('{"tags": []}'),
        throwsA(
          isA<BackupSerializerException>().having(
            (e) => e.message,
            'message',
            contains('manifest'),
          ),
        ),
      );
    });

    test('refuses a payload version newer than this build', () {
      // Guessing at a layout that changed is how a restore quietly writes the
      // wrong thing, so it refuses instead.
      final payload = BackupPayload(
        manifest: _manifest(
          payloadVersion: BackupSerializer.payloadVersion + 1,
        ),
      );

      expect(
        () => serializer.decode(serializer.encode(payload)),
        throwsA(
          isA<BackupSerializerException>().having(
            (e) => e.message,
            'message',
            contains('newer'),
          ),
        ),
      );
    });

    test('accepts an older payload version', () {
      final payload = BackupPayload(manifest: _manifest(payloadVersion: 1));
      expect(
        serializer.decode(serializer.encode(payload)).manifest.payloadVersion,
        1,
      );
    });
  });

  group('BackupMediaRecord.hasUserData', () {
    test('is false for a record that is pure identity', () {
      const record = BackupMediaRecord(
        id: 'a',
        path: '/a.jpg',
        displayName: 'a.jpg',
        sizeBytes: 10,
      );
      expect(record.hasUserData, isFalse);
    });

    test('is true once anything the user set is present', () {
      const base = BackupMediaRecord(
        id: 'a',
        path: '/a.jpg',
        displayName: 'a.jpg',
        sizeBytes: 10,
      );

      expect(
        const BackupMediaRecord(
          id: 'a',
          path: '/a.jpg',
          displayName: 'a.jpg',
          sizeBytes: 10,
          isFavorite: true,
        ).hasUserData,
        isTrue,
      );
      expect(
        const BackupMediaRecord(
          id: 'a',
          path: '/a.jpg',
          displayName: 'a.jpg',
          sizeBytes: 10,
          userNotes: 'hi',
        ).hasUserData,
        isTrue,
      );
      expect(
        const BackupMediaRecord(
          id: 'a',
          path: '/a.jpg',
          displayName: 'a.jpg',
          sizeBytes: 10,
          latitude: 1.0,
        ).hasUserData,
        isTrue,
      );
      expect(base.hasUserData, isFalse);
    });

    test('an empty note does not count as user data', () {
      const record = BackupMediaRecord(
        id: 'a',
        path: '/a.jpg',
        displayName: 'a.jpg',
        sizeBytes: 10,
        userNotes: '',
      );
      expect(record.hasUserData, isFalse);
    });
  });
}
