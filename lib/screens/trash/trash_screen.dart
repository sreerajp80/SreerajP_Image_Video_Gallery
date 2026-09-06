import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_media_grid.dart';

/// Shows every item the user has moved to the trash.
///
/// The app bar offers two bulk actions — restore all and empty trash — and the
/// grid lets the user browse or select items for per-item restore. Nothing here
/// touches the original files on disk: "empty trash" removes the rows from the
/// app's database, and a future scan would index the same files again.
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
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

  /// Asks before permanently removing trashed items from the database.
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
