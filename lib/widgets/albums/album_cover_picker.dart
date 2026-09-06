import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';

/// Picks which of an album's own items covers it.
///
/// Only the album's members are offered: a cover that is not in the album
/// would go blank the moment that photo left the library.
class AlbumCoverPicker extends ConsumerWidget {
  final String albumId;

  const AlbumCoverPicker({super.key, required this.albumId});

  /// Opens the chooser and applies whatever the user picks.
  static Future<void> show(BuildContext context, String albumId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AlbumCoverPicker(albumId: albumId),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    String? mediaId,
  ) async {
    final navigator = Navigator.of(context);
    await ref
        .read(albumEditControllerProvider.notifier)
        .setCover(albumId, mediaId);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final failed = ref.read(albumEditControllerProvider).hasError;
    final messenger = ScaffoldMessenger.of(context);
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed ? l10n.albumErrorFailed : l10n.albumCoverSet),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final media = ref.watch(albumMediaProvider(albumId));

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.albumCoverTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Flexible(
              child: media.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(l10n.albumsLoadFailed),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Text(l10n.albumEmptyTitle),
                    );
                  }
                  return GridView.builder(
                    shrinkWrap: true,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 110,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => MediaGridTile(
                      item: items[index],
                      size: 110,
                      onTap: (item) => _choose(context, ref, item.id),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _choose(context, ref, null),
                child: Text(l10n.albumCoverClear),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
