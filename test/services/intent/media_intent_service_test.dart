import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/intent/media_intent_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../media/fake_media_store_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('MediaIntentData', () {
    test('parses image intent map correctly', () {
      final map = <String, dynamic>{
        'uri': 'content://media/external/images/media/42',
        'mimeType': 'image/png',
        'displayName': 'screenshot.png',
        'size': 12345,
        'isVideo': false,
      };

      final data = MediaIntentData.fromMap(map);
      expect(data.uri, 'content://media/external/images/media/42');
      expect(data.mimeType, 'image/png');
      expect(data.displayName, 'screenshot.png');
      expect(data.size, 12345);
      expect(data.isVideo, isFalse);
    });

    test('detects video from mime type when isVideo is absent', () {
      final map = <String, dynamic>{
        'uri': 'content://media/external/video/media/99',
        'mimeType': 'video/mp4',
        'displayName': 'clip.mp4',
      };

      final data = MediaIntentData.fromMap(map);
      expect(data.isVideo, isTrue);
    });

    test('handles empty map with safe defaults', () {
      final data = MediaIntentData.fromMap(const <String, dynamic>{});
      expect(data.uri, isEmpty);
      expect(data.mimeType, 'image/*');
      expect(data.displayName, isEmpty);
      expect(data.size, 0);
      expect(data.isVideo, isFalse);
    });
  });

  group('MediaIntentService', () {
    const channelName = 'in.sreerajp.imgvidgal/intents';
    late MethodChannel channel;
    late MediaIntentService service;
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late MediaRepository repository;

    setUp(() {
      channel = const MethodChannel(channelName);
      service = MediaIntentService(channel: channel);

      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      repository = MediaRepository(
        mediaDao: mediaDao,
        scanner: MediaScannerService(
          channel: FakeMediaStoreChannel(),
          mediaDao: mediaDao,
        ),
      );
    });

    tearDown(() async {
      service.dispose();
      await dbHelper.close();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getInitialMediaIntent returns parsed data from platform', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getInitialMediaIntent') {
              return <String, dynamic>{
                'uri': 'content://media/external/images/media/10',
                'mimeType': 'image/jpeg',
                'displayName': 'photo.jpg',
                'size': 54321,
                'isVideo': false,
              };
            }
            return null;
          });

      final initial = await service.getInitialMediaIntent();
      expect(initial, isNotNull);
      expect(initial!.uri, 'content://media/external/images/media/10');
      expect(initial.displayName, 'photo.jpg');
    });

    test('getInitialMediaIntent returns null when no intent', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            return null;
          });

      final initial = await service.getInitialMediaIntent();
      expect(initial, isNull);
    });

    test('openDefaultAppsSettings invokes platform method', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'openDefaultAppsSettings') {
              return true;
            }
            return null;
          });

      final success = await service.openDefaultAppsSettings();
      expect(success, isTrue);
    });

    test('incomingIntents stream emits on onMediaIntent call', () async {
      final emitted = <MediaIntentData>[];
      final sub = service.incomingIntents.listen(emitted.add);

      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final encoded = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onMediaIntent', <String, dynamic>{
          'uri': 'content://media/external/images/media/77',
          'mimeType': 'image/webp',
          'displayName': 'sticker.webp',
        }),
      );

      await messenger.handlePlatformMessage(channelName, encoded, (reply) {});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(emitted, hasLength(1));
      expect(emitted.first.uri, 'content://media/external/images/media/77');
      expect(emitted.first.displayName, 'sticker.webp');
    });

    test('resolveMediaItem returns existing item if found by URI', () async {
      final existingItem = MediaItem(
        id: 'item_uri_1',
        path: '/storage/emulated/0/DCIM/u1.jpg',
        uri: 'content://media/external/images/media/888',
        displayName: 'u1.jpg',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: 5000,
        dateAdded: DateTime.now(),
        dateModified: DateTime.now(),
      );
      await mediaDao.insertMediaItem(existingItem);

      const data = MediaIntentData(
        uri: 'content://media/external/images/media/888',
        mimeType: 'image/jpeg',
        displayName: 'u1.jpg',
        size: 5000,
        isVideo: false,
      );

      final resolved = await service.resolveMediaItem(data, repository);
      expect(resolved.id, 'item_uri_1');
    });

    test(
      'resolveMediaItem returns existing item if found by file path',
      () async {
        final existingItem = MediaItem(
          id: 'item_path_1',
          path: '/storage/emulated/0/DCIM/p2.jpg',
          uri: 'content://media/external/images/media/777',
          displayName: 'p2.jpg',
          mediaType: MediaType.image,
          mimeType: 'image/jpeg',
          size: 6000,
          dateAdded: DateTime.now(),
          dateModified: DateTime.now(),
        );
        await mediaDao.insertMediaItem(existingItem);

        const data = MediaIntentData(
          uri: 'file:///storage/emulated/0/DCIM/p2.jpg',
          mimeType: 'image/jpeg',
          displayName: 'p2.jpg',
          size: 6000,
          isVideo: false,
        );

        final resolved = await service.resolveMediaItem(data, repository);
        expect(resolved.id, 'item_path_1');
      },
    );

    test('resolveMediaItem builds safe transient item if not in DB', () async {
      const data = MediaIntentData(
        uri: 'content://com.whatsapp.provider.media/item/1234',
        mimeType: 'image/jpeg',
        displayName: 'shared_photo.jpg',
        size: 2048,
        isVideo: false,
      );

      final resolved = await service.resolveMediaItem(data, repository);
      expect(resolved.id.startsWith('ext_'), isTrue);
      expect(resolved.uri, 'content://com.whatsapp.provider.media/item/1234');
      expect(resolved.displayName, 'shared_photo.jpg');
      expect(resolved.isImage, isTrue);
      expect(resolved.isVideo, isFalse);
    });
  });
}
