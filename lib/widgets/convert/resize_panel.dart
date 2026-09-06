import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/resize_spec.dart';

/// The resize controls: a mode chooser and the boxes that mode needs.
///
/// The widget holds no rules of its own. It reports what the user typed and
/// the notifier decides what is allowed, so the limits live in one place.
class ResizePanel extends StatefulWidget {
  final ResizeSpec spec;

  /// Pixel size of the picture being converted, used for the hints.
  final int sourceWidth;
  final int sourceHeight;

  final ValueChanged<ResizeMode> onModeChanged;
  final ValueChanged<int> onLongestSideChanged;
  final ValueChanged<int> onPercentChanged;
  final void Function({int? width, int? height}) onExactChanged;
  final ValueChanged<bool> onKeepAspectChanged;

  const ResizePanel({
    super.key,
    required this.spec,
    required this.sourceWidth,
    required this.sourceHeight,
    required this.onModeChanged,
    required this.onLongestSideChanged,
    required this.onPercentChanged,
    required this.onExactChanged,
    required this.onKeepAspectChanged,
  });

  @override
  State<ResizePanel> createState() => _ResizePanelState();
}

class _ResizePanelState extends State<ResizePanel> {
  late final TextEditingController _longestSide;
  late final TextEditingController _width;
  late final TextEditingController _height;

  @override
  void initState() {
    super.initState();
    _longestSide = TextEditingController(
      text: widget.spec.longestSide.toString(),
    );
    _width = TextEditingController(text: widget.spec.width.toString());
    _height = TextEditingController(text: widget.spec.height.toString());
  }

  @override
  void dispose() {
    _longestSide.dispose();
    _width.dispose();
    _height.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            _modeChip(ResizeMode.none, l10n.convertResizeNone),
            _modeChip(ResizeMode.longestSide, l10n.convertResizeLongestSide),
            _modeChip(ResizeMode.percent, l10n.convertResizePercent),
            _modeChip(ResizeMode.exact, l10n.convertResizeExact),
          ],
        ),
        const SizedBox(height: 12),
        ..._controlsForMode(l10n),
      ],
    );
  }

  Widget _modeChip(ResizeMode mode, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: widget.spec.mode == mode,
      onSelected: (selected) {
        if (selected) widget.onModeChanged(mode);
      },
    );
  }

  List<Widget> _controlsForMode(AppLocalizations l10n) {
    switch (widget.spec.mode) {
      case ResizeMode.none:
        return <Widget>[
          Text(
            l10n.convertPixelSize(widget.sourceWidth, widget.sourceHeight),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ];

      case ResizeMode.longestSide:
        return <Widget>[
          _numberField(
            controller: _longestSide,
            label: l10n.convertLongestSideLabel,
            onSubmitted: widget.onLongestSideChanged,
          ),
        ];

      case ResizeMode.percent:
        return <Widget>[
          Text(
            l10n.convertPercentLabel,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          Slider(
            value: widget.spec.percent.toDouble().clamp(
              AppConstants.convertMinPercent.toDouble(),
              AppConstants.convertMaxPercent.toDouble(),
            ),
            min: AppConstants.convertMinPercent.toDouble(),
            max: AppConstants.convertMaxPercent.toDouble(),
            divisions:
                AppConstants.convertMaxPercent - AppConstants.convertMinPercent,
            label: '${widget.spec.percent}',
            onChanged: (value) => widget.onPercentChanged(value.round()),
          ),
        ];

      case ResizeMode.exact:
        return <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: _numberField(
                  controller: _width,
                  label: l10n.convertWidth,
                  onSubmitted: (value) => widget.onExactChanged(width: value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _numberField(
                  controller: _height,
                  label: l10n.convertHeight,
                  onSubmitted: (value) => widget.onExactChanged(height: value),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.convertKeepAspect),
            value: widget.spec.keepAspect,
            onChanged: widget.onKeepAspectChanged,
          ),
        ];
    }
  }

  Widget _numberField({
    required TextEditingController controller,
    required String label,
    required ValueChanged<int> onSubmitted,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
      ],
      decoration: InputDecoration(labelText: label, isDense: true),
      onChanged: (text) {
        final value = int.tryParse(text);
        if (value != null && value > 0) onSubmitted(value);
      },
    );
  }
}
