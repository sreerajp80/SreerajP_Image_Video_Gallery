import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/device/device_memory_service.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_decoder_isolate.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_disk_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_memory_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_request_queue.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_service.dart';

import '../media/fake_media_store_channel.dart';

Uint8List bytesOf(int length, [int fill = 1]) =>
    Uint8List.fromList(List<int>.filled(length, fill));

/// Waits (in real time) until [condition] holds. Disk-cache misses finish
/// in real file I/O, so a request reaches the queue a little later.
Future<void> waitUntil(bool Function() condition) async {
  for (var i = 0; i < 2000 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
  expect(condition(), isTrue, reason: 'condition never became true');
}

MediaItem buildItem({
  String id = 'm1',
  MediaType mediaType = MediaType.image,
  int size = 2048,
  String? uri,
}) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    uri: uri ?? 'content://media/external/images/media/$id',
    displayName: '$id.jpg',
    mediaType: mediaType,
    mimeType: mediaType == MediaType.video ? 'video/mp4' : 'image/jpeg',
    size: size,
    dateAdded: DateTime.fromMillisecondsSinceEpoch(1000),
    dateModified: DateTime.fromMillisecondsSinceEpoch(1000),
  );
}

void main() {
  late Directory tempDir;
  late FakeMediaStoreChannel channel;
  late ThumbnailMemoryCache memoryCache;
  late ThumbnailDiskCache diskCache;

  /// Counts how often the pure Dart fallback decoder was asked to run.
  var decoderCalls = 0;
  Uint8List? decoderOutput;

  /// Services built in the current test, so tearDown can wait for their
  /// background disk writes before deleting the folder.
  final built = <ThumbnailService>[];

  ThumbnailService buildService({ThumbnailRequestQueue? queue}) {
    final service = ThumbnailService(
      queue: queue,
      channel: channel,
      memoryCache: memoryCache,
      diskCache: diskCache,
      config: ThumbnailCacheConfig.lowTier,
      decoder: (ThumbnailDecodeRequest request) async {
        decoderCalls++;
        return decoderOutput;
      },
    );
    built.add(service);
    return service;
  }

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thumb_service_test');
    channel = FakeMediaStoreChannel();
    memoryCache = ThumbnailMemoryCache(maxItems: 10, maxBytes: 100000);
    diskCache = ThumbnailDiskCache(
      rootDirectory: Directory('${tempDir.path}/thumbnails'),
      maxBytes: 100000,
    );
    decoderCalls = 0;
    decoderOutput = null;
  });

  tearDown(() async {
    final gate = channel.thumbnailGate;
    if (gate != null && !gate.isCompleted) gate.complete();
    for (final service in built) {
      await service.flushDiskWrites();
    }
    built.clear();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThumbnailService lookup order', () {
    test(
      'uses the native thumbnail and caches it in RAM and on disk',
      () async {
        channel.nativeThumbnail = bytesOf(64);
        final service = buildService();
        final item = buildItem();

        final result = await service.getThumbnail(item);

        expect(result, isNotNull);
        expect(result!.lengthInBytes, 64);
        expect(channel.thumbnailCallCount, 1);
        expect(memoryCache.length, 1);

        await service.flushDiskWrites();
        final key = ThumbnailDiskCache.buildKey(item, service.defaultSize);
        expect(await diskCache.read(key, service.defaultSize), isNotNull);
      },
    );

    test(
      'a second request is served from RAM without touching the device',
      () async {
        channel.nativeThumbnail = bytesOf(64);
        final service = buildService();
        final item = buildItem();

        await service.getThumbnail(item);
        await service.getThumbnail(item);

        expect(channel.thumbnailCallCount, 1);
      },
    );

    test('reads from disk when RAM was cleared', () async {
      channel.nativeThumbnail = bytesOf(64);
      final service = buildService();
      final item = buildItem();

      await service.getThumbnail(item);
      // The disk write runs in the background; let it land first.
      await service.flushDiskWrites();
      service.clearMemoryCache();
      final result = await service.getThumbnail(item);

      expect(result, isNotNull);
      // Still only the one native call from the first request.
      expect(channel.thumbnailCallCount, 1);
    });

    test(
      'falls back to the Dart decoder when the native thumbnail is null',
      () async {
        channel.nativeThumbnail = null;
        channel.sourceBytes = bytesOf(500);
        decoderOutput = bytesOf(48, 2);
        final service = buildService();

        final result = await service.getThumbnail(buildItem());

        expect(decoderCalls, 1);
        expect(result, isNotNull);
        expect(result!.lengthInBytes, 48);
      },
    );

    test('falls back when the native thumbnail call throws', () async {
      channel.throwOnThumbnail = true;
      channel.sourceBytes = bytesOf(500);
      decoderOutput = bytesOf(48, 2);
      final service = buildService();

      final result = await service.getThumbnail(buildItem());

      expect(result, isNotNull);
      expect(decoderCalls, 1);
    });

    test('returns null when nothing can produce a thumbnail', () async {
      channel.nativeThumbnail = null;
      channel.sourceBytes = null;
      final service = buildService();

      final result = await service.getThumbnail(buildItem());

      expect(result, isNull);
      expect(decoderCalls, 0);
    });

    test('returns null instead of throwing when the decoder fails', () async {
      channel.nativeThumbnail = null;
      channel.sourceBytes = bytesOf(500);
      decoderOutput = null;
      final service = buildService();

      expect(await service.getThumbnail(buildItem()), isNull);
      expect(decoderCalls, 1);
    });
  });

  group('ThumbnailService fallback guards', () {
    test('does not run the Dart decoder for videos', () async {
      channel.nativeThumbnail = null;
      channel.sourceBytes = bytesOf(500);
      final service = buildService();

      final result = await service.getThumbnail(
        buildItem(id: 'v1', mediaType: MediaType.video),
      );

      expect(result, isNull);
      expect(decoderCalls, 0);
      expect(channel.readBytesCallCount, 0);
    });

    test('skips originals larger than the fallback limit', () async {
      channel.nativeThumbnail = null;
      channel.sourceBytes = bytesOf(500);
      final service = buildService();

      final result = await service.getThumbnail(
        buildItem(size: ThumbnailService.maxFallbackSourceBytes + 1),
      );

      expect(result, isNull);
      expect(decoderCalls, 0);
    });

    test('skips the fallback when the item has no URI', () async {
      channel.nativeThumbnail = null;
      final service = buildService();

      final result = await service.getThumbnail(buildItem(uri: ''));

      expect(result, isNull);
      expect(channel.thumbnailCallCount, 0);
      expect(decoderCalls, 0);
    });
  });

  group('ThumbnailService request coalescing', () {
    test('shares one generation between concurrent requests', () async {
      channel.nativeThumbnail = bytesOf(64);
      final service = buildService();
      final item = buildItem();

      final results = await Future.wait(<Future<Uint8List?>>[
        service.getThumbnail(item),
        service.getThumbnail(item),
        service.getThumbnail(item),
      ]);

      expect(results.every((bytes) => bytes != null), isTrue);
      expect(channel.thumbnailCallCount, 1);
      expect(service.inFlightCount, 0);
    });

    test('different sizes are generated separately', () async {
      channel.nativeThumbnail = bytesOf(64);
      final service = buildService();
      final item = buildItem();

      await service.getThumbnail(item, size: 128);
      await service.getThumbnail(item, size: 256);

      expect(channel.thumbnailCallCount, 2);
    });

    /// Starts requests one by one, each only after the previous one reached
    /// the queue, so their order in the queue is known.
    Future<List<ThumbnailRequest>> requestInOrder(
      ThumbnailService service,
      ThumbnailRequestQueue queue,
      List<String> ids,
    ) async {
      final requests = <ThumbnailRequest>[];
      for (final id in ids) {
        final before = queue.runningCount + queue.waitingCount;
        requests.add(service.requestThumbnail(buildItem(id: id)));
        await waitUntil(
          () => queue.runningCount + queue.waitingCount == before + 1,
        );
      }
      return requests;
    }

    test('serves the newest waiting request first', () async {
      channel.nativeThumbnail = bytesOf(64);
      channel.thumbnailGate = Completer<void>();
      final queue = ThumbnailRequestQueue(maxConcurrent: 3);
      final service = buildService(queue: queue);

      final requests = await requestInOrder(service, queue, [
        for (var i = 0; i < 6; i++) 'm$i',
      ]);
      // Only the first three reached the device; the rest wait.
      expect(channel.thumbnailCallCount, 3);
      expect(queue.waitingCount, 3);

      channel.thumbnailGate!.complete();
      await Future.wait(requests.map((r) => r.future));

      expect(channel.thumbnailUris.skip(3), [
        for (final id in ['m5', 'm4', 'm3']) buildItem(id: id).uri,
      ]);
    });

    test('a cancelled waiting request never reaches the device', () async {
      channel.nativeThumbnail = bytesOf(64);
      channel.thumbnailGate = Completer<void>();
      final queue = ThumbnailRequestQueue(maxConcurrent: 3);
      final service = buildService(queue: queue);

      final requests = await requestInOrder(service, queue, [
        'busy0',
        'busy1',
        'busy2',
        'gone',
      ]);
      final gone = requests.last;
      expect(queue.waitingCount, 1);

      gone.cancel();
      expect(queue.waitingCount, 0);
      channel.thumbnailGate!.complete();
      await Future.wait(requests.take(3).map((r) => r.future));

      expect(await gone.future, isNull);
      expect(channel.thumbnailUris, isNot(contains(buildItem(id: 'gone').uri)));
      expect(service.inFlightCount, 0);
    });

    test('shared work stays alive while one caller still wants it', () async {
      channel.nativeThumbnail = bytesOf(64);
      channel.thumbnailGate = Completer<void>();
      final queue = ThumbnailRequestQueue(maxConcurrent: 3);
      final service = buildService(queue: queue);

      final busy = await requestInOrder(service, queue, [
        'busy0',
        'busy1',
        'busy2',
      ]);
      final item = buildItem(id: 'shared');
      final a = service.requestThumbnail(item);
      final b = service.requestThumbnail(item);
      await waitUntil(() => queue.waitingCount == 1);

      a.cancel();
      expect(queue.waitingCount, 1);
      channel.thumbnailGate!.complete();
      await Future.wait(busy.map((r) => r.future));

      expect(await b.future, isNotNull);
    });

    test('a request after a cancel starts fresh work', () async {
      channel.nativeThumbnail = bytesOf(64);
      channel.thumbnailGate = Completer<void>();
      final queue = ThumbnailRequestQueue(maxConcurrent: 3);
      final service = buildService(queue: queue);

      final requests = await requestInOrder(service, queue, [
        'busy0',
        'busy1',
        'busy2',
        'again',
      ]);
      final first = requests.last;
      first.cancel();

      final second = service.requestThumbnail(buildItem(id: 'again'));
      channel.thumbnailGate!.complete();

      expect(await first.future, isNull);
      expect(await second.future, isNotNull);
      await Future.wait(requests.take(3).map((r) => r.future));
    });

    test('memory cache hits do not wait in the queue', () async {
      channel.nativeThumbnail = bytesOf(64);
      final service = buildService();
      final cachedItem = buildItem(id: 'cached');
      await service.getThumbnail(cachedItem);

      channel.thumbnailGate = Completer<void>();
      final busy = [
        for (var i = 0; i < 5; i++)
          service.getThumbnail(buildItem(id: 'busy$i')),
      ];
      await pumpEventQueue();

      // Answered at once although the queue is full.
      expect(await service.getThumbnail(cachedItem), isNotNull);

      channel.thumbnailGate!.complete();
      await Future.wait(busy);
    });

    test('clearAll empties both caches', () async {
      channel.nativeThumbnail = bytesOf(64);
      final service = buildService();
      final item = buildItem();
      await service.getThumbnail(item);

      await service.clearAll();

      expect(memoryCache.length, 0);
      expect(await diskCache.currentBytes(), 0);
    });
  });
}
