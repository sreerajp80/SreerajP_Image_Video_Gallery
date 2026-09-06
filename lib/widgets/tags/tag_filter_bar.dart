import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_chip.dart';

/// A row of tag chips with the "has all" / "has any" switch beside them.
///
/// The switch only appears once two tags are ticked, because with one tag the
/// two modes mean exactly the same thing and the control would just be noise.
class TagFilterBar extends StatelessWidget {
  /// Every tag that can be ticked.
  final List<Tag> tags;

  /// Ids of the ticked tags.
  final Set<String> selectedTagIds;

  /// Whether a photo must carry all the ticked tags or any of them.
  final TagFilterMode mode;

  /// Called when a chip is tapped.
  final ValueChanged<String> onToggle;

  /// Called when the mode is switched.
  final ValueChanged<TagFilterMode> onModeChanged;

  const TagFilterBar({
    super.key,
    required this.tags,
    required this.selectedTagIds,
    required this.mode,
    required this.onToggle,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (tags.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          l10n.filterNoTags,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (selectedTagIds.length > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<TagFilterMode>(
              segments: <ButtonSegment<TagFilterMode>>[
                ButtonSegment<TagFilterMode>(
                  value: TagFilterMode.andMode,
                  label: Text(l10n.filterTagModeAll),
                ),
                ButtonSegment<TagFilterMode>(
                  value: TagFilterMode.orMode,
                  label: Text(l10n.filterTagModeAny),
                ),
              ],
              selected: <TagFilterMode>{mode},
              onSelectionChanged: (selection) => onModeChanged(selection.first),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final tag in tags)
              TagChip(
                tag: tag,
                selected: selectedTagIds.contains(tag.id),
                onTap: () => onToggle(tag.id),
              ),
          ],
        ),
      ],
    );
  }
}
