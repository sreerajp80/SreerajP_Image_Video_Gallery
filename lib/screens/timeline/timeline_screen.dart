import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/timeline/timeline_grouping_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_action_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/selection_app_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/home/home_overflow_menu.dart';
import 'package:in_sreerajp_imgvidgal/widgets/timeline/timeline_body.dart';
import 'package:in_sreerajp_imgvidgal/widgets/timeline/timeline_messages.dart';

/// The main gallery screen: media grouped by day, newest first.
///
/// It reads only providers. Grouping, flashback selection, and scroll-offset
/// maths all live in the service layer, so this widget stays presentation only.
///
/// This screen lives inside [HomeShellScreen] as the first tab. Permission
/// handling is done by the parent shell, so this widget assumes media access
/// has already been granted.
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

    // The shell builds this screen only once permission is already granted,
    // so the permission listener in build() never fires on a normal start.
    // Pick up anything added since the last visit without a pull-to-refresh.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshIfPermitted();
    });
  }

  void _onResume() {
    final status = ref.read(mediaPermissionStatusProvider).value;
    if (status == null || !status.canRead) {
      ref.invalidate(mediaPermissionStatusProvider);
      return;
    }
    // Media may have been added while the app was in the background.
    _refresh();
  }

  void _refreshIfPermitted() {
    final status = ref.read(mediaPermissionStatusProvider).value;
    if (status != null && status.canRead) _refresh();
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
      final data = ref.read(timelineDataProvider).value;
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
      final data = ref.read(timelineDataProvider).value;
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
      ).showSnackBar(SnackBar(content: Text(l10n.bodySelectionFull)));
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
        final prevCanRead = previous?.value?.canRead ?? false;
        final nextCanRead = next.value?.canRead ?? false;
        if (!prevCanRead && nextCanRead) {
          ref.read(mediaScanControllerProvider.notifier).scan();
        }
      },
    );

    final selecting = ref.watch(selectionModeProvider);
    final visibleIds = timeline.value == null
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
              title: Text(l10n.titleTimeline),
              actions: [
                IconButton(
                  onPressed: () => context.push(kRouteSearch),
                  icon: const Icon(Icons.search),
                  tooltip: l10n.tooltipSearchOpen,
                ),
                IconButton(
                  onPressed: () => context.push(kRoutePdfExport),
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  tooltip: l10n.tooltipPdfOpen,
                ),
                const HomeOverflowMenu(),
              ],
            ),
      bottomNavigationBar: selecting ? const BatchActionBar() : null,
      body: SafeArea(
        child: permission.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => TimelineMessageState(
            icon: Icons.error_outline,
            title: l10n.errorScanFailed,
            actionLabel: l10n.labelScanMedia,
            onAction: _refresh,
          ),
          data: (status) {
            if (!status.canRead) {
              final isPermanentlyDenied =
                  status == MediaPermissionStatus.permanentlyDenied;
              return TimelineMessageState(
                icon: Icons.photo_library_outlined,
                title: l10n.labelPermissionRequired,
                body: l10n.bodyPermissionRequired,
                actionLabel: isPermanentlyDenied
                    ? l10n.labelOpenSettings
                    : l10n.labelGrantPermission,
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
                  PartialAccessNotice(message: l10n.bodyPermissionPartial),
                if (scanState.isLoading) const LinearProgressIndicator(),
                Expanded(
                  child: timeline.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, _) => TimelineMessageState(
                      icon: Icons.error_outline,
                      title: l10n.errorScanFailed,
                      actionLabel: l10n.labelScanMedia,
                      onAction: _refresh,
                    ),
                    data: (data) {
                      if (data.isEmpty) {
                        return RefreshIndicator(
                          onRefresh: _refresh,
                          child: TimelineMessageState(
                            icon: Icons.photo_library_outlined,
                            title: l10n.bodyNoMediaInTimeline,
                            body: l10n.bodyPullToScan,
                            actionLabel: l10n.labelScanMedia,
                            onAction: _refresh,
                            scrollable: true,
                          ),
                        );
                      }
                      return TimelineBody(
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
