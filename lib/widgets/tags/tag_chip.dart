import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// One tag drawn as a coloured chip.
///
/// The tag's own colour is used for the dot and, when the chip is selected,
/// for a tinted background. The label itself keeps the theme's text colour, so
/// a chip stays readable on every palette colour in both light and dark.
class TagChip extends StatelessWidget {
  /// The tag to draw.
  final Tag tag;

  /// Whether the chip is ticked.
  final bool selected;

  /// Called when the chip is tapped, or null to make it read-only.
  final VoidCallback? onTap;

  /// Optional trailing count shown after the name.
  final int? count;

  const TagChip({
    super.key,
    required this.tag,
    this.selected = false,
    this.onTap,
    this.count,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(TagColorPalette.resolve(tag.colorValue, tag.name));

    return FilterChip(
      selected: selected,
      onSelected: onTap == null ? null : (_) => onTap!(),
      showCheckmark: false,
      avatar: TagColorDot(color: color, selected: selected),
      // The name is the user's own text; the count beside it is a number and
      // rides along with whichever way the name reads.
      label: AdaptiveDirectionality(
        text: tag.name,
        child: Text(count == null ? tag.name : '${tag.name}  $count'),
      ),
      selectedColor: color.withValues(alpha: 0.22),
      side: BorderSide(
        color: selected ? color : theme.colorScheme.outlineVariant,
      ),
    );
  }
}

/// The small round colour marker used on a chip and in the tag list.
class TagColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final double size;

  const TagColorDot({
    super.key,
    required this.color,
    this.selected = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: Theme.of(context).colorScheme.onSurface)
            : null,
      ),
      child: selected
          ? Icon(Icons.check, size: size * 0.7, color: Colors.white)
          : null,
    );
  }
}
