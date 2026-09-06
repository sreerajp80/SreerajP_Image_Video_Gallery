import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/timeline_grouping_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_action_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/selection_app_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/fast_scroll_scrubber.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/flashback_carousel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/timeline_date_header.dart';

/// Gap between tiles in the grid.
const double kTileSpacing = 2;

/// Fixed height of a date header row.
const double kTimelineHeaderHeight = 48;

/// The main gallery screen: media grouped by day, newest first.
///
/// It reads only providers. Grouping, flashback selection, and scroll-offset
/// maths all live in the service layer, so this widget stays presentation only.
class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  late final AppLifecycleListener _lifecycleListener;

  /// Identifies the flashback carousel so its real height can be measured.
  final GlobalKey _flashbackKey = GlobalKey();

  /// Cumulative row offsets for the currently drawn timeline.
  TimelineMetrics? _metrics;

  /// Column count captured when a pinch begins.
  int _scaleStartColumns = kDefaultGridColumnCount;

  /// Group the user was looking at when a pinch began, so the view can be
  /// re-anchored to the same day after the grid rebuilds.
  int? _anchorGroupIndex;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: _onResume);
  }

  void _onResume() {
    final status = ref.read(mediaPermissionStatusProvider).valueOrNull;
    if (status == null || !status.canRead) {
      ref.invalidate(mediaPermissionStatusProvider);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Height of everything drawn above the first timeline row.
  ///
  /// The flashback carousel is a separate sliver, so every scroll offset is
  /// shifted by its height. Both the scrubber and the pinch anchor subtract
  /// this before mapping an offset onto a row. It measures 0 when no carousel
  /// is on screen.
  double get _leadingExtent {
    final box = _flashbackKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.size.height ?? 0;
  }

  Future<void> _refresh() async {
    await ref
        .read(mediaScanControllerProvider.notifier)
        .scan(incremental: true);
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount < 2) return;
    _scaleStartColumns = ref.read(gridColumnCountProvider);

    final metrics = _metrics;
    if (metrics != null && _scrollController.hasClients) {
      final rowIndex = metrics.rowIndexAtOffset(
        _scrollController.offset - _leadingExtent,
      );
      final data = ref.read(timelineDataProvider).valueOrNull;
      if (data != null && rowIndex < data.rows.length) {
        _anchorGroupIndex = data.rows[rowIndex].groupIndex;
      }
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount < 2) return;

    // Spreading the fingers means bigger tiles, so fewer columns.
    final scaled = (_scaleStartColumns / details.scale).round();
    final next = TimelineGroupingService.clampColumns(scaled);
    if (next == ref.read(gridColumnCountProvider)) return;

    ref.read(gridColumnCountProvider.notifier).set(next);
    _restoreAnchorAfterRebuild();
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _anchorGroupIndex = null;
  }

  /// Scrolls back to the day the user was on before the density changed.
  void _restoreAnchorAfterRebuild() {
    final groupIndex = _anchorGroupIndex;
    if (groupIndex == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final metrics = _metrics;
      final data = ref.read(timelineDataProvider).valueOrNull;
      if (metrics == null || data == null) return;

      final target = _leadingExtent + metrics.offsetForGroup(data, groupIndex);
      final max = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(target > max ? max : target);
    });
  }

  /// Opens the tapped item, or ticks it while a selection is running.
  ///
  /// The viewer pages through the same list in the same order, so it only
  /// needs the id: it resolves the item and its neighbours itself.
  void _onItemTap(MediaItem item) {
    if (ref.read(selectionModeProvider)) {
      ref.read(selectionProvider.notifier).toggle(item.id);
      return;
    }
    context.push(mediaViewerPath(item.id));
  }

  /// Starts a selection, or adds to one already running.
  void _onItemLongPress(MediaItem item) {
    final selection = ref.read(selectionProvider.notifier);

    // Says so rather than doing nothing, so a long press that has no effect
    // is not read as the app being broken.
    if (!selection.contains(item.id) && selection.isFull) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.selectionFull)));
      return;
    }
    selection.toggle(item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final permission = ref.watch(mediaPermissionStatusProvider);
    final timeline = ref.watch(timelineDataProvider);
    final scanState = ref.watch(mediaScanControllerProvider);

    ref.listen<AsyncValue<MediaPermissionStatus>>(
      mediaPermissionStatusProvider,
      (previous, next) {
        final prevCanRead = previous?.valueOrNull?.canRead ?? false;
        final nextCanRead = next.valueOrNull?.canRead ?? false;
        if (!prevCanRead && nextCanRead) {
          ref.read(mediaScanControllerProvider.notifier).scan();
        }
      },
    );

    final selecting = ref.watch(selectionModeProvider);
    final visibleIds = timeline.valueOrNull == null
        ? const <String>[]
        : <String>[
            for (final group in timeline.value!.groups)
              for (final item in group.items) item.id,
          ];

    return Scaffold(
      // While selecting, the ordinary bar is replaced rather than joined, so
      // there is never a moment where two sets of actions are both offered.
      appBar: selecting
          ? SelectionAppBar(visibleIds: visibleIds)
          : AppBar(
              title: Text(l10n.timelineTitle),
              actions: [
                IconButton(
                  onPressed: () => context.push(kRouteSearch),
                  icon: const Icon(Icons.search),
                  tooltip: l10n.searchOpen,
                ),
                IconButton(
                  onPressed: () => context.push(kRouteAlbums),
                  icon: const Icon(Icons.photo_album_outlined),
                  tooltip: l10n.albumsOpen,
                ),
                IconButton(
                  onPressed: () => context.push(kRoutePdfExport),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: l10n.pdfOpen,
                ),
                // Tags and the cleaner live in the overflow: they are used now and
                // then, unlike search, and a crowded bar helps nobody.
                PopupMenuButton<String>(
                  onSelected: (route) => context.push(route),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: kRouteTags,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.label_outline),
                        title: Text(l10n.tagsOpen),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRouteCleaner,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.copy_all_outlined),
                        title: Text(l10n.cleanerOpen),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRouteTrash,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline),
                        title: Text(l10n.trashTitle),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRouteVault,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.lock_outline),
                        title: Text(l10n.vaultMenuLabel),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRouteSync,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.send_to_mobile_outlined),
                        title: Text(l10n.syncOpen),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRoutePdfImages,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.image_search_outlined),
                        title: Text(l10n.pdfImagesOpen),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRouteBackup,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.backup_outlined),
                        title: Text(l10n.backupOpen),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: kRouteSettings,
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.settings_outlined),
                        title: Text(l10n.settings),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: selecting ? const BatchActionBar() : null,
      body: SafeArea(
        child: permission.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _MessageState(
            icon: Icons.error_outline,
            title: l10n.scanFailed,
            actionLabel: l10n.scanMedia,
            onAction: _refresh,
          ),
          data: (status) {
            if (!status.canRead) {
              final isPermanentlyDenied =
                  status == MediaPermissionStatus.permanentlyDenied;
              return _MessageState(
                icon: Icons.photo_library_outlined,
                title: l10n.permissionRequired,
                body: l10n.permissionRequiredBody,
                actionLabel: isPermanentlyDenied
                    ? l10n.openSettings
                    : l10n.grantPermission,
                onAction: () async {
                  if (isPermanentlyDenied) {
                    await ref
                        .read(mediaPermissionServiceProvider)
                        .openSettings();
                  } else {
                    final newStatus = await ref
                        .read(mediaPermissionServiceProvider)
                        .request();
                    ref.invalidate(mediaPermissionStatusProvider);
                    if (newStatus.canRead) {
                      await ref
                          .read(mediaScanControllerProvider.notifier)
                          .scan();
                    }
                  }
                },
              );
            }

            return Column(
              children: [
                if (status == MediaPermissionStatus.partial)
                  _PartialAccessNotice(message: l10n.permissionPartial),
                if (scanState.isLoading) const LinearProgressIndicator(),
                Expanded(
                  child: timeline.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => _MessageState(
                      icon: Icons.error_outline,
                      title: l10n.scanFailed,
                      actionLabel: l10n.scanMedia,
                      onAction: _refresh,
                    ),
                    data: (data) {
                      if (data.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: _MessageState(
                            icon: Icons.photo_library_outlined,
                            title: l10n.noMediaInTimeline,
                            body: l10n.pullToScan,
                            actionLabel: l10n.scanMedia,
                            onAction: _refresh,
                            scrollable: true,
                          ),
                        );
                      }
                      return _TimelineBody(
                        data: data,
                        scrollController: _scrollController,
                        onRefresh: _refresh,
                        onItemTap: _onItemTap,
                        onItemLongPress: _onItemLongPress,
                        onScaleStart: _onScaleStart,
                        onScaleUpdate: _onScaleUpdate,
                        onScaleEnd: _onScaleEnd,
                        onMetrics: (metrics) => _metrics = metrics,
                        flashbackKey: _flashbackKey,
                        leadingExtent: () => _leadingExtent,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The scrolling part of the timeline: flashbacks, headers, tile rows, scrubber.
class _TimelineBody extends ConsumerWidget {
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

  const _TimelineBody({
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
        ? ref.watch(flashbackMemoriesProvider).valueOrNull
        : null;

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
                  slivers: [
                    if (flashbacks != null && flashbacks.isNotEmpty)
                      SliverToBoxAdapter(
                        child: FlashbackCarousel(
                          key: flashbackKey,
                          memories: flashbacks,
                          onItemTap: onItemTap,
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

/// Notice shown when Android granted access to only some media.
class _PartialAccessNotice extends StatelessWidget {
  final String message;

  const _PartialAccessNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Shared empty, permission, and error state layout.
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String actionLabel;
  final VoidCallback onAction;

  /// Wraps the content in a scroll view so pull-to-refresh still works.
  final bool scrollable;

  const _MessageState({
    required this.icon,
    required this.title,
    this.body,
    required this.actionLabel,
    required this.onAction,
    this.scrollable = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final content = Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (body != null) ...[
            const SizedBox(height: 8),
            Text(
              body!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel),
          ),
        ],
      ),
    );

    if (!scrollable) return Center(child: content);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: content,
          ),
        );
      },
    );
  }
}
