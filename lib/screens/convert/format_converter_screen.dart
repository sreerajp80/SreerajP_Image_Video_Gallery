import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/conversion_result.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/size_estimate.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/convert_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/convert/format_chip_row.dart';
import 'package:in_sreerajp_imgvidgal/widgets/convert/resize_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/convert/size_preview_card.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';
import 'package:path/path.dart' as p;

/// The format converter and resizer, opened from the viewer.
///
/// Nothing here changes the picture on disk. The controls build a request,
/// the request drives a background encode that reports the exact size the
/// copy would be, and only the save button writes anything — and then always
/// as a new file beside the original.
class FormatConverterScreen extends ConsumerWidget {
  /// Id of the picture being converted.
  final String mediaId;

  const FormatConverterScreen({super.key, required this.mediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(timelineItemsProvider);

    return items.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _MessageScaffold(message: l10n.scanFailed),
      data: (list) {
        final index = list.indexWhere((item) => item.id == mediaId);
        if (index < 0) {
          return _MessageScaffold(message: l10n.mediaUnavailable);
        }

        final item = list[index];
        if (!item.isImage) {
          return _MessageScaffold(message: l10n.convertCannotOpen);
        }
        if (!const OutputNamingService().isConvertibleSize(item.size)) {
          return _MessageScaffold(message: l10n.convertTooLarge);
        }

        return _ConverterBody(item: item);
      },
    );
  }
}

/// The converter itself, once the picture is known to be usable.
class _ConverterBody extends ConsumerStatefulWidget {
  final MediaItem item;

  const _ConverterBody({required this.item});

  @override
  ConsumerState<_ConverterBody> createState() => _ConverterBodyState();
}

class _ConverterBodyState extends ConsumerState<_ConverterBody> {
  /// The last estimate that finished, kept so the card does not empty out
  /// while the next encode is running.
  SizeEstimate? _lastEstimate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;

    final request = ref.watch(conversionRequestProvider(item));
    final notifier = ref.read(conversionRequestProvider(item).notifier);
    final sourceBytes = ref.watch(convertSourceBytesProvider(item));
    final saveState = ref.watch(convertSaveControllerProvider);

    final estimate = ref.watch(
      conversionEstimateProvider(EstimateRequest(item: item, request: request)),
    );
    estimate.whenData((value) {
      if (value != null) _lastEstimate = value;
    });

    _listenForSaveResult(item);

    final isSaving = saveState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.convertTitle),
        actions: <Widget>[
          if (isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: sourceBytes.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CenteredMessage(message: l10n.convertUnreadable),
        data: (bytes) {
          if (bytes == null) {
            return _CenteredMessage(message: l10n.convertUnreadable);
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: <Widget>[
              _Preview(item: item),
              const SizedBox(height: 20),
              _SectionTitle(text: l10n.convertFormatLabel),
              FormatChipRow(
                selected: request.format,
                onChanged: notifier.setFormat,
              ),
              if (request.format.supportsQuality) ...<Widget>[
                const SizedBox(height: 16),
                _SectionTitle(text: l10n.convertQualityLabel),
                Slider(
                  value: request.effectiveQuality.toDouble(),
                  min: AppConstants.convertMinQuality.toDouble(),
                  max: AppConstants.convertMaxQuality.toDouble(),
                  divisions:
                      AppConstants.convertMaxQuality -
                      AppConstants.convertMinQuality,
                  label: '${request.effectiveQuality}',
                  onChanged: (value) => notifier.setQuality(value.round()),
                ),
              ],
              const SizedBox(height: 8),
              _SectionTitle(text: l10n.convertResizeLabel),
              ResizePanel(
                spec: request.resize,
                sourceWidth: item.width ?? 0,
                sourceHeight: item.height ?? 0,
                onModeChanged: notifier.setResizeMode,
                onLongestSideChanged: notifier.setLongestSide,
                onPercentChanged: notifier.setPercent,
                onExactChanged: notifier.setExactSize,
                onKeepAspectChanged: notifier.setKeepAspect,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.convertStripMetadata),
                subtitle: Text(l10n.convertStripMetadataHint),
                value: request.stripMetadata,
                onChanged: notifier.setStripMetadata,
              ),
              const SizedBox(height: 16),
              SizePreviewCard(
                estimate: _lastEstimate,
                originalBytes: item.size,
                isWorking: estimate.isLoading,
                hasFailed:
                    estimate.hasValue && estimate.value == null ||
                    estimate.hasError,
              ),
            ],
          );
        },
      ),
      floatingActionButton: sourceBytes.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: isSaving
                  ? null
                  : () => ref
                        .read(convertSaveControllerProvider.notifier)
                        .save(
                          item: item,
                          request: request,
                          sourceBytes: sourceBytes.valueOrNull!,
                        ),
              icon: const Icon(Icons.save_alt_rounded),
              label: Text(isSaving ? l10n.convertSaving : l10n.convertSave),
            ),
    );
  }

  /// Turns the save result into a message, once per finished save.
  void _listenForSaveResult(MediaItem item) {
    ref.listen<AsyncValue<ConversionResult?>>(convertSaveControllerProvider, (
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
              content: Text(l10n.convertSavedAs(p.basename(result.path))),
            ),
          );
          ref.read(convertSaveControllerProvider.notifier).clear();
        },
        error: (_, _) {
          messenger.showSnackBar(SnackBar(content: Text(l10n.convertFailed)));
          ref.read(convertSaveControllerProvider.notifier).clear();
        },
      );
    });
  }
}

/// The picture being converted, shown above the controls.
class _Preview extends StatelessWidget {
  final MediaItem item;

  const _Preview({required this.item});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: MediaThumbnail(item: item, size: 180, borderRadius: 12),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
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

class _MessageScaffold extends StatelessWidget {
  final String message;

  const _MessageScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.convertTitle)),
      body: _CenteredMessage(message: message),
    );
  }
}
