import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';

/// Height of one horizontal memory strip, tiles plus caption.
const double kFlashbackTileSize = 104;

/// The "On This Day" section shown above the first date header.
///
/// It sits in its own bordered box with a shaded title bar, so it never looks
/// like part of the timeline below it. Its tiles open the viewer but, on
/// purpose, do not start selection; the different look is what tells the user
/// these are memories, not timeline rows.
///
/// The title bar is a button that opens and closes the section. The parent
/// owns the open state ([expanded]) and is told about taps through
/// [onToggle].
///
/// It draws nothing at all when there are no memories, so the timeline does not
/// carry an empty gap on most days.
class FlashbackCarousel extends StatelessWidget {
  final List<FlashbackMemory> memories;

  /// Called when a memory tile is tapped. Phase 5 wires this to the viewer.
  final ValueChanged<MediaItem>? onItemTap;

  /// Whether the memory rows are shown. When false only the title bar is.
  final bool expanded;

  /// Called when the title bar is tapped.
  final VoidCallback? onToggle;

  const FlashbackCarousel({
    super.key,
    required this.memories,
    this.onItemTap,
    this.expanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    const radius = BorderRadius.all(Radius.circular(16));

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleBar(
                photoCount: memories.fold<int>(
                  0,
                  (sum, memory) => sum + memory.items.length,
                ),
                expanded: expanded,
                onToggle: onToggle,
              ),
              if (expanded) ...[
                for (final memory in memories)
                  _MemoryRow(memory: memory, onItemTap: onItemTap),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Shaded, tappable title bar: icon, "On This Day", photo count and arrow.
class _TitleBar extends StatelessWidget {
  final int photoCount;
  final bool expanded;
  final VoidCallback? onToggle;

  const _TitleBar({
    required this.photoCount,
    required this.expanded,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final scheme = theme.colorScheme;
    final tooltip = expanded
        ? l10n.tooltipCollapseFlashback
        : l10n.tooltipExpandFlashback;

    // Tertiary is a different colour family from the timeline date headers
    // (surfaceContainerHigh), so the two kinds of title never look alike.
    return Material(
      color: scheme.tertiaryContainer,
      child: Semantics(
        button: true,
        expanded: expanded,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  size: 18,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.titleFlashback,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onTertiaryContainer,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                DecoratedBox(
                  decoration: ShapeDecoration(
                    color: scheme.surface,
                    shape: const StadiumBorder(),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    child: Text(
                      '$photoCount',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: tooltip,
                  onPressed: onToggle,
                  color: scheme.onTertiaryContainer,
                  icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MemoryRow extends StatelessWidget {
  final FlashbackMemory memory;
  final ValueChanged<MediaItem>? onItemTap;

  const _MemoryRow({required this.memory, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final caption = memory.yearsAgo == 1
        ? l10n.labelFlashbackOneYearAgo
        : l10n.bodyFlashbackYearsAgo(memory.yearsAgo);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Text(
            caption,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: kFlashbackTileSize,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: memory.items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              return MediaGridTile(
                item: memory.items[index],
                size: kFlashbackTileSize,
                onTap: onItemTap,
                semanticLabel: memory.items[index].displayName,
              );
            },
          ),
        ),
      ],
    );
  }
}
