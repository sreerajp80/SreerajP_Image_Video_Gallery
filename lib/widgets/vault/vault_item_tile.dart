import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';

/// One tile in the vault grid.
///
/// The preview is decrypted into memory and shown with [Image.memory]. It is
/// never written anywhere, and it is dropped when the tile is disposed or the
/// vault locks, so a shut vault leaves no readable picture behind.
///
/// A preview that will not decrypt shows a type icon instead. It is a
/// cosmetic loss, and hiding the item over it would be worse — the item is
/// still there and still has to be reachable.
class VaultItemTile extends ConsumerWidget {
  /// The record this tile shows.
  final VaultItem item;

  /// Whether it is currently selected.
  final bool isSelected;

  /// Whether the grid is in selection mode.
  final bool selectionMode;

  /// Called on a tap.
  final VoidCallback onTap;

  /// Called on a long press.
  final VoidCallback onLongPress;

  const VaultItemTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onLongPress,
    this.isSelected = false,
    this.selectionMode = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final thumbnail = ref.watch(vaultThumbnailProvider(item.id));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: thumbnail.when(
              data: (bytes) => bytes == null
                  ? _FallbackIcon(mediaType: item.mediaType)
                  : Image.memory(
                      bytes,
                      fit: BoxFit.cover,
                      // A preview that will not decode must not throw inside
                      // a grid; it falls back like a missing one.
                      errorBuilder: (_, _, _) =>
                          _FallbackIcon(mediaType: item.mediaType),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => _FallbackIcon(mediaType: item.mediaType),
            ),
          ),
          if (item.mediaType == MediaType.video)
            const Positioned(
              right: 4,
              bottom: 4,
              child: Icon(
                Icons.play_circle_fill,
                size: 20,
                color: Colors.white70,
              ),
            ),
          if (selectionMode)
            Positioned(
              left: 4,
              top: 4,
              child: Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 22,
                color: isSelected ? scheme.primary : Colors.white70,
              ),
            ),
          if (isSelected)
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.primary, width: 3),
              ),
            ),
        ],
      ),
    );
  }
}

/// What a tile shows when there is no usable preview.
class _FallbackIcon extends StatelessWidget {
  final MediaType mediaType;

  const _FallbackIcon({required this.mediaType});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        mediaType == MediaType.video
            ? Icons.movie_outlined
            : Icons.image_outlined,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
