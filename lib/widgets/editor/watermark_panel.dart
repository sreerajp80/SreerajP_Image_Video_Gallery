import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/watermark_config.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';
import 'package:path/path.dart' as p;

/// The watermark tool's controls.
///
/// The logo is picked with the system photo picker by the screen, because a
/// widget must not reach for files itself.
class WatermarkPanel extends StatefulWidget {
  final WatermarkConfig config;

  /// Called while a slider moves, for the live preview.
  final ValueChanged<WatermarkConfig> onChanged;

  /// Called when a change is finished, so undo gets one step.
  final ValueChanged<WatermarkConfig> onChangeEnd;

  /// Asks the screen to pick a logo file.
  final VoidCallback onPickLogo;

  const WatermarkPanel({
    super.key,
    required this.config,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onPickLogo,
  });

  @override
  State<WatermarkPanel> createState() => _WatermarkPanelState();
}

class _WatermarkPanelState extends State<WatermarkPanel> {
  late final TextEditingController _textController = TextEditingController(
    text: widget.config.text,
  );

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  /// The name of [position] in the user's language.
  static String positionLabel(
    AppLocalizations l10n,
    WatermarkPosition position,
  ) {
    switch (position) {
      case WatermarkPosition.topLeft:
        return l10n.positionTopLeft;
      case WatermarkPosition.topCenter:
        return l10n.positionTopCenter;
      case WatermarkPosition.topRight:
        return l10n.positionTopRight;
      case WatermarkPosition.centerLeft:
        return l10n.positionCenterLeft;
      case WatermarkPosition.center:
        return l10n.positionCenter;
      case WatermarkPosition.centerRight:
        return l10n.positionCenterRight;
      case WatermarkPosition.bottomLeft:
        return l10n.positionBottomLeft;
      case WatermarkPosition.bottomCenter:
        return l10n.positionBottomCenter;
      case WatermarkPosition.bottomRight:
        return l10n.positionBottomRight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final config = widget.config;

    final modeLabels = <WatermarkMode, String>{
      WatermarkMode.none: l10n.watermarkNone,
      WatermarkMode.text: l10n.watermarkText,
      WatermarkMode.timestamp: l10n.watermarkTimestamp,
      WatermarkMode.logo: l10n.watermarkLogo,
    };

    final logoPath = config.logoPath;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Wrap(
            spacing: 8,
            children: WatermarkMode.values.map((mode) {
              return ChoiceChip(
                label: Text(modeLabels[mode]!),
                selected: config.mode == mode,
                onSelected: (_) =>
                    widget.onChangeEnd(config.copyWith(mode: mode)),
              );
            }).toList(),
          ),
        ),
        if (config.mode == WatermarkMode.text)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: l10n.watermarkTextHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) =>
                  widget.onChanged(config.copyWith(text: value)),
              onEditingComplete: () => widget.onChangeEnd(
                config.copyWith(text: _textController.text),
              ),
            ),
          ),
        if (config.mode == WatermarkMode.logo)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    // Only the file name is shown; the full path would give
                    // away more of the user's device than it needs to.
                    logoPath == null || logoPath.isEmpty
                        ? l10n.watermarkNoLogo
                        : p.basename(logoPath),
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: widget.onPickLogo,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(l10n.watermarkPickLogo),
                ),
              ],
            ),
          ),
        if (config.mode != WatermarkMode.none) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.watermarkPosition, style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WatermarkPosition.values.map((position) {
                    return ChoiceChip(
                      label: Text(positionLabel(l10n, position)),
                      selected: config.position == position,
                      onSelected: (_) => widget.onChangeEnd(
                        config.copyWith(position: position),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          EditorSliderRow(
            label: l10n.watermarkOpacity,
            value: config.opacity,
            min: 0,
            max: 1,
            neutral: 0.7,
            onChanged: (value) =>
                widget.onChanged(config.copyWith(opacity: value)),
            onChangeEnd: (value) =>
                widget.onChangeEnd(config.copyWith(opacity: value)),
          ),
          EditorSliderRow(
            label: l10n.watermarkSize,
            value: config.scale,
            min: 0.02,
            max: 0.25,
            neutral: 0.06,
            onChanged: (value) =>
                widget.onChanged(config.copyWith(scale: value)),
            onChangeEnd: (value) =>
                widget.onChangeEnd(config.copyWith(scale: value)),
            formatValue: (value) => (value * 100).round().toString(),
          ),
          EditorSliderRow(
            label: l10n.watermarkMargin,
            value: config.margin,
            min: 0,
            max: 0.15,
            neutral: 0.03,
            onChanged: (value) =>
                widget.onChanged(config.copyWith(margin: value)),
            onChangeEnd: (value) =>
                widget.onChangeEnd(config.copyWith(margin: value)),
            formatValue: (value) => (value * 100).round().toString(),
          ),
        ],
      ],
    );
  }
}
