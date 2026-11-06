import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/gps_fuzz_result.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_scrub_options.dart';
import 'package:in_sreerajp_imgvidgal/services/platform/share_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/exif_scrubber_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/gps_geofence_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/privacy_export_service.dart';

import '../media/fake_media_store_channel.dart';
import 'package:image/image.dart' as img;

class _FakeShare implements ShareService {
  bool succeeds = true;
  final List<String> sharedNames = <String>[];
  final List<String> titles = <String>[];

  @override
  Future<bool> shareBytes({
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    String title = 'Share Media',
  }) async {
    sharedNames.add(filename);
    titles.add(title);
    return succeeds;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _item() => MediaItem(
  id: 'm1',
  path: '/storage/emulated/0/DCIM/m1.jpg',
  uri: 'content://media/external/images/media/m1',
  displayName: 'm1.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 8,
  dateAdded: DateTime.fromMillisecondsSinceEpoch(1000),
  dateModified: DateTime.fromMillisecondsSinceEpoch(1000),
);

const _fuzz = GpsFuzzResult(
  originalLatitude: 10,
  originalLongitude: 76,
  fuzzedLatitude: 10.02,
  fuzzedLongitude: 76.01,
  offsetDistanceKm: 2.5,
  bearingDegrees: 30,
  cardinalDirection: 'NE',
);

void main() {
  late Directory tempDir;
  late FakeMediaStoreChannel channel;
  late _FakeShare share;
  late Uint8List? original;

  PrivacyExportService build({bool readThrows = false}) {
    return PrivacyExportService(
      readOriginal: (_) async {
        if (readThrows) throw const FileSystemException('gone');
        return original;
      },
      channel: channel,
      share: share,
      scrubber: const ExifScrubberService(),
      geofence: GpsGeofenceService(),
      tempDirectory: () async => tempDir,
      now: () => DateTime.fromMillisecondsSinceEpoch(42),
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('privacy_export_test');
    channel = FakeMediaStoreChannel();
    share = _FakeShare();
    // A real (tiny) JPEG, so both cleaners can do their work on it.
    original = Uint8List.fromList(
      img.encodeJpg(img.Image(width: 4, height: 4)),
    );
  });

  tearDown(() {
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('share', () {
    test('a scrubbed copy is shared under a prefixed name', () async {
      final result = await build().shareScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
        shareTitle: 'Share clean copy',
      );

      expect(result, PrivacyExportResult.done);
      expect(share.sharedNames, <String>['scrubbed_m1.jpg']);
      expect(share.titles, <String>['Share clean copy']);
    });

    test('a location-shifted copy is shared under its own prefix', () async {
      final result = await build().shareFuzzed(
        _item(),
        _fuzz,
        shareTitle: 'Share',
      );

      expect(result, PrivacyExportResult.done);
      expect(share.sharedNames, <String>['geofuzzed_m1.jpg']);
    });

    test('a share sheet that fails to open is reported', () async {
      share.succeeds = false;

      final result = await build().shareScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
        shareTitle: 'Share',
      );

      expect(result, PrivacyExportResult.shareFailed);
    });
  });

  group('a copy that could not be cleaned', () {
    // Long enough to be taken for a picture, but not one: neither cleaner can
    // work on it. The original must never go out under a "clean" name.
    setUp(() => original = Uint8List.fromList(List<int>.filled(64, 7)));

    test('is never shared as scrubbed', () async {
      final result = await build().shareScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
        shareTitle: 'Share',
      );

      expect(result, PrivacyExportResult.failed);
      expect(share.sharedNames, isEmpty);
    });

    test('is never shared with its true location', () async {
      final result = await build().shareFuzzed(
        _item(),
        _fuzz,
        shareTitle: 'Share',
      );

      expect(result, PrivacyExportResult.failed);
      expect(share.sharedNames, isEmpty);
    });

    test('is never saved as clean', () async {
      final result = await build().saveScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
      );

      expect(result, PrivacyExportResult.failed);
    });
  });

  group('save', () {
    test('a scrubbed copy is published and the temp file removed', () async {
      final result = await build().saveScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
      );

      expect(result, PrivacyExportResult.done);
      expect(channel.publishedNames, <String>['clean_42_m1.jpg']);
      expect(tempDir.listSync(), isEmpty);
    });

    test('a location-shifted copy is published and cleaned up', () async {
      final result = await build().saveFuzzed(_item(), _fuzz);

      expect(result, PrivacyExportResult.done);
      expect(channel.publishedNames, <String>['fuzzed_42_m1.jpg']);
      expect(tempDir.listSync(), isEmpty);
    });

    test('a refused publish is a failure and leaves no temp file', () async {
      channel.publishThrows = true;

      final result = await build().saveScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
      );

      expect(result, PrivacyExportResult.failed);
      expect(tempDir.listSync(), isEmpty);
    });
  });

  group('reading the original', () {
    test('an unreadable original is reported and nothing happens', () async {
      original = null;

      final result = await build().saveScrubbed(
        _item(),
        PrivacyScrubOptions.fullScrub,
      );

      expect(result, PrivacyExportResult.unreadable);
      expect(channel.publishedNames, isEmpty);
      expect(share.sharedNames, isEmpty);
    });

    test('a read that throws becomes a failure, not a crash', () async {
      final result = await build(
        readThrows: true,
      ).shareFuzzed(_item(), _fuzz, shareTitle: 'Share');

      expect(result, PrivacyExportResult.failed);
    });
  });
}
