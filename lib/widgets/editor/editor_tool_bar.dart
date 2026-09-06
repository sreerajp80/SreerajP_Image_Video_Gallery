import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/editor_providers.dart';

/// The row of tool buttons along the bottom of the editor.
///
/// It only reports which tool was tapped. The screen owns the state, so this
/// widget stays a plain, testable piece of layout.
class EditorToolBar extends StatelessWidget {
  final EditorTool activeTool;
  final ValueChanged<EditorTool> onToolSelected;

  const EditorToolBar({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final entries = <(EditorTool, IconData, String)>[
      (EditorTool.crop, Icons.crop_rotate, l10n.editorToolCrop),
      (EditorTool.tune, Icons.tune, l10n.editorToolTune),
      (
        EditorTool.filters,
        Icons.filter_vintage_outlined,
        l10n.editorToolFilters,
      ),
      (EditorTool.markup, Icons.draw_outlined, l10n.editorToolMarkup),
      (EditorTool.redact, Icons.blur_on, l10n.editorToolRedact),
      (
        EditorTool.watermark,
        Icons.branding_watermark_outlined,
        l10n.editorToolWatermark,
      ),
    ];

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 76,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final (tool, icon, label) = entries[index];
            final isActive = tool == activeTool;
            final color = isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant;

            return InkWell(
              onTap: () => onToolSelected(tool),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: theme.textTheme.labelSmall?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
