import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../services/media/fake_media_store_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Trash providers and controller', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late MediaRepository mediaRepository;

    final item1 = MediaItem(
      id: 't1',
      path: '/storage/DCIM/Camera/T1.jpg',
      displayName: 'T1.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 1000,
      dateAdded: DateTime(2026, 9, 1),
      dateModified: DateTime(2026, 9, 1),
      dateTaken: DateTime(2026, 9, 1),
      isTrash: true,
    );

    final item2 = MediaItem(
      id: 't2',
      path: '/storage/DCIM/Camera/T2.jpg',
      displayName: 'T2.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 2000,
      dateAdded: DateTime(2026, 9, 2),
      dateModified: DateTime(2026, 9, 2),
      dateTaken: DateTime(2026, 9, 2),
      isTrash: true,
    );

    setUp(() async {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      final scanner = MediaScannerService(
        channel: FakeMediaStoreChannel(),
        mediaDao: mediaDao,
        batchSize: 10,
      );
      mediaRepository = MediaRepository(mediaDao: mediaDao, scanner: scanner);
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: <Override>[
          mediaRepositoryProvider.overrideWithValue(mediaRepository),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test(
      'trashMediaProvider and trashCountProvider read initial state',
      () async {
        await mediaDao.batchUpsertMediaItems([item1, item2]);
        final container = createContainer();

        final items = await container.read(trashMediaProvider.future);
        expect(items.length, 2);

        final count = await container.read(trashCountProvider.future);
        expect(count, 2);
      },
    );

    test(
      'TrashController restoreItem removes item from trash and bumps revision',
      () async {
        await mediaDao.batchUpsertMediaItems([item1, item2]);
        final container = createContainer();

        final controller = container.read(trashControllerProvider.notifier);
        await controller.restoreItem(item1.id);

        final count = await container.read(trashCountProvider.future);
        expect(count, 1);

        final active = await mediaDao.getMediaItems();
        expect(active.length, 1);
        expect(active.first.id, 't1');
      },
    );

    test('TrashController restoreAll restores all items', () async {
      await mediaDao.batchUpsertMediaItems([item1, item2]);
      final container = createContainer();

      final controller = container.read(trashControllerProvider.notifier);
      final restored = await controller.restoreAll();
      expect(restored, 2);

      final count = await container.read(trashCountProvider.future);
      expect(count, 0);

      final active = await mediaDao.getMediaItems();
      expect(active.length, 2);
    });

    test(
      'TrashController emptyTrash deletes all trashed database rows',
      () async {
        await mediaDao.batchUpsertMediaItems([item1, item2]);
        final container = createContainer();

        final controller = container.read(trashControllerProvider.notifier);
        final emptied = await controller.emptyTrash();
        expect(emptied, 2);

        final count = await container.read(trashCountProvider.future);
        expect(count, 0);

        final allInDb = await mediaDao.getMediaItems(
          filter: const FilterOptions(isTrash: true),
        );
        expect(allInDb.isEmpty, isTrue);
      },
    );
  });
}
