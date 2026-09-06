import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/viewer/viewer_transform_service.dart';

/// Interactive sliding curtain comparison view.
///
/// Photo A and Photo B are layered with a draggable vertical divider. Panning
/// and pinching anywhere on the images operates on a shared
/// [TransformationController], guaranteeing 100% synchronized zoom and pan
/// across both photos.
class CurtainComparisonView extends ConsumerStatefulWidget {
  final MediaItem itemA;
  final MediaItem itemB;
  final TransformationController transformationController;
  final VoidCallback? onResetZoom;
  final VoidCallback? onTap;

  const CurtainComparisonView({
    super.key,
    required this.itemA,
    required this.itemB,
    required this.transformationController,
    this.onResetZoom,
    this.onTap,
  });

  @override
  ConsumerState<CurtainComparisonView> createState() =>
      _CurtainComparisonViewState();
}

class _CurtainComparisonViewState extends ConsumerState<CurtainComparisonView>
    with SingleTickerProviderStateMixin {
  /// Divider fraction from 0.0 (left) to 1.0 (right).
  double _dividerFraction = 0.5;

  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _zoomAnimationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 220),
        )..addListener(() {
          final anim = _zoomAnimation;
          if (anim != null) {
            widget.transformationController.value = anim.value;
          }
        });
  }

  @override
  void dispose() {
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _onDoubleTap() {
    final service = ref.read(viewerTransformServiceProvider);
    final currentScale = service.scaleOf(widget.transformationController.value);
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
          begin: widget.transformationController.value,
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
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final dividerX = width * _dividerFraction;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Base Layer: Photo B (shown on the right of the divider)
            GestureDetector(
              onTap: widget.onTap,
              onDoubleTapDown: _onDoubleTapDown,
              onDoubleTap: _onDoubleTap,
              child: InteractiveViewer(
                transformationController: widget.transformationController,
                minScale: ViewerTransformService.minScale,
                maxScale: ViewerTransformService.maxScale,
                clipBehavior: Clip.none,
                child: SizedBox(
                  width: width,
                  height: height,
                  child: _CompareImageDisplay(item: widget.itemB),
                ),
              ),
            ),

            // Top Layer: Photo A clipped to the left of the divider
            Positioned.fill(
              child: ClipRect(
                clipper: _LeftCurtainClipper(dividerX: dividerX),
                child: IgnorePointer(
                  // Pointer events pass through to the InteractiveViewer underneath
                  ignoring: true,
                  child: ValueListenableBuilder<Matrix4>(
                    valueListenable: widget.transformationController,
                    builder: (context, matrix, _) {
                      return Transform(
                        transform: matrix,
                        child: SizedBox(
                          width: width,
                          height: height,
                          child: _CompareImageDisplay(item: widget.itemA),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Floating Badges: "A" (top-left) and "B" (top-right)
            Positioned(
              top: 16,
              left: 16,
              child: _CurtainBadge(
                label: 'A: ${widget.itemA.displayName}',
                color: theme.colorScheme.primaryContainer,
                textColor: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: _CurtainBadge(
                label: 'B: ${widget.itemB.displayName}',
                color: theme.colorScheme.secondaryContainer,
                textColor: theme.colorScheme.onSecondaryContainer,
              ),
            ),

            // Vertical Divider Line
            Positioned(
              left: dividerX - 1.5,
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Draggable Divider Handle
            Positioned(
              left: dividerX - 22,
              top: height * 0.48 - 22,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _dividerFraction = (details.globalPosition.dx / width)
                        .clamp(0.02, 0.98);
                  });
                },
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.compare_arrows_rounded,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _LeftCurtainClipper extends CustomClipper<Rect> {
  final double dividerX;

  const _LeftCurtainClipper({required this.dividerX});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, dividerX, size.height);
  }

  @override
  bool shouldReclip(_LeftCurtainClipper oldClipper) {
    return oldClipper.dividerX != dividerX;
  }
}

class _CurtainBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;

  const _CurtainBadge({
    required this.label,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 160),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: textColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Renders the image bytes (full image or fallback thumbnail).
class _CompareImageDisplay extends ConsumerWidget {
  final MediaItem item;

  const _CompareImageDisplay({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullBytes = ref.watch(fullImageBytesProvider(item));
    final thumbnail = ref.watch(thumbnailProvider(item));
    final l10n = AppLocalizations.of(context)!;

    final bytes = fullBytes.valueOrNull ?? thumbnail.valueOrNull;

    if (bytes == null || bytes.isEmpty) {
      if (fullBytes.isLoading || thumbnail.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mediaUnavailable,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      );
    }

    return Image.memory(
      bytes,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.broken_image_outlined,
              size: 40,
              color: Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.mediaUnavailable,
              style: const TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
