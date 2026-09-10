import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/edit_session.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/editor_save_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/filter_preset_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/hsl_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/image_render_pipeline.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/markup_geometry_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/markup_render_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/redaction_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/selective_mask_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_adjustment_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_curve_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/watermark_service.dart';

/// Crop, straighten, rotate, and perspective maths.
final cropTransformServiceProvider = Provider<CropTransformService>((ref) {
  return const CropTransformService();
});

/// Curve interpolation for the RGB curve control.
final toneCurveServiceProvider = Provider<ToneCurveService>((ref) {
  return const ToneCurveService();
});

/// The tone slider lookup tables.
final toneAdjustmentServiceProvider = Provider<ToneAdjustmentService>((ref) {
  return ToneAdjustmentService(
    curveService: ref.watch(toneCurveServiceProvider),
  );
});

/// The catalogue of one-tap looks.
final filterPresetServiceProvider = Provider<FilterPresetService>((ref) {
  return const FilterPresetService();
});

/// Markup coordinate maths shared by the canvas and the renderer.
final markupGeometryServiceProvider = Provider<MarkupGeometryService>((ref) {
  return const MarkupGeometryService();
});

/// Drawing of doodles, shapes, and text onto pixels.
final markupRenderServiceProvider = Provider<MarkupRenderService>((ref) {
  return MarkupRenderService(
    geometry: ref.watch(markupGeometryServiceProvider),
  );
});

/// Blur, pixelate, and blackout.
final redactionServiceProvider = Provider<RedactionService>((ref) {
  return RedactionService(cropService: ref.watch(cropTransformServiceProvider));
});

/// Watermark text and placement.
final watermarkServiceProvider = Provider<WatermarkService>((ref) {
  return const WatermarkService();
});

/// Selective gradient and radial mask maths.
final selectiveMaskServiceProvider = Provider<SelectiveMaskService>((ref) {
  return SelectiveMaskService(
    toneService: ref.watch(toneAdjustmentServiceProvider),
  );
});

/// Per-colour-range HSL tuner.
final hslServiceProvider = Provider<HslService>((ref) {
  return const HslService();
});

/// The whole render, from bytes to bytes.
final imageRenderPipelineProvider = Provider<ImageRenderPipeline>((ref) {
  return ImageRenderPipeline(
    cropService: ref.watch(cropTransformServiceProvider),
    toneService: ref.watch(toneAdjustmentServiceProvider),
    filterService: ref.watch(filterPresetServiceProvider),
    redactionService: ref.watch(redactionServiceProvider),
    maskService: ref.watch(selectiveMaskServiceProvider),
    hslService: ref.watch(hslServiceProvider),
    markupService: ref.watch(markupRenderServiceProvider),
    watermarkService: ref.watch(watermarkServiceProvider),
  );
});

/// Versioned, non-destructive saving.
final editorSaveServiceProvider = Provider<EditorSaveService>((ref) {
  return const EditorSaveService();
});

/// Which tool panel the editor is showing.
enum EditorTool { crop, tune, masks, filters, markup, redact, watermark }

/// The tool the editor currently has open.
final editorActiveToolProvider = StateProvider.autoDispose<EditorTool>((ref) {
  return EditorTool.crop;
});

/// The pen, shape, or text style the markup tool draws with next.
///
/// This is a working preference rather than part of the edit, so it lives
/// beside the session instead of inside it. Nothing here ends up in the
/// saved file except through the layers the user actually draws.
class MarkupToolSettings {
  final ShapeKind shape;

  /// Whether the markup tool is drawing freehand rather than shapes.
  final bool freehand;

  final int colorArgb;
  final double strokeWidth;
  final bool filled;

  const MarkupToolSettings({
    this.shape = ShapeKind.rectangle,
    this.freehand = true,
    this.colorArgb = 0xFFFF3B30,
    this.strokeWidth = 0.008,
    this.filled = false,
  });

  MarkupToolSettings copyWith({
    ShapeKind? shape,
    bool? freehand,
    int? colorArgb,
    double? strokeWidth,
    bool? filled,
  }) {
    return MarkupToolSettings(
      shape: shape ?? this.shape,
      freehand: freehand ?? this.freehand,
      colorArgb: colorArgb ?? this.colorArgb,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      filled: filled ?? this.filled,
    );
  }
}

