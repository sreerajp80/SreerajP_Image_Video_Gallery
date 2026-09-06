import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/models/convert/image_output_format.dart';

/// The row of output format chips.
///
/// The names are the format names themselves (JPEG, PNG, WEBP, BMP), which
/// are the same in every language, so they are not translated. Everything
/// around them is.
class FormatChipRow extends StatelessWidget {
  /// The format currently chosen.
  final ImageOutputFormat selected;

  /// The formats offered. Defaults to all of them.
  final List<ImageOutputFormat> formats;

  final ValueChanged<ImageOutputFormat> onChanged;

  const FormatChipRow({
    super.key,
    required this.selected,
    required this.onChanged,
    this.formats = ImageOutputFormat.values,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: formats
          .map((format) {
            return ChoiceChip(
              label: Text(format.displayName),
              selected: format == selected,
              onSelected: (isSelected) {
                if (isSelected) onChanged(format);
              },
            );
          })
          .toList(growable: false),
    );
  }
}
