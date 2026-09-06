import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';

/// One candidate copy, shown beside the others.
///
/// The facts under the picture are the ones the keeper is chosen on, in the
/// same order the scoring uses them, so a user can see for themselves why one
/// copy was suggested over another.
class ComparisonPane extends StatelessWidget {
  /// The copy being shown.
  final MediaItem item;

  /// Whether this is the copy the user has chosen to keep.
  final bool isKeeper;

  /// Whether this is the copy the app suggested.
  final bool isSuggested;

  /// Chooses this copy as the one to keep.
  final VoidCallback onKeep;

  /// Width of the pane.
  final double width;

  const ComparisonPane({
    super.key,
    required this.item,
    required this.isKeeper,
    required this.isSuggested,
    required this.onKeep,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isKeeper
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isKeeper ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              children: <Widget>[
                MediaThumbnail(item: item, size: width, borderRadius: 0),
                if (isSuggested)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _Badge(label: l10n.compareBestBadge),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    item.displayName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  _Fact(label: l10n.compareFieldPixels, value: _pixels(l10n)),
                  _Fact(
                    label: l10n.compareFieldSize,
                    value: formatFileSize(item.size),
                  ),
                  _Fact(
                    label: l10n.compareFieldDate,
                    value: item.dateTaken == null
                        ? l10n.compareUnknown
                        : formatDetailDate(context, item.dateTaken!),
                  ),
                  _Fact(label: l10n.compareFieldCamera, value: _camera(l10n)),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: isKeeper
                        ? FilledButton.icon(
                            onPressed: null,
                            icon: const Icon(Icons.check),
                            label: Text(l10n.compareKeepThis),
                          )
                        : OutlinedButton(
                            onPressed: onKeep,
                            child: Text(l10n.compareKeepThis),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pixels(AppLocalizations l10n) {
    final width = item.width;
    final height = item.height;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return l10n.compareUnknown;
    }
    return '$width x $height';
  }

  String _camera(AppLocalizations l10n) {
    final exif = item.exifData;
    if (exif == null) return l10n.compareUnknown;
    final parts = <String>[
      if (exif.make != null && exif.make!.isNotEmpty) exif.make!,
      if (exif.model != null && exif.model!.isNotEmpty) exif.model!,
    ];
    if (parts.isEmpty) return l10n.compareUnknown;
    return parts.join(' ');
  }
}

/// One label and value row under the picture.
class _Fact extends StatelessWidget {
  final String label;
  final String value;

  const _Fact({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 68,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The "suggested" marker over the best copy.
class _Badge extends StatelessWidget {
  final String label;

  const _Badge({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
