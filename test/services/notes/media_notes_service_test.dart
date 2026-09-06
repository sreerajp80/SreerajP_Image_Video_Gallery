import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/search_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/notes/media_notes_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../media/fake_media_store_channel.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late MediaDao mediaDao;
  late MediaScannerService scanner;
  late MediaRepository repository;
  late MediaNotesService service;

  const photoId = 'photo-1';

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    mediaDao = MediaDao(dbHelper: dbHelper);
    scanner = MediaScannerService(
      channel: FakeMediaStoreChannel(),
      mediaDao: mediaDao,
      batchSize: 10,
    );
    repository = MediaRepository(mediaDao: mediaDao, scanner: scanner);
    service = MediaNotesService(repository: repository);

    await mediaDao.insertMediaItem(
      MediaItem(
        id: photoId,
        path: '/storage/photo-1.jpg',
        displayName: 'photo-1.jpg',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: 1024,
        dateAdded: DateTime(2026, 1, 1),
        dateModified: DateTime(2026, 1, 1),
      ),
    );
  });

  tearDown(() async {
    await scanner.dispose();
    await dbHelper.close();
  });

  group('reading', () {
    test('an item with no note gives an empty note, not null', () async {
      final note = await service.read(photoId);
      expect(note.mediaId, photoId);
      expect(note.isEmpty, isTrue);
      expect(note.markdown, '');
    });

    test('an item that does not exist gives an empty note', () async {
      expect((await service.read('no-such-item')).isEmpty, isTrue);
    });
  });

  group('saving', () {
    test('a note is written and read back', () async {
      await service.save(photoId, '# Kovalam\n\nTaken at sunrise.');
      final note = await service.read(photoId);

      expect(note.markdown, '# Kovalam\n\nTaken at sunrise.');
      expect(note.isNotEmpty, isTrue);
    });

    test('the saved note carries a time', () async {
      final saved = await service.save(photoId, 'a note');
      expect(saved.updatedAt, isNotNull);
    });

    test('surrounding blank space is trimmed off', () async {
      await service.save(photoId, '   spaced out   ');
      expect((await service.read(photoId)).markdown, 'spaced out');
    });

    test(
      'a whitespace-only note clears it rather than storing blanks',
      () async {
        await service.save(photoId, 'something');
        await service.save(photoId, '    \n  ');

        final item = await repository.getMediaItemById(photoId);
        expect(item?.userNotes, isNull);
      },
    );

    test('a note past the cap is refused', () async {
      final tooLong = 'x' * 21;
      final small = MediaNotesService(repository: repository, maxLength: 20);

      expect(
        () => small.save(photoId, tooLong),
        throwsA(isA<NotesException>()),
      );
    });

    test('a note exactly at the cap is accepted', () async {
      final small = MediaNotesService(repository: repository, maxLength: 20);
      await small.save(photoId, 'x' * 20);
      expect((await service.read(photoId)).markdown.length, 20);
    });

    test('saving with no item id is refused', () {
      expect(() => service.save('', 'text'), throwsA(isA<NotesException>()));
    });

    test('malayalam text survives the round trip', () async {
      const malayalam = 'കോവളം കടപ്പുറത്ത് എടുത്തത്';
      await service.save(photoId, malayalam);
      expect((await service.read(photoId)).markdown, malayalam);
    });
  });

  group('appending', () {
    test('appending to an empty note just writes the text', () async {
      await service.append(photoId, 'https://example.com');
      expect((await service.read(photoId)).markdown, 'https://example.com');
    });

    // Someone who has already written about a photo must not lose it by
    // tapping "save to notes" on a scanned code.
    test('appending keeps what was already written', () async {
      await service.save(photoId, 'My own words.');
      await service.append(photoId, 'https://example.com');

      final note = await service.read(photoId);
      expect(note.markdown, startsWith('My own words.'));
      expect(note.markdown, endsWith('https://example.com'));
    });

    test('a blank line separates the old note from the new text', () async {
      await service.save(photoId, 'first');
      await service.append(photoId, 'second');
      expect((await service.read(photoId)).markdown, 'first\n\nsecond');
    });

    test('appending nothing changes nothing', () async {
      await service.save(photoId, 'unchanged');
      await service.append(photoId, '   ');
      expect((await service.read(photoId)).markdown, 'unchanged');
    });

    test('appending past the cap trims rather than failing', () async {
      final small = MediaNotesService(repository: repository, maxLength: 20);
      await small.save(photoId, 'x' * 15);
      await small.append(photoId, 'y' * 50);

      final note = await service.read(photoId);
      expect(note.markdown.length, lessThanOrEqualTo(20));
      expect(note.markdown, startsWith('x' * 15));
    });
  });

  group('clearing', () {
    test('a cleared note is gone', () async {
      await service.save(photoId, 'temporary');
      await service.clear(photoId);

      expect((await service.read(photoId)).isEmpty, isTrue);
      expect((await repository.getMediaItemById(photoId))?.userNotes, isNull);
    });
  });

  // The whole reason notes live in the media row rather than a table of their
  // own: the update trigger mirrors them into the search index for free.
  group('a note is searchable the moment it is saved', () {
    test('the note text finds the photo', () async {
      final search = SearchRepository(mediaDao: mediaDao);
      await service.save(photoId, 'birthday at the beach');

      final results = await search.searchText('birthday');
      expect(results.map((result) => result.item.id), contains(photoId));
    });

    test('a cleared note stops finding the photo', () async {
      final search = SearchRepository(mediaDao: mediaDao);
      await service.save(photoId, 'birthday at the beach');
      await service.clear(photoId);

      final results = await search.searchText('birthday');
      expect(results.map((result) => result.item.id), isNot(contains(photoId)));
    });
  });
}
