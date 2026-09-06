import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/viewer/viewer_transform_service.dart';

/// Displays Photo A and Photo B in a split view (either side-by-side or
/// stacked vertically).
///
/// Supports locked (synchronized) or independent pan and pinch-to-zoom.
class SplitComparisonView extends ConsumerStatefulWidget {
  final MediaItem itemA;
  final MediaItem itemB;
  final bool isHorizontal;
  final bool isSynchronized;
  final VoidCallback? onTap;
  final TransformationController controllerA;
  final TransformationController controllerB;

  const SplitComparisonView({
    super.key,
    required this.itemA,
    required this.itemB,
    required this.isHorizontal,
    required this.isSynchronized,
    required this.controllerA,
    required this.controllerB,
    this.onTap,
  });

  @override
  ConsumerState<SplitComparisonView> createState() =>
      _SplitComparisonViewState();
}

class _SplitComparisonViewState extends ConsumerState<SplitComparisonView>
    with SingleTickerProviderStateMixin {
  bool _isUpdating = false;

  late final AnimationController _zoomAnimationController;
  Animation<Matrix4>? _zoomAnimation;
  TransformationController? _animatingController;
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _zoomAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(_applyZoomAnimation);

    widget.controllerA.addListener(_onControllerAChanged);
    widget.controllerB.addListener(_onControllerBChanged);

    // Initial sync if synchronized
    if (widget.isSynchronized) {
      widget.controllerB.value = widget.controllerA.value.clone();
    }
  }

  @override
  void didUpdateWidget(SplitComparisonView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controllerA != widget.controllerA) {
      oldWidget.controllerA.removeListener(_onControllerAChanged);
      widget.controllerA.addListener(_onControllerAChanged);
    }
    if (oldWidget.controllerB != widget.controllerB) {
      oldWidget.controllerB.removeListener(_onControllerBChanged);
      widget.controllerB.addListener(_onControllerBChanged);
    }

    if (!oldWidget.isSynchronized && widget.isSynchronized) {
      // Re-locking sync: mirror controller A onto controller B
      widget.controllerB.value = widget.controllerA.value.clone();
    }
  }

  @override
  void dispose() {
    widget.controllerA.removeListener(_onControllerAChanged);
    widget.controllerB.removeListener(_onControllerBChanged);
    _zoomAnimationController.removeListener(_applyZoomAnimation);
    _zoomAnimationController.dispose();
    super.dispose();
  }

  void _applyZoomAnimation() {
    final anim = _zoomAnimation;
    final ctrl = _animatingController;
    if (anim != null && ctrl != null) {
      ctrl.value = anim.value;
    }
  }

  void _onControllerAChanged() {
    if (_isUpdating || !widget.isSynchronized) return;
    _isUpdating = true;
    try {
      if (widget.controllerB.value != widget.controllerA.value) {
        widget.controllerB.value = widget.controllerA.value.clone();
      }
    } finally {
      _isUpdating = false;
    }
  }

  void _onControllerBChanged() {
    if (_isUpdating || !widget.isSynchronized) return;
    _isUpdating = true;
    try {
      if (widget.controllerA.value != widget.controllerB.value) {
        widget.controllerA.value = widget.controllerB.value.clone();
      }
    } finally {
      _isUpdating = false;
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _doubleTapPosition = details.localPosition;
  }

  void _onDoubleTap(TransformationController targetController, Size paneSize) {
    final service = ref.read(viewerTransformServiceProvider);
    final currentScale = service.scaleOf(targetController.value);
    final targetScale = service.doubleTapTargetScale(currentScale);

    final target = service.zoomMatrix(
      targetScale: targetScale,
      focalPoint: _doubleTapPosition,
      viewportSize: paneSize,
    );

    _animatingController = targetController;
    _zoomAnimation = Matrix4Tween(begin: targetController.value, end: target)
        .animate(
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

    final paneA = _ComparisonPane(
      key: const ValueKey('paneA'),
      item: widget.itemA,
      controller: widget.controllerA,
      badgeLabel: 'A: ${widget.itemA.displayName}',
      badgeColor: theme.colorScheme.primaryContainer,
      badgeTextColor: theme.colorScheme.onPrimaryContainer,
      onTap: widget.onTap,
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: (size) => _onDoubleTap(widget.controllerA, size),
    );

    final paneB = _ComparisonPane(
      key: const ValueKey('paneB'),
      item: widget.itemB,
      controller: widget.controllerB,
      badgeLabel: 'B: ${widget.itemB.displayName}',
      badgeColor: theme.colorScheme.secondaryContainer,
      badgeTextColor: theme.colorScheme.onSecondaryContainer,
      onTap: widget.onTap,
      onDoubleTapDown: _onDoubleTapDown,
      onDoubleTap: (size) => _onDoubleTap(widget.controllerB, size),
    );

    final divider = Container(
      color: theme.colorScheme.outlineVariant,
      width: widget.isHorizontal ? 2 : double.infinity,
      height: widget.isHorizontal ? double.infinity : 2,
    );

    if (widget.isHorizontal) {
      return Row(
        children: [
          Expanded(child: paneA),
          divider,
          Expanded(child: paneB),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(child: paneA),
          divider,
          Expanded(child: paneB),
        ],
      );
    }
  }
}

class _ComparisonPane extends StatelessWidget {
  final MediaItem item;
  final TransformationController controller;
  final String badgeLabel;
  final Color badgeColor;
  final Color badgeTextColor;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onDoubleTapDown;
  final void Function(Size size) onDoubleTap;

  const _ComparisonPane({
    super.key,
    required this.item,
    required this.controller,
    required this.badgeLabel,
    required this.badgeColor,
    required this.badgeTextColor,
    this.onTap,
    this.onDoubleTapDown,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: onTap,
              onDoubleTapDown: onDoubleTapDown,
              onDoubleTap: () => onDoubleTap(size),
              child: InteractiveViewer(
                transformationController: controller,
                minScale: ViewerTransformService.minScale,
                maxScale: ViewerTransformService.maxScale,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: _SplitImageDisplay(item: item),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 4),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 150),
                  child: Text(
                    badgeLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeTextColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
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

class _SplitImageDisplay extends ConsumerWidget {
  final MediaItem item;

  const _SplitImageDisplay({required this.item});

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
              size: 36,
              color: Colors.white54,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.mediaUnavailable,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
              size: 36,
              color: Colors.white54,
            ),
            const SizedBox(height: 6),
            Text(
              l10n.mediaUnavailable,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
