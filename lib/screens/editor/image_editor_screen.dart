import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/edit_session.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/editor_save_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/crop_overlay.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_tool_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/filter_preset_strip.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/markup_canvas.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/redaction_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/selective_mask_overlay.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/selective_mask_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/tone_slider_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/watermark_panel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';
import 'package:path/path.dart' as p;

/// The non-destructive image editor, opened from the viewer.
///
/// The screen owns no editing logic at all. Every gesture becomes a call on
/// the edit session notifier, and everything on screen is drawn from the
/// session and the preview provider. Nothing is written to disk until the
/// user taps save, and even then a new file is created beside the original.
class ImageEditorScreen extends ConsumerStatefulWidget {
  /// Id of the photo being edited.
  final String mediaId;

  const ImageEditorScreen({super.key, required this.mediaId});

  @override
  ConsumerState<ImageEditorScreen> createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends ConsumerState<ImageEditorScreen> {
  /// The last preview that rendered, kept so the image does not blink white
  /// while the next one is being drawn.
  Uint8List? _lastPreview;

  /// The selective mask currently being tweaked, or null when none is selected.
  String? _selectedMaskId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(timelineItemsProvider);

    return items.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => _MessageScaffold(message: l10n.scanFailed),
      data: (list) {
        final index = list.indexWhere((item) => item.id == widget.mediaId);
        if (index < 0) {
          return _MessageScaffold(message: l10n.mediaUnavailable);
        }

        final item = list[index];
        if (!item.isImage) {
          return _MessageScaffold(message: l10n.editorCannotOpen);
        }
        if (!const EditorSaveService().isEditableSize(item.size)) {
          return _MessageScaffold(message: l10n.editorTooLarge);
        }

        return _buildEditor(context, item);
      },
    );
  }

  Widget _buildEditor(BuildContext context, MediaItem item) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(editSessionProvider(item.id));
    final notifier = ref.read(editSessionProvider(item.id).notifier);
    final tool = ref.watch(editorActiveToolProvider);
    final saveState = ref.watch(editorSaveControllerProvider);

    _listenForSaveResult(item);

    return PopScope(
      canPop: !session.isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard(context)) {
          if (!context.mounted) return;
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.editorTitle),
          actions: [
            IconButton(
              onPressed: notifier.canUndo ? notifier.undo : null,
              icon: const Icon(Icons.undo),
              tooltip: l10n.editorUndo,
            ),
            IconButton(
              onPressed: notifier.canRedo ? notifier.redo : null,
              icon: const Icon(Icons.redo),
              tooltip: l10n.editorRedo,
            ),
            IconButton(
              onPressed: session.isDirty ? notifier.resetAll : null,
              icon: const Icon(Icons.restart_alt),
              tooltip: l10n.editorResetAll,
            ),
            TextButton(
              onPressed: session.isDirty && !saveState.isLoading
                  ? () => _save(item, session)
                  : null,
              child: Text(l10n.editorSave),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              flex: 3,
              child: _buildPreview(context, item, session, tool),
            ),
            if (saveState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.editorSaving),
                  ],
                ),
              ),
            Expanded(
              flex: 2,
              child: _buildToolPanel(context, item, session, tool),
            ),
            EditorToolBar(
              activeTool: tool,
              onToolSelected: (next) =>
                  ref.read(editorActiveToolProvider.notifier).state = next,
            ),
          ],
        ),
      ),
    );
  }

  /// The photo with the current edit drawn on it, plus the tool's overlay.
  Widget _buildPreview(
    BuildContext context,
    MediaItem item,
    EditSession session,
    EditorTool tool,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final preview = ref.watch(
      editorPreviewProvider(PreviewRequest(item: item, session: session)),
    );

    preview.whenData((bytes) {
      if (bytes != null) _lastPreview = bytes;
    });

    final bytes = preview.valueOrNull ?? _lastPreview;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: bytes == null
              ? Center(
                  child: preview.hasError
                      ? Text(l10n.editorPreviewFailed)
                      : const CircularProgressIndicator(),
                )
              : Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  // A photo the decoder chokes on shows a message instead of
                  // taking the editor down with it.
                  errorBuilder: (context, _, _) =>
                      Center(child: Text(l10n.editorCannotOpen)),
                ),
        ),
        if (bytes != null) _buildOverlay(item, session, tool),
      ],
    );
  }

  /// The gesture layer the active tool needs, if it needs one.
  Widget _buildOverlay(MediaItem item, EditSession session, EditorTool tool) {
    final notifier = ref.read(editSessionProvider(item.id).notifier);

    switch (tool) {
      case EditorTool.crop:
        return CropOverlay(
          rect: session.crop.rect,
          onChanged: notifier.setCropRect,
          onChangeEnd: notifier.setCropRect,
        );
      case EditorTool.markup:
        return MarkupCanvas(
          layers: session.markup,
          settings: ref.watch(markupToolSettingsProvider),
          onLayerCompleted: notifier.addMarkup,
        );
      case EditorTool.redact:
        return RedactionCanvas(
          regions: session.redactions,
          settings: ref.watch(redactionToolSettingsProvider),
          onRegionCompleted: notifier.addRedaction,
        );
      case EditorTool.masks:
        return SelectiveMaskOverlay(
          masks: session.selectiveMasks,
          selectedMaskId: _selectedMaskId,
          onMaskUpdated: notifier.updateMask,
        );
      case EditorTool.tune:
      case EditorTool.filters:
      case EditorTool.watermark:
        // These tools are driven entirely by the panel below the photo.
        return const SizedBox.shrink();
    }
  }

  /// The controls for the active tool.
  Widget _buildToolPanel(
    BuildContext context,
    MediaItem item,
    EditSession session,
    EditorTool tool,
  ) {
    final notifier = ref.read(editSessionProvider(item.id).notifier);
    final imageSize = PixelSize(item.width ?? 1, item.height ?? 1);

    switch (tool) {
      case EditorTool.crop:
        return CropControlsPanel(
          transform: session.crop,
          onAspectSelected: (preset) =>
              notifier.setAspectPreset(preset, imageSize),
          onRotateLeft: () => notifier.rotateQuarter(clockwise: false),
          onRotateRight: () => notifier.rotateQuarter(clockwise: true),
          onFlipHorizontal: notifier.toggleFlipHorizontal,
          onFlipVertical: notifier.toggleFlipVertical,
          onStraightenChanged: notifier.setStraighten,
          onStraightenEnd: notifier.setStraighten,
          onPerspectiveChanged: notifier.setPerspective,
          onPerspectiveEnd: notifier.setPerspective,
          onReset: notifier.resetCrop,
        );

      case EditorTool.tune:
        return ToneSliderPanel(
          adjustments: session.tone,
          onChanged: notifier.setTone,
          onChangeEnd: notifier.setTone,
          onReset: notifier.resetTone,
        );

      case EditorTool.masks:
        return SelectiveMaskPanel(
          masks: session.selectiveMasks,
          selectedMaskId: _selectedMaskId,
          onMaskAdded: (mask) {
            notifier.addMask(mask);
            setState(() => _selectedMaskId = mask.id);
          },
          onMaskUpdated: notifier.updateMask,
          onMaskRemoved: (id) {
            notifier.removeMask(id);
            if (_selectedMaskId == id) {
              setState(() => _selectedMaskId = null);
            }
          },
          onMaskSelected: (id) => setState(() => _selectedMaskId = id),
        );

      case EditorTool.filters:
        return FilterPresetStrip(
          selected: session.filter,
          onChanged: notifier.setFilter,
          onChangeEnd: notifier.setFilter,
        );

      case EditorTool.markup:
        return MarkupControlsPanel(
          settings: ref.watch(markupToolSettingsProvider),
          onSettingsChanged: (next) =>
              ref.read(markupToolSettingsProvider.notifier).state = next,
          onAddText: () => _addText(item),
          onRemoveLast: notifier.removeLastMarkup,
          canRemove: session.markup.isNotEmpty,
        );

      case EditorTool.redact:
        return RedactionControlsPanel(
          settings: ref.watch(redactionToolSettingsProvider),
          regionCount: session.redactions.length,
          onSettingsChanged: (next) =>
              ref.read(redactionToolSettingsProvider.notifier).state = next,
          onRemoveLast: () {
            if (session.redactions.isEmpty) return;
            notifier.removeRedaction(session.redactions.last.id);
          },
        );

      case EditorTool.watermark:
        return WatermarkPanel(
          config: session.watermark,
          onChanged: notifier.setWatermark,
          onChangeEnd: notifier.setWatermark,
          onPickLogo: () => _pickLogo(item),
        );
    }
  }

  /// Asks for a line of text and drops it in the middle of the photo.
  Future<void> _addText(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.markupTextTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: l10n.markupTextHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.editorKeepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(l10n.markupTextAdd),
          ),
        ],
      ),
    );

    controller.dispose();
    if (text == null || text.trim().isEmpty) return;
    if (!mounted) return;

    final settings = ref.read(markupToolSettingsProvider);
    ref
        .read(editSessionProvider(item.id).notifier)
        .addMarkup(
          TextAnnotation(
            id: 'text_${DateTime.now().microsecondsSinceEpoch}',
            colorArgb: settings.colorArgb,
            text: text.trim(),
            // Dropped a little above centre, where it is easy to see and to
            // drag somewhere else later.
            position: const NormalizedPoint(0.15, 0.4),
          ),
        );
  }

  /// Picks the watermark logo from the photos already indexed on the device.
  ///
  /// The app has no file browser of its own and adds no picker package, so
  /// the gallery itself is the picker. Only images are offered.
  Future<void> _pickLogo(MediaItem item) async {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.read(timelineItemsProvider).valueOrNull ?? const [];
    final images = items.where((candidate) => candidate.isImage).toList();

    final picked = await showDialog<MediaItem>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.watermarkPickLogo),
        content: SizedBox(
          width: double.maxFinite,
          height: 320,
          child: images.isEmpty
              ? Center(child: Text(l10n.noMediaFound))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final candidate = images[index];
                    return InkWell(
                      onTap: () => Navigator.of(dialogContext).pop(candidate),
                      child: MediaThumbnail(item: candidate, size: 96),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.editorKeepEditing),
          ),
        ],
      ),
    );

    if (picked == null || !mounted) return;
    final notifier = ref.read(editSessionProvider(item.id).notifier);
    notifier.setWatermark(
      ref
          .read(editSessionProvider(item.id))
          .watermark
          .copyWith(mode: WatermarkMode.logo, logoPath: picked.path),
    );
  }

  /// Renders at full size and writes the copy.
  Future<void> _save(MediaItem item, EditSession session) async {
    final bytes = await ref.read(editorSourceBytesProvider(item).future);
    if (!mounted) return;

    if (bytes == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.editorCannotOpen)));
      return;
    }

    await ref
        .read(editorSaveControllerProvider.notifier)
        .save(item: item, session: session, sourceBytes: bytes);
  }

  /// Tells the user where the copy went, or that it failed.
  void _listenForSaveResult(MediaItem item) {
    ref.listen<AsyncValue<SaveOutcome?>>(editorSaveControllerProvider, (
      previous,
      next,
    ) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final messenger = ScaffoldMessenger.of(context);

      next.when(
        loading: () {},
        error: (_, _) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.editorSaveFailed)),
          );
          ref.read(editorSaveControllerProvider.notifier).clear();
        },
        data: (outcome) {
          if (outcome == null) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                '${l10n.editorSaved(p.basename(outcome.path))}\n'
                '${l10n.editorOriginalKept}',
              ),
            ),
          );
          ref.read(editorSaveControllerProvider.notifier).clear();
        },
      );
    });
  }

  /// Asks before leaving with unsaved edits.
  Future<bool> _confirmDiscard(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.editorDiscardTitle),
        content: Text(l10n.editorDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.editorKeepEditing),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.editorDiscard),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

/// A plain screen showing one message, used when the photo cannot be edited.
class _MessageScaffold extends StatelessWidget {
  final String message;

  const _MessageScaffold({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
