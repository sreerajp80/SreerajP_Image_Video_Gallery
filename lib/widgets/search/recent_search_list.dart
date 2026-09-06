import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_history_entry.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// The recent searches, shown while the search box is empty.
class RecentSearchList extends StatelessWidget {
  /// Recent searches, newest first.
  final List<SearchHistoryEntry> entries;

  /// Called when a search is tapped, to run it again.
  final ValueChanged<String> onRun;

  /// Called to forget one search.
  final ValueChanged<String> onRemove;

  /// Called to forget every search.
  final VoidCallback onClearAll;

  const RecentSearchList({
    super.key,
    required this.entries,
    required this.onRun,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l10n.searchRecentTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: onClearAll,
                child: Text(l10n.searchRecentClear),
              ),
            ],
          ),
        ),
        for (final entry in entries)
          ListTile(
            dense: true,
            leading: const Icon(Icons.history),
            // What somebody typed into the search box, shown back the way
            // they typed it.
            title: AdaptiveDirectionality(
              text: entry.text,
              child: Text(
                entry.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            trailing: IconButton(
              tooltip: l10n.searchRecentRemove,
              icon: const Icon(Icons.close, size: 18),
              onPressed: () => onRemove(entry.text),
            ),
            onTap: () => onRun(entry.text),
          ),
      ],
    );
  }
}
