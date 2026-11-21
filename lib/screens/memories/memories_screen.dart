import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/memories_page.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/home/home_overflow_menu.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';
import 'package:in_sreerajp_imgvidgal/widgets/memories/memory_section_header.dart';
import 'package:in_sreerajp_imgvidgal/widgets/timeline/timeline_body.dart'
    show kTileSpacing;
import 'package:in_sreerajp_imgvidgal/widgets/timeline/timeline_messages.dart';

/// The Memories tab: photos and videos from this day in earlier years.
///
/// One section per year, newest first, with every item from that day. When
/// today has nothing, the provider widens to the week around today and a note
/// says so. Tiles open the viewer; there is no selection on this tab.
class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  Future<void> _refresh(WidgetRef ref) {
    return ref
        .read(mediaScanControllerProvider.notifier)
        .scan(incremental: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final page = ref.watch(memoriesPageProvider);
    final scanState = ref.watch(mediaScanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleMemories),
        actions: [
          IconButton(
            onPressed: () => context.push(kRouteSearch),
            icon: const Icon(Icons.search),
            tooltip: l10n.tooltipSearchOpen,
          ),
          const HomeOverflowMenu(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (scanState.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: page.when(
                // Keep the old page on screen while a rescan rebuilds it.
                skipLoadingOnReload: true,
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => TimelineMessageState(
                  icon: Icons.error_outline,
                  title: l10n.errorScanFailed,
                  actionLabel: l10n.labelScanMedia,
                  onAction: () => _refresh(ref),
                ),
                data: (data) => RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: data.isEmpty
                      ? const _EmptyMemories()
                      : _MemoriesList(page: data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The scrolling list of year sections.
class _MemoriesList extends StatelessWidget {
  final MemoriesPage page;

  const _MemoriesList({required this.page});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        // Same density as the timeline, so the two tabs look alike.
        final columns = ref.watch(gridColumnCountProvider);

        void open(MediaItem item) => context.push(mediaViewerPath(item.id));

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (page.range == MemoriesRange.sameWeek)
              const SliverToBoxAdapter(child: _WeekFallbackNote()),
            for (final memory in page.memories) ...[
              SliverToBoxAdapter(child: MemorySectionHeader(memory: memory)),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: kTileSpacing),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final tileSize =
                        (constraints.crossAxisExtent -
                            kTileSpacing * (columns - 1)) /
                        columns;
                    return SliverGrid.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: kTileSpacing,
                        crossAxisSpacing: kTileSpacing,
                      ),
                      itemCount: memory.items.length,
                      itemBuilder: (context, index) {
                        final item = memory.items[index];
                        return MediaGridTile(
                          item: item,
                          size: tileSize,
                          onTap: open,
                          semanticLabel: item.displayName,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        );
      },
    );
  }
}

/// Note shown when today had nothing and the week around it is shown.
class _WeekFallbackNote extends StatelessWidget {
  const _WeekFallbackNote();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      color: theme.colorScheme.secondaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        l10n.bodyMemoriesWeekFallback,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

/// Shown when neither today nor this week has anything from earlier years.
///
/// It scrolls, so pull-to-refresh still works on an empty tab.
class _EmptyMemories extends StatelessWidget {
  const _EmptyMemories();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 56,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.emptyMemories,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
