import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_curve_service.dart';

/// Which curve the editor is showing.
enum CurveChannel { rgb, red, green, blue }

/// The RGB curve control with free-point placement and cubic spline.
///
/// The user can:
/// - **Tap** on the curve area to add a new control point.
/// - **Drag** any point to reshape the curve.
/// - **Long-press** a point to delete it (end-points cannot be removed,
///   and at least 2 points must remain).
///
/// The maths of turning the points into a table lives in [ToneCurveService],
/// which now uses natural cubic spline interpolation.
class CurveEditor extends StatefulWidget {
  final ToneAdjustments adjustments;

  /// Called when a handle is let go, so one drag is one undo step.
  final ValueChanged<ToneAdjustments> onChanged;

  const CurveEditor({
    super.key,
    required this.adjustments,
    required this.onChanged,
  });

  @override
  State<CurveEditor> createState() => _CurveEditorState();
}

class _CurveEditorState extends State<CurveEditor> {
  static const ToneCurveService _service = ToneCurveService();

  /// Hit radius for detecting a tap or drag near a point.
  static const double _hitRadius = 20;

  /// The maximum number of user-placed control points.
  static const int _maxPoints = 10;

  CurveChannel _channel = CurveChannel.rgb;

  /// The handle currently under the finger, or null between drags.
  int? _draggingIndex;

  ToneCurve get _curve {
    switch (_channel) {
      case CurveChannel.rgb:
        return widget.adjustments.rgbCurve;
      case CurveChannel.red:
        return widget.adjustments.redCurve;
      case CurveChannel.green:
        return widget.adjustments.greenCurve;
      case CurveChannel.blue:
        return widget.adjustments.blueCurve;
    }
  }

  /// The control points for the shown channel.
  List<CurvePoint> get _points {
    final points = _service.sanitize(_curve.points);
    if (points.length >= 2) return points;
    return const <CurvePoint>[CurvePoint(0, 0), CurvePoint(255, 255)];
  }

  ToneAdjustments _withCurve(ToneCurve curve) {
    switch (_channel) {
      case CurveChannel.rgb:
        return widget.adjustments.copyWith(rgbCurve: curve);
      case CurveChannel.red:
        return widget.adjustments.copyWith(redCurve: curve);
      case CurveChannel.green:
        return widget.adjustments.copyWith(greenCurve: curve);
      case CurveChannel.blue:
        return widget.adjustments.copyWith(blueCurve: curve);
    }
  }

  Offset _pointToLocal(CurvePoint point, Size size) {
    return Offset(
      point.input / 255 * size.width,
      (1 - point.output / 255) * size.height,
    );
  }

  CurvePoint _localToPoint(Offset local, Size size) {
    return CurvePoint(
      (local.dx / size.width * 255).clamp(0.0, 255.0),
      ((1 - local.dy / size.height) * 255).clamp(0.0, 255.0),
    );
  }

