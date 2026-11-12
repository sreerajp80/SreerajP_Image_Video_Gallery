import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_mark.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/sync_mark_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late SyncMarkDao dao;
  late MediaDao mediaDao;

  final now = DateTime(2026, 11, 11, 10);

  MediaItem media(String id) => MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 100,
    dateAdded: now,
    dateModified: now,
  );

  SyncMark mark(String id, String peer, {String sha = 'abc'}) => SyncMark(
    mediaId: id,
    peerId: peer,
    sha256: sha,
    sizeBytes: 100,
    sentAt: now,
  );

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    dao = SyncMarkDao(dbHelper: dbHelper);
    mediaDao = MediaDao(dbHelper: dbHelper);
    await mediaDao.insertMediaItem(media('m1'));
    await mediaDao.insertMediaItem(media('m2'));
  });

  tearDown(() async => dbHelper.close());

  test('marks are kept per phone', () async {
    await dao.saveMark(mark('m1', 'phoneA'));
    await dao.saveMark(mark('m2', 'phoneB'));

    final a = await dao.marksForPeer('phoneA');
    expect(a.keys, ['m1']);
    expect(a['m1'], mark('m1', 'phoneA'));
    expect((await dao.marksForPeer('phoneB')).keys, ['m2']);
  });

  test('a newer mark for the same file and phone replaces the old', () async {
    await dao.saveMark(mark('m1', 'phoneA', sha: 'old'));
    await dao.saveMark(mark('m1', 'phoneA', sha: 'new'));
    final marks = await dao.marksForPeer('phoneA');
    expect(marks, hasLength(1));
    expect(marks['m1']!.sha256, 'new');
  });

  test('clearing one phone leaves the others', () async {
    await dao.saveMark(mark('m1', 'phoneA'));
    await dao.saveMark(mark('m1', 'phoneB'));
    await dao.clearPeer('phoneA');
    expect(await dao.marksForPeer('phoneA'), isEmpty);
    expect(await dao.marksForPeer('phoneB'), hasLength(1));
  });

  test('a mark goes with its photo', () async {
    await dao.saveMark(mark('m1', 'phoneA'));
    await mediaDao.deleteMediaItem('m1');
    expect(await dao.marksForPeer('phoneA'), isEmpty);
  });
}
