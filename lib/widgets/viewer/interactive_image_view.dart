import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/viewer/viewer_transform_service.dart';

/// One zoomable, pannable, rotatable image page of the fullscreen viewer.
///
/// It draws the cached thumbnail first and swaps in the original bytes once
/// they arrive, so a page never opens blank. Files that cannot be read at full
/// size simply stay on the thumbnail, and a file that cannot be decoded at all
/// shows a message rather than throwing.
class InteractiveImageView extends ConsumerStatefulWidget {
  final MediaItem item;

  /// Rotation preview in degrees, one of 0, 90, 180, or 270.
  final int rotationDegrees;

  /// Called whenever the zoom level changes.
  ///
  /// The viewer uses it to decide whether paging and swipe-to-dismiss are
  /// allowed, because both are only safe while the image is fitted.
  final ValueChanged<double> onScaleChanged;

  /// Called on a single tap, which shows or hides the viewer chrome.
  final VoidCallback onTap;

  const InteractiveImageView({
    super.key,
    required this.item,
    required this.rotationDegrees,
    required this.onScaleChanged,
    required this.onTap,
  });

  @override
  ConsumerState<InteractiveImageView> createState() =>
      _InteractiveImageViewState();
}

class _InteractiveImageViewState extends ConsumerState<InteractiveImageView>
    with SingleTickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();

  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;

  /// Where the last double tap landed, used as the zoom focal point.
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_applyZoomAnimation);
    _transformationController.addListener(_reportScale);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_reportScale);
    _zoomAnimationController.removeListener(_applyZoomAnimation);
    _zoomAnimationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _reportScale() {
    final service = ref.read(viewerTransformServiceProvider);
    widget.onScaleChanged(service.scaleOf(_transformationController.value));
  }

  void _applyZoomAnimation() {
    final animation = _zoomAnimation;
    if (animation == null) return;
    _transformationController.value = animation.value;
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  /// Animates between the fitted size and the double-tap zoom level.
  void _onDoubleTap() {
    final service = ref.read(viewerTransformServiceProvider);
    final currentScale = service.scaleOf(_transformationController.value);
    final targetScale = service.doubleTapTargetScale(currentScale);

    final size = context.size;
    if (size == null) return;

    final target = service.zoomMatrix(
      targetScale: targetScale,
      focalPoint: _doubleTapPosition,
      viewportSize: size,
    );

    _zoomAnimation =
        Matrix4Tween(
          begin: _transformationController.value,
          end: target,
        ).animate(
          CurvedAnimation(
            parent: _zoomAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _zoomAnimationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(viewerTransformServiceProvider);
    final fullBytes = ref.watch(fullImageBytesProvider(widget.item));
    final thumbnail = ref.watch(thumbnailProvider(widget.item));
    final l10n = AppLocalizations.of(context)!;

    final bytes = fullBytes.valueOrNull ?? thumbnail.valueOrNull;

    Widget content;
    if (bytes == null || bytes.isEmpty) {
      content = fullBytes.isLoading || thumbnail.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ViewerMessage(
              icon: Icons.broken_image_outlined,
              message: l10n.mediaUnavailable,
            );
    } else {
      content = Image.memory(
        bytes,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, error, stackTrace) => _ViewerMessage(
          icon: Icons.broken_image_outlined,
          message: l10n.mediaUnavailable,
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        minScale: ViewerTransformService.minScale,
        maxScale: ViewerTransformService.maxScale,
        clipBehavior: Clip.none,
        child: Center(
          child: Transform.rotate(
            angle: service.rotationRadians(widget.rotationDegrees),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Centred icon and message used when a page cannot be drawn.
class _ViewerMessage extends StatelessWidget {
  final IconData icon;
  final String message;

  const _ViewerMessage({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.white70),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
