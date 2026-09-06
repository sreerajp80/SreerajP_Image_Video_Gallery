import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/markup_layer.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/crop_transform_service.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/markup_geometry_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';

/// The drawing surface laid over the preview.
///
/// It captures a finger, shows the stroke or shape as it is being made, and
/// hands the finished layer up when the finger lifts. It never keeps the
/// finished drawing itself: that lives in the edit session, which is what
/// makes undo work.
class MarkupCanvas extends StatefulWidget {
  /// Layers already in the session, drawn under the one being made.
  final List<MarkupLayer> layers;

  final MarkupToolSettings settings;

  /// Called once with the finished layer when the finger lifts.
  final ValueChanged<MarkupLayer> onLayerCompleted;

  const MarkupCanvas({
    super.key,
    required this.layers,
    required this.settings,
    required this.onLayerCompleted,
  });

  @override
  State<MarkupCanvas> createState() => _MarkupCanvasState();
}

class _MarkupCanvasState extends State<MarkupCanvas> {
  static const MarkupGeometryService _geometry = MarkupGeometryService();

  /// The layer the finger is currently making, or null between drags.
  MarkupLayer? _inProgress;

  NormalizedPoint _pointFor(Offset local, Size size) =>
      _geometry.toNormalized(local.dx, local.dy, size.width, size.height);

  /// A new id for a layer, unique enough for one editing session.
  String _newId() => 'layer_${DateTime.now().microsecondsSinceEpoch}';

  void _start(Offset local, Size size) {
    final point = _pointFor(local, size);
    final settings = widget.settings;

    setState(() {
      _inProgress = settings.freehand
          ? DoodleStroke(
              id: _newId(),
              colorArgb: settings.colorArgb,
              points: <NormalizedPoint>[point],
              strokeWidth: settings.strokeWidth,
            )
          : ShapeAnnotation(
              id: _newId(),
              colorArgb: settings.colorArgb,
              shape: settings.shape,
              start: point,
              end: point,
              strokeWidth: settings.strokeWidth,
              filled: settings.filled,
            );
    });
  }

  void _update(Offset local, Size size) {
    final current = _inProgress;
    if (current == null) return;

    final point = _pointFor(local, size);
    setState(() {
      _inProgress = switch (current) {
        DoodleStroke() => current.withPoint(point),
        ShapeAnnotation() => current.copyWith(end: point),
        // Text is placed by the panel, not dragged, so it never gets here.
        TextAnnotation() => current,
      };
    });
  }

  void _finish() {
    final current = _inProgress;
    setState(() => _inProgress = null);
    if (current == null) return;
    // A tap that drew nothing is simply dropped.
    if (!_geometry.isDrawable(current)) return;
    widget.onLayerCompleted(current);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => _start(details.localPosition, size),
          onPanUpdate: (details) => _update(details.localPosition, size),
          onPanEnd: (_) => _finish(),
          onPanCancel: _finish,
          child: CustomPaint(
            painter: MarkupPainter(
              layers: <MarkupLayer>[
                ...widget.layers,
                if (_inProgress != null) _inProgress!,
              ],
            ),
            size: size,
          ),
        );
      },
    );
  }
}

/// Adapts a layout [Size] to the pixel size the geometry service expects.
///
/// The canvas works in logical pixels while the service works in image
/// pixels, but the maths is the same shape, so the size is simply rounded.
PixelSize _pixelSizeOf(Size size) => PixelSize(
  size.width.round().clamp(1, 1 << 24),
  size.height.round().clamp(1, 1 << 24),
);

/// Draws markup layers on screen.
///
/// This is the on-screen twin of the renderer that writes the same layers
/// into the saved file. Both read the geometry service, so what the user sees
/// is what gets saved.
class MarkupPainter extends CustomPainter {
  final List<MarkupLayer> layers;

  static const MarkupGeometryService _geometry = MarkupGeometryService();

  const MarkupPainter({required this.layers});

