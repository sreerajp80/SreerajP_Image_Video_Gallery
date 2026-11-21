import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Media captured around today's calendar date in one earlier year.
///
/// This powers one section of the Memories tab. It is computed from
/// already-loaded items, so it needs no database table.
@immutable
class FlashbackMemory {
  /// The calendar year of [date].
  final int year;

  /// How many years ago that was, counted from today.
  final int yearsAgo;

  /// Midnight local time of today's month and day in [year].
  final DateTime date;

  /// First day of the window searched in [year]. Equal to [date] for a
  /// same-day memory.
  final DateTime rangeStart;

  /// Last day of the window searched in [year]. Equal to [date] for a
  /// same-day memory.
  final DateTime rangeEnd;

  /// The media captured in that window, newest first.
  final List<MediaItem> items;

  const FlashbackMemory({
    required this.year,
    required this.yearsAgo,
    required this.date,
    required this.rangeStart,
    required this.rangeEnd,
    required this.items,
  });

  /// Whether this memory covers more than one day.
  bool get isRange => rangeStart != rangeEnd;

  /// Creates a copy of this [FlashbackMemory] with updated properties.
  FlashbackMemory copyWith({
    int? year,
    int? yearsAgo,
    DateTime? date,
    DateTime? rangeStart,
    DateTime? rangeEnd,
    List<MediaItem>? items,
  }) {
    return FlashbackMemory(
      year: year ?? this.year,
      yearsAgo: yearsAgo ?? this.yearsAgo,
      date: date ?? this.date,
      rangeStart: rangeStart ?? this.rangeStart,
      rangeEnd: rangeEnd ?? this.rangeEnd,
      items: items ?? this.items,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlashbackMemory &&
          runtimeType == other.runtimeType &&
          year == other.year &&
          yearsAgo == other.yearsAgo &&
          date == other.date &&
          rangeStart == other.rangeStart &&
          rangeEnd == other.rangeEnd &&
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(
    year,
    yearsAgo,
    date,
    rangeStart,
    rangeEnd,
    Object.hashAll(items),
  );
}
