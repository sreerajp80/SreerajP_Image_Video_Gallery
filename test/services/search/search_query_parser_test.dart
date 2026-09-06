import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_query.dart';
import 'package:in_sreerajp_imgvidgal/services/search/search_query_parser.dart';

void main() {
  const parser = SearchQueryParser();

  group('SearchQueryParser parsing', () {
    test('plain words become search text', () {
      final query = parser.parse('sunset beach');

      expect(query.textTerms, <String>['sunset', 'beach']);
      expect(query.tagNames, isEmpty);
      expect(query.mediaTypes, isEmpty);
      expect(query.rawText, 'sunset beach');
      expect(query.isNotEmpty, isTrue);
    });

    test('empty and whitespace-only text produce an empty query', () {
      expect(parser.parse('').isEmpty, isTrue);
      expect(parser.parse('    ').isEmpty, isTrue);
    });

    test('tag: pulls out a tag name, lower cased', () {
      final query = parser.parse('tag:Beach sunset');

      expect(query.tagNames, <String>{'beach'});
      expect(query.textTerms, <String>['sunset']);
    });

    test('type: understands friendly spellings', () {
      expect(parser.parse('type:photo').mediaTypes, <MediaType>{
        MediaType.image,
      });
      expect(parser.parse('type:videos').mediaTypes, <MediaType>{
        MediaType.video,
      });
      expect(parser.parse('type:GIF').mediaTypes, <MediaType>{MediaType.gif});
      expect(parser.parse('type:raw').mediaTypes, <MediaType>{
        MediaType.rawImage,
      });
    });

    test('an unrecognised type: value is dropped, not guessed', () {
      final query = parser.parse('type:banana');

      expect(query.mediaTypes, isEmpty);
      expect(query.textTerms, isEmpty);
    });

    test('place: and camera: are kept apart from plain text', () {
      final query = parser.parse('place:Kochi camera:Nikon holiday');

      expect(query.placeTerms, <String>['Kochi']);
      expect(query.cameraTerms, <String>['Nikon']);
      expect(query.textTerms, <String>['holiday']);
      expect(query.allTextTerms, <String>['holiday', 'Kochi', 'Nikon']);
    });

    test('after: and before: read an ISO date', () {
      final query = parser.parse('after:2026-01-01 before:2026-06-30');

      expect(query.after, DateTime(2026, 1, 1));
      // The end day is included in full, so a single-day range still matches.
      expect(query.before, DateTime(2026, 6, 30, 23, 59, 59, 999));
    });

    test('a malformed date is ignored rather than failing', () {
      final query = parser.parse('before:yesterday after:2026-13-99');

      expect(query.before, isNull);
      expect(query.after, isNull);
    });

    test('a prefix with nothing after it does not narrow the search', () {
      // Half-typed input must not silently filter everything away.
      final query = parser.parse('tag: sunset');

      expect(query.tagNames, isEmpty);
      expect(query.textTerms, <String>['sunset']);
    });

    test('an unknown prefix falls back to plain text', () {
      final query = parser.parse('colour:red');

      expect(query.textTerms, <String>['colour:red']);
    });

    test('needsFullTextSearch is false for a tags-only query', () {
      expect(parser.parse('tag:beach').needsFullTextSearch, isFalse);
      expect(parser.parse('type:video').needsFullTextSearch, isFalse);
      expect(parser.parse('sunset').needsFullTextSearch, isTrue);
      expect(parser.parse('place:Kochi').needsFullTextSearch, isTrue);
    });
  });

  group('SearchQueryParser FTS escaping', () {
    test('every word is quoted and given a prefix wildcard', () {
      final expression = parser.buildMatchExpression(
        parser.parse('sunset beach'),
      );

      expect(expression, '"sunset"* "beach"*');
    });

    test('a typed double quote is doubled, not left to break the query', () {
      final expression = parser.buildMatchExpression(parser.parse('say"hi'));

      expect(expression, '"say""hi"*');
    });

    test('FTS operator words are searched for, not obeyed', () {
      // Unquoted, these would change the shape of the query. Quoted, they are
      // just words the user typed.
      final expression = parser.buildMatchExpression(
        parser.parse('cat AND dog NOT bird'),
      );

      expect(expression, '"cat"* "AND"* "dog"* "NOT"* "bird"*');
    });

    test('a typed star cannot become a second wildcard', () {
      final expression = parser.buildMatchExpression(parser.parse('a*b'));

      expect(expression, '"a*b"*');
    });

    test('punctuation-only words are dropped', () {
      expect(parser.escapeTerm('---'), isNull);
      expect(parser.escapeTerm('   '), isNull);
      expect(parser.buildMatchExpression(parser.parse('-- ??')), isNull);
    });

    test('a query with no text at all has no match expression', () {
      expect(parser.buildMatchExpression(parser.parse('tag:beach')), isNull);
      expect(parser.buildMatchExpression(const SearchQuery()), isNull);
    });

    test('place and camera words are searched alongside plain text', () {
      final expression = parser.buildMatchExpression(
        parser.parse('holiday place:Kochi'),
      );

      expect(expression, '"holiday"* "Kochi"*');
    });

    test('non-Latin words survive escaping', () {
      final expression = parser.buildMatchExpression(parser.parse('കടൽ'));

      expect(expression, '"കടൽ"*');
    });
  });
}
