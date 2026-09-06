import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The search box, with a clear button and a filter button beside it.
class SearchFieldBar extends StatelessWidget {
  /// Controls the text being typed.
  final TextEditingController controller;

  /// Called on every change.
  final ValueChanged<String> onChanged;

  /// Called when the user presses enter, so the search can be remembered.
  final ValueChanged<String> onSubmitted;

  /// Opens the filter sheet.
  final VoidCallback onOpenFilters;

  /// Whether any filter is set, so the button can show a marker.
  final bool hasActiveFilters;

  const SearchFieldBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onOpenFilters,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (context, value, _) {
                return TextField(
                  controller: controller,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                  decoration: InputDecoration(
                    hintText: l10n.searchHint,
                    prefixIcon: const Icon(Icons.search),
                    isDense: true,
                    border: const OutlineInputBorder(),
                    suffixIcon: value.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: l10n.searchClear,
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              controller.clear();
                              onChanged('');
                            },
                          ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: l10n.searchFilters,
            onPressed: onOpenFilters,
            icon: Icon(
              hasActiveFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: hasActiveFilters ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }
}
