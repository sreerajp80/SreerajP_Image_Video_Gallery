import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/media_hashes.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/duplicate_group_service.dart';

MediaItem item(String id, {int size = 1000, int side = 100}) {
  final when = DateTime(2026, 1, 1);
  return MediaItem(
    id: id,
    path: '/storage/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: size,
    dateAdded: when,
    dateModified: when,
    width: side,
    height: side,
  );
}

/// A hash that differs from [base] in exactly [bits] low bit positions.
int flip(int base, int bits) {
  var out = base;
  for (var i = 0; i < bits; i++) {
    out ^= 1 << i;
  }
  return out;
}

void main() {
  const service = DuplicateGroupService();

  group('exact groups', () {
    test('files sharing a digest become one group', () {
      final items = <MediaItem>[item('a'), item('b'), item('c')];
      final hashes = <String, MediaHashes>{
        'a': const MediaHashes(mediaId: 'a', sha256: 'aaa'),
        'b': const MediaHashes(mediaId: 'b', sha256: 'aaa'),
        'c': const MediaHashes(mediaId: 'c', sha256: 'zzz'),
      };

      final groups = service.buildGroups(items: items, hashes: hashes);

      expect(groups.length, 1);
      expect(groups.first.kind, DuplicateGroupKind.exact);
      expect(groups.first.items.map((i) => i.id).toSet(), <String>{'a', 'b'});
    });

    test('a digest held by only one file is not a group', () {
      final groups = service.buildGroups(
        items: <MediaItem>[item('a')],
        hashes: <String, MediaHashes>{
          'a': const MediaHashes(mediaId: 'a', sha256: 'aaa'),
        },
      );

      expect(groups, isEmpty);
    });

    test('items with no hash at all are left out', () {
      final groups = service.buildGroups(
        items: <MediaItem>[item('a'), item('b')],
        hashes: const <String, MediaHashes>{},
      );

      expect(groups, isEmpty);
    });
  });

  group('similar groups', () {
    const base = 0x0F1E2D3C4B5A6978;

    test('close hashes are grouped, distant ones are not', () {
      final items = <MediaItem>[item('a'), item('b'), item('far')];
      final hashes = <String, MediaHashes>{
        'a': const MediaHashes(mediaId: 'a', pHash: base, dHash: base),
        'b': MediaHashes(
          mediaId: 'b',
          pHash: flip(base, 3),
          dHash: flip(base, 3),
        ),
        'far': const MediaHashes(
          mediaId: 'far',
          pHash: 0x7777777777777777,
          dHash: 0x1111111111111111,
        ),
      };

      final groups = service.buildGroups(items: items, hashes: hashes);

      expect(groups.length, 1);
      expect(groups.first.kind, DuplicateGroupKind.similar);
      expect(groups.first.items.map((i) => i.id).toSet(), <String>{'a', 'b'});
    });

    test('a burst of five becomes one group, not ten pairs', () {
      // Each shot is a little further from the first, but every neighbouring
      // pair is close. The union-find has to merge them into a single group.
      final items = <MediaItem>[for (var i = 0; i < 5; i++) item('burst$i')];
      final hashes = <String, MediaHashes>{
        for (var i = 0; i < 5; i++)
          'burst$i': MediaHashes(
            mediaId: 'burst$i',
            pHash: flip(base, i),
            dHash: flip(base, i),
          ),
      };

      final groups = service.buildGroups(items: items, hashes: hashes);

      expect(groups.length, 1);
      expect(groups.first.memberCount, 5);
    });

    test('a photo already in an exact group is not put in a similar one', () {
      // Otherwise the same photo would appear in two groups and could be
      // trashed twice.
      final items = <MediaItem>[item('a'), item('b'), item('c')];
      final hashes = <String, MediaHashes>{
        'a': const MediaHashes(
          mediaId: 'a',
          sha256: 'same',
          pHash: base,
          dHash: base,
        ),
        'b': const MediaHashes(
          mediaId: 'b',
          sha256: 'same',
          pHash: base,
          dHash: base,
        ),
        'c': MediaHashes(
          mediaId: 'c',
          sha256: 'other',
          pHash: flip(base, 2),
          dHash: flip(base, 2),
        ),
      };

      final groups = service.buildGroups(items: items, hashes: hashes);

      final seen = <String>[];
      for (final group in groups) {
        seen.addAll(group.items.map((i) => i.id));
      }
      expect(seen.length, seen.toSet().length);
    });

    test('a pHash match with a distant dHash is refused', () {
      // Both hashes must agree. This is what removes the false pairs the DCT
      // hash makes on pictures that merely share a layout.
      final items = <MediaItem>[item('a'), item('b')];
      final hashes = <String, MediaHashes>{
        'a': const MediaHashes(mediaId: 'a', pHash: base, dHash: 0),
        'b': MediaHashes(mediaId: 'b', pHash: flip(base, 2), dHash: -1),
      };

      expect(service.buildGroups(items: items, hashes: hashes), isEmpty);
    });

    test('a picture with only one perceptual hash is not compared', () {
      final a = const MediaHashes(mediaId: 'a', pHash: base);
      final b = const MediaHashes(mediaId: 'b', pHash: base, dHash: base);

      expect(service.areSimilar(a, b), isFalse);
    });

    test('videos, which have no perceptual hash, only match exactly', () {
      final items = <MediaItem>[item('v1'), item('v2')];
      final hashes = <String, MediaHashes>{
        'v1': const MediaHashes(mediaId: 'v1', sha256: 'clip'),
        'v2': const MediaHashes(mediaId: 'v2', sha256: 'clip'),
      };

      final groups = service.buildGroups(items: items, hashes: hashes);

      expect(groups.single.kind, DuplicateGroupKind.exact);
    });
  });

  group('group shape', () {
    test('the best copy leads and is the suggested keeper', () {
      final items = <MediaItem>[
        item('small', side: 50),
        item('large', side: 400),
      ];
      final hashes = <String, MediaHashes>{
        'small': const MediaHashes(mediaId: 'small', sha256: 'x'),
        'large': const MediaHashes(mediaId: 'large', sha256: 'x'),
      };

      final group = service.buildGroups(items: items, hashes: hashes).single;

      expect(group.items.first.id, 'large');
      expect(group.suggestedKeeperId, 'large');
      expect(group.others.map((i) => i.id).toList(), <String>['small']);
    });

    test('reclaimable bytes exclude the keeper', () {
      final items = <MediaItem>[
        item('keep', side: 400, size: 900),
        item('drop1', side: 50, size: 100),
        item('drop2', side: 50, size: 200),
      ];
      final hashes = <String, MediaHashes>{
        for (final id in <String>['keep', 'drop1', 'drop2'])
          id: MediaHashes(mediaId: id, sha256: 'x'),
      };

      final group = service.buildGroups(items: items, hashes: hashes).single;

      expect(group.reclaimableBytes, 300);
    });

    test('groups are ordered with the biggest saving first', () {
      final items = <MediaItem>[
        item('a1', size: 10),
        item('a2', size: 10),
        item('b1', size: 5000),
        item('b2', size: 5000),
      ];
      final hashes = <String, MediaHashes>{
        'a1': const MediaHashes(mediaId: 'a1', sha256: 'a'),
        'a2': const MediaHashes(mediaId: 'a2', sha256: 'a'),
        'b1': const MediaHashes(mediaId: 'b1', sha256: 'b'),
        'b2': const MediaHashes(mediaId: 'b2', sha256: 'b'),
      };

      final groups = service.buildGroups(items: items, hashes: hashes);

      expect(groups.length, 2);
      expect(groups.first.reclaimableBytes, 5000);
    });

    test('a group id is stable across runs', () {
      final items = <MediaItem>[item('a'), item('b')];
      final hashes = <String, MediaHashes>{
        'a': const MediaHashes(mediaId: 'a', pHash: 0x1234, dHash: 0x1234),
        'b': const MediaHashes(mediaId: 'b', pHash: 0x1234, dHash: 0x1234),
      };

      final first = service.buildGroups(items: items, hashes: hashes).single;
      final second = service
          .buildGroups(items: items.reversed.toList(), hashes: hashes)
          .single;

      // A route points at a group by id, so the id must not depend on the
      // order the rows happened to come out of the database.
      expect(first.id, second.id);
    });
  });
}
