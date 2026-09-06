import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_query.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_result.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/search/search_query_parser.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';

/// Runs searches against the indexed library.
///
/// A search is one query, not two. The text half becomes a full-text match
/// expression and the rest becomes ordinary column filters, and both go into
/// the same statement, so the database does the narrowing and the sorting once.
class SearchRepository {
  final MediaDao _mediaDao;
  final TagDao _tagDao;
  final SearchQueryParser _parser;

  SearchRepository({
    MediaDao? mediaDao,
    TagDao? tagDao,
    SearchQueryParser parser = const SearchQueryParser(),
  }) : _mediaDao = mediaDao ?? MediaDao(),
       _tagDao = tagDao ?? TagDao(),
       _parser = parser;

  /// Runs [query] on top of [baseFilter] and returns what matched.
  ///
  /// [baseFilter] carries whatever the filter sheet is set to. Anything the
  /// typed query names as well is merged on top of it, so `tag:beach` in the
  /// box and a ticked tag chip both narrow the same search.
  ///
  /// A query that asks for nothing at all returns nothing rather than the
  /// whole library, because an empty search box should show the recent
  /// searches, not every photo on the device.
  Future<List<SearchResult>> search(
    SearchQuery query, {
    FilterOptions baseFilter = const FilterOptions(),
    int limit = AppConstants.searchPageSize,
    int offset = 0,
  }) async {
    if (query.isEmpty && !baseFilter.hasActiveFilters) {
      return const <SearchResult>[];
    }

    final filter = await mergeIntoFilter(query, baseFilter);

    // A tag named in the text that does not exist can match nothing, so the
    // search stops here instead of quietly widening to every photo.
    if (query.tagNames.isNotEmpty && filter.tagIds.isEmpty) {
      return const <SearchResult>[];
    }

    final match = _parser.buildMatchExpression(query);
    final items = await _mediaDao.getMediaItems(
      filter: filter,
      ftsMatchExpression: match,
      limit: limit,
      offset: offset,
    );

    return <SearchResult>[
      for (final item in items)
        SearchResult(item: item, matchField: matchFieldFor(item, query)),
    ];
  }

  /// Parses [rawText] and searches with it in one step.
  Future<List<SearchResult>> searchText(
    String rawText, {
    FilterOptions baseFilter = const FilterOptions(),
    int limit = AppConstants.searchPageSize,
    int offset = 0,
  }) {
    return search(
      _parser.parse(rawText),
      baseFilter: baseFilter,
      limit: limit,
      offset: offset,
    );
  }

  /// Folds the structured half of [query] into [baseFilter].
  ///
  /// Tag names from the text are looked up here, because the database filters
  /// on tag ids while a person types tag names.
  Future<FilterOptions> mergeIntoFilter(
    SearchQuery query,
    FilterOptions baseFilter,
  ) async {
    var filter = baseFilter;

    if (query.mediaTypes.isNotEmpty) {
      filter = filter.copyWith(
        mediaTypes: <MediaType>{...filter.mediaTypes, ...query.mediaTypes},
      );
    }

    if (query.tagNames.isNotEmpty) {
      final ids = await resolveTagNames(query.tagNames);
      filter = filter.copyWith(tagIds: <String>{...filter.tagIds, ...ids});
    }

    if (query.after != null) {
      filter = filter.copyWith(startDate: query.after);
    }
    if (query.before != null) {
      filter = filter.copyWith(endDate: query.before);
    }

    return filter;
  }

  /// Turns tag names into tag ids, dropping any name with no tag behind it.
  Future<Set<String>> resolveTagNames(Set<String> names) async {
    if (names.isEmpty) return const <String>{};
    final all = await _tagDao.getAllTags();
    final ids = <String>{};
    for (final name in names) {
      for (final tag in all) {
        if (TagNameRules.isSameName(tag.name, name)) {
          ids.add(tag.id);
          break;
        }
      }
    }
    return ids;
  }

  /// Every tag, so the filter sheet can list them.
  Future<List<Tag>> getAllTags() => _tagDao.getAllTags();

  /// Guesses which part of [item] the text matched.
  ///
  /// The database tells us a row matched but not where, and asking FTS5 for a
  /// snippet per row would cost a second query. Since this only decides a
  /// small caption under a tile, the same words are checked against the item
  /// in the order a person would expect, and the first hit wins.
  SearchMatchField matchFieldFor(MediaItem item, SearchQuery query) {
    final terms = query.allTextTerms
        .map((t) => t.toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
    if (terms.isEmpty) return SearchMatchField.filter;

    bool hits(String? value) {
      if (value == null || value.isEmpty) return false;
      final lower = value.toLowerCase();
      return terms.any(lower.contains);
    }

    if (hits(item.displayName)) return SearchMatchField.displayName;
    if (item.tags.any((tag) => hits(tag))) return SearchMatchField.tags;
    if (hits(item.userNotes)) return SearchMatchField.notes;
    if (hits(item.address)) return SearchMatchField.address;
    return SearchMatchField.exif;
  }
}
