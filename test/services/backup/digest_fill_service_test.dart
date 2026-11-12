import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/digest_fill_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../duplicates/fake_hash_tools_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late MediaDao mediaDao;
  late FakeHashToolsChannel channel;
  late DigestFillService service;

  final now = DateTime(2026, 11, 11);

  MediaItem item(String id, int size, {String? sha}) => MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    uri: 'content://media/$id',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: size,
    dateAdded: now,
    dateModified: now,
    sha256Hash: sha,
  );

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    mediaDao = MediaDao(dbHelper: dbHelper);
    channel = FakeHashToolsChannel(
      digests: {
        'content://media/a': 'AAA',
        'content://media/b': 'bbb',
        'content://media/c': 'ccc',
      },
    );
    service = DigestFillService(mediaDao: mediaDao, channel: channel);
  });

  tearDown(() async => dbHelper.close());

  test('fills and saves only the missing digests', () async {
    await mediaDao.insertMediaItem(item('a', 10));
    await mediaDao.insertMediaItem(item('b', 20, sha: 'known'));

    final added = await service.fillMissing(['a', 'b']);

    expect(added, 1);
    expect(channel.sha256CallCount, 1);
    // Saved lower-case, so it compares equal to digests from elsewhere.
    expect((await mediaDao.getMediaItemById('a'))!.sha256Hash, 'aaa');
    expect((await mediaDao.getMediaItemById('b'))!.sha256Hash, 'known');
  });

  test('restore hashes only same-size photos with no digest', () async {
    final local = [item('a', 10), item('b', 20), item('c', 30, sha: 'have')];
    for (final m in local) {
      await mediaDao.insertMediaItem(m);
    }

    final out = await service.fillBySize(local, {20, 30});

    expect(channel.sha256CallCount, 1);
    expect(out.map((m) => m.sha256Hash), [null, 'bbb', 'have']);
    expect((await mediaDao.getMediaItemById('b'))!.sha256Hash, 'bbb');
  });

  test('an unreadable file is left without a digest', () async {
    channel.throwingUris.add('content://media/a');
    await mediaDao.insertMediaItem(item('a', 10));
    expect(await service.fillMissing(['a']), 0);
    expect((await mediaDao.getMediaItemById('a'))!.sha256Hash, isNull);
  });
}
