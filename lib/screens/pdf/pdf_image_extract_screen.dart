import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/pdf/pdf_extraction_result.dart';
import 'package:in_sreerajp_imgvidgal/providers/pdf_tools_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/pdf/pdf_image_tile.dart';

/// Pulls the pictures out of a PDF, at `/pdf-images`.
///
/// The PDF is chosen through the system file picker, so this needs no storage
/// permission. The source file is never changed: every picture saved is a new
/// file written into the gallery under a fresh name.
class PdfImageExtractScreen extends ConsumerStatefulWidget {
  const PdfImageExtractScreen({super.key});

  @override
  ConsumerState<PdfImageExtractScreen> createState() =>
      _PdfImageExtractScreenState();
}

class _PdfImageExtractScreenState extends ConsumerState<PdfImageExtractScreen> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(pdfExtractionControllerProvider);
    final pdfName = ref.watch(pickedPdfNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(pdfName.isEmpty ? l10n.pdfImagesTitle : pdfName),
        actions: <Widget>[
          if (state.value != null && !state.value!.isRefused)
            IconButton(
              onPressed: _pick,
              icon: const Icon(Icons.folder_open_outlined),
              tooltip: l10n.pdfImagesChooseAnother,
            ),
        ],
      ),
      body: state.when(
        loading: () => _busy(l10n.pdfImagesReading),
        error: (_, __) => _message(
          context,
          icon: Icons.error_outline,
          title: l10n.pdfRefusedUnreadable,
        ),
        data: (result) {
          if (result == null) return _empty(context, l10n);
          if (result.isRefused) {
            return _message(
              context,
              icon: Icons.picture_as_pdf_outlined,
              title: _refusalText(l10n, result.refusal!),
              action: l10n.pdfImagesPick,
            );
          }
          if (result.isEmpty) {
            return _message(
              context,
              icon: Icons.image_not_supported_outlined,
              title: l10n.pdfImagesNone,
              action: l10n.pdfImagesChooseAnother,
            );
          }
          return _list(context, l10n, result);
        },
      ),
      bottomNavigationBar: _saveBar(context, l10n, state.value),
    );
  }

  Widget _empty(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.picture_as_pdf_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.pdfImagesEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(l10n.pdfImagesEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(l10n.pdfImagesPick),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list(
    BuildContext context,
    AppLocalizations l10n,
    PdfExtractionResult result,
  ) {
    final selected = ref.watch(selectedPdfImagesProvider);
    final skipped = result.skipped.length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(l10n.pdfImagesFound(result.extractable.length)),
              if (skipped > 0)
                Text(
                  l10n.pdfImagesSkippedCount(skipped),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (result.wasTruncated)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    l10n.pdfImagesTruncated,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              TextButton(
                onPressed: () => _selectAll(result),
                child: Text(l10n.pdfImagesSelectAll),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(selectedPdfImagesProvider.notifier).state =
                        <int>{},
                child: Text(l10n.pdfImagesClearSelection),
              ),
            ],
          ),
        ),
        for (final entry in result.entries)
          PdfImageTile(
            entry: entry,
            isSelected: selected.contains(entry.objectNumber),
            onToggle: () => ref
                .read(pdfExtractionControllerProvider.notifier)
                .toggle(entry.objectNumber),
          ),
      ],
    );
  }

  Widget? _saveBar(
    BuildContext context,
    AppLocalizations l10n,
    PdfExtractionResult? result,
  ) {
    if (result == null || result.isRefused || result.extractable.isEmpty) {
      return null;
    }

    final selected = ref.watch(selectedPdfImagesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt_outlined),
          label: Text(
            _saving
                ? l10n.pdfImagesSaving
                : '${l10n.pdfImagesSave} (${selected.length})',
          ),
        ),
      ),
    );
  }

  Widget _busy(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? action,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton(onPressed: _pick, child: Text(action)),
            ],
          ],
        ),
      ),
    );
  }

  void _selectAll(PdfExtractionResult result) {
    ref.read(selectedPdfImagesProvider.notifier).state = <int>{
      for (final entry in result.extractable) entry.objectNumber,
    };
  }

  Future<void> _pick() async {
    await ref.read(pdfExtractionControllerProvider.notifier).pickAndRead();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;

    if (ref.read(selectedPdfImagesProvider).isEmpty) {
      _say(l10n.pdfImagesNothingSelected);
      return;
    }

    setState(() => _saving = true);
    try {
      final summary = await ref
          .read(pdfExtractionControllerProvider.notifier)
          .saveSelected();

      if (!mounted || summary == null) return;

      final parts = <String>[
        l10n.pdfImagesSavedCount(summary.savedCount),
        if (summary.failedCount > 0)
          l10n.pdfImagesSaveFailedCount(summary.failedCount),
        if (summary.usedFallbackDirectory) l10n.pdfImagesFallbackDirectory,
      ];
      _say(parts.join('. '));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _refusalText(AppLocalizations l10n, PdfRefusalReason reason) {
    return switch (reason) {
      PdfRefusalReason.notAPdf => l10n.pdfRefusedNotPdf,
      PdfRefusalReason.encrypted => l10n.pdfRefusedEncrypted,
      PdfRefusalReason.fileTooLarge => l10n.pdfRefusedTooLarge,
      PdfRefusalReason.unreadable => l10n.pdfRefusedUnreadable,
    };
  }
}
