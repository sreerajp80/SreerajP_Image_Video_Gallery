import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';

/// Height of one horizontal memory strip, tiles plus caption.
const double kFlashbackTileSize = 104;

/// The "On This Day" strip shown above the first date header.
///
/// It draws nothing at all when there are no memories, so the timeline does not
/// carry an empty gap on most days.
class FlashbackCarousel extends StatelessWidget {
  final List<FlashbackMemory> memories;

  /// Called when a memory tile is tapped. Phase 5 wires this to the viewer.
  final ValueChanged<MediaItem>? onItemTap;

  const FlashbackCarousel({super.key, required this.memories, this.onItemTap});

  @override
  Widget build(BuildContext context) {
    if (memories.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.flashbackTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        for (final memory in memories)
          _MemoryRow(memory: memory, onItemTap: onItemTap),
        const Divider(height: 24),
      ],
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
        ? l10n.flashbackOneYearAgo
        : l10n.flashbackYearsAgo(memory.yearsAgo);

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
