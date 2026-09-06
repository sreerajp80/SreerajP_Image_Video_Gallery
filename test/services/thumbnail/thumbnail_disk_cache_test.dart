import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_disk_cache.dart';

MediaItem buildItem({
  String id = 'm1',
  int modifiedMs = 1000,
  int size = 2048,
}) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: size,
    dateAdded: DateTime.fromMillisecondsSinceEpoch(modifiedMs),
    dateModified: DateTime.fromMillisecondsSinceEpoch(modifiedMs),
  );
}

Uint8List bytesOf(int length) =>
    Uint8List.fromList(List<int>.filled(length, 7));

void main() {
  late Directory tempDir;
  late ThumbnailDiskCache cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('thumb_cache_test');
    cache = ThumbnailDiskCache(
      rootDirectory: Directory('${tempDir.path}/thumbnails'),
      maxBytes: 1000,
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ThumbnailDiskCache keys', () {
    test('the same item and size always give the same key', () {
      final item = buildItem();
      expect(
        ThumbnailDiskCache.buildKey(item, 256),
        ThumbnailDiskCache.buildKey(buildItem(), 256),
      );
    });

    test('a different thumbnail size gives a different key', () {
      final item = buildItem();
      expect(
        ThumbnailDiskCache.buildKey(item, 256),
        isNot(ThumbnailDiskCache.buildKey(item, 512)),
      );
    });

    test('an edited file gives a different key', () {
      expect(
        ThumbnailDiskCache.buildKey(buildItem(modifiedMs: 1000), 256),
        isNot(ThumbnailDiskCache.buildKey(buildItem(modifiedMs: 2000), 256)),
      );
    });

    test('a changed file size gives a different key', () {
      expect(
        ThumbnailDiskCache.buildKey(buildItem(size: 2048), 256),
        isNot(ThumbnailDiskCache.buildKey(buildItem(size: 4096), 256)),
      );
    });
  });

  group('ThumbnailDiskCache storage', () {
    test('writes then reads the same bytes back', () async {
      final key = ThumbnailDiskCache.buildKey(buildItem(), 256);

      final written = await cache.write(key, 256, bytesOf(50));
      expect(written, isTrue);

      final read = await cache.read(key, 256);
      expect(read, isNotNull);
      expect(read!.lengthInBytes, 50);
    });

    test('reading a key that was never written is a miss', () async {
      expect(await cache.read('does_not_exist', 256), isNull);
    });

    test('refuses to write empty bytes', () async {
      expect(await cache.write('key', 256, Uint8List(0)), isFalse);
    });

    test('separates thumbnails by size folder', () async {
      await cache.write('same_key', 256, bytesOf(10));
      await cache.write('same_key', 512, bytesOf(20));

      expect((await cache.read('same_key', 256))!.lengthInBytes, 10);
      expect((await cache.read('same_key', 512))!.lengthInBytes, 20);
    });

    test('leaves no staging files behind', () async {
      await cache.write('key', 256, bytesOf(30));

      final leftovers = await cache.rootDirectory
          .list(recursive: true)
          .where((entity) => entity.path.endsWith('.tmp'))
          .toList();
      expect(leftovers, isEmpty);
    });

    test('evicts the oldest files when over the byte budget', () async {
      // The budget is 1000 bytes, so three 400-byte files cannot all survive.
      // Modification times are set explicitly, because filesystem timestamp
      // granularity is too coarse to order three writes made microseconds
      // apart.
      await cache.write('old', 256, bytesOf(400));
      await cache.write('middle', 256, bytesOf(400));

      final now = DateTime.now();
      await cache
          .fileFor('old', 256)
          .setLastModified(now.subtract(const Duration(hours: 2)));
      await cache
          .fileFor('middle', 256)
          .setLastModified(now.subtract(const Duration(hours: 1)));

      // This third write pushes the cache over budget and triggers eviction.
      await cache.write('new', 256, bytesOf(400));

      expect(await cache.currentBytes(), lessThanOrEqualTo(1000));
      expect(await cache.read('old', 256), isNull);
      expect(await cache.read('middle', 256), isNotNull);
      expect(await cache.read('new', 256), isNotNull);
    });

    test('clear removes every cached thumbnail', () async {
      await cache.write('a', 256, bytesOf(10));
      await cache.write('b', 256, bytesOf(10));

      await cache.clear();

      expect(await cache.currentBytes(), 0);
      expect(await cache.read('a', 256), isNull);
    });

    test('currentBytes is zero before anything is written', () async {
      expect(await cache.currentBytes(), 0);
    });
  });
}
