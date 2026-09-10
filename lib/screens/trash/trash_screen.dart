import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_media_grid.dart';

/// Shows every item the user has moved to the trash.
///
/// The app bar offers bulk restore and emptying actions. Tapping or long-pressing
/// an item lets the user restore it or permanently delete it from the device.
class TrashScreen extends ConsumerWidget {
  const TrashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final trashMedia = ref.watch(trashMediaProvider);
    final trashCount = ref.watch(trashCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trashTitle),
        actions: <Widget>[
          if (trashCount.valueOrNull != null &&
              trashCount.valueOrNull! > 0) ...<Widget>[
            IconButton(
              onPressed: () => _confirmRestoreAll(context, ref),
              icon: const Icon(Icons.restore),
              tooltip: l10n.trashRestoreAllAction,
            ),
            IconButton(
              onPressed: () => _confirmEmptyTrash(context, ref),
              icon: const Icon(Icons.delete_forever),
              tooltip: l10n.trashEmptyAction,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: trashMedia.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.trashEmpty)),
          data: (items) {
            if (items.isEmpty) {
              return _TrashEmptyState(l10n: l10n);
            }
            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.trashItemCount(items.length),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: AlbumMediaGrid(
                    items: items,
                    emptyTitle: l10n.trashEmpty,
                    onItemLongPress: (item) =>
                        _showItemOptions(context, ref, item),
                    onItemTap: (item) => _showItemOptions(context, ref, item),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Shows actions for a specific trashed item.
  Future<void> _showItemOptions(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final thumbnailAsync = ref.read(thumbnailProvider(item));
    final thumbBytes = thumbnailAsync.valueOrNull;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: thumbBytes != null
                          ? Image.memory(thumbBytes, fit: BoxFit.cover)
                          : Container(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: Icon(
                                item.isVideo ? Icons.videocam : Icons.photo,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSize(item.size),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.fullscreen),
              title: Text(l10n.editorOpen),
              onTap: () {
                Navigator.of(sheetContext).pop();
                context.push(mediaViewerPath(item.id));
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: Text(l10n.trashRestoreAction),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await ref
                    .read(trashControllerProvider.notifier)
                    .restoreItem(item.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.trashRestoredSnackbar)),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_forever,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                l10n.trashDeletePermanentlyAction,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _confirmDeletePermanently(context, ref, item);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Asks before permanently deleting a single item from the phone storage.
  Future<void> _confirmDeletePermanently(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(l10n.trashDeletePermanentlyConfirmTitle),
        content: Text(l10n.trashDeletePermanentlyConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trashDeletePermanentlyAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final success = await ref
        .read(trashControllerProvider.notifier)
        .deletePermanently(item);
    if (success) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashDeletedPermanentlySnackbar)),
      );
    }
  }

  static String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Asks before restoring every item back to the library.
  Future<void> _confirmRestoreAll(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.trashRestoreAllAction),
        content: Text(l10n.trashRestoreAllConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trashRestoreAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final count = await ref.read(trashControllerProvider.notifier).restoreAll();
    if (count > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashRestoredSnackbar)),
      );
    }
  }

  /// Asks before permanently removing trashed items from the database and device.
  Future<void> _confirmEmptyTrash(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(l10n.trashEmptyConfirmTitle),
        content: Text(l10n.trashEmptyConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.settingsCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.trashEmptyAction),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final count = await ref.read(trashControllerProvider.notifier).emptyTrash();
    if (count > 0) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.trashEmptiedSnackbar)),
      );
    }
  }
}

/// A centered empty state shown when the trash holds no items.
class _TrashEmptyState extends StatelessWidget {
  final AppLocalizations l10n;

  const _TrashEmptyState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.delete_outline,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.trashEmpty,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trashEmptySubtitle,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.7,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
