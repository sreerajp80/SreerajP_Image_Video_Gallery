import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/color_swatch_button.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_chip.dart';

/// The palette swatches a tag colour is chosen from.
///
/// A fixed set rather than a colour wheel, so every tag stays readable on both
/// themes and the library looks like one set of tags rather than a jumble.
class TagColorPicker extends StatelessWidget {
  /// The currently chosen colour value.
  final int selectedColorValue;

  /// Called with the chosen colour.
  final ValueChanged<int> onChanged;

  const TagColorPicker({
    super.key,
    required this.selectedColorValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: <Widget>[
        for (final value in TagColorPalette.colors)
          ColorSwatchButton(
            argb: value,
            selected: value == selectedColorValue,
            onTap: () => onChanged(value),
            child: TagColorDot(
              color: Color(value),
              selected: value == selectedColorValue,
              size: 30,
            ),
          ),
      ],
    );
  }
}
