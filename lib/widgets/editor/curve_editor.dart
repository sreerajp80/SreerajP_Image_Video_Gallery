import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_adjustments.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/tone_curve.dart';
import 'package:in_sreerajp_imgvidgal/services/editor/tone_curve_service.dart';

/// Which curve the editor is showing.
enum CurveChannel { rgb, red, green, blue }

/// The RGB curve control.
///
/// The user drags three handles: the dark end, the middle, and the light end.
/// Three is enough to shape a photo and keeps the control usable with a
/// finger, where a free-point curve would be fiddly. The maths of turning
/// those points into a table lives in [ToneCurveService].
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

  /// The three handles for the shown channel, filled in for a straight curve.
  List<CurvePoint> get _handles {
    final points = _service.sanitize(_curve.points);
    if (points.length >= 3) return points;
    return const <CurvePoint>[
      CurvePoint(0, 0),
      CurvePoint(128, 128),
      CurvePoint(255, 255),
    ];
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

  /// Moves the handle nearest [local] to where the finger is.
  ///
  /// The two end handles keep their input value, so the curve always covers
  /// the whole range and cannot be dragged into a fold.
  void _moveHandle(Offset local, Size size, {required bool isEnd}) {
    if (size.width <= 0 || size.height <= 0) return;

    final points = List<CurvePoint>.from(_handles);
    final x = (local.dx / size.width * 255).clamp(0.0, 255.0);
    final y = ((1 - local.dy / size.height) * 255).clamp(0.0, 255.0);

    var index = _draggingIndex;
    if (index == null) {
      var best = 0;
      var bestDistance = double.infinity;
      for (var i = 0; i < points.length; i++) {
        final distance = (points[i].input - x).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          best = i;
        }
      }
      index = best;
      _draggingIndex = best;
    }

    final current = points[index];
    // Only the middle handle may slide sideways.
    final nextInput = (index == 0 || index == points.length - 1)
        ? current.input
        : x.clamp(points[index - 1].input + 1, points[index + 1].input - 1);
    points[index] = CurvePoint(nextInput, y);

    final updated = _withCurve(ToneCurve(points));
    setState(() {});
    if (isEnd) {
      _draggingIndex = null;
      widget.onChanged(updated);
    } else {
      // Live feedback while dragging goes through the same call; the screen
      // decides whether that lands in undo.
      widget.onChanged(updated);
    }
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
                  onPanUpdate: (details) =>
                      _moveHandle(details.localPosition, size, isEnd: false),
                  onPanEnd: (_) {
                    _draggingIndex = null;
                    setState(() {});
                  },
                  child: CustomPaint(
                    painter: _CurvePainter(
                      points: _handles,
                      service: _service,
                      lineColor: _channelColor(theme),
                      gridColor: theme.colorScheme.outlineVariant,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
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
                  l10n.curveHint,
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

/// Draws the curve, its grid, and the draggable handles.
class _CurvePainter extends CustomPainter {
  final List<CurvePoint> points;
  final ToneCurveService service;
  final Color lineColor;
  final Color gridColor;
  final Color backgroundColor;

  const _CurvePainter({
    required this.points,
    required this.service,
    required this.lineColor,
    required this.gridColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = backgroundColor;
    final rect = Offset.zero & size;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      background,
    );

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final dx = size.width * i / 4;
      final dy = size.height * i / 4;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), grid);
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), grid);
    }

    final line = Paint()
      ..color = lineColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    for (var i = 0; i <= 64; i++) {
      final input = i / 64 * 255;
      final output = service.evaluate(points, input);
      final x = input / 255 * size.width;
      final y = (1 - output / 255) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, line);

    final handle = Paint()..color = lineColor;
    for (final point in points) {
      canvas.drawCircle(
        Offset(
          point.input / 255 * size.width,
          (1 - point.output / 255) * size.height,
        ),
        6,
        handle,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.lineColor != lineColor;
}
