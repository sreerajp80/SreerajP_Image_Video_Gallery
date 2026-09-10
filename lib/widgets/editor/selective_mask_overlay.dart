import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';

/// The gesture and visualisation overlay for selective masks.
///
/// Drawn over the preview when the Masks tool is active. Shows:
/// - For linear: a line between start and end handles with gradient fill.
/// - For radial: a circle with centre and edge handles.
/// - Drag handles for repositioning.
class SelectiveMaskOverlay extends StatelessWidget {
  final List<SelectiveMask> masks;
  final String? selectedMaskId;
  final ValueChanged<SelectiveMask> onMaskUpdated;

  const SelectiveMaskOverlay({
    super.key,
    required this.masks,
    required this.selectedMaskId,
    required this.onMaskUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          children: [
            // Paint all masks as semi-transparent overlays.
            CustomPaint(
              painter: _MaskOverlayPainter(
                masks: masks,
                selectedId: selectedMaskId,
                size: size,
              ),
              size: size,
            ),
            // Drag handles for the selected mask.
            if (selectedMaskId != null) ..._buildHandles(size),
          ],
        );
      },
    );
  }

  List<Widget> _buildHandles(Size size) {
    final mask = masks.cast<SelectiveMask?>().firstWhere(
      (m) => m?.id == selectedMaskId,
      orElse: () => null,
    );
    if (mask == null) return const [];

    Widget handle(NormalizedPoint point, bool isStart) {
      final left = point.x * size.width - 14;
      final top = point.y * size.height - 14;

      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          onPanUpdate: (details) {
            final nx = ((point.x * size.width + details.delta.dx) / size.width)
                .clamp(0.0, 1.0);
            final ny =
                ((point.y * size.height + details.delta.dy) / size.height)
                    .clamp(0.0, 1.0);
            final newPoint = NormalizedPoint(nx, ny);
            onMaskUpdated(
              mask.copyWith(
                startPoint: isStart ? newPoint : mask.startPoint,
                endPoint: isStart ? mask.endPoint : newPoint,
              ),
            );
          },
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.9),
              border: Border.all(color: Colors.black54, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return [handle(mask.startPoint, true), handle(mask.endPoint, false)];
  }
}

/// Paints mask regions as semi-transparent coloured overlays.
class _MaskOverlayPainter extends CustomPainter {
  final List<SelectiveMask> masks;
  final String? selectedId;
  final Size size;

  const _MaskOverlayPainter({
    required this.masks,
    required this.selectedId,
    required this.size,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    for (final mask in masks) {
      final isSelected = mask.id == selectedId;
      final alpha = isSelected ? 0.3 : 0.15;

      switch (mask.shape) {
        case MaskShape.linear:
          _paintLinear(canvas, mask, alpha);
        case MaskShape.radial:
          _paintRadial(canvas, mask, alpha);
      }
    }
  }

  void _paintLinear(Canvas canvas, SelectiveMask mask, double alpha) {
    final start = Offset(
      mask.startPoint.x * size.width,
      mask.startPoint.y * size.height,
    );
    final end = Offset(
      mask.endPoint.x * size.width,
      mask.endPoint.y * size.height,
    );

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(
          (mask.startPoint.x * 2 - 1),
          (mask.startPoint.y * 2 - 1),
        ),
        end: Alignment((mask.endPoint.x * 2 - 1), (mask.endPoint.y * 2 - 1)),
        colors: mask.invert
            ? [
                Colors.blue.withValues(alpha: 0),
                Colors.blue.withValues(alpha: alpha),
              ]
            : [
                Colors.blue.withValues(alpha: alpha),
                Colors.blue.withValues(alpha: 0),
              ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    // Connection line.
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(start, end, linePaint);
  }

  void _paintRadial(Canvas canvas, SelectiveMask mask, double alpha) {
    final cx = mask.startPoint.x * size.width;
    final cy = mask.startPoint.y * size.height;
    final ex = mask.endPoint.x * size.width;
    final ey = mask.endPoint.y * size.height;
    final radius = math.sqrt((ex - cx) * (ex - cx) + (ey - cy) * (ey - cy));

    if (radius < 1) return;

    final centre = Offset(cx, cy);

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment(
          (mask.startPoint.x * 2 - 1),
          (mask.startPoint.y * 2 - 1),
        ),
        radius: radius / math.max(size.width, size.height),
        colors: mask.invert
            ? [
                Colors.blue.withValues(alpha: 0),
                Colors.blue.withValues(alpha: alpha),
              ]
            : [
                Colors.blue.withValues(alpha: alpha),
                Colors.blue.withValues(alpha: 0),
              ],
      ).createShader(Offset.zero & size);

    canvas.drawRect(Offset.zero & size, paint);

    // Circle outline.
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(centre, radius, circlePaint);
  }

  @override
  bool shouldRepaint(covariant _MaskOverlayPainter old) =>
      old.masks != masks || old.selectedId != selectedId;
}
