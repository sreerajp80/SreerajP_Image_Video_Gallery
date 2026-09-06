import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_chip.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_edit_dialog.dart';

/// The tag management screen at `/tags`.
class TagsScreen extends ConsumerWidget {
  const TagsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tags = ref.watch(allTagsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.tagsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.tagNew),
      ),
      body: SafeArea(
        child: tags.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.tagErrorFailed)),
          data: (list) => list.isEmpty
              ? _EmptyState(
                  title: l10n.tagsEmptyTitle,
                  body: l10n.tagsEmptyBody,
                )
              : ListView.separated(
                  // Room under the last row so the button never covers it.
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => _TagRow(
                    tag: list[index],
                    onEdit: () => _edit(context, ref, list[index], list),
                    onDelete: () => _confirmDelete(context, ref, list[index]),
                    onShowMedia: () =>
                        context.push(searchPathForTag(list[index].id)),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final existing = ref.read(allTagsProvider).valueOrNull ?? const <Tag>[];
    final result = await showDialog<TagEditResult>(
      context: context,
      builder: (_) =>
          TagEditDialog(existingNames: existing.map((t) => t.name).toList()),
    );
    if (result == null) return;

    await ref
        .read(tagEditControllerProvider.notifier)
        .create(result.name, colorValue: result.colorValue);
    if (context.mounted) _reportFailure(context, ref);
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
    List<Tag> existing,
  ) async {
    final result = await showDialog<TagEditResult>(
      context: context,
      builder: (_) => TagEditDialog(
        tag: tag,
        existingNames: existing.map((t) => t.name).toList(),
      ),
    );
    if (result == null) return;

    final controller = ref.read(tagEditControllerProvider.notifier);
    if (result.name != tag.name) {
      await controller.rename(tag.id, result.name);
    }
    if (result.colorValue != tag.colorValue) {
      await controller.setColor(tag.id, result.colorValue);
    }
    if (context.mounted) _reportFailure(context, ref);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Tag tag,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.tagDeleteTitle),
        content: Text(l10n.tagDeleteBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.tagCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.tagDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(tagEditControllerProvider.notifier).delete(tag.id);
    if (context.mounted) _reportFailure(context, ref);
  }

  /// Shows a message when the last tag change failed.
  void _reportFailure(BuildContext context, WidgetRef ref) {
    final state = ref.read(tagEditControllerProvider);
    if (!state.hasError) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.tagErrorFailed)));
  }
}

/// One row of the tag list.
class _TagRow extends StatelessWidget {
  final Tag tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShowMedia;

  const _TagRow({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
    required this.onShowMedia,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = Color(TagColorPalette.resolve(tag.colorValue, tag.name));

    return ListTile(
      leading: TagColorDot(color: color, size: 20),
      title: Text(tag.name),
      subtitle: Text(l10n.tagItemCount(tag.itemCount)),
      onTap: onShowMedia,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            tooltip: l10n.tagEditTitle,
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: l10n.tagDelete,
            icon: const Icon(Icons.delete_outline),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

/// Shown when no tag has been made yet.
class _EmptyState extends StatelessWidget {
  final String title;
  final String body;

  const _EmptyState({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.label_outline,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
