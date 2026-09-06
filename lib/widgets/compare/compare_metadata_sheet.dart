import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';

/// Bottom sheet displaying side-by-side technical metadata and camera EXIF
/// attributes for Photo A and Photo B.
class CompareMetadataSheet extends ConsumerWidget {
  final MediaItem itemA;
  final MediaItem itemB;

  const CompareMetadataSheet({
    super.key,
    required this.itemA,
    required this.itemB,
  });

  /// Displays the comparison sheet.
  static Future<void> show(
    BuildContext context, {
    required MediaItem itemA,
    required MediaItem itemB,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => CompareMetadataSheet(itemA: itemA, itemB: itemB),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final exifA = ref.watch(mediaExifProvider(itemA)).valueOrNull;
    final exifB = ref.watch(mediaExifProvider(itemB)).valueOrNull;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.35,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Row(
              children: [
                const Icon(Icons.tune_outlined),
                const SizedBox(width: 12),
                Text(
                  l10n.compareDetails,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Header row: Photo A vs Photo B
            Row(
              children: [
                const Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.comparePhotoA,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 8,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      l10n.comparePhotoB,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CompareRow(
              label: l10n.detailsFileName,
              valA: itemA.displayName,
              valB: itemB.displayName,
            ),
            _CompareRow(
              label: l10n.compareDimensions,
              valA: itemA.width != null && itemA.height != null
                  ? '${itemA.width} × ${itemA.height} (${_megapixels(itemA.width!, itemA.height!)})'
                  : '—',
              valB: itemB.width != null && itemB.height != null
                  ? '${itemB.width} × ${itemB.height} (${_megapixels(itemB.width!, itemB.height!)})'
                  : '—',
            ),
            _CompareRow(
              label: l10n.compareFileSize,
              valA: formatFileSize(itemA.size),
              valB: formatFileSize(itemB.size),
            ),
            _CompareRow(
              label: l10n.detailsFormat,
              valA: itemA.mimeType,
              valB: itemB.mimeType,
            ),
            _CompareRow(
              label: l10n.compareDateTaken,
              valA: formatDetailDate(context, itemA.effectiveDate),
              valB: formatDetailDate(context, itemB.effectiveDate),
            ),
            const Divider(height: 24),
            _CompareRow(
              label: l10n.compareCamera,
              valA: _cameraName(exifA),
              valB: _cameraName(exifB),
            ),
            _CompareRow(
              label: l10n.compareAperture,
              valA: exifA?.fNumber != null ? 'f/${exifA!.fNumber}' : '—',
              valB: exifB?.fNumber != null ? 'f/${exifB!.fNumber}' : '—',
            ),
            _CompareRow(
              label: l10n.compareShutterSpeed,
              valA: exifA?.exposureTime ?? '—',
              valB: exifB?.exposureTime ?? '—',
            ),
            _CompareRow(
              label: l10n.compareIso,
              valA: exifA?.iso != null ? 'ISO ${exifA!.iso}' : '—',
              valB: exifB?.iso != null ? 'ISO ${exifB!.iso}' : '—',
            ),
            _CompareRow(
              label: l10n.compareFocalLength,
              valA: exifA?.focalLength != null
                  ? '${exifA!.focalLength!.toStringAsFixed(1)} mm'
                  : '—',
              valB: exifB?.focalLength != null
                  ? '${exifB!.focalLength!.toStringAsFixed(1)} mm'
                  : '—',
            ),
          ],
        );
      },
    );
  }

  static String _megapixels(int width, int height) {
    final mp = (width * height) / 1000000.0;
    return '${mp.toStringAsFixed(1)} MP';
  }

  static String _cameraName(ExifData? exif) {
    if (exif == null) return '—';
    final parts = [
      exif.make,
      exif.model,
    ].where((s) => s != null && s.trim().isNotEmpty).toList();
    if (parts.isEmpty) return '—';
    return parts.join(' ');
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String valA;
  final String valB;

  const _CompareRow({
    required this.label,
    required this.valA,
    required this.valB,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDifferent = valA != valB;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              valA,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              valB,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isDifferent ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
