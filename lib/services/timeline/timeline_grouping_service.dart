import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';

/// Turns a flat list of media into date buckets and then into list rows.
///
/// This is pure Dart on purpose. It holds no `BuildContext`, does no I/O, and
/// never formats a date into text, so the whole thing is unit-testable and the
/// timeline widget stays free of business logic.
class TimelineGroupingService {
  /// Smallest allowed grid density.
  static const int minColumns = 1;

  /// Largest allowed grid density.
  static const int maxColumns = 5;

  const TimelineGroupingService();

  /// Forces [columns] into the supported 1..5 range.
  static int clampColumns(int columns) {
    if (columns < minColumns) return minColumns;
    if (columns > maxColumns) return maxColumns;
    return columns;
  }

  /// Midnight local time of the day [date] falls on.
  static DateTime dayKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Groups [items] by calendar day and flattens them into list rows.
  ///
  /// [items] may arrive in any order; it is sorted newest first here so callers
  /// do not have to trust the query order. [now] is injectable so tests can pin
  /// "today" without depending on the wall clock.
  TimelineData build(
    List<MediaItem> items, {
    required int columnCount,
    DateTime? now,
  }) {
    final columns = clampColumns(columnCount);
    if (items.isEmpty) return TimelineData.empty(columnCount: columns);

    final today = dayKey(now ?? DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    final sorted = List<MediaItem>.of(items)
      ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

    // Bucket by day. Insertion order follows the sort, so buckets come out
    // newest day first without a second sort.
    final buckets = <DateTime, List<MediaItem>>{};
    for (final item in sorted) {
      buckets.putIfAbsent(dayKey(item.effectiveDate), () => <MediaItem>[])
        ..add(item);
    }

    final groups = <TimelineGroup>[];
    final rows = <TimelineRow>[];

    for (final entry in buckets.entries) {
      final date = entry.key;
      final kind = _headerKind(date: date, today: today, yesterday: yesterday);
      final groupIndex = groups.length;

      groups.add(
        TimelineGroup(date: date, headerKind: kind, items: entry.value),
      );
      rows.add(
        TimelineRow.header(
          groupIndex: groupIndex,
          date: date,
          headerKind: kind,
        ),
      );

      for (var start = 0; start < entry.value.length; start += columns) {
        final end = (start + columns) > entry.value.length
            ? entry.value.length
            : start + columns;
        rows.add(
          TimelineRow.tiles(
            groupIndex: groupIndex,
            date: date,
            headerKind: kind,
            items: entry.value.sublist(start, end),
          ),
        );
      }
    }

    return TimelineData(
      groups: List<TimelineGroup>.unmodifiable(groups),
      rows: List<TimelineRow>.unmodifiable(rows),
      columnCount: columns,
      itemCount: sorted.length,
    );
  }

  TimelineHeaderKind _headerKind({
    required DateTime date,
    required DateTime today,
    required DateTime yesterday,
  }) {
    if (date == today) return TimelineHeaderKind.today;
    if (date == yesterday) return TimelineHeaderKind.yesterday;
    if (date.year == today.year) return TimelineHeaderKind.dayThisYear;
    return TimelineHeaderKind.dayEarlierYear;
  }
}

/// Maps flattened timeline rows onto scroll offsets, and back again.
///
/// The fast scroll scrubber needs to turn a scroll position into a date and a
/// drag fraction into a scroll position. Both are plain arithmetic over the row
/// heights, so they live here as pure Dart instead of inside the widget.
class TimelineMetrics {
  /// Height of every row, in list order.
  final List<double> rowHeights;

  /// Cumulative offset of the top of each row.
  final List<double> rowOffsets;

  /// Combined height of every row.
  final double totalExtent;

  const TimelineMetrics._({
    required this.rowHeights,
    required this.rowOffsets,
    required this.totalExtent,
  });

  /// Builds metrics for [data] given the pixel height of each row kind.
  factory TimelineMetrics.build(
    TimelineData data, {
    required double headerHeight,
    required double tileRowHeight,
  }) {
    final heights = <double>[];
    final offsets = <double>[];
    var running = 0.0;

    for (final row in data.rows) {
      offsets.add(running);
      final height = row.isHeader ? headerHeight : tileRowHeight;
      heights.add(height);
      running += height;
    }

    return TimelineMetrics._(
      rowHeights: List<double>.unmodifiable(heights),
      rowOffsets: List<double>.unmodifiable(offsets),
      totalExtent: running,
    );
  }

  /// Whether there are no rows to measure.
  bool get isEmpty => rowHeights.isEmpty;

  /// Index of the row containing [offset], clamped into range.
  ///
  /// Uses a binary search so a very large library costs no more than a small
  /// one on every scroll frame.
  int rowIndexAtOffset(double offset) {
    if (rowOffsets.isEmpty) return 0;
    if (offset <= 0) return 0;
    if (offset >= totalExtent) return rowOffsets.length - 1;

    var low = 0;
    var high = rowOffsets.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (rowOffsets[mid] <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  /// Scroll offset that puts the top of [rowIndex] at the top of the viewport.
  double offsetForRow(int rowIndex) {
    if (rowOffsets.isEmpty) return 0;
    final clamped = rowIndex < 0
        ? 0
        : (rowIndex >= rowOffsets.length ? rowOffsets.length - 1 : rowIndex);
    return rowOffsets[clamped];
  }

  /// Scroll offset that shows the header of [groupIndex] at the viewport top.
  ///
  /// Used to hold the user's place when the grid density changes.
  double offsetForGroup(TimelineData data, int groupIndex) {
    for (var i = 0; i < data.rows.length; i++) {
      if (data.rows[i].groupIndex == groupIndex) return offsetForRow(i);
    }
    return 0;
  }
}
