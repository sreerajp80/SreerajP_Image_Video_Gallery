import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../services/media/fake_media_store_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MediaRepository', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late FakeMediaStoreChannel channel;
    late MediaScannerService scanner;
    late MediaRepository repository;

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
        batchSize: 10,
      );
      repository = MediaRepository(
        mediaDao: mediaDao,
        scanner: scanner,
        channel: channel,
      );
    });

    tearDown(() async {
      await scanner.dispose();
      await dbHelper.close();
    });

    test('scanDevice indexes device media and reports the count', () async {
      channel.entries = List<MediaStoreEntry>.generate(
        3,
        (index) => buildEntry(id: 'r$index'),
      );

      final result = await repository.scanDevice();

      expect(result.indexed, 3);
      expect(await repository.getTotalCount(), 3);
    });

    test('getMediaItems applies the media type filter', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'img1'),
        buildEntry(id: 'vid1', displayName: 'clip.mp4', mimeType: 'video/mp4'),
      ];
      await repository.scanDevice();

      final videos = await repository.getMediaItems(
        filter: const FilterOptions(mediaTypes: {MediaType.video}),
      );

      expect(videos.length, 1);
      expect(videos.first.id, 'vid1');
    });

    test('getMediaItems filters by folder path prefix', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'a', path: '/storage/emulated/0/DCIM/Camera/a.jpg'),
        buildEntry(id: 'b', path: '/storage/emulated/0/Pictures/b.jpg'),
      ];
      await repository.scanDevice();

      final camera = await repository.getMediaItems(
        filter: const FilterOptions(
          folderPaths: {'/storage/emulated/0/DCIM/Camera'},
        ),
      );

      expect(camera.length, 1);
      expect(camera.first.id, 'a');
    });

    test('getMediaItems honours limit and offset', () async {
      channel.entries = List<MediaStoreEntry>.generate(
        5,
        (index) => buildEntry(id: 'p$index', dateModifiedMs: 1000 + index),
      );
      await repository.scanDevice();

      final firstPage = await repository.getMediaItems(limit: 2);
      final secondPage = await repository.getMediaItems(limit: 2, offset: 2);

      expect(firstPage.length, 2);
      expect(secondPage.length, 2);
      expect(firstPage.first.id, isNot(secondPage.first.id));
    });

    test('toggleFavorite flips the flag and persists it', () async {
      channel.entries = <MediaStoreEntry>[buildEntry(id: 'fav')];
      await repository.scanDevice();

      expect(await repository.toggleFavorite('fav'), isTrue);
      expect((await repository.getMediaItemById('fav'))!.isFavorite, isTrue);

      expect(await repository.toggleFavorite('fav'), isFalse);
      expect((await repository.getMediaItemById('fav'))!.isFavorite, isFalse);
    });

    test('setTrash hides an item from the default listing', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'keep'),
        buildEntry(id: 'trashed'),
      ];
      await repository.scanDevice();

      await repository.setTrash('trashed', true);

      final visible = await repository.getMediaItems();
      expect(visible.map((item) => item.id), <String>['keep']);

      final inTrash = await repository.getMediaItems(
        filter: const FilterOptions(isTrash: true),
      );
      expect(inTrash.map((item) => item.id), <String>['trashed']);
    });

    test('getMediaItemByPath finds an indexed item', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'p1', path: '/storage/emulated/0/DCIM/p1.jpg'),
      ];
      await repository.scanDevice();

      final found = await repository.getMediaItemByPath(
        '/storage/emulated/0/DCIM/p1.jpg',
      );

      expect(found, isNotNull);
      expect(found!.id, 'p1');
    });

    test('getMediaItemByUri finds an indexed item', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'u1', path: '/storage/emulated/0/DCIM/u1.jpg'),
      ];
      await repository.scanDevice();

      final found = await repository.getMediaItemByUri(
        'content://media/external/images/media/u1',
      );

      expect(found, isNotNull);
      expect(found!.id, 'u1');
    });

    test('exposes scan progress from the scanner', () async {
      channel.entries = <MediaStoreEntry>[buildEntry(id: 'x')];

      final phases = <ScanPhase>[];
      final subscription = repository.scanProgress.listen(
        (event) => phases.add(event.phase),
      );

      await repository.scanDevice();
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(phases.last, ScanPhase.completed);
    });

    test(
      'deletePermanently deletes files via channel and removes rows from db',
      () async {
        channel.entries = <MediaStoreEntry>[
          buildEntry(id: 'del1', path: '/storage/emulated/0/DCIM/del1.jpg'),
          buildEntry(id: 'del2', path: '/storage/emulated/0/DCIM/del2.jpg'),
        ];
        await repository.scanDevice();
        expect(await repository.getTotalCount(), 2);

        final items = await repository.getMediaItems();
        expect(items.length, 2);

        // Both rows share a date, so pick by id rather than by list position.
        final target = items.singleWhere((item) => item.id == 'del1');
        final result = await repository.deletePermanently([target]);
        expect(result.deleted, 1);
        expect(result.failed, 0);
        expect(channel.deletedUris, contains(target.uri));
        expect(await repository.getTotalCount(), 1);

        final remaining = await repository.getMediaItems();
        expect(remaining.single.id, 'del2');
      },
    );

    test(
      'deletePermanently aborts and preserves db if channel refuses deletion',
      () async {
        channel.entries = <MediaStoreEntry>[
          buildEntry(id: 'safe1', path: '/storage/emulated/0/DCIM/safe1.jpg'),
        ];
        await repository.scanDevice();
        channel.deleteSucceeds = false;

        final items = await repository.getMediaItems();
        final result = await repository.deletePermanently([items.first]);
        expect(result.anyDeleted, isFalse);
        expect(result.failed, 1);
        expect(await repository.getTotalCount(), 1);
      },
    );

    test('secure delete overwrites through the channel', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 's1', path: '/storage/emulated/0/DCIM/s1.jpg'),
      ];
      await repository.scanDevice();
      final items = await repository.getMediaItems();

      final result = await repository.deletePermanently(items, secure: true);

      expect(result.secure, isTrue);
      expect(result.deleted, 1);
      expect(result.overwritten, 1);
      expect(result.notOverwritten, 0);
      expect(channel.securelyDeletedUris, contains(items.first.uri));
      expect(channel.deletedUris, isEmpty);
      expect(channel.lastSecurePasses, AppConstants.secureDeletePasses);
      expect(await repository.getTotalCount(), 0);
    });

    test('secure delete keeps rows whose file is still there', () async {
      channel.entries = <MediaStoreEntry>[
        buildEntry(id: 'k1', path: '/storage/emulated/0/DCIM/k1.jpg'),
        buildEntry(id: 'k2', path: '/storage/emulated/0/DCIM/k2.jpg'),
        buildEntry(id: 'k3', path: '/storage/emulated/0/DCIM/k3.jpg'),
      ];
      await repository.scanDevice();
      final items = await repository.getMediaItems();
      channel.secureOutcomes = <MediaDeleteOutcome>[
        MediaDeleteOutcome.overwritten,
        MediaDeleteOutcome.deleted,
        MediaDeleteOutcome.failed,
      ];

      final result = await repository.deletePermanently(items, secure: true);

      expect(result.deleted, 2);
      expect(result.overwritten, 1);
      expect(result.notOverwritten, 1);
      expect(result.failed, 1);
      final remaining = await repository.getMediaItems();
      expect(remaining.single.id, items[2].id);
    });
  });
}
