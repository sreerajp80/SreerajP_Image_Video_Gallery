import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_badges.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';

/// One square tile in the timeline grid.
///
/// It layers the cached thumbnail, the badge overlay, and a tap target. All
/// loading and fallback handling lives inside [MediaThumbnail], so a corrupt
/// file shows a placeholder rather than breaking the grid.
class MediaGridTile extends StatelessWidget {
  final MediaItem item;

  /// Side length of the tile in logical pixels.
  final double size;

  /// Called when the tile is tapped. Phase 5 wires this to the viewer.
  final ValueChanged<MediaItem>? onTap;

  /// Called on a long press. Phase 11 wires this to selection mode.
  final ValueChanged<MediaItem>? onLongPress;

  /// Whether this tile is ticked.
  final bool isSelected;

  /// Whether the grid is in selection mode.
  ///
  /// Every tile shows a tick outline while it is, not only the ticked ones,
  /// so it is obvious that a tap now selects rather than opens.
  final bool selectionMode;

  /// Semantic description read out by screen readers.
  final String? semanticLabel;

  const MediaGridTile({
    super.key,
    required this.item,
    required this.size,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    // Badges shrink on dense grids where a full-size pill would not fit.
    final compact = size < 96;
    final radius = size < 72 ? 4.0 : 8.0;

    final theme = Theme.of(context);

    return Semantics(
      image: true,
      button: onTap != null,
      selected: selectionMode ? isSelected : null,
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // A ticked tile shrinks slightly, so the selection reads at a
            // glance on a dense grid where a small tick would be easy to miss.
            AnimatedPadding(
              duration: const Duration(milliseconds: 120),
              padding: EdgeInsets.all(isSelected ? size * 0.06 : 0),
              child: MediaThumbnail(
                item: item,
                size: size,
                borderRadius: radius,
              ),
            ),
            Positioned.fill(
              child: MediaBadges(item: item, compact: compact),
            ),

            if (isSelected)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              ),

            if (selectionMode)
              PositionedDirectional(
                top: 4,
                start: 4,
                child: _Tick(
                  isSelected: isSelected,
                  compact: compact,
                  colours: theme.colorScheme,
                ),
              ),

            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(radius),
                  onTap: onTap == null ? null : () => onTap!(item),
                  onLongPress: onLongPress == null
                      ? null
                      : () => onLongPress!(item),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tick box drawn on every tile while a grid is selecting.
class _Tick extends StatelessWidget {
  final bool isSelected;
  final bool compact;
  final ColorScheme colours;

  const _Tick({
    required this.isSelected,
    required this.compact,
    required this.colours,
  });

  @override
  Widget build(BuildContext context) {
    final side = compact ? 18.0 : 24.0;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? colours.primary : Colors.black38,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: isSelected
          ? Icon(Icons.check, size: side * 0.7, color: colours.onPrimary)
          : null,
    );
  }
}
