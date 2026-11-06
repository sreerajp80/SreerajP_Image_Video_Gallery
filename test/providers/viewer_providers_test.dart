import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/device/screen_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/exif_reader_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/frame_step_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/video/playback_speed_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/video/video_gesture_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/viewer/viewer_transform_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../services/media/fake_media_store_channel.dart';
import 'package:flutter_riverpod/misc.dart';

MediaItem imageItem({ExifData? exif}) {
  final taken = DateTime(2026, 8, 29, 10);
  return MediaItem(
    id: 'image-1',
    path: '/storage/emulated/0/DCIM/image-1.jpg',
    uri: 'content://media/external/images/media/1',
    displayName: 'image-1.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2048,
    dateAdded: taken,
    dateModified: taken,
    dateTaken: taken,
    exifData: exif,
  );
}

MediaItem videoItem() {
  final taken = DateTime(2026, 8, 29, 11);
  return MediaItem(
    id: 'video-1',
    path: '/storage/emulated/0/DCIM/video-1.mp4',
    uri: 'content://media/external/video/media/1',
    displayName: 'video-1.mp4',
    mediaType: MediaType.video,
    mimeType: 'video/mp4',
    size: 900000,
    dateAdded: taken,
    dateModified: taken,
    durationMs: 12000,
  );
}

ProviderContainer buildContainer() {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('service providers', () {
    test('expose the pure viewer and playback services', () {
      final container = buildContainer();

      expect(
        container.read(viewerTransformServiceProvider),
        isA<ViewerTransformService>(),
      );
      expect(
        container.read(playbackSpeedServiceProvider),
        isA<PlaybackSpeedService>(),
      );
      expect(
        container.read(videoGestureServiceProvider),
        isA<VideoGestureService>(),
      );
      expect(container.read(frameStepServiceProvider), isA<FrameStepService>());
      expect(
        container.read(exifReaderServiceProvider),
        isA<ExifReaderService>(),
      );
      expect(
        container.read(screenSettingsServiceProvider),
        isA<ScreenSettingsService>(),
      );
    });
  });

  group('viewerPageIndexProvider', () {
    test('starts on the first page', () {
      final container = buildContainer();

      expect(container.read(viewerPageIndexProvider), 0);
    });

    test('follows the page the user swipes to', () {
      final container = buildContainer();

      container.read(viewerPageIndexProvider.notifier).state = 4;
      expect(container.read(viewerPageIndexProvider), 4);
    });
  });

  group('mediaExifProvider', () {
    test('returns metadata already indexed without reading the file', () async {
      const stored = ExifData(make: 'TestCam', model: 'Model X');
      final container = buildContainer();

      final result = await container.read(
        mediaExifProvider(imageItem(exif: stored)).future,
      );

      expect(result, stored);
    });

    test('returns null for a video, which carries no EXIF', () async {
      final container = buildContainer();

      final result = await container.read(
        mediaExifProvider(videoItem()).future,
      );

      expect(result, isNull);
    });
  });

  group('fullImageBytesProvider', () {
    test(
      'returns null for a video, which is never decoded as an image',
      () async {
        final container = buildContainer();

        final result = await container.read(
          fullImageBytesProvider(videoItem()).future,
        );

        expect(result, isNull);
      },
    );
  });

  group('ViewerActions', () {
    late MediaDao mediaDao;
    late ProviderContainer container;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      final dbHelper = DatabaseHelper(
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
      await mediaDao.batchUpsertMediaItems(<MediaItem>[imageItem()]);
      container = ProviderContainer(
        overrides: <Override>[
          mediaRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('toggleFavorite stars and un-stars the item', () async {
      final actions = container.read(viewerActionsProvider);

      await actions.toggleFavorite('image-1');
      expect((await mediaDao.getMediaItemById('image-1'))!.isFavorite, isTrue);

      await actions.toggleFavorite('image-1');
      expect((await mediaDao.getMediaItemById('image-1'))!.isFavorite, isFalse);
    });

    test('moveToTrash trashes the item and bumps both revisions', () async {
      final actions = container.read(viewerActionsProvider);

      await actions.moveToTrash('image-1');

      expect((await mediaDao.getMediaItemById('image-1'))!.isTrash, isTrue);
      expect(container.read(trashRevisionProvider), 1);
      expect(container.read(albumRevisionProvider), 1);
    });

    test('restoreFromTrash undoes moveToTrash', () async {
      final actions = container.read(viewerActionsProvider);

      await actions.moveToTrash('image-1');
      await actions.restoreFromTrash('image-1');

      expect((await mediaDao.getMediaItemById('image-1'))!.isTrash, isFalse);
      expect(container.read(trashRevisionProvider), 2);
    });
  });
}
