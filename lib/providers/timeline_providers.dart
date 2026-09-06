import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/flashback_service.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/timeline_grouping_service.dart';

/// Default grid density used on first launch.
const int kDefaultGridColumnCount = 3;

/// Holds the current grid density, always inside the supported 1..5 range.
class GridColumnCountNotifier extends StateNotifier<int> {
  /// Told about every settled density, so it can be remembered for next time.
  ///
  /// Optional: a test that only cares about the clamping does not need one.
  final void Function(int columns)? _onChanged;

  GridColumnCountNotifier({
    int initial = kDefaultGridColumnCount,
    void Function(int columns)? onChanged,
  }) : _onChanged = onChanged,
       super(TimelineGroupingService.clampColumns(initial));

  /// Sets an exact column count, clamped to 1..5.
  void set(int columns) {
    final clamped = TimelineGroupingService.clampColumns(columns);
    if (clamped == state) return;
    state = clamped;
    _onChanged?.call(clamped);
  }

  /// Shows more, smaller tiles per row.
  void increaseDensity() => set(state + 1);

  /// Shows fewer, larger tiles per row.
  void decreaseDensity() => set(state - 1);

  /// Whether another step towards smaller tiles is possible.
  bool get canIncreaseDensity => state < TimelineGroupingService.maxColumns;

  /// Whether another step towards larger tiles is possible.
  bool get canDecreaseDensity => state > TimelineGroupingService.minColumns;
}

/// Current number of grid columns on the timeline.
///
/// Starts at the density the user last pinched to, and saves each new one, so
/// the grid is not reset to three columns on every launch.
final gridColumnCountProvider =
    StateNotifierProvider<GridColumnCountNotifier, int>((ref) {
      return GridColumnCountNotifier(
        initial: ref.read(appSettingsProvider).gridColumns,
        onChanged: (columns) {
          ref.read(appSettingsProvider.notifier).setGridColumns(columns);
        },
      );
    });

/// Groups media into date buckets and list rows.
final timelineGroupingServiceProvider = Provider<TimelineGroupingService>((
  ref,
) {
  return const TimelineGroupingService();
});

/// Builds the "On This Day" memories.
final flashbackServiceProvider = Provider<FlashbackService>((ref) {
  return const FlashbackService();
});

/// Supplies "now" to the date-sensitive providers.
///
/// It exists so tests can pin the current date instead of depending on the
/// wall clock, which otherwise makes flashback results change day to day.
final timelineNowProvider = Provider<DateTime Function()>((ref) {
  return DateTime.now;
});

/// Filter applied to the timeline query.
///
/// Phase 4 keeps this at the default (everything, newest first). Later phases
/// point the filter sheets and search at this same provider.
final timelineFilterProvider = StateProvider<FilterOptions>((ref) {
  return const FilterOptions();
});

/// The indexed media backing the timeline.
final timelineItemsProvider = FutureProvider<List<MediaItem>>((ref) async {
  final filter = ref.watch(timelineFilterProvider);
  return ref.watch(mediaItemsProvider(filter).future);
});

/// The timeline grouped and flattened for the current grid density.
///
/// Changing the density regroups the already-loaded items; it does not re-query
/// the database, so a pinch stays cheap.
final timelineDataProvider = FutureProvider<TimelineData>((ref) async {
  final columnCount = ref.watch(gridColumnCountProvider);
  final items = await ref.watch(timelineItemsProvider.future);

  return ref
      .watch(timelineGroupingServiceProvider)
      .build(
        items,
        columnCount: columnCount,
        now: ref.watch(timelineNowProvider)(),
      );
});

/// "On This Day" memories for today, or an empty list when there are none.
final flashbackMemoriesProvider = FutureProvider<List<FlashbackMemory>>((
  ref,
) async {
  final items = await ref.watch(timelineItemsProvider.future);
  return ref
      .watch(flashbackServiceProvider)
      .build(items, now: ref.watch(timelineNowProvider)());
});
