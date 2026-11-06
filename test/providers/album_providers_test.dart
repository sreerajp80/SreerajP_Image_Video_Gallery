import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
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

  final photo = MediaItem(
    id: 'a1',
    path: '/storage/DCIM/Camera/A1.jpg',
    displayName: 'A1.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 1000,
    dateAdded: DateTime(2026, 9),
    dateModified: DateTime(2026, 9),
  );

  late MediaDao mediaDao;
  late DatabaseHelper dbHelper;
  late ProviderContainer container;

  setUp(() {
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
    container = ProviderContainer(
      overrides: <Override>[
        mediaDaoProvider.overrideWithValue(mediaDao),
        mediaRepositoryProvider.overrideWithValue(
          MediaRepository(mediaDao: mediaDao, scanner: scanner),
        ),
        albumDaoProvider.overrideWithValue(AlbumDao(dbHelper: dbHelper)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await dbHelper.close();
  });

  AlbumEditController controller() =>
      container.read(albumEditControllerProvider.notifier);

  test('creating an album bumps the revision and lists it', () async {
    final before = container.read(albumRevisionProvider);

    final album = await controller().create('Trip');

    expect(album, isNotNull);
    expect(container.read(albumRevisionProvider), before + 1);
    final albums = await container.read(virtualAlbumsProvider.future);
    expect(albums.map((a) => a.name), contains('Trip'));
  });

  test('an invalid name gives an error state and no album', () async {
    final before = container.read(albumRevisionProvider);

    expect(await controller().create('   '), isNull);

    expect(container.read(albumEditControllerProvider).hasError, isTrue);
    expect(container.read(albumRevisionProvider), before);
  });

  test('adding and removing media is seen by the album providers', () async {
    await mediaDao.batchUpsertMediaItems(<MediaItem>[photo]);
    final album = (await controller().create('Trip'))!;

    await controller().addMedia(album.id, photo.id);
    expect(
      await container.read(albumMediaIdsProvider(album.id).future),
      <String>[photo.id],
    );
    expect(
      await container.read(albumsForMediaProvider(photo.id).future),
      <String>[album.id],
    );

    await controller().removeMedia(album.id, photo.id);
    expect(
      await container.read(albumMediaIdsProvider(album.id).future),
      isEmpty,
    );
  });

  test('a deleted album is gone', () async {
    final album = (await controller().create('Old'))!;

    await controller().delete(album.id);

    expect(await container.read(albumSummaryProvider(album.id).future), isNull);
  });
}
