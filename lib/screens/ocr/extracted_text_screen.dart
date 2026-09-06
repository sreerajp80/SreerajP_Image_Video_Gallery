import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_language.dart';
import 'package:in_sreerajp_imgvidgal/models/ocr/ocr_result.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/notes_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/ocr_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// Shows the text read out of one picture, at `/media-viewer/:id/text`.
///
/// The reading happens on the device, and the text is shown, copied, or kept
/// in the item's own notes. It is never sent anywhere and never written
/// somewhere the user did not ask for.
class ExtractedTextScreen extends ConsumerStatefulWidget {
  /// The media item being read.
  final String mediaId;

  const ExtractedTextScreen({super.key, required this.mediaId});

  @override
  ConsumerState<ExtractedTextScreen> createState() =>
      _ExtractedTextScreenState();
}

class _ExtractedTextScreenState extends ConsumerState<ExtractedTextScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _read());
  }

  Future<void> _read() async {
    if (!mounted) return;

    final item = await ref.read(mediaItemProvider(widget.mediaId).future);
    if (!mounted) return;

    await ref.read(ocrControllerProvider.notifier).read(item?.path ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(ocrControllerProvider);
    final language = ref.watch(ocrLanguageProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ocrTitle)),
      body: Column(
        children: <Widget>[
          _languageBar(context, l10n, language),
          const Divider(height: 1),
          Expanded(
            child: state.when(
              loading: () => _busy(context, l10n),
              error: (_, __) => _message(context, l10n.ocrFailedEngine),
              data: (result) {
                if (result == null) return _busy(context, l10n);
                if (result.isFailure) {
                  return _message(context, _failureText(l10n, result.failure!));
                }
                if (result.foundNothing) {
                  return _message(context, l10n.ocrNoText);
                }
                return _text(context, l10n, result);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageBar(
    BuildContext context,
    AppLocalizations l10n,
    OcrLanguage language,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: <Widget>[
          Text(l10n.ocrLanguage, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final choice in OcrLanguage.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_languageLabel(l10n, choice)),
                        selected: choice == language,
                        onSelected: (selected) {
                          if (!selected) return;
                          ref.read(ocrLanguageProvider.notifier).state = choice;
                          // Changing the language means reading again: the old
                          // text was read with a different alphabet in mind.
                          _read();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _busy(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l10n.ocrReading),
          const SizedBox(height: 8),
          Text(
            l10n.ocrSlowHint,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, String text) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.text_fields_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: _read, child: Text(l10n.ocrReadAgain)),
          ],
        ),
      ),
    );
  }

  Widget _text(BuildContext context, AppLocalizations l10n, OcrResult result) {
    return Column(
      children: <Widget>[
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            // Selectable, so a phone number or one line can be taken out
            // without copying the lot.
            //
            // The reader ships English and Malayalam models, but a photo can
            // hold any script at all, so the recognised text is laid out the
            // way it reads rather than the way the app reads.
            child: AdaptiveDirectionality(
              text: result.text,
              child: SelectableText(
                result.text,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.ocrWordCount(result.wordCount),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton.icon(
                onPressed: () => _saveToNotes(result.text),
                icon: const Icon(Icons.note_add_outlined),
                label: Text(l10n.ocrSaveToNotes),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _copy(result.text),
                icon: const Icon(Icons.copy_outlined),
                label: Text(l10n.ocrCopyAll),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _copy(String text) async {
    final l10n = AppLocalizations.of(context)!;
    await ref.read(scanActionRunnerProvider).copy(text);
    _say(l10n.ocrCopied);
  }

  Future<void> _saveToNotes(String text) async {
    final l10n = AppLocalizations.of(context)!;
    final saved = await ref
        .read(notesControllerProvider.notifier)
        .append(widget.mediaId, text);

    _say(saved ? l10n.ocrSavedToNotes : l10n.notesSaveFailed);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _languageLabel(AppLocalizations l10n, OcrLanguage language) {
    return switch (language) {
      OcrLanguage.english => l10n.ocrLanguageEnglish,
      OcrLanguage.malayalam => l10n.ocrLanguageMalayalam,
      OcrLanguage.both => l10n.ocrLanguageBoth,
    };
  }

  String _failureText(AppLocalizations l10n, OcrFailure failure) {
    return switch (failure) {
      OcrFailure.unreadableImage => l10n.ocrFailedUnreadable,
      OcrFailure.imageTooLarge => l10n.ocrFailedTooLarge,
      OcrFailure.missingLanguageData => l10n.ocrFailedMissingData,
      OcrFailure.timedOut => l10n.ocrFailedTimeout,
      OcrFailure.engineFailed => l10n.ocrFailedEngine,
    };
  }
}
