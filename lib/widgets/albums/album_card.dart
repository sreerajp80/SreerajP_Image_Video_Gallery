import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/unit_format_context.dart';

/// Translates a smart album's route key into its shown name.
///
/// The repository leaves the key in place because it has no access to
/// [AppLocalizations], so the translation happens at the edge, here.
String smartAlbumLabel(AppLocalizations l10n, AlbumType type) {
  return switch (type) {
    AlbumType.smartFavorites => l10n.labelSmartAlbumFavorites,
    AlbumType.smartVideos => l10n.labelSmartAlbumVideos,
    AlbumType.smartGifs => l10n.labelSmartAlbumGifs,
    AlbumType.smartRaw => l10n.labelSmartAlbumRaw,
    AlbumType.smartPanoramas => l10n.labelSmartAlbumPanoramas,
    AlbumType.smartRecentlyAdded => l10n.labelSmartAlbumRecent,
    AlbumType.smartTrash => l10n.labelSmartAlbumTrash,
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

  /// Side length of the square cover. When null or non-finite, the cover fills
  /// the available width with a 1:1 aspect ratio, ideal for grid layouts.
  final double? size;

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

    final hasFiniteSize = size != null && size!.isFinite;
    final sizeText = summary.totalBytes > 0
        ? context.units.bytes(summary.totalBytes)
        : null;
    final coverImage = hasFiniteSize
        ? SizedBox(
            width: size,
            height: size,
            child: cover == null
                ? _EmptyCover(size: size, albumType: summary.albumType)
                : MediaThumbnail(item: cover, size: size, borderRadius: 12),
          )
        : AspectRatio(
            aspectRatio: 1.0,
            child: cover == null
                ? _EmptyCover(albumType: summary.albumType)
                : MediaThumbnail(item: cover, borderRadius: 12),
          );
    final coverWidget = sizeText == null
        ? coverImage
        : Stack(
            children: <Widget>[
              coverImage,
              PositionedDirectional(
                top: 6,
                start: 6,
                child: _SizeBadge(label: sizeText),
              ),
            ],
          );
    final itemCountText = l10n.descAlbumItemCount(summary.itemCount);

    return Semantics(
      button: onTap != null,
      label: sizeText == null
          ? '$name, $itemCountText'
          : '$name, $itemCountText, $sizeText',
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
              coverWidget,
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
                itemCountText,
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

/// The total size drawn over the top-start corner of the cover.
///
/// A dark see-through pill with white text, the same idea as the badges on
/// media tiles, so it stays readable over bright and dark covers alike. The
/// card's own [Semantics] label already reads the size, so the pill is hidden
/// from screen readers to avoid reading it twice.
class _SizeBadge extends StatelessWidget {
  final String label;

  const _SizeBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Colors.white,
      fontWeight: FontWeight.w600,
      height: 1.2,
    );

    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Text(label, maxLines: 1, softWrap: false, style: style),
        ),
      ),
    );
  }
}

/// What an album with nothing in it shows instead of a cover.
class _EmptyCover extends StatelessWidget {
  final double? size;
  final AlbumType albumType;

  const _EmptyCover({this.size, required this.albumType});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasFiniteSize = size != null && size!.isFinite;

    return Container(
      width: hasFiniteSize ? size : null,
      height: hasFiniteSize ? size : null,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final iconDimension = hasFiniteSize
              ? size!
              : (constraints.maxWidth.isFinite ? constraints.maxWidth : 120.0);
          return Icon(
            _iconFor(albumType),
            size: iconDimension * 0.35,
            color: colorScheme.onSurfaceVariant,
          );
        },
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
