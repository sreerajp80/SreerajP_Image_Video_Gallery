import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/search/search_history_service.dart';

void main() {
  group('SearchHistoryService', () {
    late Directory directory;
    late SearchHistoryService service;

    setUp(() async {
      directory = await Directory.systemTemp.createTemp('search_history_test');
      service = SearchHistoryService(directory: directory, maxEntries: 3);
    });

    tearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });

    test('starts empty when nothing has been stored', () async {
      expect(await service.load(), isEmpty);
    });

    test('records a search and reads it back', () async {
      await service.record('beach');

      final entries = await service.load();

      expect(entries.length, 1);
      expect(entries.first.text, 'beach');
    });

    test('keeps the newest search first', () async {
      await service.record('one', now: DateTime(2026, 1, 1));
      await service.record('two', now: DateTime(2026, 1, 2));

      final entries = await service.load();

      expect(entries.map((e) => e.text).toList(), <String>['two', 'one']);
    });

    test(
      'running an old search moves it up rather than repeating it',
      () async {
        await service.record('one', now: DateTime(2026, 1, 1));
        await service.record('two', now: DateTime(2026, 1, 2));
        await service.record('ONE ', now: DateTime(2026, 1, 3));

        final entries = await service.load();

        // Case and stray spaces must not make a second copy of the same search.
        expect(entries.length, 2);
        expect(entries.first.text, 'ONE');
      },
    );

    test('drops the oldest once the cap is reached', () async {
      for (var i = 1; i <= 5; i++) {
        await service.record('search $i', now: DateTime(2026, 1, i));
      }

      final entries = await service.load();

      expect(entries.length, 3);
      expect(entries.map((e) => e.text).toList(), <String>[
        'search 5',
        'search 4',
        'search 3',
      ]);
    });

    test('blank text is not recorded', () async {
      await service.record('   ');

      expect(await service.load(), isEmpty);
    });

    test('one search can be forgotten', () async {
      await service.record('one', now: DateTime(2026, 1, 1));
      await service.record('two', now: DateTime(2026, 1, 2));

      final left = await service.remove('ONE');

      expect(left.map((e) => e.text).toList(), <String>['two']);
      expect((await service.load()).length, 1);
    });

    test('everything can be forgotten', () async {
      await service.record('one');
      await service.clear();

      expect(await service.load(), isEmpty);
    });

    test('a corrupt file reads as no history rather than an error', () async {
      await File(service.filePath).writeAsString('{not json at all');

      expect(await service.load(), isEmpty);
    });

    test('a file holding the wrong shape reads as no history', () async {
      await File(service.filePath).writeAsString('{"nope": true}');

      expect(await service.load(), isEmpty);
    });

    test('unusable rows are skipped and the good ones kept', () async {
      await File(service.filePath).writeAsString(
        '[{"text":"good","last_used":1700000000000},'
        '{"text":""},'
        '"rubbish"]',
      );

      final entries = await service.load();

      expect(entries.length, 1);
      expect(entries.first.text, 'good');
    });

    test('recording over a corrupt file repairs it', () async {
      await File(service.filePath).writeAsString('broken');

      await service.record('beach');

      expect((await service.load()).map((e) => e.text), <String>['beach']);
    });
  });
}
