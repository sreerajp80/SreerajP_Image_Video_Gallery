import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/providers/search_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/search/search_history_service.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  group('debounced search text', () {
    test('empty text gives an empty query at once', () async {
      expect(await container.read(debouncedSearchTextProvider.future), '');
    });

    test('text shorter than the minimum is not searched', () async {
      container.read(searchTextProvider.notifier).state = 'a';

      expect(await container.read(debouncedSearchTextProvider.future), '');
    });

    test('longer text comes through trimmed after the pause', () async {
      container.read(searchTextProvider.notifier).state = '  beach  ';

      expect(await container.read(debouncedSearchTextProvider.future), 'beach');
    });
  });

  test('chosen tags are added to the search filter', () {
    expect(container.read(effectiveSearchFilterProvider).tagIds, isEmpty);

    container.read(tagFilterProvider.notifier)
      ..toggle('t1')
      ..setMode(TagFilterMode.orMode);

    final filter = container.read(effectiveSearchFilterProvider);
    expect(filter.tagIds, <String>{'t1'});
    expect(filter.tagFilterMode, TagFilterMode.orMode);
  });

  test('no query and no filter gives no results, without a search', () async {
    expect(await container.read(searchResultsProvider.future), isEmpty);
  });

  group('SearchHistoryController', () {
    late Directory directory;
    late ProviderContainer history;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('search_history');
      history = ProviderContainer(
        overrides: <Override>[
          searchHistoryServiceProvider.overrideWith(
            (ref) async => SearchHistoryService(directory: directory),
          ),
        ],
      );
    });

    tearDown(() async {
      history.dispose();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    test('records, removes and clears entries', () async {
      final notifier = history.read(searchHistoryProvider.notifier);
      await notifier.load();

      await notifier.record('beach');
      await notifier.record('hills');
      expect(
        history.read(searchHistoryProvider).map((e) => e.text),
        containsAll(<String>['beach', 'hills']),
      );

      await notifier.remove('beach');
      expect(history.read(searchHistoryProvider).map((e) => e.text), <String>[
        'hills',
      ]);

      await notifier.clear();
      expect(history.read(searchHistoryProvider), isEmpty);
    });
  });
}
