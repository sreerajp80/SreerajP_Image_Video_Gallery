import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_history_entry.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_result.dart';
import 'package:in_sreerajp_imgvidgal/providers/search_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_grid_tile.dart';
import 'package:in_sreerajp_imgvidgal/widgets/search/recent_search_list.dart';
import 'package:in_sreerajp_imgvidgal/widgets/search/search_field_bar.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/smart_filter_sheet.dart';

/// Number of result columns.
const int kSearchGridColumns = 3;

/// Gap between result tiles.
const double kSearchGridSpacing = 2;

/// The search screen at `/search`.
///
/// It only reads providers and draws them. Parsing, escaping, and querying all
/// happen below the provider layer, so nothing here knows what FTS5 is.
class SearchScreen extends ConsumerStatefulWidget {
  /// A tag id to start filtered by, used when arriving from the tag list.
  final String? initialTagId;

  const SearchScreen({super.key, this.initialTagId});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final tagId = widget.initialTagId;
    if (tagId != null && tagId.isNotEmpty) {
      // Providers cannot be written while the first frame is being built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(tagFilterProvider.notifier).selectOnly(tagId);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = ref.watch(searchTextProvider);
    final filter = ref.watch(effectiveSearchFilterProvider);
    final results = ref.watch(searchResultsProvider);
    final history = ref.watch(searchHistoryProvider);

    final hasQuery = text.trim().isNotEmpty || filter.hasActiveFilters;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SearchFieldBar(
              controller: _controller,
              hasActiveFilters: filter.hasActiveFilters,
              onChanged: (value) =>
                  ref.read(searchTextProvider.notifier).state = value,
              onSubmitted: _remember,
              onOpenFilters: () => SmartFilterSheet.show(
                context,
                filterProvider: searchFilterProvider,
              ),
            ),
            Expanded(
              child: !hasQuery
                  ? _IdleState(
                      history: history,
                      onRun: _runRemembered,
                      onRemove: (value) => ref
                          .read(searchHistoryProvider.notifier)
                          .remove(value),
                      onClearAll: () =>
                          ref.read(searchHistoryProvider.notifier).clear(),
                    )
                  : results.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => _Message(
                        icon: Icons.error_outline,
                        title: l10n.searchFailed,
                      ),
                      data: (items) => items.isEmpty
                          ? _Message(
                              icon: Icons.search_off,
                              title: l10n.searchNoResultsTitle,
                              body: l10n.searchNoResultsBody,
                            )
                          : _ResultGrid(results: items),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Remembers a search the user pressed enter on.
  ///
  /// Only submitted searches are remembered, not every keystroke, so the
  /// recent list holds things the user meant rather than every prefix of them.
  void _remember(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    ref.read(searchHistoryProvider.notifier).record(trimmed);
  }

  void _runRemembered(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    ref.read(searchTextProvider.notifier).state = value;
    _remember(value);
  }
}

/// What the screen shows before anything is typed.
class _IdleState extends StatelessWidget {
  final List<SearchHistoryEntry> history;
  final ValueChanged<String> onRun;
  final ValueChanged<String> onRemove;
  final VoidCallback onClearAll;

  const _IdleState({
    required this.history,
    required this.onRun,
    required this.onRemove,
    required this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ListView(
      children: <Widget>[
        RecentSearchList(
          entries: history,
          onRun: onRun,
          onRemove: onRemove,
          onClearAll: onClearAll,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            children: <Widget>[
              Icon(
                Icons.manage_search,
                size: 56,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.searchStartTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.searchStartBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The result tiles, with a count above them.
class _ResultGrid extends StatelessWidget {
  final List<SearchResult> results;

  const _ResultGrid({required this.results});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final tileSize =
        (width - kSearchGridSpacing * (kSearchGridColumns + 1)) /
        kSearchGridColumns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text(
            l10n.searchResultCount(results.length),
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(kSearchGridSpacing),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: kSearchGridColumns,
              mainAxisSpacing: kSearchGridSpacing,
              crossAxisSpacing: kSearchGridSpacing,
            ),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return MediaGridTile(
                item: result.item,
                size: tileSize,
                semanticLabel: _matchLabel(l10n, result.matchField),
                onTap: (item) => context.push(mediaViewerPath(item.id)),
              );
            },
          ),
        ),
      ],
    );
  }

  /// The reason a result came back, read out by a screen reader.
  ///
  /// A result that matched only the filters has no reason worth saying, so it
  /// gets no extra label.
  String? _matchLabel(AppLocalizations l10n, SearchMatchField field) {
    return switch (field) {
      SearchMatchField.displayName => l10n.searchMatchedInName,
      SearchMatchField.tags => l10n.searchMatchedInTags,
      SearchMatchField.notes => l10n.searchMatchedInNotes,
      SearchMatchField.address => l10n.searchMatchedInPlace,
      SearchMatchField.exif => l10n.searchMatchedInDetails,
      SearchMatchField.filter => null,
    };
  }
}

/// A centred icon, title, and optional body.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;

  const _Message({required this.icon, required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
