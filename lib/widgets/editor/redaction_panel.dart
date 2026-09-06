import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/crop_transform.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/redaction_region.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';

/// The surface the user drags over to mark an area as hidden.
///
/// The area is only marked here. It is really hidden when the render runs,
/// which is what replaces the pixels rather than covering them.
class RedactionCanvas extends StatefulWidget {
  final List<RedactionRegion> regions;
  final RedactionToolSettings settings;

  /// Called with the finished area when the finger lifts.
  final ValueChanged<RedactionRegion> onRegionCompleted;

  const RedactionCanvas({
    super.key,
    required this.regions,
    required this.settings,
    required this.onRegionCompleted,
  });

  @override
  State<RedactionCanvas> createState() => _RedactionCanvasState();
}

class _RedactionCanvasState extends State<RedactionCanvas> {
  Offset? _start;
  Offset? _current;

  NormalizedRect? _rectFor(Size size) {
    final start = _start;
    final current = _current;
    if (start == null || current == null) return null;
    if (size.width <= 0 || size.height <= 0) return null;

    double fx(double value) => (value / size.width).clamp(0.0, 1.0);
    double fy(double value) => (value / size.height).clamp(0.0, 1.0);

    return NormalizedRect(
      left: fx(start.dx < current.dx ? start.dx : current.dx),
      top: fy(start.dy < current.dy ? start.dy : current.dy),
      right: fx(start.dx > current.dx ? start.dx : current.dx),
      bottom: fy(start.dy > current.dy ? start.dy : current.dy),
    );
  }

  void _finish(Size size) {
    final rect = _rectFor(size);
    setState(() {
      _start = null;
      _current = null;
    });
    if (rect == null) return;
    // A tap that covered nothing would hide nothing, so it is dropped.
    if (rect.width < 0.01 || rect.height < 0.01) return;

    widget.onRegionCompleted(
      RedactionRegion(
        id: 'redact_${DateTime.now().microsecondsSinceEpoch}',
        rect: rect,
        mode: widget.settings.mode,
        strength: widget.settings.strength,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) => setState(() {
            _start = details.localPosition;
            _current = details.localPosition;
          }),
          onPanUpdate: (details) =>
              setState(() => _current = details.localPosition),
          onPanEnd: (_) => _finish(size),
          onPanCancel: () => _finish(size),
          child: CustomPaint(
            painter: _RedactionPainter(
              regions: widget.regions,
              pending: _rectFor(size),
              fillColor: theme.colorScheme.inverseSurface.withValues(
                alpha: 0.6,
              ),
              borderColor: theme.colorScheme.primary,
            ),
            size: size,
          ),
        );
      },
    );
  }
}

/// Shows where the hidden areas are while the user is still working.
class _RedactionPainter extends CustomPainter {
  final List<RedactionRegion> regions;
  final NormalizedRect? pending;
  final Color fillColor;
  final Color borderColor;

  const _RedactionPainter({
    required this.regions,
    required this.pending,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Rect toRect(NormalizedRect rect) => Rect.fromLTRB(
      rect.left * size.width,
      rect.top * size.height,
      rect.right * size.width,
      rect.bottom * size.height,
    );

    final fill = Paint()..color = fillColor;
    for (final region in regions) {
      canvas.drawRect(toRect(region.rect), fill);
    }

    final current = pending;
    if (current != null) {
      canvas.drawRect(toRect(current), fill);
      canvas.drawRect(
        toRect(current),
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RedactionPainter oldDelegate) =>
      oldDelegate.regions != regions || oldDelegate.pending != pending;
}

/// The redaction tool's controls: mode, strength, and remove.
class RedactionControlsPanel extends StatelessWidget {
  final RedactionToolSettings settings;
  final int regionCount;
  final ValueChanged<RedactionToolSettings> onSettingsChanged;
  final VoidCallback onRemoveLast;

  const RedactionControlsPanel({
    super.key,
    required this.settings,
    required this.regionCount,
    required this.onSettingsChanged,
    required this.onRemoveLast,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final labels = <RedactionMode, String>{
      RedactionMode.blur: l10n.redactBlur,
      RedactionMode.pixelate: l10n.redactPixelate,
      RedactionMode.blackout: l10n.redactBlackout,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: RedactionMode.values.map((mode) {
              return ChoiceChip(
                label: Text(labels[mode]!),
                selected: settings.mode == mode,
                onSelected: (_) =>
                    onSettingsChanged(settings.copyWith(mode: mode)),
              );
            }).toList(),
          ),
        ),
        if (settings.mode != RedactionMode.blackout)
          EditorSliderRow(
            label: l10n.redactStrength,
            value: settings.strength,
            min: 0,
            max: 1,
            neutral: 0.6,
            onChanged: (value) =>
                onSettingsChanged(settings.copyWith(strength: value)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  regionCount == 0
                      ? l10n.redactHint
                      : l10n.redactCount(regionCount),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: regionCount > 0 ? onRemoveLast : null,
                icon: const Icon(Icons.undo),
                label: Text(l10n.redactRemoveLast),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
