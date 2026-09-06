import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Media captured on today's calendar date in one earlier year.
///
/// This powers the "On This Day" carousel at the top of the timeline. It is
/// computed from already-loaded items, so it needs no database table.
@immutable
class FlashbackMemory {
  /// The calendar year the media was captured in.
  final int year;

  /// How many years ago that was, counted from today.
  final int yearsAgo;

  /// Midnight local time of the matching day in [year].
  final DateTime date;

  /// The media captured that day, newest first.
  final List<MediaItem> items;

  const FlashbackMemory({
    required this.year,
    required this.yearsAgo,
    required this.date,
    required this.items,
  });

  /// Creates a copy of this [FlashbackMemory] with updated properties.
  FlashbackMemory copyWith({
    int? year,
    int? yearsAgo,
    DateTime? date,
    List<MediaItem>? items,
  }) {
    return FlashbackMemory(
      year: year ?? this.year,
      yearsAgo: yearsAgo ?? this.yearsAgo,
      date: date ?? this.date,
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
          listEquals(items, other.items);

  @override
  int get hashCode => Object.hash(year, yearsAgo, date, Object.hashAll(items));
}