/// Current markup pen settings.
final markupToolSettingsProvider =
    StateProvider.autoDispose<MarkupToolSettings>((ref) {
      return const MarkupToolSettings();
    });

/// The redaction brush settings the next drag will use.
class RedactionToolSettings {
  final RedactionMode mode;
  final double strength;

  const RedactionToolSettings({
    this.mode = RedactionMode.blur,
    this.strength = 0.6,
  });

  RedactionToolSettings copyWith({RedactionMode? mode, double? strength}) {
    return RedactionToolSettings(
      mode: mode ?? this.mode,
      strength: strength ?? this.strength,
    );
  }
}

/// Current redaction brush settings.
final redactionToolSettingsProvider =
    StateProvider.autoDispose<RedactionToolSettings>((ref) {
      return const RedactionToolSettings();
    });

/// Holds the edit being built, and its undo and redo history.
///
/// Every tool calls a method here and gets a new immutable session back. The
/// history is just the sessions that came before, which is why undo needs no
/// per-tool logic at all.
class EditSessionNotifier extends StateNotifier<EditSession> {
  final CropTransformService _cropService;

  final List<EditSession> _past = <EditSession>[];
  final List<EditSession> _future = <EditSession>[];

  EditSessionNotifier({
    required String mediaId,
    required CropTransformService cropService,
  }) : _cropService = cropService,
       super(EditSession.initial(mediaId));

  /// Whether there is a step to go back to.
  bool get canUndo => _past.isNotEmpty;

  /// Whether a step was undone and can be put back.
  bool get canRedo => _future.isNotEmpty;

  /// Replaces the session and remembers the old one for undo.
  ///
  /// A change that does not actually alter anything is dropped, so dragging a
  /// slider back to where it started does not fill the history with noise.
  void _push(EditSession next) {
    if (next == state) return;

    _past.add(state);
    if (_past.length > AppConstants.editorUndoDepth) {
      _past.removeAt(0);
    }
    // Any new edit ends the redo branch, which is what users expect.
    _future.clear();
    state = next;
  }

  /// Steps one change back.
  void undo() {
    if (_past.isEmpty) return;
    _future.add(state);
    state = _past.removeLast();
  }

  /// Puts back the change that was undone.
  void redo() {
    if (_future.isEmpty) return;
    _past.add(state);
    state = _future.removeLast();
  }

  /// Clears every edit, keeping the history so the reset itself can be undone.
  void resetAll() => _push(state.reset());

  /// Sets the crop box, correcting anything dragged out of bounds.
  void setCropRect(NormalizedRect rect) {
    _push(
      state.copyWith(
        crop: state.crop.copyWith(rect: _cropService.clampRect(rect)),
      ),
    );
  }

  /// Locks the crop box to an aspect shape and reshapes it to match.
  void setAspectPreset(CropAspectPreset preset, PixelSize imageSize) {
    final ratio = _cropService.ratioFor(preset, imageSize);
    final reshaped = _cropService.applyAspectRatio(
      state.crop.rect,
      ratio,
      imageSize,
    );
    _push(
      state.copyWith(
        crop: state.crop.copyWith(aspectPreset: preset, rect: reshaped),
      ),
    );
  }

  /// Turns the photo a quarter turn.
  void rotateQuarter({bool clockwise = true}) {
    final turns = _cropService.normalizeQuarterTurns(
      state.crop.quarterTurns + (clockwise ? 1 : -1),
    );
    _push(state.copyWith(crop: state.crop.copyWith(quarterTurns: turns)));
  }

  /// Sets the fine levelling angle.
  void setStraighten(double degrees) {
    _push(
      state.copyWith(
        crop: state.crop.copyWith(
          straightenDegrees: _cropService.clampStraighten(degrees),
        ),
      ),
    );
  }

  /// Mirrors the photo left to right.
  void toggleFlipHorizontal() {
    _push(
      state.copyWith(
        crop: state.crop.copyWith(flipHorizontal: !state.crop.flipHorizontal),
      ),
    );
  }

  /// Mirrors the photo top to bottom.
  void toggleFlipVertical() {
    _push(
      state.copyWith(
        crop: state.crop.copyWith(flipVertical: !state.crop.flipVertical),
      ),
    );
  }

