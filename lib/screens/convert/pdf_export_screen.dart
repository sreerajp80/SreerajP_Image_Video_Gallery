import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/convert_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/pdf_export_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/convert/pdf_image_picker_grid.dart';
import 'package:in_sreerajp_imgvidgal/widgets/convert/pdf_options_panel.dart';
import 'package:path/path.dart' as p;

/// Builds one PDF document from several photos.
///
/// Photos are picked in the order they will appear, the page settings sit
/// under the grid, and the document is written beside the first photo picked.
/// Nothing on the device is changed; only a new file is added.
class PdfExportScreen extends ConsumerStatefulWidget {
  const PdfExportScreen({super.key});

  @override
  ConsumerState<PdfExportScreen> createState() => _PdfExportScreenState();
}

class _PdfExportScreenState extends ConsumerState<PdfExportScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(timelineItemsProvider);
    final selected = ref.watch(pdfSelectionProvider);
    final options = ref.watch(pdfExportOptionsProvider);
    final progress = ref.watch(pdfExportProgressProvider);
    final exportState = ref.watch(pdfExportControllerProvider);

    _listenForResult();

    final isExporting = exportState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.pdfExportTitle),
        bottom: progress == null
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(4),
                child: LinearProgressIndicator(
                  value: progress.total == 0 ? null : progress.fraction,
                ),
              ),
      ),
      body: items.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CenteredMessage(message: l10n.scanFailed),
        data: (list) {
          final photos = list
              .where((item) => item.isImage)
              .toList(growable: false);
          if (photos.isEmpty) {
            return _CenteredMessage(message: l10n.pdfNoPhotos);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    l10n.pdfChoosePhotos,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    selected.isEmpty
                        ? l10n.pdfNoSelection
                        : l10n.pdfSelectedCount(selected.length),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              if (selected.length >= AppConstants.pdfMaxPages)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.pdfMaxPagesReached(AppConstants.pdfMaxPages),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              PdfImagePickerGrid(
                items: photos,
                selectedIds: selected,
                onToggle: (item) =>
                    ref.read(pdfSelectionProvider.notifier).toggle(item.id),
              ),
              const SizedBox(height: 24),
              PdfOptionsPanel(
                options: options,
                onChanged: (value) =>
                    ref.read(pdfExportOptionsProvider.notifier).state = value,
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: selected.isEmpty || isExporting
            ? null
            : () => _export(items.valueOrNull ?? const <MediaItem>[], selected),
        icon: const Icon(Icons.picture_as_pdf_rounded),
        label: Text(isExporting ? l10n.pdfExporting : l10n.pdfExportAction),
      ),
    );
  }

  /// Turns the picked ids back into file paths, in page order, and exports.
  void _export(List<MediaItem> all, List<String> selectedIds) {
    final byId = <String, MediaItem>{for (final item in all) item.id: item};
    final paths = <String>[
      for (final id in selectedIds)
        if (byId[id] != null) byId[id]!.path,
    ];
    if (paths.isEmpty) return;

    ref
        .read(pdfExportControllerProvider.notifier)
        .export(imagePaths: paths, options: ref.read(pdfExportOptionsProvider));
  }

  /// Turns the export result into a message, once per finished export.
  void _listenForResult() {
    ref.listen<AsyncValue<PdfExportResult?>>(pdfExportControllerProvider, (
      previous,
      next,
    ) {
      final l10n = AppLocalizations.of(context)!;
      final messenger = ScaffoldMessenger.of(context);

      next.whenOrNull(
        data: (result) {
          if (result == null) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                result.skippedCount > 0
                    ? l10n.pdfSkippedCount(result.skippedCount)
                    : l10n.pdfExportedAs(
                        p.basename(result.path),
                        result.pageCount,
                      ),
              ),
            ),
          );
          ref.read(pdfExportControllerProvider.notifier).clear();
          ref.read(pdfSelectionProvider.notifier).clear();
        },
        error: (_, _) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.pdfFailed)));
          ref.read(pdfExportControllerProvider.notifier).clear();
        },
      );
    });
  }
}

class _CenteredMessage extends StatelessWidget {
  final String message;

  const _CenteredMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
