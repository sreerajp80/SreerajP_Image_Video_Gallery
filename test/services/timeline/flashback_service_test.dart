import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/memories_page.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/flashback_service.dart';

MediaItem itemAt(String id, DateTime taken) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 2048,
    dateAdded: taken,
    dateModified: taken,
    dateTaken: taken,
  );
}

void main() {
  const service = FlashbackService();
  final now = DateTime(2026, 8, 29, 14, 30);

  group('same day', () {
    test('returns an empty page for an empty library', () {
      final page = service.buildPage(const <MediaItem>[], now: now);

      expect(page.isEmpty, isTrue);
    });

    test('matches the same month and day in earlier years only', () {
      final page = service.buildPage([
        itemAt('today', DateTime(2026, 8, 29, 9)),
        itemAt('lastYear', DateTime(2025, 8, 29, 9)),
        itemAt('twoYears', DateTime(2024, 8, 29, 9)),
        itemAt('nearMiss', DateTime(2025, 8, 30, 9)),
      ], now: now);

      expect(page.range, MemoriesRange.sameDay);
      expect(page.memories.map((m) => m.year).toList(), [2025, 2024]);
      expect(page.memories.first.items.single.id, 'lastYear');
      expect(page.memories.last.items.single.id, 'twoYears');
    });

    test('counts years ago and keeps a one-day range', () {
      final page = service.buildPage([
        itemAt('a', DateTime(2025, 8, 29, 9)),
        itemAt('b', DateTime(2021, 8, 29, 9)),
      ], now: now);

      final first = page.memories.first;
      expect(first.yearsAgo, 1);
      expect(page.memories.last.yearsAgo, 5);
      expect(first.date, DateTime(2025, 8, 29));
      expect(first.rangeStart, first.date);
      expect(first.rangeEnd, first.date);
      expect(first.isRange, isFalse);
    });

    test('orders items inside a year newest first', () {
      final page = service.buildPage([
        itemAt('morning', DateTime(2025, 8, 29, 8)),
        itemAt('night', DateTime(2025, 8, 29, 22)),
        itemAt('noon', DateTime(2025, 8, 29, 12)),
      ], now: now);

      expect(page.memories.single.items.map((i) => i.id).toList(), [
        'night',
        'noon',
        'morning',
      ]);
    });

    test('keeps every item and every year, with no cap', () {
      final items = [
        for (var i = 0; i < 40; i++)
          itemAt(
            'i$i',
            DateTime(2025, 8, 29, 20).subtract(Duration(minutes: i)),
          ),
        for (var year = 2010; year <= 2024; year++)
          itemAt('y$year', DateTime(year, 8, 29, 9)),
      ];

      final page = service.buildPage(items, now: now);

      expect(page.memories, hasLength(16));
      expect(page.memories.first.items, hasLength(40));
      expect(page.memories.last.year, 2010);
    });

    test('matches a leap day only against other leap years', () {
      final page = service.buildPage([
        itemAt('leap2024', DateTime(2024, 2, 29, 9)),
        itemAt('leap2020', DateTime(2020, 2, 29, 9)),
        itemAt('mar2025', DateTime(2025, 3, 1, 9)),
        itemAt('feb2025', DateTime(2025, 2, 28, 9)),
      ], now: DateTime(2028, 2, 29, 12));

      expect(page.range, MemoriesRange.sameDay);
      expect(page.memories.map((m) => m.year).toList(), [2024, 2020]);
      // The stored date must stay on Feb 29, not roll into March.
      expect(page.memories.first.date, DateTime(2024, 2, 29));
    });

    test('falls back to dateModified when dateTaken is missing', () {
      final modified = DateTime(2025, 8, 29, 11);
      final item = MediaItem(
        id: 'noExif',
        path: '/storage/emulated/0/DCIM/noExif.jpg',
        displayName: 'noExif.jpg',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: 10,
        dateAdded: modified,
        dateModified: modified,
      );

      final page = service.buildPage([item], now: now);

      expect(page.memories.single.items.single.id, 'noExif');
    });
  });

  group('week fallback', () {
    test('is used only when the exact day has nothing', () {
      final page = service.buildPage([
        itemAt('exact', DateTime(2025, 8, 29, 9)),
        itemAt('near', DateTime(2025, 8, 27, 9)),
      ], now: now);

      expect(page.range, MemoriesRange.sameDay);
      expect(page.memories.single.items.single.id, 'exact');
    });

    test('takes media up to three days either side', () {
      final page = service.buildPage([
        itemAt('minus3', DateTime(2025, 8, 26, 9)),
        itemAt('plus3', DateTime(2025, 9, 1, 9)),
        itemAt('minus4', DateTime(2025, 8, 25, 9)),
        itemAt('plus4', DateTime(2025, 9, 2, 9)),
      ], now: now);

      expect(page.range, MemoriesRange.sameWeek);
      final memory = page.memories.single;
      expect(memory.items.map((i) => i.id).toSet(), {'minus3', 'plus3'});
      expect(memory.rangeStart, DateTime(2025, 8, 26));
      expect(memory.rangeEnd, DateTime(2025, 9));
      expect(memory.isRange, isTrue);
    });

    test('crosses a year end into the right memory year', () {
      // Today is 30 Dec 2026. 2 Jan 2026 is three days after 30 Dec 2025, so
      // it belongs to "1 year ago" even though its own year is 2026.
      final page = service.buildPage([
        itemAt('recent', DateTime(2026, 12, 28, 9)),
        itemAt('oneYear', DateTime(2026, 1, 2, 9)),
        itemAt('twoYears', DateTime(2024, 12, 28, 9)),
      ], now: DateTime(2026, 12, 30, 10));

      expect(page.range, MemoriesRange.sameWeek);
      expect(page.memories.map((m) => m.yearsAgo).toList(), [1, 2]);
      expect(page.memories.first.items.single.id, 'oneYear');
      expect(page.memories.first.year, 2025);
      expect(page.memories.first.rangeStart, DateTime(2025, 12, 27));
      expect(page.memories.first.rangeEnd, DateTime(2026, 1, 2));
      expect(page.memories.last.items.single.id, 'twoYears');
    });

    test('never treats the last few days as a memory', () {
      final page = service.buildPage([
        itemAt('yesterday', DateTime(2026, 8, 28, 9)),
        itemAt('soon', DateTime(2026, 8, 31, 9)),
      ], now: now);

      expect(page.isEmpty, isTrue);
    });

    test('centres on 28 February when today is a leap day', () {
      final page = service.buildPage([
        itemAt('mar2', DateTime(2025, 3, 2, 9)),
        itemAt('mar4', DateTime(2025, 3, 4, 9)),
      ], now: DateTime(2028, 2, 29, 12));

      final memory = page.memories.firstWhere((m) => m.year == 2025);
      expect(memory.date, DateTime(2025, 2, 28));
      expect(memory.items.single.id, 'mar2');
    });

    test('a zero window turns the fallback off', () {
      final page = service.buildPage(
        [itemAt('near', DateTime(2025, 8, 27, 9))],
        now: now,
        windowDays: 0,
      );

      expect(page.isEmpty, isTrue);
    });
  });
}
