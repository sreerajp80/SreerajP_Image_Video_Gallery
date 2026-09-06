import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_scan_state.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/content_hash_service.dart';
import 'package:in_sreerajp_imgvidgal/services/duplicates/duplicate_scan_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_hash_tools_channel.dart';

MediaItem item(String id, {MediaType type = MediaType.image}) {
  final when = DateTime(2026, 1, 1);
  return MediaItem(
    id: id,
    path: '/storage/DCIM/$id.jpg',
    uri: 'content://media/$id',
    displayName: '$id.jpg',
    mediaType: type,
    mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
    size: 1000,
    dateAdded: when,
    dateModified: when,
    width: 100,
    height: 100,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DuplicateScanService', () {
    late DatabaseHelper dbHelper;
    late MediaDao mediaDao;
    late FakeHashToolsChannel channel;

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      channel = FakeHashToolsChannel();
    });

    tearDown(() async {
      await dbHelper.close();
    });

    DuplicateScanService build({int pageSize = 2}) {
      return DuplicateScanService(
        mediaDao: mediaDao,
        hashService: ContentHashService(channel: channel, mediaDao: mediaDao),
        pageSize: pageSize,
      );
    }

    test('finds identical files and reports done', () async {
      for (final id in <String>['a', 'b', 'c']) {
        await mediaDao.insertMediaItem(item(id));
      }
      channel.digests
        ..['content://media/a'] = 'same'
        ..['content://media/b'] = 'same'
        ..['content://media/c'] = 'different';
      channel.grids
        ..['content://media/a'] = texturedGrid(3)
        ..['content://media/b'] = texturedGrid(3)
        ..['content://media/c'] = texturedGrid(29);

      final state = await build().run();

      expect(state.stage, DuplicateScanStage.done);
      expect(state.processed, 3);
      expect(state.total, 3);
      expect(state.groups.length, 1);
      expect(state.groups.first.memberCount, 2);
    });

    test('pages through the whole library', () async {
      for (var i = 0; i < 5; i++) {
        await mediaDao.insertMediaItem(item('item$i'));
        channel.digests['content://media/item$i'] = 'digest$i';
      }

      final state = await build(pageSize: 2).run();

      expect(state.processed, 5);
      expect(state.stage, DuplicateScanStage.done);
    });

    test('stores hashes so a second scan reads no files', () async {
      await mediaDao.insertMediaItem(item('a'));
      channel.digests['content://media/a'] = 'aaa';
      channel.grids['content://media/a'] = texturedGrid(3);

      await build().run();
      final callsAfterFirst = channel.sha256CallCount;
      expect(callsAfterFirst, 1);

      await build().run();

      // The second run reads the stored hash instead of the file, which is
      // what makes rescanning quick.
      expect(channel.sha256CallCount, callsAfterFirst);
    });

    test('keeps going past a file it cannot read, and counts it', () async {
      await mediaDao.insertMediaItem(item('good'));
      await mediaDao.insertMediaItem(item('broken'));
      channel.digests['content://media/good'] = 'ok';
      channel.grids['content://media/good'] = texturedGrid(3);
      // 'broken' has no digest and no grid, so nothing can be worked out.

      final state = await build().run();

      expect(state.stage, DuplicateScanStage.done);
      expect(state.processed, 2);
      expect(state.failures, 1);
    });

    test('a platform failure is a skipped row, not a broken scan', () async {
      await mediaDao.insertMediaItem(item('good'));
      await mediaDao.insertMediaItem(item('angry'));
      channel.digests['content://media/good'] = 'ok';
      channel.throwingUris.add('content://media/angry');

      final state = await build().run();

      expect(state.stage, DuplicateScanStage.done);
      expect(state.failures, 1);
    });

    test('a video gets a digest but no perceptual hash', () async {
      await mediaDao.insertMediaItem(item('clip', type: MediaType.video));
      channel.digests['content://media/clip'] = 'movie';

      final state = await build().run();

      expect(state.stage, DuplicateScanStage.done);
      expect(state.failures, 0);
      // Perceptual hashing a video frame is out of scope, so the decoder is
      // never asked for one.
      expect(channel.grayscaleCallCount, 0);
    });

    test('cancelling part way through ends as cancelled', () async {
      for (var i = 0; i < 6; i++) {
        await mediaDao.insertMediaItem(item('item$i'));
        channel.digests['content://media/item$i'] = 'digest$i';
      }

      final service = build(pageSize: 2);
      final state = await service.run(
        onProgress: (s) {
          if (s.processed >= 2) service.cancel();
        },
      );

      expect(state.stage, DuplicateScanStage.cancelled);
      expect(state.processed, lessThan(6));
    });

    test('reports progress as it goes', () async {
      for (var i = 0; i < 4; i++) {
        await mediaDao.insertMediaItem(item('item$i'));
        channel.digests['content://media/item$i'] = 'digest$i';
      }

      final seen = <int>[];
      await build(
        pageSize: 2,
      ).run(onProgress: (state) => seen.add(state.processed));

      expect(seen, contains(2));
      expect(seen.last, 4);
    });

    test('an empty library finishes with no groups', () async {
      final state = await build().run();

      expect(state.stage, DuplicateScanStage.done);
      expect(state.processed, 0);
      expect(state.groups, isEmpty);
    });
  });
}