  @override
  void paint(Canvas canvas, Size size) {
    for (final layer in layers) {
      if (!_geometry.isDrawable(layer)) continue;

      final paint = Paint()
        ..color = Color(
          layer.colorArgb,
        ).withValues(alpha: layer.opacity.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      switch (layer) {
        case DoodleStroke():
          paint.strokeWidth = _strokePixels(layer.strokeWidth, size);
          final path = Path();
          for (var i = 0; i < layer.points.length; i++) {
            final offset = _offsetFor(layer.points[i], size);
            if (i == 0) {
              path.moveTo(offset.dx, offset.dy);
            } else {
              path.lineTo(offset.dx, offset.dy);
            }
          }
          canvas.drawPath(path, paint);

        case ShapeAnnotation():
          paint.strokeWidth = _strokePixels(layer.strokeWidth, size);
          if (layer.filled &&
              layer.shape != ShapeKind.line &&
              layer.shape != ShapeKind.arrow) {
            paint.style = PaintingStyle.fill;
          }
          final start = _offsetFor(layer.start, size);
          final end = _offsetFor(layer.end, size);
          final rect = Rect.fromPoints(start, end);

          switch (layer.shape) {
            case ShapeKind.rectangle:
              canvas.drawRect(rect, paint);
            case ShapeKind.ellipse:
              canvas.drawOval(rect, paint);
            case ShapeKind.line:
              canvas.drawLine(start, end, paint);
            case ShapeKind.arrow:
              canvas.drawLine(start, end, paint);
              final barbs = _geometry.arrowHeadPoints(
                layer.start,
                layer.end,
                _pixelSizeOf(size),
                paint.strokeWidth.round().clamp(1, 1 << 20),
              );
              for (final barb in barbs) {
                canvas.drawLine(
                  end,
                  Offset(barb.x.toDouble(), barb.y.toDouble()),
                  paint,
                );
              }
          }

        case TextAnnotation():
          _paintText(canvas, size, layer);
      }
    }
  }

  void _paintText(Canvas canvas, Size size, TextAnnotation layer) {
    final fontSize = _geometry
        .fontSizeInPixels(layer.fontScale, _pixelSizeOf(size))
        .toDouble();

    final painter = TextPainter(
      text: TextSpan(
        text: layer.text,
        style: TextStyle(
          color: Color(
            layer.colorArgb,
          ).withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
          fontSize: fontSize,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final origin = _offsetFor(layer.position, size);
    final dx = origin.dx.clamp(
      0.0,
      (size.width - painter.width).clamp(0.0, size.width),
    );
    final dy = origin.dy.clamp(
      0.0,
      (size.height - painter.height).clamp(0.0, size.height),
    );

    if (layer.hasBackground) {
      final padding = fontSize / 6;
      canvas.drawRect(
        Rect.fromLTWH(
          dx - padding,
          dy - padding,
          painter.width + padding * 2,
          painter.height + padding * 2,
        ),
        Paint()
          ..color = Color(
            layer.backgroundArgb,
          ).withValues(alpha: layer.opacity.clamp(0.0, 1.0)),
      );
    }

    painter.paint(canvas, Offset(dx, dy));
  }

  Offset _offsetFor(NormalizedPoint point, Size size) =>
      Offset(point.x * size.width, point.y * size.height);

  double _strokePixels(double normalized, Size size) {
    final shorter = size.shortestSide;
    return (normalized.abs() * shorter).clamp(1.0, shorter);
  }

  @override
  bool shouldRepaint(covariant MarkupPainter oldDelegate) =>
      oldDelegate.layers != layers;
}

/// The markup tool's controls: pen, shape, colour, thickness, and text.
class MarkupControlsPanel extends StatelessWidget {
  final MarkupToolSettings settings;
  final ValueChanged<MarkupToolSettings> onSettingsChanged;
  final VoidCallback onAddText;
  final VoidCallback onRemoveLast;
  final bool canRemove;

  /// The colours the pen can be set to.
  static const List<int> penColors = <int>[
    0xFFFF3B30,
    0xFFFFCC00,
    0xFF34C759,
    0xFF007AFF,
    0xFFFFFFFF,
    0xFF000000,
  ];

  const MarkupControlsPanel({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onAddText,
    required this.onRemoveLast,
    required this.canRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.markupFreehand),
                selected: settings.freehand,
                onSelected: (_) =>
                    onSettingsChanged(settings.copyWith(freehand: true)),
              ),
              _shapeChip(l10n.markupRectangle, ShapeKind.rectangle),
              _shapeChip(l10n.markupEllipse, ShapeKind.ellipse),
              _shapeChip(l10n.markupLine, ShapeKind.line),
              _shapeChip(l10n.markupArrow, ShapeKind.arrow),
              ActionChip(
                avatar: const Icon(Icons.text_fields, size: 18),
                label: Text(l10n.markupText),
                onPressed: onAddText,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(l10n.markupColor, style: theme.textTheme.labelLarge),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 10,
                  children: penColors.map((argb) {
                    final isSelected = settings.colorArgb == argb;
                    return GestureDetector(
                      onTap: () =>
                          onSettingsChanged(settings.copyWith(colorArgb: argb)),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Color(argb),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        EditorSliderRow(
          label: l10n.markupThickness,
          value: settings.strokeWidth,
          min: 0.002,
          max: 0.04,
          neutral: 0.008,
          onChanged: (value) =>
              onSettingsChanged(settings.copyWith(strokeWidth: value)),
          formatValue: (value) => (value * 1000).round().toString(),
        ),
        if (!settings.freehand &&
            settings.shape != ShapeKind.line &&
            settings.shape != ShapeKind.arrow)
          SwitchListTile(
            title: Text(l10n.markupFilled),
            value: settings.filled,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(filled: value)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.markupHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: canRemove ? onRemoveLast : null,
                icon: const Icon(Icons.undo),
                label: Text(l10n.markupUndoLayer),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shapeChip(String label, ShapeKind kind) {
    return ChoiceChip(
      label: Text(label),
      selected: !settings.freehand && settings.shape == kind,
      onSelected: (_) =>
          onSettingsChanged(settings.copyWith(freehand: false, shape: kind)),
    );
  }
}