  /// Sets the perspective corner pulls.
  void setPerspective(PerspectiveSkew skew) {
    _push(
      state.copyWith(
        crop: state.crop.copyWith(
          perspective: _cropService.clampPerspective(skew),
        ),
      ),
    );
  }

  /// Clears every geometry change but keeps the rest of the edit.
  void resetCrop() => _push(state.copyWith(crop: CropTransform.identity));

  /// Replaces the tone sliders.
  void setTone(ToneAdjustments tone) => _push(state.copyWith(tone: tone));

  /// Puts every tone slider and curve back to neutral.
  void resetTone() => _push(state.copyWith(tone: ToneAdjustments.neutral));

  /// Picks a one-tap look.
  void setFilter(FilterPreset filter) => _push(state.copyWith(filter: filter));

  /// Adds a finished markup layer.
  void addMarkup(MarkupLayer layer) => _push(state.addMarkup(layer));

  /// Removes one markup layer.
  void removeMarkup(String layerId) => _push(state.removeMarkup(layerId));

  /// Removes the most recently added markup layer.
  void removeLastMarkup() {
    if (state.markup.isEmpty) return;
    _push(state.removeMarkup(state.markup.last.id));
  }

  /// Adds a redaction area.
  void addRedaction(RedactionRegion region) =>
      _push(state.addRedaction(region));

  /// Removes one redaction area.
  void removeRedaction(String regionId) =>
      _push(state.removeRedaction(regionId));

  /// Replaces the watermark settings.
  void setWatermark(WatermarkConfig config) =>
      _push(state.copyWith(watermark: config));

  /// Adds a selective mask.
  void addMask(SelectiveMask mask) => _push(state.addMask(mask));

  /// Removes a selective mask by id.
  void removeMask(String maskId) => _push(state.removeMask(maskId));

  /// Replaces a selective mask (same id) with an updated version.
  void updateMask(SelectiveMask mask) => _push(state.replaceMask(mask));
}

/// The edit being built for one media item.
///
/// It is keyed by media id and auto-disposed, so leaving the editor and
/// opening a different photo always starts clean.
final editSessionProvider = StateNotifierProvider.autoDispose
    .family<EditSessionNotifier, EditSession, String>((ref, mediaId) {
      return EditSessionNotifier(
        mediaId: mediaId,
        cropService: ref.watch(cropTransformServiceProvider),
      );
    });

/// The original bytes of the photo being edited, or null when unavailable.
///
/// Null covers a missing file, an unreadable one, and a file too big to
/// decode safely. The editor shows a message for all three rather than
/// opening onto a blank canvas.
final editorSourceBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, MediaItem>((ref, item) async {
      if (!item.isImage) return null;
      if (!const EditorSaveService().isEditableSize(item.size)) return null;

      // The decoded source is reused by every preview render, so it is worth
      // keeping alive while the editor is open.
      ref.keepAlive();
      return ref
          .watch(mediaRepositoryProvider)
          .readOriginalBytes(item, maxBytes: AppConstants.editorMaxSourceBytes);
    });

/// Everything one preview render needs, as a single comparable key.
///
/// Riverpod rebuilds the preview when this value changes, so the render only
/// re-runs when the edit itself actually moved.
class PreviewRequest {
  final MediaItem item;
  final EditSession session;

  const PreviewRequest({required this.item, required this.session});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PreviewRequest &&
          runtimeType == other.runtimeType &&
          item.id == other.item.id &&
          session == other.session;

  @override
  int get hashCode => Object.hash(item.id, session);
}

