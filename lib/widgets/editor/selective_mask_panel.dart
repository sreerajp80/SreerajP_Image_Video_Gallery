import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/selective_mask.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';

/// The controls panel shown when the Masks tool is active.
///
/// Lets the user create, configure, and remove selective gradient and radial
/// masks. Each mask has its own shape, feather, invert toggle, and local
/// adjustment sliders.
class SelectiveMaskPanel extends StatelessWidget {
  final List<SelectiveMask> masks;

  /// The mask being edited, or null when no mask is selected.
  final String? selectedMaskId;

  final ValueChanged<SelectiveMask> onMaskAdded;
  final ValueChanged<SelectiveMask> onMaskUpdated;
  final ValueChanged<String> onMaskRemoved;
  final ValueChanged<String?> onMaskSelected;

  const SelectiveMaskPanel({
    super.key,
    required this.masks,
    required this.selectedMaskId,
    required this.onMaskAdded,
    required this.onMaskUpdated,
    required this.onMaskRemoved,
    required this.onMaskSelected,
  });

  SelectiveMask? get _selected {
    if (selectedMaskId == null) return null;
    final index = masks.indexWhere((m) => m.id == selectedMaskId);
    return index >= 0 ? masks[index] : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final mask = _selected;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        // Mask list header with add buttons.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.labelEditorToolMasks,
                style: theme.textTheme.labelLarge,
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _addMask(MaskShape.linear),
                    icon: const Icon(Icons.gradient, size: 20),
                    tooltip: l10n.tooltipMaskAddLinear,
                  ),
                  IconButton(
                    onPressed: () => _addMask(MaskShape.radial),
                    icon: const Icon(Icons.radio_button_unchecked, size: 20),
                    tooltip: l10n.tooltipMaskAddRadial,
                  ),
                ],
              ),
            ],
          ),
        ),

        if (masks.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: Text(
                l10n.emptyMask,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

        // Mask chips.
        if (masks.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: masks.map((m) {
                final isActive = m.id == selectedMaskId;
                final label = m.shape == MaskShape.linear
                    ? l10n.labelMaskShapeLinear
                    : l10n.labelMaskShapeRadial;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InputChip(
                    label: Text(label),
                    selected: isActive,
                    onSelected: (_) => onMaskSelected(isActive ? null : m.id),
                    avatar: Icon(
                      m.shape == MaskShape.linear
                          ? Icons.gradient
                          : Icons.radio_button_unchecked,
                      size: 16,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => onMaskRemoved(m.id),
                  ),
                );
              }).toList(),
            ),
          ),

        // Controls for the selected mask.
        if (mask != null) ...[
          const Divider(height: 16),

          // Shape toggle.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.labelMaskShapeLinear),
                  selected: mask.shape == MaskShape.linear,
                  onSelected: (_) =>
                      onMaskUpdated(mask.copyWith(shape: MaskShape.linear)),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(l10n.labelMaskShapeRadial),
                  selected: mask.shape == MaskShape.radial,
                  onSelected: (_) =>
                      onMaskUpdated(mask.copyWith(shape: MaskShape.radial)),
                ),
                const Spacer(),
                FilterChip(
                  label: Text(l10n.labelMaskInvert),
                  selected: mask.invert,
                  onSelected: (v) => onMaskUpdated(mask.copyWith(invert: v)),
                ),
              ],
            ),
          ),

          // Feather slider.
          EditorSliderRow(
            label: l10n.labelMaskFeather,
            value: mask.feather,
            min: 0,
            neutral: 0.3,
            formatValue: (v) => '${(v * 100).round()}%',
            onChanged: (v) => onMaskUpdated(mask.copyWith(feather: v)),
            onChangeEnd: (v) => onMaskUpdated(mask.copyWith(feather: v)),
          ),

          const Divider(height: 8),

          // Local adjustments.
          EditorSliderRow(
            label: l10n.labelToneExposure,
            value: mask.exposure,
            onChanged: (v) => onMaskUpdated(mask.copyWith(exposure: v)),
            onChangeEnd: (v) => onMaskUpdated(mask.copyWith(exposure: v)),
          ),
          EditorSliderRow(
            label: l10n.labelToneContrast,
            value: mask.contrast,
            onChanged: (v) => onMaskUpdated(mask.copyWith(contrast: v)),
            onChangeEnd: (v) => onMaskUpdated(mask.copyWith(contrast: v)),
          ),
          EditorSliderRow(
            label: l10n.labelToneTemperature,
            value: mask.temperature,
            onChanged: (v) => onMaskUpdated(mask.copyWith(temperature: v)),
            onChangeEnd: (v) => onMaskUpdated(mask.copyWith(temperature: v)),
          ),
          EditorSliderRow(
            label: l10n.labelMaskBlur,
            value: mask.blur,
            min: 0,
            formatValue: (v) => '${(v * 100).round()}%',
            onChanged: (v) => onMaskUpdated(mask.copyWith(blur: v)),
            onChangeEnd: (v) => onMaskUpdated(mask.copyWith(blur: v)),
          ),
        ],
      ],
    );
  }

  void _addMask(MaskShape shape) {
    final id = 'mask_${DateTime.now().microsecondsSinceEpoch}';
    onMaskAdded(SelectiveMask(id: id, shape: shape));
    onMaskSelected(id);
  }
}
