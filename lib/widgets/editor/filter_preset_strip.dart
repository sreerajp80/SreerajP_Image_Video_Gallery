import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/editor/filter_preset.dart';
import 'package:in_sreerajp_imgvidgal/widgets/editor/editor_slider_row.dart';

/// The row of one-tap looks, with a strength slider under it.
class FilterPresetStrip extends StatelessWidget {
  final FilterPreset selected;
  final ValueChanged<FilterPreset> onChanged;

  /// Called when the strength slider is let go, so undo gets one step.
  final ValueChanged<FilterPreset> onChangeEnd;

  const FilterPresetStrip({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onChangeEnd,
  });

  /// The name of [id] in the user's language.
  static String labelFor(AppLocalizations l10n, FilterPresetId id) {
    switch (id) {
      case FilterPresetId.none:
        return l10n.labelFilterNone;
      case FilterPresetId.mono:
        return l10n.labelFilterMono;
      case FilterPresetId.sepia:
        return l10n.labelFilterSepia;
      case FilterPresetId.vintage:
        return l10n.labelFilterVintage;
      case FilterPresetId.vivid:
        return l10n.labelFilterVivid;
      case FilterPresetId.cool:
        return l10n.labelFilterCool;
      case FilterPresetId.warm:
        return l10n.labelFilterWarm;
      case FilterPresetId.fade:
        return l10n.labelFilterFade;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: FilterPresetId.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final id = FilterPresetId.values[index];
              return ChoiceChip(
                label: Text(labelFor(l10n, id)),
                selected: selected.id == id,
                onSelected: (_) => onChangeEnd(
                  // Picking a look starts it at full strength, which is what
                  // the strip's thumbnails are showing.
                  FilterPreset(id: id),
                ),
              );
            },
          ),
        ),
        if (selected.id != FilterPresetId.none)
          EditorSliderRow(
            label: l10n.labelFilterIntensity,
            value: selected.intensity,
            min: 0,
            neutral: 1,
            onChanged: (value) =>
                onChanged(selected.copyWith(intensity: value)),
            onChangeEnd: (value) =>
                onChangeEnd(selected.copyWith(intensity: value)),
          ),
      ],
    );
  }
}
