import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';

/// Which part of the crop box a finger grabbed.
enum _CropHandle { topLeft, topRight, bottomLeft, bottomRight, move }

/// The draggable crop box drawn over the preview.
///
/// It works entirely in fractions of the shown image, so the box means the
/// same thing whatever size the preview is laid out at.
class CropOverlay extends StatefulWidget {
  final NormalizedRect rect;

  /// Called while a handle moves, for live feedback.
  final ValueChanged<NormalizedRect> onChanged;

  /// Called when the finger lifts, so one drag is one undo step.
  final ValueChanged<NormalizedRect> onChangeEnd;

  const CropOverlay({
    super.key,
    required this.rect,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  /// How close, in logical pixels, a finger must be to grab a corner.
  static const double _grabRadius = 44;

  _CropHandle? _handle;

  _CropHandle _handleAt(Offset local, Size size) {
    final rect = widget.rect;
    final corners = <_CropHandle, Offset>{
      _CropHandle.topLeft: Offset(
        rect.left * size.width,
        rect.top * size.height,
      ),
      _CropHandle.topRight: Offset(
        rect.right * size.width,
        rect.top * size.height,
      ),
      _CropHandle.bottomLeft: Offset(
        rect.left * size.width,
        rect.bottom * size.height,
      ),
      _CropHandle.bottomRight: Offset(
        rect.right * size.width,
        rect.bottom * size.height,
      ),
    };

    for (final entry in corners.entries) {
      if ((entry.value - local).distance <= _grabRadius) return entry.key;
    }
    return _CropHandle.move;
  }

  void _drag(Offset delta, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final dx = delta.dx / size.width;
    final dy = delta.dy / size.height;
    final rect = widget.rect;

    NormalizedRect next;
    switch (_handle ?? _CropHandle.move) {
      case _CropHandle.topLeft:
        next = rect.copyWith(left: rect.left + dx, top: rect.top + dy);
      case _CropHandle.topRight:
        next = rect.copyWith(right: rect.right + dx, top: rect.top + dy);
      case _CropHandle.bottomLeft:
        next = rect.copyWith(left: rect.left + dx, bottom: rect.bottom + dy);
      case _CropHandle.bottomRight:
        next = rect.copyWith(right: rect.right + dx, bottom: rect.bottom + dy);
      case _CropHandle.move:
        // Moving the whole box must not change its size, so the shift is
        // trimmed to whatever room is left on each side.
        final shiftX = dx.clamp(-rect.left, 1 - rect.right);
        final shiftY = dy.clamp(-rect.top, 1 - rect.bottom);
        next = NormalizedRect(
          left: rect.left + shiftX,
          top: rect.top + shiftY,
          right: rect.right + shiftX,
          bottom: rect.bottom + shiftY,
        );
    }

    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            _handle = _handleAt(details.localPosition, size);
          },
          onPanUpdate: (details) => _drag(details.delta, size),
          onPanEnd: (_) {
            _handle = null;
            widget.onChangeEnd(widget.rect);
          },
          child: CustomPaint(
            painter: _CropPainter(
              rect: widget.rect,
              lineColor: theme.colorScheme.onInverseSurface,
              shadeColor: Colors.black.withValues(alpha: 0.45),
            ),
            size: size,
          ),
        );
      },
    );
  }
}

/// Draws the shaded outside, the crop border, the thirds grid, and corners.
class _CropPainter extends CustomPainter {
  final NormalizedRect rect;
  final Color lineColor;
  final Color shadeColor;

  const _CropPainter({
    required this.rect,
    required this.lineColor,
    required this.shadeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final box = Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );

    // Darken everything outside the crop so the kept part stands out.
    final shade = Path.combine(
      PathOperation.difference,
      Path()..addRect(Offset.zero & size),
      Path()..addRect(box),
    );
    canvas.drawPath(shade, Paint()..color = shadeColor);

    final border = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(box, border);

    final grid = Paint()
      ..color = lineColor.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final dx = box.left + box.width * i / 3;
      final dy = box.top + box.height * i / 3;
      canvas.drawLine(Offset(dx, box.top), Offset(dx, box.bottom), grid);
      canvas.drawLine(Offset(box.left, dy), Offset(box.right, dy), grid);
    }

    final corner = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    const armLength = 22.0;
    void drawCorner(Offset point, double signX, double signY) {
      canvas.drawLine(point, point.translate(armLength * signX, 0), corner);
      canvas.drawLine(point, point.translate(0, armLength * signY), corner);
    }

