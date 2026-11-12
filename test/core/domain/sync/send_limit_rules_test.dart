import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/send_limit_rules.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/sync_selection_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/send_plan.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_source.dart';

const int _mb = 1024 * 1024;
const int _gb = 1024 * _mb;

MediaItem _item(String id, int size, {String? sha}) => MediaItem(
  id: id,
  path: '/storage/emulated/0/DCIM/Camera/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: size,
  dateAdded: DateTime(2026),
  dateModified: DateTime(2026),
  sha256Hash: sha,
);

SyncMark _mark(String id, int size, {String sha = 'abc'}) => SyncMark(
  mediaId: id,
  peerId: 'peer',
  sha256: sha,
  sizeBytes: size,
  sentAt: DateTime(2026),
);

void main() {
  group('the reserve on the receiving phone', () {
    test('is never below the fixed minimum', () {
      expect(
        SendLimitRules.reserveFor(1 * _gb),
        AppConstants.syncFreeSpaceMinReserveBytes,
      );
    });

    test('grows with the free space', () {
      expect(SendLimitRules.reserveFor(100 * _gb), 5 * _gb);
    });

    test('one file needs room for its staging copy too', () {
      // 1 GB free, 200 MB reserve: 824 MB left, so a 412 MB file just fits
      // (two copies) and a byte more does not.
      expect(
        SendLimitRules.fitsOneFile(freeBytes: 1 * _gb, fileBytes: 412 * _mb),
        isTrue,
      );
      expect(
        SendLimitRules.fitsOneFile(
          freeBytes: 1 * _gb,
          fileBytes: 412 * _mb + 1,
        ),
        isFalse,
      );
    });
  });

  group('what one send carries', () {
    test('everything, when it all fits', () {
      final plan = SendLimitRules.plan(
        candidates: [_item('a', 10 * _mb), _item('b', 10 * _mb)],
        freeBytes: 50 * _gb,
      );
      expect(plan.toSend.map((i) => i.id), ['a', 'b']);
      expect(plan.limitedBy, SendLimit.none);
      expect(plan.hasLeftOver, isFalse);
      expect(plan.sendBytes, 20 * _mb);
    });

    test('stops at the size cap and keeps the order', () {
      final plan = SendLimitRules.plan(
        candidates: [
          _item('a', 600 * _mb),
          _item('b', 600 * _mb),
          _item('c', 10 * _mb),
        ],
        freeBytes: null,
        capBytes: 1 * _gb,
      );
      // 'c' would fit after 'a', but skipping 'b' would break the order.
      expect(plan.toSend.map((i) => i.id), ['a']);
      expect(plan.limitedBy, SendLimit.cap);
      expect(plan.leftCount, 2);
      expect(plan.leftBytes, 610 * _mb);
    });

    test('the first file may be larger than the cap', () {
      final plan = SendLimitRules.plan(
        candidates: [_item('video', 3 * _gb), _item('b', 1 * _mb)],
        freeBytes: 100 * _gb,
        capBytes: 1 * _gb,
      );
      expect(plan.toSend.map((i) => i.id), ['video']);
      expect(plan.limitedBy, SendLimit.cap);
    });

    test('stops at the free space, counting the staging copy', () {
      final plan = SendLimitRules.plan(
        candidates: [_item('a', 300 * _mb), _item('b', 300 * _mb)],
        // 1 GB free - 200 MB reserve = 824 MB of room.
        freeBytes: 1 * _gb,
      );
      // a: 0 + 600 <= 824. b: 300 + 600 = 900 > 824.
      expect(plan.toSend.map((i) => i.id), ['a']);
      expect(plan.limitedBy, SendLimit.space);
    });

    test('a phone with no room gets nothing, and says why', () {
      final plan = SendLimitRules.plan(
        candidates: [_item('a', 10 * _mb)],
        freeBytes: 100 * _mb,
      );
      expect(plan.isEmpty, isTrue);
      expect(plan.limitedBy, SendLimit.space);
      expect(plan.leftCount, 1);
    });

    test('stops at the file count', () {
      final plan = SendLimitRules.plan(
        candidates: [for (var i = 0; i < 5; i++) _item('i$i', 1)],
        freeBytes: null,
        maxFiles: 3,
      );
      expect(plan.toSend, hasLength(3));
      expect(plan.limitedBy, SendLimit.count);
      expect(plan.leftCount, 2);
    });
  });

  group('turning ticked folders and albums into a send', () {
    final a = _item('a', 10, sha: 'sha-a');
    final b = _item('b', 20, sha: 'sha-b');
    final c = _item('c', 30);
    final sources = [
      SyncSource(
        key: 'folder:/x',
        kind: SyncSourceKind.folder,
        name: 'x',
        items: [a, b],
      ),
      SyncSource(
        key: 'album:1',
        kind: SyncSourceKind.album,
        name: 'Trip',
        items: [b, c],
      ),
    ];

    test('a file in two ticked sources is sent once', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'folder:/x', 'album:1'},
        marks: const {},
        freeBytes: null,
      );
      expect(plan.toSend.map((i) => i.id), ['a', 'b', 'c']);
    });

    test('only ticked sources count', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'album:1'},
        marks: const {},
        freeBytes: null,
      );
      expect(plan.toSend.map((i) => i.id), ['b', 'c']);
    });

    test('files already sent to this phone are left out and counted', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'folder:/x', 'album:1'},
        marks: {'a': _mark('a', 10, sha: 'sha-a')},
        freeBytes: null,
      );
      expect(plan.toSend.map((i) => i.id), ['b', 'c']);
      expect(plan.alreadySentCount, 1);
    });

    test('a file edited since it was sent is offered again', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'folder:/x'},
        // The size and the digest no longer match the file.
        marks: {
          'a': _mark('a', 10, sha: 'old-sha'),
          'b': _mark('b', 99, sha: 'sha-b'),
        },
        freeBytes: null,
      );
      expect(plan.toSend.map((i) => i.id), ['a', 'b']);
      expect(plan.alreadySentCount, 0);
    });

    test('a mark counts while the file has no digest yet', () {
      expect(SyncSelectionRules.countSent([c], {'c': _mark('c', 30)}), 1);
    });
  });

  group('a manual send (files sent before go again)', () {
    final a = _item('a', 10, sha: 'sha-a');
    final b = _item('b', 20, sha: 'sha-b');
    final sources = [
      SyncSource(
        key: 'selection',
        kind: SyncSourceKind.selection,
        name: '',
        items: [a, b],
      ),
      SyncSource(
        key: 'folder:/x',
        kind: SyncSourceKind.folder,
        name: 'x',
        items: [b],
      ),
    ];
    final marks = {'a': _mark('a', 10, sha: 'sha-a')};

    test('a file sent before is sent again and counted for the warning', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'selection'},
        marks: marks,
        freeBytes: null,
        allowResend: true,
      );
      expect(plan.toSend.map((i) => i.id), ['a', 'b']);
      expect(plan.resendCount, 1);
      expect(plan.alreadySentCount, 0);
    });

    test('the same pick in Device Sync skips the file sent before', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'selection'},
        marks: marks,
        freeBytes: null,
      );
      expect(plan.toSend.map((i) => i.id), ['b']);
      expect(plan.alreadySentCount, 1);
      expect(plan.resendCount, 0);
    });

    test('a file in two ticked sources is sent once', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'selection', 'folder:/x'},
        marks: marks,
        freeBytes: null,
        allowResend: true,
      );
      expect(plan.toSend.map((i) => i.id), ['a', 'b']);
    });

    test('files sent in this session are not offered again', () {
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'selection'},
        marks: marks,
        freeBytes: null,
        allowResend: true,
        sentThisSession: {'a', 'b'},
      );
      expect(plan.isEmpty, isTrue);
      expect(plan.resendCount, 0);
    });

    test('a file that failed is offered again', () {
      // "a" was tried but did not arrive, so it is not in sentThisSession.
      final plan = SyncSelectionRules.plan(
        sources: sources,
        selectedKeys: {'selection'},
        marks: marks,
        freeBytes: null,
        allowResend: true,
        sentThisSession: {'b'},
      );
      expect(plan.toSend.map((i) => i.id), ['a']);
    });
  });

  group('the send button text', () {
    final a = _item('a', 10);
    final b = _item('b', 20);

    test('the first send is never "the rest"', () {
      expect(
        SyncSelectionRules.isRest(batchCount: 0, toSend: [a], triedIds: {}),
        isFalse,
      );
    });

    test('a follow-up with only new files is "the rest"', () {
      expect(
        SyncSelectionRules.isRest(batchCount: 1, toSend: [b], triedIds: {'a'}),
        isTrue,
      );
    });

    test('a retry of a failed file is not "the rest"', () {
      expect(
        SyncSelectionRules.isRest(
          batchCount: 1,
          toSend: [a, b],
          triedIds: {'a'},
        ),
        isFalse,
      );
    });

    test('an empty send is not "the rest"', () {
      expect(
        SyncSelectionRules.isRest(batchCount: 1, toSend: [], triedIds: {}),
        isFalse,
      );
    });
  });
}