/// The downscaled preview of the current edit.
///
/// It waits a moment after the last change before rendering, so dragging a
/// slider does not queue a render per pixel of finger movement. A render that
/// fails resolves to null and the editor keeps showing the original.
final editorPreviewProvider = FutureProvider.autoDispose
    .family<Uint8List?, PreviewRequest>((ref, request) async {
      // Set when a newer edit replaces this one, so the wait below can bail
      // out instead of paying for a render nobody will see.
      var superseded = false;
      ref.onDispose(() => superseded = true);

      final bytes = await ref.watch(
        editorSourceBytesProvider(request.item).future,
      );
      if (bytes == null) return null;
      if (!request.session.isDirty) return bytes;

      await Future<void>.delayed(
        const Duration(milliseconds: AppConstants.editorPreviewDebounceMs),
      );
      if (superseded) return null;

      final logoBytes = await _readLogoBytes(
        request.session.watermark,
        ref.watch(mediaRepositoryProvider),
      );

      try {
        final result = await ref
            .watch(imageRenderPipelineProvider)
            .renderInBackground(
              RenderRequest(
                sourceBytes: bytes,
                sessionJson: request.session.toJson(),
                maxSide: AppConstants.editorPreviewMaxSide,
                // The preview is thrown away, so the cheaper encode is used.
                format: RenderFormat.jpeg,
                quality: 85,
                logoBytes: logoBytes,
                captureDate: request.item.dateTaken,
              ),
            );
        return result.bytes;
      } on ImageRenderException {
        // A file the decoder cannot read is reported by the screen, which
        // already handles a null preview.
        return null;
      }
    });

/// The state of a save the user asked for.
///
/// `null` data means no save has been made yet; a value means the last save
/// finished and says where the copy went.
class EditorSaveController extends StateNotifier<AsyncValue<SaveOutcome?>> {
  final ImageRenderPipeline _pipeline;
  final EditorSaveService _saveService;
  final MediaRepository _repository;

  EditorSaveController({
    required ImageRenderPipeline pipeline,
    required EditorSaveService saveService,
    required MediaRepository repository,
  }) : _pipeline = pipeline,
       _saveService = saveService,
       _repository = repository,
       super(const AsyncValue<SaveOutcome?>.data(null));

  /// Renders the edit at full resolution and writes it as a new file.
  ///
  /// The original is only read. Any failure is reported through the state,
  /// never thrown at the widget.
  Future<void> save({
    required MediaItem item,
    required EditSession session,
    required Uint8List sourceBytes,
  }) async {
    if (!session.isDirty) return;

    state = const AsyncValue<SaveOutcome?>.loading();
    try {
      final format = RenderFormat.forFileName(item.displayName);
      final logoBytes = await _readLogoBytes(session.watermark, _repository);

      final rendered = await _pipeline.renderInBackground(
        RenderRequest(
          sourceBytes: sourceBytes,
          sessionJson: session.toJson(),
          format: format,
          quality: AppConstants.editorJpegQuality,
          logoBytes: logoBytes,
          captureDate: item.dateTaken,
        ),
      );

      final outcome = await _saveService.saveCopy(
        sourcePath: item.path,
        bytes: rendered.bytes,
        format: format,
      );
      state = AsyncValue<SaveOutcome?>.data(outcome);
    } catch (error, stackTrace) {
      state = AsyncValue<SaveOutcome?>.error(error, stackTrace);
    }
  }

  /// Clears the result so the screen stops showing the last message.
  void clear() => state = const AsyncValue<SaveOutcome?>.data(null);
}

/// Controller the editor's save button talks to.
final editorSaveControllerProvider =
    StateNotifierProvider.autoDispose<
      EditorSaveController,
      AsyncValue<SaveOutcome?>
    >((ref) {
      return EditorSaveController(
        pipeline: ref.watch(imageRenderPipelineProvider),
        saveService: ref.watch(editorSaveServiceProvider),
        repository: ref.watch(mediaRepositoryProvider),
      );
    });

/// Reads the watermark logo, or null when there is nothing to read.
///
/// The direct file read is tried first; under scoped storage it often fails,
/// so the indexed copy is asked for through the repository as well. A logo
/// the user has since deleted must never stop a save, so every failure just
/// means the watermark is skipped.
Future<Uint8List?> _readLogoBytes(
  WatermarkConfig config,
  MediaRepository repository,
) async {
  if (config.mode != WatermarkMode.logo) return null;
  final path = config.logoPath;
  if (path == null || path.isEmpty) return null;

  try {
    final file = File(path);
    if (await file.exists()) return await file.readAsBytes();
  } catch (_) {
    // Fall through to the repository, which goes via the MediaStore.
  }

  try {
    final item = await repository.getMediaItemByPath(path);
    if (item == null) return null;
    return await repository.readOriginalBytes(
      item,
      maxBytes: AppConstants.editorMaxSourceBytes,
    );
  } catch (_) {
    return null;
  }
}
