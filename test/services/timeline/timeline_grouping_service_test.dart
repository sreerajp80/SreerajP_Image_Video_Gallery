import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/timeline_grouping_service.dart';

MediaItem itemAt(String id, DateTime taken) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 1024,
    dateAdded: taken,
    dateModified: taken,
    dateTaken: taken,
  );
}

void main() {
  const service = TimelineGroupingService();
  final now = DateTime(2026, 8, 29, 14, 30);

  group('clampColumns', () {
    test('keeps values inside the 1..5 range', () {
      expect(TimelineGroupingService.clampColumns(3), 3);
      expect(TimelineGroupingService.clampColumns(1), 1);
      expect(TimelineGroupingService.clampColumns(5), 5);
    });

    test('clamps values outside the range', () {
      expect(TimelineGroupingService.clampColumns(0), 1);
      expect(TimelineGroupingService.clampColumns(-4), 1);
      expect(TimelineGroupingService.clampColumns(6), 5);
      expect(TimelineGroupingService.clampColumns(99), 5);
    });
  });

  group('dayKey', () {
    test('strips the time of day', () {
      expect(
        TimelineGroupingService.dayKey(DateTime(2026, 8, 29, 23, 59, 59)),
        DateTime(2026, 8, 29),
      );
    });
  });

  group('build', () {
    test('returns an empty timeline for no items', () {
      final data = service.build(const <MediaItem>[], columnCount: 3, now: now);

      expect(data.isEmpty, isTrue);
      expect(data.groups, isEmpty);
      expect(data.rows, isEmpty);
      expect(data.itemCount, 0);
      expect(data.columnCount, 3);
    });

    test('clamps an out-of-range column count', () {
      final data = service.build([itemAt('a', now)], columnCount: 42, now: now);

      expect(data.columnCount, 5);
    });

    test('labels today, yesterday, this year, and an earlier year', () {
      final data = service.build(
        [
          itemAt('today', DateTime(2026, 8, 29, 9)),
          itemAt('yesterday', DateTime(2026, 8, 28, 9)),
          itemAt('thisYear', DateTime(2026, 3, 2, 9)),
          itemAt('lastYear', DateTime(2025, 3, 2, 9)),
        ],
        columnCount: 3,
        now: now,
      );

      expect(data.groups.map((g) => g.headerKind).toList(), [
        TimelineHeaderKind.today,
        TimelineHeaderKind.yesterday,
        TimelineHeaderKind.dayThisYear,
        TimelineHeaderKind.dayEarlierYear,
      ]);
    });

    test('sorts unsorted input newest first', () {
      final data = service.build(
        [
          itemAt('old', DateTime(2024, 1, 1, 9)),
          itemAt('new', DateTime(2026, 8, 29, 9)),
          itemAt('middle', DateTime(2025, 6, 15, 9)),
        ],
        columnCount: 3,
        now: now,
      );

      expect(data.groups.map((g) => g.date).toList(), [
        DateTime(2026, 8, 29),
        DateTime(2025, 6, 15),
        DateTime(2024, 1, 1),
      ]);
    });

    test('groups items captured on the same day together', () {
      final data = service.build(
        [
          itemAt('morning', DateTime(2026, 8, 29, 8)),
          itemAt('noon', DateTime(2026, 8, 29, 12)),
          itemAt('night', DateTime(2026, 8, 29, 22)),
        ],
        columnCount: 3,
        now: now,
      );

      expect(data.groups, hasLength(1));
      expect(data.groups.single.items, hasLength(3));
      // Newest first inside the day.
      expect(data.groups.single.items.first.id, 'night');
    });

    test('keeps days in different months apart', () {
      final data = service.build(
        [
          itemAt('aug31', DateTime(2026, 8, 31, 9)),
          itemAt('sep01', DateTime(2026, 9, 1, 9)),
        ],
        columnCount: 3,
        now: DateTime(2026, 9, 2),
      );

      expect(data.groups, hasLength(2));
      expect(data.groups.first.date, DateTime(2026, 9, 1));
      expect(data.groups.last.date, DateTime(2026, 8, 31));
    });

    test('falls back to dateModified when dateTaken is missing', () {
      final modified = DateTime(2026, 8, 29, 10);
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

      final data = service.build([item], columnCount: 3, now: now);

      expect(data.groups.single.date, DateTime(2026, 8, 29));
      expect(data.groups.single.headerKind, TimelineHeaderKind.today);
    });

    test('flattens one header row plus the right number of tile rows', () {
      final items = List.generate(
        7,
        (i) => itemAt('i$i', DateTime(2026, 8, 29, 23 - i)),
      );

      final data = service.build(items, columnCount: 3, now: now);

      // 1 header + ceil(7 / 3) = 3 tile rows.
      expect(data.rows, hasLength(4));
      expect(data.rows.first.isHeader, isTrue);
      expect(data.rows[1].items, hasLength(3));
      expect(data.rows[2].items, hasLength(3));
      expect(data.rows[3].items, hasLength(1));
      expect(data.itemCount, 7);
    });

    test('re-flattens correctly at every supported density', () {
      final items = List.generate(
        10,
        (i) => itemAt(
          'i$i',
          DateTime(2026, 8, 29, 23).subtract(Duration(minutes: i)),
        ),
      );

      const expectedTileRows = <int, int>{1: 10, 2: 5, 3: 4, 4: 3, 5: 2};

      for (final entry in expectedTileRows.entries) {
        final data = service.build(items, columnCount: entry.key, now: now);

        final tileRows = data.rows.where((r) => !r.isHeader).toList();
        expect(
          tileRows,
          hasLength(entry.value),
          reason: 'at ${entry.key} columns',
        );
        // No row ever holds more tiles than the density allows.
        for (final row in tileRows) {
          expect(row.items.length, lessThanOrEqualTo(entry.key));
        }
        // Every item is still drawn exactly once.
        expect(
          tileRows.fold<int>(0, (sum, r) => sum + r.items.length),
          items.length,
        );
      }
    });

    test('every row points back at its own group', () {
      final data = service.build(
        [
          itemAt('a', DateTime(2026, 8, 29, 9)),
          itemAt('b', DateTime(2026, 8, 28, 9)),
        ],
        columnCount: 3,
        now: now,
      );

      for (final row in data.rows) {
        expect(row.date, data.groups[row.groupIndex].date);
        expect(row.headerKind, data.groups[row.groupIndex].headerKind);
      }
    });
  });

  group('TimelineMetrics', () {
    final data = service.build(
      [
        itemAt('a', DateTime(2026, 8, 29, 9)),
        itemAt('b', DateTime(2026, 8, 28, 9)),
        itemAt('c', DateTime(2026, 8, 28, 8)),
      ],
      columnCount: 1,
      now: now,
    );

    // Rows: header, a, header, b, c  ->  48 + 100 + 48 + 100 + 100 = 396
    final metrics = TimelineMetrics.build(
      data,
      headerHeight: 48,
      tileRowHeight: 100,
    );

    test('measures the total scroll extent', () {
      expect(metrics.isEmpty, isFalse);
      expect(metrics.totalExtent, 396);
      expect(metrics.rowOffsets, [0, 48, 148, 196, 296]);
    });

    test('maps an offset back onto the right row', () {
      expect(metrics.rowIndexAtOffset(0), 0);
      expect(metrics.rowIndexAtOffset(47), 0);
      expect(metrics.rowIndexAtOffset(48), 1);
      expect(metrics.rowIndexAtOffset(147), 1);
      expect(metrics.rowIndexAtOffset(200), 3);
    });

    test('clamps offsets outside the scroll range', () {
      expect(metrics.rowIndexAtOffset(-500), 0);
      expect(metrics.rowIndexAtOffset(99999), data.rows.length - 1);
    });

    test('finds the offset of a row and of a group header', () {
      expect(metrics.offsetForRow(2), 148);
      expect(metrics.offsetForRow(-1), 0);
      expect(metrics.offsetForRow(500), 296);
      expect(metrics.offsetForGroup(data, 0), 0);
      expect(metrics.offsetForGroup(data, 1), 148);
    });

    test('handles an empty timeline without throwing', () {
      final empty = TimelineMetrics.build(
        const TimelineData.empty(),
        headerHeight: 48,
        tileRowHeight: 100,
      );

      expect(empty.isEmpty, isTrue);
      expect(empty.totalExtent, 0);
      expect(empty.rowIndexAtOffset(120), 0);
      expect(empty.offsetForRow(3), 0);
    });
  });
}
