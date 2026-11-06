import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/sized_memory_image.dart';

/// Shows the cached thumbnail for one media item.
///
/// The widget only reads a provider: no file I/O, no database, and no platform
/// call happens here. When no thumbnail can be produced it shows a placeholder
/// instead of failing, which keeps a corrupt file from breaking the grid.
class MediaThumbnail extends ConsumerWidget {
  final MediaItem item;

  /// Side length of the square tile, or null to fill parent constraints.
  final double? size;

  /// Corner radius of the tile.
  final double borderRadius;

  const MediaThumbnail({
    super.key,
    required this.item,
    this.size,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thumbnail = ref.watch(thumbnailProvider(item));
    final colorScheme = Theme.of(context).colorScheme;

    Widget child = thumbnail.when(
      data: (bytes) {
        if (bytes == null || bytes.isEmpty) {
          return _Placeholder(
            icon: Icons.broken_image_outlined,
            colorScheme: colorScheme,
            label: AppLocalizations.of(context)!.labelMediaUnavailable,
          );
        }
        return SizedMemoryImage(
          bytes,
          width: size,
          height: size,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => _Placeholder(
            icon: Icons.broken_image_outlined,
            colorScheme: colorScheme,
            label: AppLocalizations.of(context)!.labelMediaUnavailable,
          ),
        );
      },
      loading: () => ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (error, stackTrace) => _Placeholder(
        icon: Icons.broken_image_outlined,
        colorScheme: colorScheme,
        label: AppLocalizations.of(context)!.labelMediaUnavailable,
      ),
    );

    if (size != null) {
      child = SizedBox(width: size, height: size, child: child);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: child,
    );
  }
}

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final ColorScheme colorScheme;
  final String label;

  const _Placeholder({
    required this.icon,
    required this.colorScheme,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: ColoredBox(
        color: colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
