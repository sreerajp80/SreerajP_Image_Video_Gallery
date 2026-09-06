import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_chip.dart';

/// Ticks tags on and off for one media item.
///
/// The ticks are held here while the sheet is open and written in one go when
/// it closes, so a change of mind costs nothing and the photo is never left
/// half-tagged.
class MediaTagSheet extends ConsumerStatefulWidget {
  /// The item being tagged.
  final String mediaId;

  const MediaTagSheet({super.key, required this.mediaId});

  /// Opens the sheet as a bottom sheet.
  static Future<void> show(BuildContext context, String mediaId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MediaTagSheet(mediaId: mediaId),
    );
  }

  @override
  ConsumerState<MediaTagSheet> createState() => _MediaTagSheetState();
}

class _MediaTagSheetState extends ConsumerState<MediaTagSheet> {
  final TextEditingController _newTagController = TextEditingController();

  /// The ticks, once the item's own tags have been read.
  Set<String>? _selected;

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTags = ref.watch(allTagsProvider);
    final mediaTags = ref.watch(tagsForMediaProvider(widget.mediaId));

    // Seed the ticks from the item's stored tags the first time they arrive.
    final current = mediaTags.valueOrNull;
    if (_selected == null && current != null) {
      _selected = current.map((t) => t.id).toSet();
    }

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.tagSheetTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          allTags.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(l10n.tagErrorFailed),
            data: (tags) => _TagWrap(
              tags: tags,
              selected: _selected ?? const <String>{},
              onToggle: _toggle,
              emptyLabel: l10n.filterNoTags,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _newTagController,
                  decoration: InputDecoration(
                    hintText: l10n.tagSheetNewHint,
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTypedTag(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                onPressed: _addTypedTag,
                child: Text(l10n.tagSheetAdd),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveAndClose,
              child: Text(l10n.tagSheetDone),
            ),
          ),
        ],
      ),
    );
  }

  void _toggle(String tagId) {
    final next = <String>{...?_selected};
    if (!next.remove(tagId)) next.add(tagId);
    setState(() => _selected = next);
  }

  /// Makes the typed tag if needed and ticks it.
  Future<void> _addTypedTag() async {
    final name = TagNameRules.normalize(_newTagController.text);
    if (name.isEmpty) return;

    // Find-or-create, so typing a name that already exists ticks that tag
    // rather than failing on the unique-name rule.
    final tag = await ref
        .read(tagEditControllerProvider.notifier)
        .findOrCreate(name);
    if (tag == null || !mounted) return;

    _newTagController.clear();
    setState(() => _selected = <String>{...?_selected, tag.id});
  }

  Future<void> _saveAndClose() async {
    final selected = _selected;
    if (selected != null) {
      await ref
          .read(tagEditControllerProvider.notifier)
          .setTagsForMedia(widget.mediaId, selected);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

/// The ticked and unticked chips, or a note when there are no tags at all.
class _TagWrap extends StatelessWidget {
  final List<Tag> tags;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String emptyLabel;

  const _TagWrap({
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final tag in tags)
              TagChip(
                tag: tag,
                selected: selected.contains(tag.id),
                onTap: () => onToggle(tag.id),
              ),
          ],
        ),
      ),
    );
  }
}
