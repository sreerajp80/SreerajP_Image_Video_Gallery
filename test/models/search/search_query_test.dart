import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_history_entry.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_query.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_result.dart';

void main() {
  group('SearchQuery', () {
    test('a fresh query asks for nothing', () {
      const query = SearchQuery();

      expect(query.isEmpty, isTrue);
      expect(query.isNotEmpty, isFalse);
      expect(query.needsFullTextSearch, isFalse);
      expect(query.allTextTerms, isEmpty);
    });

    test('any one part makes it non-empty', () {
      expect(const SearchQuery(textTerms: <String>['a']).isNotEmpty, isTrue);
      expect(const SearchQuery(tagNames: <String>{'beach'}).isNotEmpty, isTrue);
      expect(
        const SearchQuery(mediaTypes: <MediaType>{MediaType.video}).isNotEmpty,
        isTrue,
      );
      expect(SearchQuery(after: DateTime(2026)).isNotEmpty, isTrue);
      expect(SearchQuery(before: DateTime(2026)).isNotEmpty, isTrue);
    });

    test('only text-like parts need the full-text index', () {
      // A tag or a media kind is answered by a plain column, so a query made
      // only of those never has to touch FTS5.
      expect(
        const SearchQuery(tagNames: <String>{'beach'}).needsFullTextSearch,
        isFalse,
      );
      expect(
        const SearchQuery(
          mediaTypes: <MediaType>{MediaType.video},
        ).needsFullTextSearch,
        isFalse,
      );
      expect(
        const SearchQuery(placeTerms: <String>['Kochi']).needsFullTextSearch,
        isTrue,
      );
      expect(
        const SearchQuery(cameraTerms: <String>['Nikon']).needsFullTextSearch,
        isTrue,
      );
    });

    test('allTextTerms keeps plain text first', () {
      const query = SearchQuery(
        textTerms: <String>['holiday'],
        placeTerms: <String>['Kochi'],
        cameraTerms: <String>['Nikon'],
      );

      expect(query.allTextTerms, <String>['holiday', 'Kochi', 'Nikon']);
    });

    test('copyWith and equality behave', () {
      const query = SearchQuery(rawText: 'a', textTerms: <String>['a']);

      expect(query.copyWith(), query);
      expect(query.copyWith(rawText: 'b'), isNot(query));
      expect(query.hashCode, query.copyWith().hashCode);
    });
  });

  group('SearchResult', () {
    final item = MediaItem(
      id: 'a',
      path: '/storage/DCIM/a.jpg',
      displayName: 'a.jpg',
      mediaType: MediaType.image,
      mimeType: 'image/jpeg',
      size: 10,
      dateAdded: DateTime(2026),
      dateModified: DateTime(2026),
    );

    test('carries the item and why it matched', () {
      final result = SearchResult(
        item: item,
        matchField: SearchMatchField.tags,
      );

      expect(result.item.id, 'a');
      expect(result.matchField, SearchMatchField.tags);
      expect(result.copyWith(), result);
      expect(
        result.copyWith(matchField: SearchMatchField.notes),
        isNot(result),
      );
    });
  });

  group('SearchHistoryEntry', () {
    test('round-trips through JSON', () {
      final entry = SearchHistoryEntry(
        text: 'beach',
        lastUsed: DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );

      final restored = SearchHistoryEntry.tryFromJson(entry.toJson());

      expect(restored, entry);
    });

    test('a broken stored row is dropped, not thrown over', () {
      // The history file is a convenience, so a bad row must never be able to
      // stop somebody searching.
      expect(SearchHistoryEntry.tryFromJson(null), isNull);
      expect(SearchHistoryEntry.tryFromJson('nonsense'), isNull);
      expect(SearchHistoryEntry.tryFromJson(<String, Object?>{}), isNull);
      expect(
        SearchHistoryEntry.tryFromJson(<String, Object?>{'text': '  '}),
        isNull,
      );
      expect(
        SearchHistoryEntry.tryFromJson(<String, Object?>{
          'text': 'beach',
          'last_used': 'yesterday',
        }),
        isNull,
      );
    });

    test('copyWith and equality behave', () {
      final entry = SearchHistoryEntry(text: 'beach', lastUsed: DateTime(2026));

      expect(entry.copyWith(), entry);
      expect(entry.copyWith(text: 'sea'), isNot(entry));
      expect(entry.hashCode, entry.copyWith().hashCode);
    });
  });
}
