import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/timeline/timeline_grouping_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/fast_scroll_scrubber.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/flashback_carousel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/timeline_date_header.dart';

/// Gap between tiles in the grid.
const double kTileSpacing = 2;

/// Fixed height of a date header row.
const double kTimelineHeaderHeight = 48;

/// The scrolling part of the timeline: flashbacks, headers, tile rows, scrubber.
class TimelineBody extends ConsumerWidget {
  final TimelineData data;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;
  final ValueChanged<MediaItem> onItemTap;
  final ValueChanged<MediaItem> onItemLongPress;
  final GestureScaleStartCallback onScaleStart;
  final GestureScaleUpdateCallback onScaleUpdate;
  final GestureScaleEndCallback onScaleEnd;
  final ValueChanged<TimelineMetrics> onMetrics;

  /// Key used to measure the flashback carousel's height.
  final GlobalKey flashbackKey;

  /// Height of the slivers drawn above the first timeline row.
  final double Function() leadingExtent;

  const TimelineBody({
    super.key,
    required this.data,
    required this.scrollController,
    required this.onRefresh,
    required this.onItemTap,
    required this.onItemLongPress,
    required this.onScaleStart,
    required this.onScaleUpdate,
    required this.onScaleEnd,
    required this.onMetrics,
    required this.flashbackKey,
    required this.leadingExtent,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Off in settings means the row is not built at all, rather than built
    // and hidden: nothing should be read off disk for a row nobody wants.
    final showFlashbacks = ref.watch(showFlashbacksProvider);
    final flashbacks = showFlashbacks
        ? ref.watch(flashbackMemoriesProvider).value
        : null;
    final flashbackExpanded = ref.watch(flashbackExpandedProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize =
            (constraints.maxWidth - kTileSpacing * (data.columnCount + 1)) /
            data.columnCount;
        final tileRowHeight = tileSize + kTileSpacing;

        final metrics = TimelineMetrics.build(
          data,
          headerHeight: kTimelineHeaderHeight,
          tileRowHeight: tileRowHeight,
        );
        onMetrics(metrics);

        return GestureDetector(
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: onScaleEnd,
          child: Stack(
            children: [
              RefreshIndicator(
                onRefresh: onRefresh,
                child: CustomScrollView(
                  controller: scrollController,
                  // A short timeline (fits on one screen) must still take a
                  // drag, or RefreshIndicator never sees an overscroll.
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    if (flashbacks != null && flashbacks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: FlashbackCarousel(
                          key: flashbackKey,
                          memories: flashbacks,
                          onItemTap: onItemTap,
                          expanded: flashbackExpanded,
                          onToggle: () =>
                              ref
                                      .read(flashbackExpandedProvider.notifier)
                                      .state =
                                  !flashbackExpanded,
                        ),
                      ),
                    SliverList.builder(
                      itemCount: data.rows.length,
                      itemBuilder: (context, index) {
                        final row = data.rows[index];
                        if (row.isHeader) {
                          return SizedBox(
                            height: kTimelineHeaderHeight,
                            child: TimelineDateHeader(
                              headerKind: row.headerKind,
                              date: row.date,
                              itemCount:
                                  data.groups[row.groupIndex].items.length,
                            ),
                          );
                        }
                        return _TileRow(
                          row: row,
                          tileSize: tileSize,
                          columnCount: data.columnCount,
                          onItemTap: onItemTap,
                          onItemLongPress: onItemLongPress,
                        );
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
              FastScrollScrubber(
                controller: scrollController,
                labelForOffset: (offset) {
                  if (metrics.isEmpty) return null;
                  // The flashback carousel sits above the rows, so subtract it
                  // before mapping an offset onto a row.
                  final rowIndex = metrics.rowIndexAtOffset(
                    offset - leadingExtent(),
                  );
                  if (rowIndex >= data.rows.length) return null;
                  final row = data.rows[rowIndex];
                  return formatTimelineDate(context, row.headerKind, row.date);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// One line of tiles inside a day group.
class _TileRow extends ConsumerWidget {
  final TimelineRow row;
  final double tileSize;
  final int columnCount;
  final ValueChanged<MediaItem> onItemTap;
  final ValueChanged<MediaItem> onItemLongPress;

  const _TileRow({
    required this.row,
    required this.tileSize,
    required this.columnCount,
    required this.onItemTap,
    required this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectionProvider);
    final selecting = selected.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(
        left: kTileSpacing,
        right: kTileSpacing,
        bottom: kTileSpacing,
      ),
      child: Row(
        children: [
          for (var i = 0; i < columnCount; i++) ...[
            if (i > 0) const SizedBox(width: kTileSpacing),
            if (i < row.items.length)
              MediaGridTile(
                item: row.items[i],
                size: tileSize,
                onTap: onItemTap,
                onLongPress: onItemLongPress,
                isSelected: selected.contains(row.items[i].id),
                selectionMode: selecting,
                semanticLabel: row.items[i].displayName,
              )
            else
              // Keeps the last row of a day aligned with the rows above it.
              SizedBox(width: tileSize, height: tileSize),
          ],
        ],
      ),
    );
  }
}