    drawCorner(box.topLeft, 1, 1);
    drawCorner(box.topRight, -1, 1);
    drawCorner(box.bottomLeft, 1, -1);
    drawCorner(box.bottomRight, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CropPainter oldDelegate) =>
      oldDelegate.rect != rect;
}

/// The crop tool's controls: aspect shapes, turns, mirrors, and the sliders.
class CropControlsPanel extends StatelessWidget {
  final CropTransform transform;
  final ValueChanged<CropAspectPreset> onAspectSelected;
  final VoidCallback onRotateLeft;
  final VoidCallback onRotateRight;
  final VoidCallback onFlipHorizontal;
  final VoidCallback onFlipVertical;
  final ValueChanged<double> onStraightenChanged;
  final ValueChanged<double> onStraightenEnd;
  final ValueChanged<PerspectiveSkew> onPerspectiveChanged;
  final ValueChanged<PerspectiveSkew> onPerspectiveEnd;
  final VoidCallback onReset;

  const CropControlsPanel({
    super.key,
    required this.transform,
    required this.onAspectSelected,
    required this.onRotateLeft,
    required this.onRotateRight,
    required this.onFlipHorizontal,
    required this.onFlipVertical,
    required this.onStraightenChanged,
    required this.onStraightenEnd,
    required this.onPerspectiveChanged,
    required this.onPerspectiveEnd,
    required this.onReset,
  });

  /// The name of [preset] in the user's language.
  static String aspectLabel(AppLocalizations l10n, CropAspectPreset preset) {
    switch (preset) {
      case CropAspectPreset.free:
        return l10n.cropAspectFree;
      case CropAspectPreset.original:
        return l10n.cropAspectOriginal;
      case CropAspectPreset.square:
        return l10n.cropAspectSquare;
      case CropAspectPreset.ratio4x3:
        return l10n.cropAspect4x3;
      case CropAspectPreset.ratio3x4:
        return l10n.cropAspect3x4;
      case CropAspectPreset.ratio16x9:
        return l10n.cropAspect16x9;
      case CropAspectPreset.ratio9x16:
        return l10n.cropAspect9x16;
      case CropAspectPreset.ratio3x2:
        return l10n.cropAspect3x2;
      case CropAspectPreset.ratio2x3:
        return l10n.cropAspect2x3;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            itemCount: CropAspectPreset.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final preset = CropAspectPreset.values[index];
              return ChoiceChip(
                label: Text(aspectLabel(l10n, preset)),
                selected: transform.aspectPreset == preset,
                onSelected: (_) => onAspectSelected(preset),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: onRotateLeft,
              icon: const Icon(Icons.rotate_left),
              tooltip: l10n.cropRotateLeft,
            ),
            IconButton(
              onPressed: onRotateRight,
              icon: const Icon(Icons.rotate_right),
              tooltip: l10n.cropRotateRight,
            ),
            IconButton(
              onPressed: onFlipHorizontal,
              icon: const Icon(Icons.flip),
              isSelected: transform.flipHorizontal,
              tooltip: l10n.cropFlipHorizontal,
            ),
            IconButton(
              onPressed: onFlipVertical,
              icon: const RotatedBox(quarterTurns: 1, child: Icon(Icons.flip)),
              isSelected: transform.flipVertical,
              tooltip: l10n.cropFlipVertical,
            ),
          ],
        ),
        EditorSliderRow(
          label: l10n.cropStraighten,
          value: transform.straightenDegrees,
          min: -45,
          max: 45,
          onChanged: onStraightenChanged,
          onChangeEnd: onStraightenEnd,
          formatValue: (value) => '${value.round()}°',
        ),
        EditorSliderRow(
          label: l10n.cropPerspectiveVertical,
          value: transform.perspective.topInset,
          min: -0.35,
          max: 0.35,
          onChanged: (value) => onPerspectiveChanged(
            transform.perspective.copyWith(topInset: value),
          ),
          onChangeEnd: (value) =>
              onPerspectiveEnd(transform.perspective.copyWith(topInset: value)),
        ),
        EditorSliderRow(
          label: l10n.cropPerspectiveHorizontal,
          value: transform.perspective.leftInset,
          min: -0.35,
          max: 0.35,
          onChanged: (value) => onPerspectiveChanged(
            transform.perspective.copyWith(leftInset: value),
          ),
          onChangeEnd: (value) => onPerspectiveEnd(
            transform.perspective.copyWith(leftInset: value),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onReset,
              icon: const Icon(Icons.restart_alt),
              label: Text(l10n.cropReset),
            ),
          ),
        ),
      ],
    );
  }
}
