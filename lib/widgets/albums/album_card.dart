import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// Translates a smart album's route key into its shown name.
///
/// The repository leaves the key in place because it has no access to
/// [AppLocalizations], so the translation happens at the edge, here.
String smartAlbumLabel(AppLocalizations l10n, AlbumType type) {
  return switch (type) {
    AlbumType.smartFavorites => l10n.smartAlbumFavorites,
    AlbumType.smartVideos => l10n.smartAlbumVideos,
    AlbumType.smartGifs => l10n.smartAlbumGifs,
    AlbumType.smartRaw => l10n.smartAlbumRaw,
    AlbumType.smartPanoramas => l10n.smartAlbumPanoramas,
    AlbumType.smartRecentlyAdded => l10n.smartAlbumRecent,
    AlbumType.smartTrash => l10n.smartAlbumTrash,
    _ => '',
  };
}

/// The name to draw for any album row.
String albumDisplayName(AppLocalizations l10n, AlbumSummary summary) {
  return summary.needsLocalizedName
      ? smartAlbumLabel(l10n, summary.albumType)
      : summary.name;
}

/// One album in the albums grid.
///
/// Draws the cover through [MediaThumbnail], so the thumbnail cache and the
/// corrupt-file fallback both apply here without any handling of its own.
class AlbumCard extends StatelessWidget {
  final AlbumSummary summary;

  /// Side length of the square cover.
  final double size;

  final VoidCallback? onTap;

  /// Called on a long press, used by the albums screen for the album menu.
  final VoidCallback? onLongPress;

  const AlbumCard({
    super.key,
    required this.summary,
    this.size = 120,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final name = albumDisplayName(l10n, summary);
    final cover = summary.coverItem;

    return Semantics(
      button: onTap != null,
      label: '$name, ${l10n.albumItemCount(summary.itemCount)}',
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: size,
                height: size,
                child: cover == null
                    ? _EmptyCover(size: size, albumType: summary.albumType)
                    : MediaThumbnail(item: cover, size: size, borderRadius: 12),
              ),
              const SizedBox(height: 6),
              // A user-made album carries whatever name was typed, and a
              // folder album carries a name off the file system. Either can
              // be in any script, so the label follows the name itself.
              AdaptiveDirectionality(
                text: name,
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Text(
                l10n.albumItemCount(summary.itemCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What an album with nothing in it shows instead of a cover.
class _EmptyCover extends StatelessWidget {
  final double size;
  final AlbumType albumType;

  const _EmptyCover({required this.size, required this.albumType});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _iconFor(albumType),
        size: size * 0.35,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  IconData _iconFor(AlbumType type) {
    return switch (type) {
      AlbumType.smartFavorites => Icons.star_outline,
      AlbumType.smartVideos => Icons.movie_outlined,
      AlbumType.smartGifs => Icons.gif_box_outlined,
      AlbumType.smartRaw => Icons.raw_on_outlined,
      AlbumType.smartPanoramas => Icons.panorama_wide_angle_outlined,
      AlbumType.smartRecentlyAdded => Icons.schedule_outlined,
      AlbumType.physicalFolder => Icons.folder_outlined,
      _ => Icons.photo_album_outlined,
    };
  }
}
