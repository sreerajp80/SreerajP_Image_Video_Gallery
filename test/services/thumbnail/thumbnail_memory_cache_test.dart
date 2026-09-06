import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_memory_cache.dart';

Uint8List bytesOf(int length) => Uint8List(length);

void main() {
  group('ThumbnailMemoryCache', () {
    test('stores and returns entries', () {
      final cache = ThumbnailMemoryCache(maxItems: 3, maxBytes: 1000);
      cache.put('a', bytesOf(10));

      expect(cache.get('a')!.lengthInBytes, 10);
      expect(cache.length, 1);
      expect(cache.currentBytes, 10);
      expect(cache.get('missing'), isNull);
    });

    test('evicts the least recently used entry over the item limit', () {
      final cache = ThumbnailMemoryCache(maxItems: 2, maxBytes: 1000);
      cache.put('a', bytesOf(10));
      cache.put('b', bytesOf(10));
      cache.put('c', bytesOf(10));

      expect(cache.containsKey('a'), isFalse);
      expect(cache.containsKey('b'), isTrue);
      expect(cache.containsKey('c'), isTrue);
      expect(cache.length, 2);
    });

    test('a read marks an entry as most recently used', () {
      final cache = ThumbnailMemoryCache(maxItems: 2, maxBytes: 1000);
      cache.put('a', bytesOf(10));
      cache.put('b', bytesOf(10));

      cache.get('a'); // 'b' is now the oldest.
      cache.put('c', bytesOf(10));

      expect(cache.containsKey('a'), isTrue);
      expect(cache.containsKey('b'), isFalse);
    });

    test('evicts oldest entries to stay inside the byte budget', () {
      final cache = ThumbnailMemoryCache(maxItems: 100, maxBytes: 100);
      cache.put('a', bytesOf(60));
      cache.put('b', bytesOf(50));

      expect(cache.containsKey('a'), isFalse);
      expect(cache.containsKey('b'), isTrue);
      expect(cache.currentBytes, 50);
    });

    test('refuses a single item larger than the whole budget', () {
      final cache = ThumbnailMemoryCache(maxItems: 10, maxBytes: 100);
      cache.put('small', bytesOf(20));
      cache.put('huge', bytesOf(500));

      expect(cache.containsKey('huge'), isFalse);
      expect(cache.containsKey('small'), isTrue);
      expect(cache.currentBytes, 20);
    });

    test('re-inserting a key replaces it without double counting bytes', () {
      final cache = ThumbnailMemoryCache(maxItems: 10, maxBytes: 1000);
      cache.put('a', bytesOf(30));
      cache.put('a', bytesOf(10));

      expect(cache.length, 1);
      expect(cache.currentBytes, 10);
    });

    test('remove and clear free their bytes', () {
      final cache = ThumbnailMemoryCache(maxItems: 10, maxBytes: 1000);
      cache.put('a', bytesOf(30));
      cache.put('b', bytesOf(30));

      cache.remove('a');
      expect(cache.length, 1);
      expect(cache.currentBytes, 30);

      cache.clear();
      expect(cache.length, 0);
      expect(cache.currentBytes, 0);
    });

    test('keysByAge lists the oldest entry first', () {
      final cache = ThumbnailMemoryCache(maxItems: 10, maxBytes: 1000);
      cache.put('a', bytesOf(1));
      cache.put('b', bytesOf(1));
      cache.get('a');

      expect(cache.keysByAge.toList(), <String>['b', 'a']);
    });
  });
}
