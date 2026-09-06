import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_card.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_edit_dialog.dart';

/// The albums screen at `/albums`.
///
/// Three sections in one scroll: the user's own albums, the smart albums, and
/// the device's folders. Each section has its own provider, so a slow one
/// cannot hold up the others.
class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final virtual = ref.watch(virtualAlbumsProvider);
    final smart = ref.watch(smartAlbumsProvider);
    final folders = ref.watch(deviceFolderAlbumsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.albumsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.albumNew),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: <Widget>[
            _Section(
              title: l10n.albumsSectionMine,
              albums: virtual,
              emptyTitle: l10n.albumsEmptyTitle,
              emptyBody: l10n.albumsEmptyBody,
              onTap: (album) => context.push(albumPath(album.id)),
              onLongPress: (album) => _showMenu(context, ref, album),
            ),
            _Section(
              title: l10n.albumsSectionSmart,
              albums: smart,
              onTap: (album) {
                if (album.albumType == AlbumType.smartTrash) {
                  context.push(kRouteTrash);
                } else {
                  context.push(smartAlbumPath(album.id));
                }
              },
            ),
            _Section(
              title: l10n.albumsSectionFolders,
              albums: folders,
              emptyTitle: l10n.albumsFoldersEmpty,
              onTap: (album) => context.push(folderAlbumPath(album.id)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final existing =
        ref.read(virtualAlbumsProvider).valueOrNull ?? const <AlbumSummary>[];
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          AlbumEditDialog(existingNames: existing.map((a) => a.name).toList()),
    );
    if (name == null) return;

    await ref.read(albumEditControllerProvider.notifier).create(name);
    if (context.mounted) _reportFailure(context, ref);
  }

  /// The album menu, opened by holding a card.
  Future<void> _showMenu(
    BuildContext context,
    WidgetRef ref,
    AlbumSummary album,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: Text(l10n.albumRename),
              onTap: () => Navigator.of(sheetContext).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(l10n.albumPin),
              onTap: () => Navigator.of(sheetContext).pop('pin'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.albumDelete),
              onTap: () => Navigator.of(sheetContext).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (action == null || !context.mounted) return;

    switch (action) {
      case 'rename':
        await _rename(context, ref, album);
      case 'pin':
        await ref
            .read(albumEditControllerProvider.notifier)
            .setPinned(album.id, true);
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

    await ref.read(albumEditControllerProvider.notifier).rename(album.id, name);
    if (context.mounted) _reportFailure(context, ref);
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
    if (confirmed != true) return;

    await ref.read(albumEditControllerProvider.notifier).delete(album.id);
    if (!context.mounted) return;

    final failed = ref.read(albumEditControllerProvider).hasError;
    ScaffoldMessenger.of(context).showSnackBar(
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

/// One titled row of album cards.
class _Section extends StatelessWidget {
  final String title;
  final AsyncValue<List<AlbumSummary>> albums;
  final String? emptyTitle;
  final String? emptyBody;
  final void Function(AlbumSummary album) onTap;
  final void Function(AlbumSummary album)? onLongPress;

  const _Section({
    required this.title,
    required this.albums,
    required this.onTap,
    this.emptyTitle,
    this.emptyBody,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        albums.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              l10n.albumsLoadFailed,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
          data: (list) {
            if (list.isEmpty) return _empty(context);
            return SizedBox(
              height: 172,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: list.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AlbumCard(
                    summary: list[index],
                    onTap: () => onTap(list[index]),
                    onLongPress: onLongPress == null
                        ? null
                        : () => onLongPress!(list[index]),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    final title = emptyTitle;
    if (title == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.bodyLarge),
          if (emptyBody != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              emptyBody!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
