import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';

/// The media grid shared by the album, folder, and smart album screens.
///
/// All three show the same thing — a grid of items that opens the viewer — and
/// differ only in where the list comes from and what the app bar offers. Only
/// the list is passed in.
class AlbumMediaGrid extends ConsumerWidget {
  final List<MediaItem> items;

  /// Shown in place of the grid when there is nothing to draw.
  final String emptyTitle;

  /// Extra explanation under [emptyTitle].
  final String? emptyBody;

  /// Called when a tile is held, used by the album screen for its item menu.
  final void Function(MediaItem item)? onItemLongPress;

  const AlbumMediaGrid({
    super.key,
    required this.items,
    required this.emptyTitle,
    this.emptyBody,
    this.onItemLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return _EmptyState(title: emptyTitle, body: emptyBody);
    }

    // The same column count the timeline uses, so the whole app keeps one grid
    // density rather than each screen picking its own.
    final columns = ref.watch(gridColumnCountProvider);

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
            return GestureDetector(
              onLongPress: onItemLongPress == null
                  ? null
                  : () => onItemLongPress!(item),
              child: MediaGridTile(
                item: item,
                size: tileSize,
                semanticLabel: item.displayName,
                onTap: (tapped) => context.push(mediaViewerPath(tapped.id)),
              ),
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
