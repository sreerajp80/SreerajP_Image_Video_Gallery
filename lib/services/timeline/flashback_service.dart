import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/memories_page.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/timeline/timeline_grouping_service.dart';

/// Builds the "On This Day" memories shown on the Memories tab.
///
/// First it looks for media captured on today's month and day in earlier
/// years. When there is none, it widens to [defaultWindowDays] days on each
/// side of that date, so the tab is rarely empty. Nothing is stored: this is a
/// filter over items the timeline already loaded.
///
/// All matching uses calendar days (year, month, day) only, never times, so a
/// time zone or daylight-saving change cannot move a photo to another day.
class FlashbackService {
  /// Days on each side of today searched when the exact day has nothing.
  static const int defaultWindowDays = 3;

  const FlashbackService();

  /// Returns the memories for today, most recent year first.
  ///
  /// [now] is injectable so tests can pin "today". Media from the last
  /// [windowDays] days is never a memory: a memory is always at least one
  /// year old.
  MemoriesPage buildPage(
    List<MediaItem> items, {
    DateTime? now,
    int windowDays = defaultWindowDays,
  }) {
    if (items.isEmpty) return const MemoriesPage.empty();

    final today = TimelineGroupingService.dayKey(now ?? DateTime.now());

    final sameDay = _sameDay(items, today);
    if (sameDay.isNotEmpty) {
      return MemoriesPage(range: MemoriesRange.sameDay, memories: sameDay);
    }
    if (windowDays <= 0) return const MemoriesPage.empty();

    return MemoriesPage(
      range: MemoriesRange.sameWeek,
      memories: _window(items, today, windowDays),
    );
  }

  /// Same month and day as [today], in an earlier year. A 29 February photo
  /// matches only on 29 February.
  List<FlashbackMemory> _sameDay(List<MediaItem> items, DateTime today) {
    final byYearsAgo = <int, List<MediaItem>>{};
    for (final item in items) {
      final date = item.effectiveDate;
      if (date.year >= today.year) continue;
      if (date.month != today.month || date.day != today.day) continue;
      byYearsAgo
          .putIfAbsent(today.year - date.year, () => <MediaItem>[])
          .add(item);
    }

    return _toMemories(byYearsAgo, (yearsAgo) {
      final day = DateTime(today.year - yearsAgo, today.month, today.day);
      return (day, day, day);
    });
  }

  /// Within [windowDays] days of today's date, in an earlier year. The window
  /// may cross a month or year end, so a photo from 2 January can belong to
  /// the year before when today is 30 December.
  List<FlashbackMemory> _window(
    List<MediaItem> items,
    DateTime today,
    int windowDays,
  ) {
    final byYearsAgo = <int, List<MediaItem>>{};
    for (final item in items) {
      final day = TimelineGroupingService.dayKey(item.effectiveDate);
      // The anniversary that contains this day is in its own year or, near a
      // year end, the year before or after.
      for (
        var yearsAgo = today.year - day.year - 1;
        yearsAgo <= today.year - day.year + 1;
        yearsAgo++
      ) {
        if (yearsAgo < 1) continue;
        final anniversary = _anniversary(today, yearsAgo);
        if (_daysBetween(anniversary, day).abs() <= windowDays) {
          byYearsAgo.putIfAbsent(yearsAgo, () => <MediaItem>[]).add(item);
          break;
        }
      }
    }

    return _toMemories(byYearsAgo, (yearsAgo) {
      final anniversary = _anniversary(today, yearsAgo);
      return (
        anniversary,
        _addDays(anniversary, -windowDays),
        _addDays(anniversary, windowDays),
      );
    });
  }

  /// Turns grouped items into memories, newest year first, items newest
  /// first. [datesFor] gives (date, rangeStart, rangeEnd) for a year.
  List<FlashbackMemory> _toMemories(
    Map<int, List<MediaItem>> byYearsAgo,
    (DateTime, DateTime, DateTime) Function(int yearsAgo) datesFor,
  ) {
    if (byYearsAgo.isEmpty) return const <FlashbackMemory>[];

    final keys = byYearsAgo.keys.toList()..sort();
    final memories = <FlashbackMemory>[];
    for (final yearsAgo in keys) {
      final (date, start, end) = datesFor(yearsAgo);
      final yearItems = byYearsAgo[yearsAgo]!
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      memories.add(
        FlashbackMemory(
          year: date.year,
          yearsAgo: yearsAgo,
          date: date,
          rangeStart: start,
          rangeEnd: end,
          items: List<MediaItem>.unmodifiable(yearItems),
        ),
      );
    }
    return List<FlashbackMemory>.unmodifiable(memories);
  }

  /// Today's month and day, [yearsAgo] years back. 29 February becomes
  /// 28 February in a year that has no leap day.
  static DateTime _anniversary(DateTime today, int yearsAgo) {
    final year = today.year - yearsAgo;
    final lastDay = DateTime(year, today.month + 1, 0).day;
    final day = today.day > lastDay ? lastDay : today.day;
    return DateTime(year, today.month, day);
  }

  /// Whole calendar days from [from] to [to], ignoring time and DST.
  static int _daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// [date] moved by [days] calendar days, at local midnight.
  static DateTime _addDays(DateTime date, int days) {
    return DateTime(date.year, date.month, date.day + days);
  }
}
