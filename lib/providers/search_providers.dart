import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_history_entry.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_query.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_result.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/search_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/search/search_history_service.dart';
import 'package:in_sreerajp_imgvidgal/services/search/search_query_parser.dart';
import 'package:path_provider/path_provider.dart';

/// Turns typed text into a query, and a query into an FTS expression.
final searchQueryParserProvider = Provider<SearchQueryParser>((ref) {
  return const SearchQueryParser();
});

/// Runs searches against the indexed library.
final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(
    mediaDao: ref.watch(mediaDaoProvider),
    tagDao: ref.watch(tagDaoProvider),
    parser: ref.watch(searchQueryParserProvider),
  );
});

/// Remembers recent searches, once the app support directory is known.
final searchHistoryServiceProvider = FutureProvider<SearchHistoryService>((
  ref,
) async {
  final directory = await getApplicationSupportDirectory();
  return SearchHistoryService(directory: directory);
});

/// What is currently typed in the search box.
final searchTextProvider = StateProvider<String>((ref) => '');

/// Filters set in the filter sheet, on top of the typed text.
final searchFilterProvider = StateProvider<FilterOptions>((ref) {
  return const FilterOptions();
});

/// The typed text, but only after it has stopped changing for a moment.
///
/// Searching on every keystroke would run a query per letter, and the last few
/// would be thrown away as soon as the next letter arrived. Waiting a beat
/// means one query per pause instead, which is both faster and calmer to look
/// at. Very short text is treated as nothing, so a single stray letter does
/// not scan the library.
final debouncedSearchTextProvider = FutureProvider<String>((ref) async {
  final text = ref.watch(searchTextProvider).trim();
  if (text.isEmpty) return '';

  final timer = Completer<void>();
  final handle = Timer(
    const Duration(milliseconds: AppConstants.searchDebounceMs),
    () {
      if (!timer.isCompleted) timer.complete();
    },
  );
  ref.onDispose(() {
    handle.cancel();
    if (!timer.isCompleted) timer.complete();
  });
  await timer.future;

  if (text.length < AppConstants.searchMinQueryLength) return '';
  return text;
});

/// The parsed form of what the user typed.
final parsedSearchQueryProvider = Provider<SearchQuery>((ref) {
  final text = ref.watch(debouncedSearchTextProvider).valueOrNull ?? '';
  return ref.watch(searchQueryParserProvider).parse(text);
});

/// The filter the search actually runs with.
///
/// The sheet's own filters and the ticked tag chips are two different pieces
/// of UI, so they are kept apart and joined here rather than one of them
/// having to know about the other.
final effectiveSearchFilterProvider = Provider<FilterOptions>((ref) {
  final base = ref.watch(searchFilterProvider);
  final tags = ref.watch(tagFilterProvider);
  if (tags.isEmpty) return base;
  return base.copyWith(
    tagIds: <String>{...base.tagIds, ...tags.tagIds},
    tagFilterMode: tags.mode,
  );
});

/// The results for whatever is currently typed and ticked.
final searchResultsProvider = FutureProvider<List<SearchResult>>((ref) async {
  final query = ref.watch(parsedSearchQueryProvider);
  final filter = ref.watch(effectiveSearchFilterProvider);

  // New photos or new tags should change what a search finds.
  ref.watch(mediaScanControllerProvider);
  ref.watch(tagRevisionProvider);

  if (query.isEmpty && !filter.hasActiveFilters) {
    return const <SearchResult>[];
  }
  return ref.watch(searchRepositoryProvider).search(query, baseFilter: filter);
});

/// Keeps the recent-search list.
class SearchHistoryController extends StateNotifier<List<SearchHistoryEntry>> {
  final Future<SearchHistoryService> _service;

  SearchHistoryController(this._service) : super(const <SearchHistoryEntry>[]) {
    unawaited(load());
  }

  /// Reads the stored list.
  Future<void> load() async {
    state = await (await _service).load();
  }

  /// Records a search the user actually ran.
  Future<void> record(String text) async {
    state = await (await _service).record(text);
  }

  /// Forgets one search.
  Future<void> remove(String text) async {
    state = await (await _service).remove(text);
  }

  /// Forgets every search.
  Future<void> clear() async {
    await (await _service).clear();
    state = const <SearchHistoryEntry>[];
  }
}

/// Recent searches, newest first.
final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryController, List<SearchHistoryEntry>>((
      ref,
    ) {
      return SearchHistoryController(
        ref.watch(searchHistoryServiceProvider.future),
      );
    });
