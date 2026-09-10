import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_cover_picker.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_edit_dialog.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_media_grid.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_action_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/selection_app_bar.dart';

/// One user-made album at `/albums/:id`.
///
/// Supports multi-select and batch actions via [SelectionAppBar] and
/// [BatchActionBar], the same way the timeline does.
class AlbumMediaScreen extends ConsumerWidget {
  final String albumId;

  const AlbumMediaScreen({super.key, required this.albumId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(albumSummaryProvider(albumId));
    final media = ref.watch(albumMediaProvider(albumId));
    final selecting = ref.watch(selectionModeProvider);

    // Build visible ids for the select-all button.
    final visibleIds =
        media.valueOrNull?.map((item) => item.id).toList(growable: false) ??
        const <String>[];

    return Scaffold(
      appBar: selecting
          ? SelectionAppBar(visibleIds: visibleIds)
          : AppBar(
              title: Text(summary.valueOrNull?.name ?? l10n.albumsTitle),
              actions: <Widget>[
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _onAction(context, ref, action, summary),
                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'rename',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.drive_file_rename_outline),
                        title: Text(l10n.albumRename),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'cover',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.image_outlined),
                        title: Text(l10n.albumChooseCover),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'reorder',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.swap_vert),
                        title: Text(l10n.albumReorder),
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.delete_outline),
                        title: Text(l10n.albumDelete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
      bottomNavigationBar: selecting ? const BatchActionBar() : null,
      body: SafeArea(
        child: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const AlbumErrorState(),
          data: (album) {
            if (album == null) return AlbumErrorState(message: l10n.albumGone);
            return media.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => const AlbumErrorState(),
              data: (items) => AlbumMediaGrid(
                items: items,
                emptyTitle: l10n.albumEmptyTitle,
                emptyBody: l10n.albumEmptyBody,
                selectable: true,
                onItemLongPress: (item) => _confirmRemove(context, ref, item),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    AsyncValue<AlbumSummary?> summary,
  ) async {
    final album = summary.valueOrNull;
    if (album == null) return;

    switch (action) {
      case 'rename':
        await _rename(context, ref, album);
      case 'cover':
        await AlbumCoverPicker.show(context, albumId);
      case 'reorder':
        if (context.mounted) context.push(albumReorderPath(albumId));
      case 'delete':
        await _confirmDelete(context, ref, album);
    }
  }

  Future<void> _rename(
    BuildContext context,
    WidgetRef ref,
    AlbumSummary album,
  ) async {
    final existing =
        ref.read(virtualAlbumsProvider).valueOrNull ?? const <AlbumSummary>[];
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlbumEditDialog(
        currentName: album.name,
        existingNames: existing.map((a) => a.name).toList(),
      ),
    );
    if (name == null) return;

    await ref.read(albumEditControllerProvider.notifier).rename(albumId, name);
    if (context.mounted) _reportFailure(context, ref);
  }

  /// Takes one item out of the album. The file itself is untouched.
  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    MediaItem item,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.remove_circle_outline),
          title: Text(l10n.albumRemoveMedia),
          subtitle: Text(item.displayName),
          onTap: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref
        .read(albumEditControllerProvider.notifier)
        .removeMedia(albumId, item.id);
    if (!context.mounted) return;

    final failed = ref.read(albumEditControllerProvider).hasError;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed ? l10n.albumErrorFailed : l10n.albumRemovedFromAlbum,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AlbumSummary album,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.albumDeleteConfirmTitle(album.name)),
        content: Text(l10n.albumDeleteConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.albumCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.albumDeleteConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await ref.read(albumEditControllerProvider.notifier).delete(albumId);
    if (!context.mounted) return;

    final failed = ref.read(albumEditControllerProvider).hasError;
    final messenger = ScaffoldMessenger.of(context);
    if (!failed) context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed ? l10n.albumErrorFailed : l10n.albumDeleted),
      ),
    );
  }

  void _reportFailure(BuildContext context, WidgetRef ref) {
    if (!ref.read(albumEditControllerProvider).hasError) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.albumErrorFailed)));
  }
}
