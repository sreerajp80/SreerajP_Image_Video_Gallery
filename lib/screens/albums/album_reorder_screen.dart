import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_media_grid.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';

/// Rearranges one album's items at `/albums/:id/reorder`.
///
/// A list rather than a draggable grid, and a screen of its own rather than a
/// mode on the album screen. A reorderable grid nested in a scrolling grid is
/// where this kind of screen usually goes wrong, and a plain list makes the
/// drag target obvious.
class AlbumReorderScreen extends ConsumerStatefulWidget {
  final String albumId;

  const AlbumReorderScreen({super.key, required this.albumId});

  @override
  ConsumerState<AlbumReorderScreen> createState() => _AlbumReorderScreenState();
}

class _AlbumReorderScreenState extends ConsumerState<AlbumReorderScreen> {
  /// The working order, or null until the stored order has been read.
  ///
  /// Held here rather than written on every drag so a user who drags around
  /// and then leaves has changed nothing.
  List<MediaItem>? _items;

  void _move(int oldIndex, int newIndex) {
    final items = _items;
    if (items == null) return;

    setState(() {
      final next = <MediaItem>[...items];
      // `onReorderItem` already accounts for the dragged row leaving its old
      // slot, so the index needs no shifting of its own here.
      next.insert(newIndex, next.removeAt(oldIndex));
      _items = next;
    });
  }

  Future<void> _save() async {
    final items = _items;
    if (items == null) return;

    final l10n = AppLocalizations.of(context)!;
    await ref
        .read(albumEditControllerProvider.notifier)
        .setOrder(widget.albumId, items.map((i) => i.id).toList());
    if (!mounted) return;

    final failed = ref.read(albumEditControllerProvider).hasError;
    final messenger = ScaffoldMessenger.of(context);
    if (!failed) context.pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(failed ? l10n.albumErrorFailed : l10n.albumOrderSaved),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = ref.watch(albumMediaProvider(widget.albumId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.albumReorderTitle)),
      body: SafeArea(
        child: media.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => const AlbumErrorState(),
          data: (loaded) {
            // The stored order seeds the working list once; re-seeding on every
            // rebuild would undo each drag as it happened.
            _items ??= loaded;
            final items = _items!;
            if (items.isEmpty) {
              return AlbumErrorState(message: l10n.albumEmptyTitle);
            }

            return Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.albumReorderHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    onReorderItem: _move,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ListTile(
                        key: ValueKey<String>(item.id),
                        leading: MediaThumbnail(item: item, size: 48),
                        title: Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: ReorderableDragStartListener(
                          index: index,
                          child: const Icon(Icons.drag_handle),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _items == null ? null : _save,
        icon: const Icon(Icons.check),
        label: Text(l10n.albumReorderSave),
      ),
    );
  }
}
