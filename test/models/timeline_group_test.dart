import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';

MediaItem itemAt(String id, DateTime taken) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 512,
    dateAdded: taken,
    dateModified: taken,
    dateTaken: taken,
  );
}

void main() {
  final date = DateTime(2026, 8, 29);
  final itemA = itemAt('a', DateTime(2026, 8, 29, 9));
  final itemB = itemAt('b', DateTime(2026, 8, 29, 10));

  group('TimelineGroup', () {
    test('copyWith replaces only the named fields', () {
      final group = TimelineGroup(
        date: date,
        headerKind: TimelineHeaderKind.today,
        items: [itemA],
      );

      final updated = group.copyWith(headerKind: TimelineHeaderKind.yesterday);

      expect(updated.date, date);
      expect(updated.items, [itemA]);
      expect(updated.headerKind, TimelineHeaderKind.yesterday);
    });

    test('equal groups compare equal and share a hash code', () {
      final one = TimelineGroup(
        date: date,
        headerKind: TimelineHeaderKind.today,
        items: [itemA, itemB],
      );
      final two = TimelineGroup(
        date: DateTime(2026, 8, 29),
        headerKind: TimelineHeaderKind.today,
        items: [itemA, itemB],
      );

      expect(one, two);
      expect(one.hashCode, two.hashCode);
    });

    test('a different item list makes groups unequal', () {
      final one = TimelineGroup(
        date: date,
        headerKind: TimelineHeaderKind.today,
        items: [itemA],
      );

      expect(one, isNot(one.copyWith(items: [itemB])));
    });
  });

  group('TimelineRow', () {
    test('the header constructor makes an empty header row', () {
      final row = TimelineRow.header(
        groupIndex: 2,
        date: date,
        headerKind: TimelineHeaderKind.today,
      );

      expect(row.isHeader, isTrue);
      expect(row.type, TimelineRowType.header);
      expect(row.items, isEmpty);
      expect(row.groupIndex, 2);
    });

    test('the tiles constructor carries its items', () {
      final row = TimelineRow.tiles(
        groupIndex: 0,
        date: date,
        headerKind: TimelineHeaderKind.today,
        items: [itemA, itemB],
      );

      expect(row.isHeader, isFalse);
      expect(row.type, TimelineRowType.tiles);
      expect(row.items, [itemA, itemB]);
    });

    test('copyWith and equality behave', () {
      final row = TimelineRow.tiles(
        groupIndex: 0,
        date: date,
        headerKind: TimelineHeaderKind.today,
        items: [itemA],
      );

      expect(row.copyWith(items: [itemA]), row);
      expect(row.copyWith(items: [itemA]).hashCode, row.hashCode);
      expect(row.copyWith(groupIndex: 1), isNot(row));
    });
  });

  group('TimelineData', () {
    test('the empty constructor holds nothing at the given density', () {
      const data = TimelineData.empty(columnCount: 4);

      expect(data.isEmpty, isTrue);
      expect(data.groups, isEmpty);
      expect(data.rows, isEmpty);
      expect(data.itemCount, 0);
      expect(data.columnCount, 4);
    });

    test('copyWith and equality behave', () {
      final data = TimelineData(
        groups: [
          TimelineGroup(
            date: date,
            headerKind: TimelineHeaderKind.today,
            items: [itemA],
          ),
        ],
        rows: [
          TimelineRow.header(
            groupIndex: 0,
            date: date,
            headerKind: TimelineHeaderKind.today,
          ),
        ],
        columnCount: 3,
        itemCount: 1,
      );

      expect(data.copyWith(), data);
      expect(data.copyWith().hashCode, data.hashCode);
      expect(data.copyWith(columnCount: 5), isNot(data));
      expect(data.isEmpty, isFalse);
    });
  });

  group('FlashbackMemory', () {
    test('copyWith and equality behave', () {
      final memory = FlashbackMemory(
        year: 2025,
        yearsAgo: 1,
        date: DateTime(2025, 8, 29),
        items: [itemA],
      );

      expect(memory.copyWith(), memory);
      expect(memory.copyWith().hashCode, memory.hashCode);
      expect(memory.copyWith(yearsAgo: 2), isNot(memory));
      expect(memory.copyWith(year: 2024).year, 2024);
    });
  });
}