  int? _findNearestPoint(Offset local, Size size) {
    final points = _points;
    int? best;
    var bestDist = double.infinity;
    for (var i = 0; i < points.length; i++) {
      final pos = _pointToLocal(points[i], size);
      final dist = (pos - local).distance;
      if (dist < _hitRadius && dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  void _onPanStart(DragStartDetails details, Size size) {
    final index = _findNearestPoint(details.localPosition, size);
    _draggingIndex = index;
    if (index != null) {
      setState(() {});
    }
  }

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (_draggingIndex == null) return;

    final points = List<CurvePoint>.from(_points);
    final index = _draggingIndex!;
    if (index >= points.length) return;

    final newPoint = _localToPoint(details.localPosition, size);

    // End points keep their input value locked.
    final isEndpoint = index == 0 || index == points.length - 1;
    final input = isEndpoint
        ? points[index].input
        : newPoint.input.clamp(
            points[index - 1].input + 1,
            points[index + 1].input - 1,
          );

    points[index] = CurvePoint(input, newPoint.output);

    final updated = _withCurve(ToneCurve(points));
    setState(() {});
    widget.onChanged(updated);
  }

  void _onPanEnd(DragEndDetails _) {
    _draggingIndex = null;
    setState(() {});
  }

  void _onTapUp(TapUpDetails details, Size size) {
    final points = _points;
    // If tapped near an existing point, do nothing (drag handles it).
    if (_findNearestPoint(details.localPosition, size) != null) return;

    // Max point limit.
    if (points.length >= _maxPoints) return;

    // Add a new point at the tap location.
    final newPoint = _localToPoint(details.localPosition, size);
    final updated = _withCurve(_curve.withPoint(newPoint));
    widget.onChanged(updated);
  }

  void _onLongPress(LongPressStartDetails details, Size size) {
    final points = _points;
    final index = _findNearestPoint(details.localPosition, size);
    if (index == null) return;

    // Cannot remove end points, and must keep at least 2 points.
    if (index == 0 || index == points.length - 1) return;
    if (points.length <= 2) return;

    final remaining = List<CurvePoint>.from(points)..removeAt(index);
    final updated = _withCurve(ToneCurve(remaining));
    widget.onChanged(updated);
  }

  void _resetCurve() {
    _draggingIndex = null;
    widget.onChanged(_withCurve(ToneCurve.linear));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final labels = <CurveChannel, String>{
      CurveChannel.rgb: l10n.curveChannelRgb,
      CurveChannel.red: l10n.curveChannelRed,
      CurveChannel.green: l10n.curveChannelGreen,
      CurveChannel.blue: l10n.curveChannelBlue,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.toneCurves, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: CurveChannel.values.map((channel) {
              return ChoiceChip(
                label: Text(labels[channel]!),
                selected: _channel == channel,
                onSelected: (_) => setState(() => _channel = channel),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.6,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = Size(constraints.maxWidth, constraints.maxHeight);
                return GestureDetector(
                  onPanStart: (d) => _onPanStart(d, size),
                  onPanUpdate: (d) => _onPanUpdate(d, size),
                  onPanEnd: _onPanEnd,
                  onTapUp: (d) => _onTapUp(d, size),
                  onLongPressStart: (d) => _onLongPress(d, size),
                  child: CustomPaint(
                    painter: _CurvePainter(
                      points: _points,
                      service: _service,
                      lineColor: _channelColor(theme),
                      gridColor: theme.colorScheme.outlineVariant,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      draggingIndex: _draggingIndex,
                    ),
                    size: size,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  l10n.curveAddHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(onPressed: _resetCurve, child: Text(l10n.curveReset)),
            ],
          ),
        ],
      ),
    );
  }

  Color _channelColor(ThemeData theme) {
    switch (_channel) {
      case CurveChannel.rgb:
        return theme.colorScheme.primary;
      case CurveChannel.red:
        return const Color(0xFFE53935);
      case CurveChannel.green:
        return const Color(0xFF43A047);
      case CurveChannel.blue:
        return const Color(0xFF1E88E5);
    }
  }
}

/// Draws the curve, its grid, the identity reference line, and the handles.
class _CurvePainter extends CustomPainter {
  final List<CurvePoint> points;
  final ToneCurveService service;
  final Color lineColor;
  final Color gridColor;
  final Color backgroundColor;
  final int? draggingIndex;

  const _CurvePainter({
    required this.points,
    required this.service,
    required this.lineColor,
    required this.gridColor,
    required this.backgroundColor,
    this.draggingIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = backgroundColor;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      background,
    );

    // Grid lines.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }

    // Identity reference line (diagonal).
    final identityPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, 0),
      identityPaint,
    );

    // The spline curve, sampled at 128 steps for smoothness.
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    const steps = 128;
    for (var i = 0; i <= steps; i++) {
      final input = i / steps * 255;
      final output = service.evaluate(points, input);
      final x = input / 255 * size.width;
      final y = (1 - output / 255) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    // Control point handles.
    final handleFill = Paint()..color = lineColor;
    final handleStroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length; i++) {
      final centre = Offset(
        points[i].input / 255 * size.width,
        (1 - points[i].output / 255) * size.height,
      );
      final radius = i == draggingIndex ? 9.0 : 6.0;
      canvas.drawCircle(centre, radius, handleFill);
      canvas.drawCircle(centre, radius, handleStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.draggingIndex != draggingIndex;
}
