import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

void main() {
  group('FilterOptions Domain Model', () {
    test('default instance has correct standard values', () {
      const defaultOptions = FilterOptions();
      expect(defaultOptions.hasActiveFilters, isFalse);
      expect(defaultOptions.sortBy, MediaSortField.dateTaken);
      expect(defaultOptions.sortDirection, SortDirection.descending);
      expect(defaultOptions.isTrash, isFalse);
    });

    test('hasActiveFilters detects active query constraints', () {
      const tagFiltered = FilterOptions(tagIds: {'tag_1'});
      expect(tagFiltered.hasActiveFilters, isTrue);

      const typeFiltered = FilterOptions(mediaTypes: {MediaType.video});
      expect(typeFiltered.hasActiveFilters, isTrue);

      const searchFiltered = FilterOptions(searchQuery: 'sunset');
      expect(searchFiltered.hasActiveFilters, isTrue);

      const favFiltered = FilterOptions(isFavoriteOnly: true);
      expect(favFiltered.hasActiveFilters, isTrue);
    });

    test('supports value equality', () {
      const opt1 = FilterOptions(
        mediaTypes: {MediaType.image, MediaType.video},
        sortBy: MediaSortField.size,
        sortDirection: SortDirection.ascending,
        isFavoriteOnly: true,
      );

      const opt2 = FilterOptions(
        mediaTypes: {MediaType.image, MediaType.video},
        sortBy: MediaSortField.size,
        sortDirection: SortDirection.ascending,
        isFavoriteOnly: true,
      );

      expect(opt1, equals(opt2));
      expect(opt1.hashCode, equals(opt2.hashCode));
    });

    test('copyWith works cleanly', () {
      const opt = FilterOptions();
      final modified = opt.copyWith(
        sortBy: MediaSortField.displayName,
        sortDirection: SortDirection.ascending,
      );

      expect(modified.sortBy, MediaSortField.displayName);
      expect(modified.sortDirection, SortDirection.ascending);
    });

    group('size range and tag presence', () {
      test('default to off', () {
        const opt = FilterOptions();
        expect(opt.minSizeBytes, isNull);
        expect(opt.maxSizeBytes, isNull);
        expect(opt.hasTagsOnly, isNull);
        expect(opt.hasActiveFilters, isFalse);
      });

      test('a size floor counts as an active filter', () {
        const opt = FilterOptions(minSizeBytes: 1000);
        expect(opt.hasActiveFilters, isTrue);
      });

      test('a size ceiling counts as an active filter', () {
        const opt = FilterOptions(maxSizeBytes: 1000);
        expect(opt.hasActiveFilters, isTrue);
      });

      test('asking for tagged items counts as an active filter', () {
        const opt = FilterOptions(hasTagsOnly: true);
        expect(opt.hasActiveFilters, isTrue);
      });

      test('explicitly asking for untagged items is not an active filter', () {
        // Only "true" narrows anything; false is the same as not asking.
        const opt = FilterOptions(hasTagsOnly: false);
        expect(opt.hasActiveFilters, isFalse);
      });

      test('copyWith sets both ends of the range', () {
        final opt = const FilterOptions().copyWith(
          minSizeBytes: 100,
          maxSizeBytes: 900,
        );
        expect(opt.minSizeBytes, 100);
        expect(opt.maxSizeBytes, 900);
      });

      test('clearSizeRange turns the range back off', () {
        const opt = FilterOptions(minSizeBytes: 100, maxSizeBytes: 900);
        final cleared = opt.copyWith(clearSizeRange: true);
        expect(cleared.minSizeBytes, isNull);
        expect(cleared.maxSizeBytes, isNull);
      });

      test('clearHasTags turns the tag flag back off', () {
        const opt = FilterOptions(hasTagsOnly: true);
        expect(opt.copyWith(clearHasTags: true).hasTagsOnly, isNull);
      });

      test('a plain copyWith keeps the new fields', () {
        const opt = FilterOptions(
          minSizeBytes: 100,
          maxSizeBytes: 900,
          hasTagsOnly: true,
        );
        final copy = opt.copyWith(sortBy: MediaSortField.size);
        expect(copy.minSizeBytes, 100);
        expect(copy.maxSizeBytes, 900);
        expect(copy.hasTagsOnly, isTrue);
      });

      test('the new fields take part in equality', () {
        const a = FilterOptions(minSizeBytes: 100);
        const b = FilterOptions(minSizeBytes: 100);
        const c = FilterOptions(minSizeBytes: 200);

        expect(a, b);
        expect(a.hashCode, b.hashCode);
        expect(a, isNot(c));
        expect(a, isNot(const FilterOptions(hasTagsOnly: true)));
      });
    });
  });
}
