import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
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

  test('returns nothing for an empty library', () {
    expect(service.build(const <MediaItem>[], now: now), isEmpty);
  });

  test('returns nothing when no earlier year matches today', () {
    final memories = service.build([
      itemAt('today', DateTime(2026, 8, 29, 9)),
      itemAt('otherDay', DateTime(2024, 8, 28, 9)),
      itemAt('otherMonth', DateTime(2023, 7, 29, 9)),
    ], now: now);

    expect(memories, isEmpty);
  });

  test('matches the same month and day in earlier years only', () {
    final memories = service.build([
      itemAt('today', DateTime(2026, 8, 29, 9)),
      itemAt('lastYear', DateTime(2025, 8, 29, 9)),
      itemAt('twoYears', DateTime(2024, 8, 29, 9)),
      itemAt('nearMiss', DateTime(2025, 8, 30, 9)),
    ], now: now);

    expect(memories, hasLength(2));
    expect(memories.map((m) => m.year).toList(), [2025, 2024]);
    expect(memories.first.items.single.id, 'lastYear');
    expect(memories.last.items.single.id, 'twoYears');
  });

  test('counts how many years ago each memory is', () {
    final memories = service.build([
      itemAt('a', DateTime(2025, 8, 29, 9)),
      itemAt('b', DateTime(2021, 8, 29, 9)),
    ], now: now);

    expect(memories.first.yearsAgo, 1);
    expect(memories.last.yearsAgo, 5);
    expect(memories.first.date, DateTime(2025, 8, 29));
  });

  test('orders items inside a year newest first', () {
    final memories = service.build([
      itemAt('morning', DateTime(2025, 8, 29, 8)),
      itemAt('night', DateTime(2025, 8, 29, 22)),
      itemAt('noon', DateTime(2025, 8, 29, 12)),
    ], now: now);

    expect(memories.single.items.map((i) => i.id).toList(), [
      'night',
      'noon',
      'morning',
    ]);
  });

  test('caps the items kept per year', () {
    final items = List.generate(
      20,
      (i) => itemAt(
        'i$i',
        DateTime(2025, 8, 29, 20).subtract(Duration(minutes: i)),
      ),
    );

    final memories = service.build(items, now: now, maxItemsPerYear: 4);

    expect(memories.single.items, hasLength(4));
  });

  test('caps the number of years shown, keeping the most recent', () {
    final items = [
      for (var year = 2016; year <= 2025; year++)
        itemAt('y$year', DateTime(year, 8, 29, 9)),
    ];

    final memories = service.build(items, now: now, maxYears: 3);

    expect(memories.map((m) => m.year).toList(), [2025, 2024, 2023]);
  });

  test('returns nothing when the caps are zero or negative', () {
    final items = [itemAt('a', DateTime(2025, 8, 29, 9))];

    expect(service.build(items, now: now, maxYears: 0), isEmpty);
    expect(service.build(items, now: now, maxItemsPerYear: 0), isEmpty);
  });

  test('matches a leap day only against other leap years', () {
    final leapDay = DateTime(2028, 2, 29, 12);

    final memories = service.build([
      itemAt('leap2024', DateTime(2024, 2, 29, 9)),
      itemAt('leap2020', DateTime(2020, 2, 29, 9)),
      itemAt('mar2025', DateTime(2025, 3, 1, 9)),
      itemAt('feb2025', DateTime(2025, 2, 28, 9)),
    ], now: leapDay);

    expect(memories.map((m) => m.year).toList(), [2024, 2020]);
    // The stored date must stay on Feb 29, not roll into March.
    expect(memories.first.date, DateTime(2024, 2, 29));
    expect(memories.first.date.month, 2);
    expect(memories.first.date.day, 29);
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

    final memories = service.build([item], now: now);

    expect(memories.single.year, 2025);
    expect(memories.single.items.single.id, 'noExif');
  });
}
