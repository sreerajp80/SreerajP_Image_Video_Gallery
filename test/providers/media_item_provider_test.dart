import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
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

  late DatabaseHelper dbHelper;
  late MediaDao mediaDao;
  late ProviderContainer container;

  MediaItem photo(String id) => MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 100,
    dateAdded: DateTime(2026, 11, 3),
    dateModified: DateTime(2026, 11, 3),
  );

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    mediaDao = MediaDao(dbHelper: dbHelper);
    final repository = MediaRepository(
      mediaDao: mediaDao,
      scanner: MediaScannerService(
        channel: FakeMediaStoreChannel(),
        mediaDao: mediaDao,
      ),
    );
    container = ProviderContainer(
      overrides: <Override>[
        mediaRepositoryProvider.overrideWithValue(repository),
      ],
    );
    await mediaDao.batchUpsertMediaItems(<MediaItem>[
      photo('seen'),
      photo('hidden'),
    ]);
    await mediaDao.markOutOfReachExcept(<String>{'seen'});
  });

  tearDown(() async {
    container.dispose();
    await dbHelper.close();
  });

  test('gives a visible item', () async {
    final item = await container.read(mediaItemProvider('seen').future);
    expect(item?.id, 'seen');
  });

  test('gives null for an item the app may not see', () async {
    expect(await container.read(mediaItemProvider('hidden').future), isNull);
  });
}
