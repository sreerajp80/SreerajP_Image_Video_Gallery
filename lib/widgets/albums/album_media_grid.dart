import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';

/// The media grid shared by the album, folder, and smart album screens.
///
/// All three show the same thing — a grid of items that opens the viewer — and
/// differ only in where the list comes from and what the app bar offers. Only
/// the list is passed in.
///
/// When [selectable] is true the grid supports the same multi-select
/// behaviour as the timeline: long-press to start selecting, taps toggle
/// during selection mode, and every tile shows a check mark when ticked.
class AlbumMediaGrid extends ConsumerWidget {
  final List<MediaItem> items;

  /// Shown in place of the grid when there is nothing to draw.
  final String emptyTitle;

  /// Extra explanation under [emptyTitle].
  final String? emptyBody;

  /// Called when a tile is held, used by the album screen for its item menu.
  ///
  /// Ignored when [selectable] is true and the grid is in selection mode —
  /// long-press then toggles selection instead.
  final void Function(MediaItem item)? onItemLongPress;

  /// Called when a tile is tapped. When null, opens the media viewer.
  final void Function(MediaItem item)? onItemTap;

  /// Whether the grid supports multi-select and batch actions.
  final bool selectable;

  const AlbumMediaGrid({
    super.key,
    required this.items,
    required this.emptyTitle,
    this.emptyBody,
    this.onItemLongPress,
    this.onItemTap,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _EmptyState(title: emptyTitle, body: emptyBody);
    }

    // The same column count the timeline uses, so the whole app keeps one grid
    // density rather than each screen picking its own.
    final columns = ref.watch(gridColumnCountProvider);
    final selected = selectable
        ? ref.watch(selectionProvider)
        : const <String>{};
    final selecting = selected.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 2.0;
        final tileSize =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return GridView.builder(
          padding: const EdgeInsets.only(bottom: 88),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return MediaGridTile(
              item: item,
              size: tileSize,
              semanticLabel: item.displayName,
              isSelected: selectable ? selected.contains(item.id) : false,
              selectionMode: selectable ? selecting : false,
              onTap: (tapped) {
                if (selectable && selecting) {
                  ref.read(selectionProvider.notifier).toggle(tapped.id);
                  return;
                }
                if (onItemTap != null) {
                  onItemTap!(tapped);
                } else {
                  context.push(mediaViewerPath(tapped.id));
                }
              },
              onLongPress: (tapped) {
                if (selectable) {
                  final selection = ref.read(selectionProvider.notifier);
                  if (!selection.contains(tapped.id) && selection.isFull) {
                    final l10n = AppLocalizations.of(context)!;
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.selectionFull)));
                    return;
                  }
                  selection.toggle(tapped.id);
                  return;
                }
                if (onItemLongPress != null) {
                  onItemLongPress!(tapped);
                }
              },
            );
          },
        );
      },
    );
  }
}

/// What a screen shows when it has nothing to draw.
class _EmptyState extends StatelessWidget {
  final String title;
  final String? body;

  const _EmptyState({required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.photo_library_outlined,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small error state the album screens share.
class AlbumErrorState extends StatelessWidget {
  final String? message;

  const AlbumErrorState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              message ?? l10n.albumsLoadFailed,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
