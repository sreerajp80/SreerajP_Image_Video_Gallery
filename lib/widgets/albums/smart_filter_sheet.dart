import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_filter_bar.dart';
import 'package:flutter_riverpod/legacy.dart';

/// One megabyte, used by the file size choices.
const int _kMegabyte = 1024 * 1024;

/// The multi-dimensional filter sheet, shared by search and the album screens.
///
/// It is given the provider to write to rather than choosing one, so search and
/// albums can each keep their own filter while offering exactly the same
/// controls. Two sheets would have drifted apart the first time either grew a
/// row.
///
/// Every control writes straight to its provider, so the results behind the
/// sheet update as the user ticks things and the Apply button only closes it.
/// There is no "unsaved changes" state to get wrong.
class SmartFilterSheet extends ConsumerWidget {
  /// The filter this sheet reads and writes.
  final StateProvider<FilterOptions> filterProvider;

  /// Whether to offer the tag chips.
  ///
  /// The album screens leave them out: an album is already a grouping, and a
  /// tag filter on top of it belongs on the search screen.
  final bool showTags;

  const SmartFilterSheet({
    super.key,
    required this.filterProvider,
    this.showTags = true,
  });

  /// Opens the sheet over the current screen.
  static Future<void> show(
    BuildContext context, {
    required StateProvider<FilterOptions> filterProvider,
    bool showTags = true,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          SmartFilterSheet(filterProvider: filterProvider, showTags: showTags),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(filterProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.tooltipFilterTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _reset(ref),
                    child: Text(l10n.actionFilterReset),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _SectionLabel(l10n.labelFilterMediaType),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final type in MediaType.values)
                    FilterChip(
                      label: Text(_typeLabel(l10n, type)),
                      selected: filter.mediaTypes.contains(type),
                      onSelected: (_) => _toggleType(ref, filter, type),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.titleFilterFavoritesOnly),
                value: filter.isFavoriteOnly == true,
                onChanged: (on) => _write(
                  ref,
                  on
                      ? filter.copyWith(isFavoriteOnly: true)
                      : filter.copyWith(clearFavorite: true),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.titleFilterHasLocation),
                value: filter.hasGpsOnly == true,
                onChanged: (on) => _write(
                  ref,
                  on
                      ? filter.copyWith(hasGpsOnly: true)
                      : filter.copyWith(clearGps: true),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.titleFilterHasTags),
                value: filter.hasTagsOnly == true,
                onChanged: (on) => _write(
                  ref,
                  on
                      ? filter.copyWith(hasTagsOnly: true)
                      : filter.copyWith(clearHasTags: true),
                ),
              ),

              _SectionLabel(l10n.labelFilterDateRange),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _dateLabel(context, l10n, filter),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _pickDates(context, ref, filter),
                    child: Text(l10n.actionFilterDateChoose),
                  ),
                  if (filter.startDate != null || filter.endDate != null)
                    TextButton(
                      onPressed: () =>
                          _write(ref, filter.copyWith(clearDates: true)),
                      child: Text(l10n.actionFilterDateClear),
                    ),
                ],
              ),

              _SectionLabel(l10n.labelFilterFileSize),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final choice in _SizeChoice.values)
                    ChoiceChip(
                      label: Text(_sizeLabel(l10n, choice)),
                      selected: _activeSize(filter) == choice,
                      onSelected: (_) => _applySize(ref, filter, choice),
                    ),
                ],
              ),

              _SectionLabel(l10n.labelFilterSortBy),
              Wrap(
                spacing: 8,
                children: <Widget>[
                  for (final field in _sortFields)
                    ChoiceChip(
                      label: Text(_sortLabel(l10n, field)),
                      selected: filter.sortBy == field,
                      onSelected: (_) =>
                          _write(ref, filter.copyWith(sortBy: field)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SegmentedButton<SortDirection>(
                segments: <ButtonSegment<SortDirection>>[
                  ButtonSegment<SortDirection>(
                    value: SortDirection.descending,
                    label: Text(l10n.actionFilterSortNewestFirst),
                  ),
                  ButtonSegment<SortDirection>(
                    value: SortDirection.ascending,
                    label: Text(l10n.actionFilterSortOldestFirst),
                  ),
                ],
                selected: <SortDirection>{filter.sortDirection},
                onSelectionChanged: (selection) => _write(
                  ref,
                  filter.copyWith(sortDirection: selection.first),
                ),
              ),

              if (showTags) ...<Widget>[
                _SectionLabel(l10n.labelFilterTags),
                _TagSection(),
              ],

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.actionFilterApply),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _write(WidgetRef ref, FilterOptions next) {
    ref.read(filterProvider.notifier).state = next;
  }

  void _reset(WidgetRef ref) {
    ref.read(filterProvider.notifier).state = const FilterOptions();
    if (showTags) ref.read(tagFilterProvider.notifier).clear();
  }

  void _toggleType(WidgetRef ref, FilterOptions filter, MediaType type) {
    final next = <MediaType>{...filter.mediaTypes};
    if (!next.remove(type)) next.add(type);
    _write(ref, filter.copyWith(mediaTypes: next));
  }

  /// Which size chip is lit, worked out from the stored bounds.
  ///
  /// Derived rather than stored so the chips cannot disagree with the filter
  /// the query actually runs.
  _SizeChoice _activeSize(FilterOptions filter) {
    final min = filter.minSizeBytes;
    final max = filter.maxSizeBytes;
    if (min == null && max == _kMegabyte) return _SizeChoice.small;
    if (min == _kMegabyte && max == 10 * _kMegabyte) return _SizeChoice.medium;
    if (min == 10 * _kMegabyte && max == null) return _SizeChoice.large;
    return _SizeChoice.any;
  }

  void _applySize(WidgetRef ref, FilterOptions filter, _SizeChoice choice) {
    // Tapping the lit chip clears the range, so a choice can be undone without
    // hunting for a separate "clear" control.
    if (_activeSize(filter) == choice || choice == _SizeChoice.any) {
      _write(ref, filter.copyWith(clearSizeRange: true));
      return;
    }
    _write(ref, switch (choice) {
      _SizeChoice.any => filter.copyWith(clearSizeRange: true),
      _SizeChoice.small =>
        filter
            .copyWith(clearSizeRange: true)
            .copyWith(maxSizeBytes: _kMegabyte),
      _SizeChoice.medium => filter.copyWith(
        minSizeBytes: _kMegabyte,
        maxSizeBytes: 10 * _kMegabyte,
      ),
      _SizeChoice.large =>
        filter
            .copyWith(clearSizeRange: true)
            .copyWith(minSizeBytes: 10 * _kMegabyte),
    });
  }

  Future<void> _pickDates(
    BuildContext context,
    WidgetRef ref,
    FilterOptions filter,
  ) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      // Digital photography does not predate this, and a range that cannot
      // include tomorrow would be surprising on a device whose clock is off.
      firstDate: DateTime(1990),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: filter.startDate != null && filter.endDate != null
          ? DateTimeRange(start: filter.startDate!, end: filter.endDate!)
          : null,
    );
    if (picked == null) return;

    _write(
      ref,
      filter.copyWith(
        startDate: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        // The end day is included in full, otherwise picking a single day would
        // match only the photos taken at exactly midnight.
        endDate: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      ),
    );
  }

  String _dateLabel(
    BuildContext context,
    AppLocalizations l10n,
    FilterOptions filter,
  ) {
    final start = filter.startDate;
    final end = filter.endDate;
    if (start == null && end == null) return l10n.labelFilterDateAny;

    // `formatShortDate` follows the app's locale, so the label reads the same
    // way as the rest of the screen without any date formatting of our own.
    final material = MaterialLocalizations.of(context);
    String format(DateTime? value) => value == null
        ? l10n.labelFilterDateAny
        : material.formatShortDate(value);
    return '${format(start)} — ${format(end)}';
  }

  String _typeLabel(AppLocalizations l10n, MediaType type) {
    return switch (type) {
      MediaType.image => l10n.labelFilterTypeImage,
      MediaType.video => l10n.labelFilterTypeVideo,
      MediaType.gif => l10n.labelFilterTypeGif,
      MediaType.rawImage => l10n.labelFilterTypeRaw,
      MediaType.svg => l10n.labelFilterTypeSvg,
    };
  }

  String _sizeLabel(AppLocalizations l10n, _SizeChoice choice) {
    return switch (choice) {
      _SizeChoice.any => l10n.labelFilterSizeAny,
      _SizeChoice.small => l10n.labelFilterSizeSmall,
      _SizeChoice.medium => l10n.bodyFilterSizeMedium,
      _SizeChoice.large => l10n.labelFilterSizeLarge,
    };
  }

  String _sortLabel(AppLocalizations l10n, MediaSortField field) {
    return switch (field) {
      MediaSortField.dateTaken => l10n.labelFilterSortDateTaken,
      MediaSortField.dateAdded => l10n.labelFilterSortDateAdded,
      MediaSortField.displayName => l10n.labelFilterSortName,
      MediaSortField.size => l10n.labelFilterSortSize,
      // Not offered as chips; the labels exist so the switch stays total.
      MediaSortField.dateModified => l10n.labelFilterSortDateAdded,
      MediaSortField.duration => l10n.labelFilterSortSize,
    };
  }
}

/// The sort fields offered as chips.
const List<MediaSortField> _sortFields = <MediaSortField>[
  MediaSortField.dateTaken,
  MediaSortField.dateAdded,
  MediaSortField.displayName,
  MediaSortField.size,
];

/// The file size bands the sheet offers.
enum _SizeChoice { any, small, medium, large }

/// The tag chips, kept apart so their provider is only watched when shown.
class _TagSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final selection = ref.watch(tagFilterProvider);

    return ref
        .watch(allTagsProvider)
        .when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.errorTagErrorFailed),
          data: (tags) => TagFilterBar(
            tags: tags,
            selectedTagIds: selection.tagIds,
            mode: selection.mode,
            onToggle: (id) => ref.read(tagFilterProvider.notifier).toggle(id),
            onModeChanged: (mode) =>
                ref.read(tagFilterProvider.notifier).setMode(mode),
          ),
        );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
