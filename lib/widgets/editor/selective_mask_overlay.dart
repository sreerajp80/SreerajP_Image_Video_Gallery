import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
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
            // A screen reader cannot drag a handle, so the selected mask can
            // also be moved with actions (standard §7.3). This node takes no
            // touches; the handles above it still get the drags.
            if (_selected != null)
              Positioned.fill(child: _semantics(context, _selected!)),
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

  SelectiveMask? get _selected => masks.cast<SelectiveMask?>().firstWhere(
    (m) => m?.id == selectedMaskId,
    orElse: () => null,
  );

  /// How far one screen-reader action moves the mask.
  static const double _step = 0.05;

  Widget _semantics(BuildContext context, SelectiveMask mask) {
    final l10n = AppLocalizations.of(context)!;
    final shape = switch (mask.shape) {
      MaskShape.linear => l10n.labelMaskShapeLinear,
      MaskShape.radial => l10n.labelMaskShapeRadial,
    };
    // A radial mask is centred on its start point; a linear one between
    // its two points.
    final centre = mask.shape == MaskShape.radial
        ? mask.startPoint
        : NormalizedPoint(
            (mask.startPoint.x + mask.endPoint.x) / 2,
            (mask.startPoint.y + mask.endPoint.y) / 2,
          );

    void move(double dx, double dy) {
      // Both points move together, kept inside the photo.
      final points = <NormalizedPoint>[mask.startPoint, mask.endPoint];
      final minX = points.map((p) => p.x).reduce(math.min);
      final maxX = points.map((p) => p.x).reduce(math.max);
      final minY = points.map((p) => p.y).reduce(math.min);
      final maxY = points.map((p) => p.y).reduce(math.max);
      final sx = dx.clamp(-minX, 1 - maxX);
      final sy = dy.clamp(-minY, 1 - maxY);
      NormalizedPoint shifted(NormalizedPoint p) =>
          NormalizedPoint(p.x + sx, p.y + sy);
      onMaskUpdated(
        mask.copyWith(
          startPoint: shifted(mask.startPoint),
          endPoint: shifted(mask.endPoint),
        ),
      );
    }

    return Semantics(
      container: true,
      label: l10n.labelA11yMaskArea,
      value: l10n.bodyA11yMaskValue(
        shape,
        (centre.x * 100).round(),
        (centre.y * 100).round(),
      ),
      hint: l10n.helpA11yMaskHint,
      customSemanticsActions: <CustomSemanticsAction, VoidCallback>{
        CustomSemanticsAction(label: l10n.labelA11yMoveLeft): () =>
            move(-_step, 0),
        CustomSemanticsAction(label: l10n.labelA11yMoveRight): () =>
            move(_step, 0),
        CustomSemanticsAction(label: l10n.labelA11yMoveUp): () =>
            move(0, -_step),
        CustomSemanticsAction(label: l10n.labelA11yMoveDown): () =>
            move(0, _step),
      },
      child: const SizedBox.expand(),
    );
  }

  List<Widget> _buildHandles(Size size) {
    final mask = masks.cast<SelectiveMask?>().firstWhere(
      (m) => m?.id == selectedMaskId,
      orElse: () => null,
    );
    if (mask == null) return const [];

    Widget handle(NormalizedPoint point, bool isStart) {
      // The dot is 28 dp, but the area that takes the drag is 48 dp
      // (standard §7.1), centred on the point.
      final left = point.x * size.width - 24;
      final top = point.y * size.height - 24;

      return Positioned(
        left: left,
        top: top,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
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
          child: SizedBox.square(
            dimension: 48,
            child: Center(
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
