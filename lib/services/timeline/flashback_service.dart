import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/timeline_grouping_service.dart';

/// Builds the "On This Day" memories shown above the timeline.
///
/// A memory is media captured on the same month and day-of-month as today, but
/// in an earlier calendar year. Nothing is stored: this is a filter over items
/// the timeline already loaded, so the phase needs no schema change.
class FlashbackService {
  /// Most items kept per year, so the carousel stays light.
  static const int defaultMaxItemsPerYear = 12;

  /// Most years shown, newest first.
  static const int defaultMaxYears = 5;

  const FlashbackService();

  /// Returns memories for today's date, most recent year first.
  ///
  /// [now] is injectable so tests can pin "today". Items from today itself are
  /// excluded — a memory is always from an earlier year.
  List<FlashbackMemory> build(
    List<MediaItem> items, {
    DateTime? now,
    int maxItemsPerYear = defaultMaxItemsPerYear,
    int maxYears = defaultMaxYears,
  }) {
    if (items.isEmpty || maxYears <= 0 || maxItemsPerYear <= 0) {
      return const <FlashbackMemory>[];
    }

    final today = TimelineGroupingService.dayKey(now ?? DateTime.now());

    final byYear = <int, List<MediaItem>>{};
    for (final item in items) {
      final date = item.effectiveDate;
      if (date.year >= today.year) continue;
      if (date.month != today.month || date.day != today.day) continue;
      byYear.putIfAbsent(date.year, () => <MediaItem>[])..add(item);
    }
    if (byYear.isEmpty) return const <FlashbackMemory>[];

    final years = byYear.keys.toList()..sort((a, b) => b.compareTo(a));

    final memories = <FlashbackMemory>[];
    for (final year in years.take(maxYears)) {
      final yearItems = byYear[year]!
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));

      memories.add(
        FlashbackMemory(
          year: year,
          yearsAgo: today.year - year,
          date: DateTime(year, today.month, today.day),
          items: List<MediaItem>.unmodifiable(yearItems.take(maxItemsPerYear)),
        ),
      );
    }

    return List<FlashbackMemory>.unmodifiable(memories);
  }
}
