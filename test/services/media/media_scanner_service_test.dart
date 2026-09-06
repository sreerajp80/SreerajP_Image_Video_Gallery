import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_media_store_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MediaScannerService', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late FakeMediaStoreChannel channel;
    late MediaScannerService scanner;

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      channel = FakeMediaStoreChannel();
      scanner = MediaScannerService(
        channel: channel,
        mediaDao: mediaDao,
        batchSize: 2,
      );
    });

    tearDown(() async {
      await scanner.dispose();
      await dbHelper.close();
    });

    test('pages through every batch and indexes all items', () async {
      channel.entries = List.generate(
        5,
        (index) => buildEntry(id: 'id$index', dateModifiedMs: 1000 + index),
      );

      final result = await scanner.scan();

      expect(result.indexed, 5);
      expect(result.skipped, 0);
      // 5 items with a batch size of 2 needs 3 pages.
      expect(channel.queryCallCount, 3);
      expect(await mediaDao.getTotalCount(), 5);
    });

    test('maps MediaStore fields onto the domain model', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(
          id: 'v1',
          displayName: 'clip.mp4',
          mimeType: 'video/mp4',
          size: 4096,
          dateModifiedMs: 5000,
          dateTakenMs: 7000,
          durationMs: 12000,
        ),
      ];

      await scanner.scan();

      final stored = await mediaDao.getMediaItemById('v1');
      expect(stored, isNotNull);
      expect(stored!.mediaType, MediaType.video);
      expect(stored.displayName, 'clip.mp4');
      expect(stored.size, 4096);
      expect(stored.durationMs, 12000);
      expect(stored.dateTaken, DateTime.fromMillisecondsSinceEpoch(7000));
      expect(stored.dateModified, DateTime.fromMillisecondsSinceEpoch(5000));
      expect(stored.uri, 'content://media/external/images/media/v1');
    });

    test('drops duration for still images', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'i1', durationMs: 999),
      ];

      await scanner.scan();

      final stored = await mediaDao.getMediaItemById('i1');
      expect(stored!.durationMs, isNull);
    });

    test('an incremental scan asks only for newer rows', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'old', dateModifiedMs: 1000),
        buildEntry(id: 'new', dateModifiedMs: 9000),
      ];
      await scanner.scan();
      channel.receivedSinceValues.clear();

      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'old', dateModifiedMs: 1000),
        buildEntry(id: 'new', dateModifiedMs: 9000),
        buildEntry(id: 'newest', dateModifiedMs: 12000),
      ];
      final result = await scanner.scan(incremental: true);

      expect(channel.receivedSinceValues.first, 9000);
      // Only the two rows at or after 9000 are re-read.
      expect(result.indexed, 2);
      expect(await mediaDao.getTotalCount(), 3);
    });

    test('emits progress updates ending in the completed phase', () async {
      channel.entries = List.generate(3, (index) => buildEntry(id: 'p$index'));

      final seen = <ScanProgress>[];
      final subscription = scanner.progressStream.listen(seen.add);

      await scanner.scan();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(seen.first.phase, ScanPhase.checkingPermission);
      expect(seen.last.phase, ScanPhase.completed);
      expect(seen.last.scanned, 3);
      expect(seen.last.total, 3);
      expect(seen.last.fraction, 1.0);
    });

    test('skips unreadable rows instead of failing the scan', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'good1'),
        const MediaStoreEntry(
          id: '',
          path: '',
          uri: 'content://media/external/images/media/bad',
          displayName: 'bad.jpg',
          mimeType: 'image/jpeg',
          size: 10,
          dateAddedMs: 1,
          dateModifiedMs: 1,
        ),
        buildEntry(id: 'good2'),
      ];

      final result = await scanner.scan();

      expect(result.skipped, 1);
      expect(result.indexed, 2);
      expect(await mediaDao.getTotalCount(), 2);
    });

    test('removes rows whose files are gone after a full scan', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'keep'),
        buildEntry(id: 'delete_me'),
      ];
      await scanner.scan();
      expect(await mediaDao.getTotalCount(), 2);

      channel.entries = <MediaStoreEntry>[buildEntry(id: 'keep')];
      final result = await scanner.scan();

      expect(result.removed, 1);
      expect(await mediaDao.getTotalCount(), 1);
      expect(await mediaDao.getMediaItemById('delete_me'), isNull);
    });

    test('keeps existing rows during an incremental scan', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'a', dateModifiedMs: 1000),
        buildEntry(id: 'b', dateModifiedMs: 2000),
      ];
      await scanner.scan();

      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'b', dateModifiedMs: 2000),
      ];
      final result = await scanner.scan(incremental: true);

      expect(result.removed, 0);
      expect(await mediaDao.getTotalCount(), 2);
    });

    test('keeps existing rows when access is only partial', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'a'),
        buildEntry(id: 'b'),
      ];
      await scanner.scan();

      channel.permissionStatus = MediaPermissionStatus.partial;
      channel.entries = <MediaStoreEntry>[buildEntry(id: 'a')];
      final result = await scanner.scan();

      expect(result.removed, 0);
      expect(await mediaDao.getTotalCount(), 2);
    });

    test('throws and reports failure when permission is missing', () async {
      channel.permissionStatus = MediaPermissionStatus.denied;

      await expectLater(
        scanner.scan(),
        throwsA(isA<PermissionDeniedException>()),
      );
      expect(scanner.progress.phase, ScanPhase.failed);
      expect(scanner.isScanning, isFalse);
    });

    test('refuses to start a second scan while one is running', () async {
      channel.entries = List.generate(4, (index) => buildEntry(id: 's$index'));

      final first = scanner.scan();
      await expectLater(scanner.scan(), throwsA(isA<MediaScanException>()));
      await first;
    });
  });
}
