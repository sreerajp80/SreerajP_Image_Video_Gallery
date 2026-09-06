import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';
import 'package:in_sreerajp_imgvidgal/models/exif_data.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:intl/intl.dart';
import 'package:in_sreerajp_imgvidgal/widgets/notes/notes_preview_tile.dart';

/// Formats a byte count as KB, MB, or GB.
///
/// The unit is a symbol rather than a translated word, and the number is
/// formatted for the current locale by the caller's `Intl` setup.
String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  const units = <String>['KB', 'MB', 'GB', 'TB'];
  var value = bytes / 1024;
  var unitIndex = 0;
  while (value >= 1024 && unitIndex < units.length - 1) {
    value /= 1024;
    unitIndex++;
  }
  return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unitIndex]}';
}

/// Formats a date and time for the details sheet.
///
/// Falls back to a plain ISO-style date when the locale has no patterns, so a
/// missing locale never breaks the sheet.
String formatDetailDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).toString();
  try {
    return '${DateFormat.yMMMd(locale).format(date)} '
        '${DateFormat.Hm(locale).format(date)}';
  } catch (_) {
    return date.toIso8601String();
  }
}

/// The swipe-up drawer showing file facts and EXIF metadata.
///
/// EXIF is fetched through a provider, which parses it once and caches it in
/// the database. A file with no readable metadata still shows everything
/// MediaStore knows, so the sheet is never empty.
class MediaDetailsSheet extends ConsumerWidget {
  final MediaItem item;

  const MediaDetailsSheet({super.key, required this.item});

  /// Opens the sheet as a draggable bottom sheet over the viewer.
  static Future<void> show(BuildContext context, MediaItem item) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        builder: (context, scrollController) =>
            MediaDetailsSheet(item: item)._body(context, scrollController),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _body(context, null);
  }

  Widget _body(BuildContext context, ScrollController? scrollController) {
    return Consumer(
      builder: (context, ref, child) {
        final l10n = AppLocalizations.of(context)!;
        final theme = Theme.of(context);
        final exif = ref.watch(mediaExifProvider(item));
        final gestures = ref.watch(videoGestureServiceProvider);

        final rows = <_DetailRow>[
          _DetailRow(l10n.detailsFileName, item.displayName),
          _DetailRow(l10n.detailsFormat, item.mimeType),
          _DetailRow(l10n.detailsSize, formatFileSize(item.size)),
          if (item.width != null && item.height != null)
            _DetailRow(
              l10n.detailsDimensions,
              '${item.width} x ${item.height}',
            ),
          if (item.durationMs != null && item.durationMs! > 0)
            _DetailRow(
              l10n.detailsDuration,
              gestures.formatDuration(Duration(milliseconds: item.durationMs!)),
            ),
          _DetailRow(
            l10n.detailsDateTaken,
            formatDetailDate(context, item.effectiveDate),
          ),
          _DetailRow(
            l10n.detailsDateModified,
            formatDetailDate(context, item.dateModified),
          ),
          if (item.path.isNotEmpty)
            _DetailRow(l10n.detailsFolder, _folderOf(item.path)),
        ];

        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: [
            Text(l10n.detailsTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            ...rows,
            const Divider(height: 24),
            NotesPreviewTile(mediaId: item.id),
            const SizedBox(height: 20),
            Text(l10n.detailsCameraSection, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            exif.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: LinearProgressIndicator(),
              ),
              error: (error, _) => Text(
                l10n.detailsNoMetadata,
                style: theme.textTheme.bodyMedium,
              ),
              data: (data) => _ExifRows(exif: data),
            ),
          ],
        );
      },
    );
  }

  /// The folder part of a file path, or the whole path when it has no folder.
  String _folderOf(String path) {
    final separator = path.lastIndexOf('/');
    if (separator <= 0) return path;
    return path.substring(0, separator);
  }
}

/// The EXIF part of the sheet, or a short note when there is none.
class _ExifRows extends StatelessWidget {
  final ExifData? exif;

  const _ExifRows({required this.exif});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final data = exif;

    if (data == null) {
      return Text(
        l10n.detailsNoMetadata,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    final rows = <_DetailRow>[
      if (data.make != null || data.model != null)
        _DetailRow(
          l10n.detailsCamera,
          [data.make, data.model].whereType<String>().join(' '),
        ),
      if (data.lensModel != null) _DetailRow(l10n.detailsLens, data.lensModel!),
      if (data.fNumber != null)
        _DetailRow(
          l10n.detailsAperture,
          'f/${data.fNumber!.toStringAsFixed(1)}',
        ),
      if (data.exposureTime != null)
        _DetailRow(l10n.detailsShutter, data.exposureTime!),
      if (data.iso != null) _DetailRow(l10n.detailsIso, 'ISO ${data.iso}'),
      if (data.focalLength != null)
        _DetailRow(
          l10n.detailsFocalLength,
          '${data.focalLength!.toStringAsFixed(0)} mm',
        ),
      if (data.flash != null) _DetailRow(l10n.detailsFlash, data.flash!),
      if (data.whiteBalance != null)
        _DetailRow(l10n.detailsWhiteBalance, data.whiteBalance!),
      if (data.meteringMode != null)
        _DetailRow(l10n.detailsMeteringMode, data.meteringMode!),
      if (data.colorSpace != null)
        _DetailRow(l10n.detailsColorSpace, data.colorSpace!),
      if (data.software != null)
        _DetailRow(l10n.detailsSoftware, data.software!),
      if (data.latitude != null && data.longitude != null)
        _DetailRow(
          l10n.detailsLocation,
          '${data.latitude!.toStringAsFixed(5)}, '
          '${data.longitude!.toStringAsFixed(5)}',
        ),
      if (data.altitude != null)
        _DetailRow(
          l10n.detailsAltitude,
          '${data.altitude!.toStringAsFixed(0)} m',
        ),
    ];

    if (rows.isEmpty) {
      return Text(
        l10n.detailsNoMetadata,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }
}

/// One label and value line.
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          // The label is a translated one and follows the locale. The value
          // is the file's own: a name, an address, a camera model. It
          // follows itself.
          Expanded(
            child: AdaptiveDirectionality(
              text: value,
              child: Text(value, style: theme.textTheme.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}
