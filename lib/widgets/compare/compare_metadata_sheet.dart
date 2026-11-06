import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/unit_format_context.dart';

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
    final exifA = ref.watch(mediaExifProvider(itemA)).value;
    final exifB = ref.watch(mediaExifProvider(itemB)).value;

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
                  l10n.tooltipCompareDetails,
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
                      l10n.labelComparePhotoA,
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
                      l10n.labelComparePhotoB,
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
              label: l10n.labelDetailsFileName,
              valA: itemA.displayName,
              valB: itemB.displayName,
            ),
            _CompareRow(
              label: l10n.labelCompareDimensions,
              valA: itemA.width != null && itemA.height != null
                  ? '${itemA.width} × ${itemA.height} (${_megapixels(itemA.width!, itemA.height!)})'
                  : '—',
              valB: itemB.width != null && itemB.height != null
                  ? '${itemB.width} × ${itemB.height} (${_megapixels(itemB.width!, itemB.height!)})'
                  : '—',
            ),
            _CompareRow(
              label: l10n.labelCompareFileSize,
              valA: context.units.bytes(itemA.size),
              valB: context.units.bytes(itemB.size),
            ),
            _CompareRow(
              label: l10n.labelDetailsFormat,
              valA: itemA.mimeType,
              valB: itemB.mimeType,
            ),
            _CompareRow(
              label: l10n.labelCompareDateTaken,
              valA: formatDetailDate(context, itemA.effectiveDate),
              valB: formatDetailDate(context, itemB.effectiveDate),
            ),
            const Divider(height: 24),
            _CompareRow(
              label: l10n.labelCompareCamera,
              valA: _cameraName(exifA),
              valB: _cameraName(exifB),
            ),
            _CompareRow(
              label: l10n.labelCompareAperture,
              valA: exifA?.fNumber != null ? 'f/${exifA!.fNumber}' : '—',
              valB: exifB?.fNumber != null ? 'f/${exifB!.fNumber}' : '—',
            ),
            _CompareRow(
              label: l10n.labelCompareShutterSpeed,
              valA: exifA?.exposureTime ?? '—',
              valB: exifB?.exposureTime ?? '—',
            ),
            _CompareRow(
              label: l10n.labelCompareIso,
              valA: exifA?.iso != null ? context.units.iso(exifA!.iso!) : '—',
              valB: exifB?.iso != null ? context.units.iso(exifB!.iso!) : '—',
            ),
            _CompareRow(
              label: l10n.labelCompareFocalLength,
              valA: exifA?.focalLength != null
                  ? context.units.millimetres(exifA!.focalLength!, decimals: 1)
                  : '—',
              valB: exifB?.focalLength != null
                  ? context.units.millimetres(exifB!.focalLength!, decimals: 1)
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
