import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// The kind of label a date header should show.
///
/// The service picks the kind; the widget turns it into localized text. This
/// keeps date formatting (which needs a locale) out of the pure Dart layer.
enum TimelineHeaderKind {
  /// The bucket is today's calendar day.
  today,

  /// The bucket is the calendar day before today.
  yesterday,

  /// The bucket is an earlier day inside the current calendar year.
  dayThisYear,

  /// The bucket is a day in an earlier calendar year.
  dayEarlierYear,
}

/// One calendar day of media, in newest-first order.
@immutable
class TimelineGroup {
  /// Midnight local time of the day this group covers.
  final DateTime date;

  /// Which label the header for this group should use.
  final TimelineHeaderKind headerKind;

  /// The media captured on [date], newest first.
  final List<MediaItem> items;

  const TimelineGroup({
    required this.date,
    required this.headerKind,
    required this.items,
  });

  /// Creates a copy of this [TimelineGroup] with updated properties.
  TimelineGroup copyWith({
    DateTime? date,
    TimelineHeaderKind? headerKind,
    List<MediaItem>? items,
  }) {
    return TimelineGroup(
      date: date ?? this.date,
      headerKind: headerKind ?? this.headerKind,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineGroup &&
          runtimeType == other.runtimeType &&
          date == other.date &&
          headerKind == other.headerKind &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(date, headerKind, Object.hashAll(items));
}

/// What a single row in the flattened timeline draws.
enum TimelineRowType { header, tiles }

/// One row of the flattened timeline list.
///
/// A row is either the date header for a group, or one line of up to
/// `columnCount` tiles. Flattening this way gives every row a predictable
/// height, so the scroll offset maps straight onto a date for the scrubber.
@immutable
class TimelineRow {
  /// Whether this row draws a header or a line of tiles.
  final TimelineRowType type;

  /// Index of the owning group inside [TimelineData.groups].
  final int groupIndex;

  /// Midnight local time of the owning group's day.
  final DateTime date;

  /// Which label a header row should use.
  final TimelineHeaderKind headerKind;

  /// The items drawn by a tile row; always empty for a header row.
  final List<MediaItem> items;

  const TimelineRow({
    required this.type,
    required this.groupIndex,
    required this.date,
    required this.headerKind,
    this.items = const <MediaItem>[],
  });

  /// Builds a header row for [groupIndex].
  const TimelineRow.header({
    required int groupIndex,
    required DateTime date,
    required TimelineHeaderKind headerKind,
  }) : this(
         type: TimelineRowType.header,
         groupIndex: groupIndex,
         date: date,
         headerKind: headerKind,
       );

  /// Builds a tile row holding [items].
  const TimelineRow.tiles({
    required int groupIndex,
    required DateTime date,
    required TimelineHeaderKind headerKind,
    required List<MediaItem> items,
  }) : this(
         type: TimelineRowType.tiles,
         groupIndex: groupIndex,
         date: date,
         headerKind: headerKind,
         items: items,
       );

  /// Whether this row draws a date header.
  bool get isHeader => type == TimelineRowType.header;

  /// Creates a copy of this [TimelineRow] with updated properties.
  TimelineRow copyWith({
    TimelineRowType? type,
    int? groupIndex,
    DateTime? date,
    TimelineHeaderKind? headerKind,
    List<MediaItem>? items,
  }) {
    return TimelineRow(
      type: type ?? this.type,
      groupIndex: groupIndex ?? this.groupIndex,
      date: date ?? this.date,
      headerKind: headerKind ?? this.headerKind,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineRow &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          groupIndex == other.groupIndex &&
          date == other.date &&
          headerKind == other.headerKind &&
          listEquals(items, other.items);

  @override
  int get hashCode =>
      Object.hash(type, groupIndex, date, headerKind, Object.hashAll(items));
}

/// The whole timeline, ready for a flat scrolling list.
@immutable
class TimelineData {
  /// Date buckets, newest day first.
  final List<TimelineGroup> groups;

  /// The flattened header and tile rows drawn by the list.
  final List<TimelineRow> rows;

  /// How many tiles each tile row holds.
  final int columnCount;

  /// Total number of media items across every group.
  final int itemCount;

  const TimelineData({
    required this.groups,
    required this.rows,
    required this.columnCount,
    required this.itemCount,
  });

  /// An empty timeline at the given density.
  const TimelineData.empty({int columnCount = 3})
    : this(
        groups: const <TimelineGroup>[],
        rows: const <TimelineRow>[],
        columnCount: columnCount,
        itemCount: 0,
      );

  /// Whether there is nothing at all to draw.
  bool get isEmpty => rows.isEmpty;

  /// Creates a copy of this [TimelineData] with updated properties.
  TimelineData copyWith({
    List<TimelineGroup>? groups,
    List<TimelineRow>? rows,
    int? columnCount,
    int? itemCount,
  }) {
    return TimelineData(
      groups: groups ?? this.groups,
      rows: rows ?? this.rows,
      columnCount: columnCount ?? this.columnCount,
      itemCount: itemCount ?? this.itemCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimelineData &&
          runtimeType == other.runtimeType &&
          listEquals(groups, other.groups) &&
          listEquals(rows, other.rows) &&
          columnCount == other.columnCount &&
          itemCount == other.itemCount;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(groups),
    Object.hashAll(rows),
    columnCount,
    itemCount,
  );
}
