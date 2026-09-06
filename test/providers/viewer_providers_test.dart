import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/device/screen_settings_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/exif_reader_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/frame_step_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/playback_speed_service.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_gesture_service.dart';
import 'package:in_sreerajp_imgvidgal/services/viewer/viewer_transform_service.dart';

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
}
