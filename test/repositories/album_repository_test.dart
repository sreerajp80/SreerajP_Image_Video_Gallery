import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/album.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/album_repository.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/album_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/album_name_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/smart_album_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late AlbumDao albumDao;
  late MediaDao mediaDao;
  late AlbumRepository repository;

  final now = DateTime(2026, 8, 30, 10);

  MediaItem media(
    String id, {
    String? path,
    MediaType type = MediaType.image,
    bool isFavorite = false,
    bool isTrash = false,
    int? width,
    int? height,
    DateTime? added,
    DateTime? taken,
  }) {
    final stamp = added ?? now;
    return MediaItem(
      id: id,
      path: path ?? '/DCIM/Camera/$id.jpg',
      displayName: '$id.jpg',
      mediaType: type,
      mimeType: 'image/jpeg',
      size: 1000,
      dateAdded: stamp,
      dateModified: stamp,
      dateTaken: taken,
      isFavorite: isFavorite,
      isTrash: isTrash,
      width: width,
      height: height,
    );
  }

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    albumDao = AlbumDao(dbHelper: dbHelper);
    mediaDao = MediaDao(dbHelper: dbHelper);
    repository = AlbumRepository(albumDao: albumDao, mediaDao: mediaDao);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  group('createAlbum', () {
    test('creates an album with a normalized name', () async {
      final album = await repository.createAlbum('  Trip   2026 ');

      expect(album.name, 'Trip 2026');
      expect(album.albumType, AlbumType.virtualAlbum);
      expect(album.itemCount, 0);
      expect((await repository.getVirtualAlbums()).length, 1);
    });

    test('gives two albums made together different ids', () async {
      final first = await repository.createAlbum('One');
      final second = await repository.createAlbum('Two');
      expect(first.id, isNot(second.id));
    });

    test('refuses an empty name', () async {
      await expectLater(
        repository.createAlbum('   '),
        throwsA(
          isA<AlbumValidationException>().having(
            (e) => e.reason,
            'reason',
            AlbumNameError.empty,
          ),
        ),
      );
    });

    test('refuses a duplicate name', () async {
      await repository.createAlbum('Holiday');
      await expectLater(
        repository.createAlbum('holiday'),
        throwsA(
          isA<AlbumValidationException>().having(
            (e) => e.reason,
            'reason',
            AlbumNameError.duplicate,
          ),
        ),
      );
    });

    test('refuses a name that is too long', () async {
      await expectLater(
        repository.createAlbum('a' * (AlbumNameRules.maxLength + 1)),
        throwsA(isA<AlbumValidationException>()),
      );
    });
  });

  group('renameAlbum', () {
    test('renames an album', () async {
      final album = await repository.createAlbum('Holiday');
      final renamed = await repository.renameAlbum(album.id, 'Vacation');

      expect(renamed.name, 'Vacation');
      expect((await albumDao.getAlbumById(album.id))!.name, 'Vacation');
    });

    test('lets an album keep its own name', () async {
      final album = await repository.createAlbum('Holiday');
      final renamed = await repository.renameAlbum(album.id, 'Holiday');
      expect(renamed.name, 'Holiday');
    });

    test('refuses another album name', () async {
      await repository.createAlbum('Work');
      final album = await repository.createAlbum('Holiday');

      await expectLater(
        repository.renameAlbum(album.id, 'Work'),
        throwsA(isA<AlbumValidationException>()),
      );
    });

    test('throws when the album is gone', () async {
      await expectLater(
        repository.renameAlbum('nope', 'Anything'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('membership', () {
    test('adds and removes items, keeping the count right', () async {
      final album = await repository.createAlbum('Holiday');
      await mediaDao.insertMediaItem(media('m1'));
      await mediaDao.insertMediaItem(media('m2'));

      await repository.addMedia(album.id, 'm1');
      await repository.addMedia(album.id, 'm2');
      expect((await repository.getAlbumMedia(album.id)).length, 2);

      await repository.removeMedia(album.id, 'm1');
      final left = await repository.getAlbumMedia(album.id);
      expect(left.map((i) => i.id).toList(), <String>['m2']);
    });

    test('keeps the order items were added in', () async {
      final album = await repository.createAlbum('Holiday');
      for (final id in <String>['m1', 'm2', 'm3']) {
        await mediaDao.insertMediaItem(media(id));
        await repository.addMedia(album.id, id);
      }

      final items = await repository.getAlbumMedia(album.id);
      expect(items.map((i) => i.id).toList(), <String>['m1', 'm2', 'm3']);
    });

    test('applies a new order', () async {
      final album = await repository.createAlbum('Holiday');
      for (final id in <String>['m1', 'm2', 'm3']) {
        await mediaDao.insertMediaItem(media(id));
        await repository.addMedia(album.id, id);
      }

      await repository.setAlbumOrder(album.id, <String>['m3', 'm2', 'm1']);
      final items = await repository.getAlbumMedia(album.id);
      expect(items.map((i) => i.id).toList(), <String>['m3', 'm2', 'm1']);
    });

    test('setAlbumsForMedia applies only the difference', () async {
      final a1 = await repository.createAlbum('One');
      final a2 = await repository.createAlbum('Two');
      final a3 = await repository.createAlbum('Three');
      await mediaDao.insertMediaItem(media('m1'));

      await repository.setAlbumsForMedia('m1', <String>{a1.id, a2.id});
      expect((await repository.getAlbumIdsForMedia('m1')).toSet(), <String>{
        a1.id,
        a2.id,
      });

      await repository.setAlbumsForMedia('m1', <String>{a2.id, a3.id});
      expect((await repository.getAlbumIdsForMedia('m1')).toSet(), <String>{
        a2.id,
        a3.id,
      });
    });

    test('setAlbumsForMedia can clear every album', () async {
      final album = await repository.createAlbum('One');
      await mediaDao.insertMediaItem(media('m1'));
      await repository.setAlbumsForMedia('m1', <String>{album.id});

      await repository.setAlbumsForMedia('m1', const <String>{});
      expect(await repository.getAlbumIdsForMedia('m1'), isEmpty);
    });

    test('deleting an album leaves the media items alone', () async {
      final album = await repository.createAlbum('Holiday');
      await mediaDao.insertMediaItem(media('m1'));
      await repository.addMedia(album.id, 'm1');

      await repository.deleteAlbum(album.id);

      expect(await albumDao.getAlbumById(album.id), isNull);
      // The photo is still in the library: an album never owned the file.
      expect(await mediaDao.getMediaItemById('m1'), isNotNull);
    });
  });

  group('covers', () {
    test('uses the chosen cover', () async {
      final album = await repository.createAlbum('Holiday');
      await mediaDao.insertMediaItem(media('m1'));
      await mediaDao.insertMediaItem(media('m2'));
      await repository.addMedia(album.id, 'm1');
      await repository.addMedia(album.id, 'm2');

      await repository.setAlbumCover(album.id, 'm2');

      final summary = await repository.getVirtualAlbumSummary(album.id);
      expect(summary!.coverItem?.id, 'm2');
    });

    test('falls back to the first member when no cover is chosen', () async {
      final album = await repository.createAlbum('Holiday');
      await mediaDao.insertMediaItem(media('m1'));
      await mediaDao.insertMediaItem(media('m2'));
      await repository.addMedia(album.id, 'm1');
      await repository.addMedia(album.id, 'm2');

      final summary = await repository.getVirtualAlbumSummary(album.id);
      expect(summary!.coverItem?.id, 'm1');
    });

    test('falls back when the chosen cover has since gone', () async {
      final album = await repository.createAlbum('Holiday');
      await mediaDao.insertMediaItem(media('m1'));
      await mediaDao.insertMediaItem(media('m2'));
      await repository.addMedia(album.id, 'm1');
      await repository.addMedia(album.id, 'm2');
      await repository.setAlbumCover(album.id, 'm2');

      await mediaDao.deleteMediaItem('m2');

      final summary = await repository.getVirtualAlbumSummary(album.id);
      expect(summary!.coverItem?.id, 'm1');
    });

    test('an empty album has no cover rather than failing', () async {
      final album = await repository.createAlbum('Holiday');
      final summary = await repository.getVirtualAlbumSummary(album.id);
      expect(summary!.coverItem, isNull);
      expect(summary.isEmpty, isTrue);
    });

    test('returns null for an album that is not there', () async {
      expect(await repository.getVirtualAlbumSummary('nope'), isNull);
    });
  });

  group('folder albums', () {
    test('lists each folder with its count, name, and cover', () async {
      await mediaDao.insertMediaItem(
        media('m1', path: '/DCIM/Camera/a.jpg', taken: DateTime(2020)),
      );
      await mediaDao.insertMediaItem(
        media('m2', path: '/DCIM/Camera/b.jpg', taken: DateTime(2026, 8)),
      );
      await mediaDao.insertMediaItem(
        media('m3', path: '/Pictures/Screenshots/c.png'),
      );

      final folders = await repository.getFolderAlbums();
      final camera = folders.firstWhere((f) => f.id == '/DCIM/Camera');

      expect(camera.name, 'Camera');
      expect(camera.albumType, AlbumType.physicalFolder);
      expect(camera.itemCount, 2);
      expect(camera.coverItem?.id, 'm2');
      expect(folders.map((f) => f.name), contains('Screenshots'));
    });

    test('opening a folder returns only its own files', () async {
      await mediaDao.insertMediaItem(media('m1', path: '/DCIM/Camera/a.jpg'));
      await mediaDao.insertMediaItem(
        media('m2', path: '/DCIM/CameraRoll/b.jpg'),
      );

      final items = await repository.getFolderMedia('/DCIM/Camera');
      expect(items.map((i) => i.id).toList(), <String>['m1']);
    });

    test('an empty library has no folders', () async {
      expect(await repository.getFolderAlbums(), isEmpty);
    });
  });

  group('smart albums', () {
    Future<void> seed() async {
      await mediaDao.insertMediaItem(media('fav', isFavorite: true));
      await mediaDao.insertMediaItem(media('vid', type: MediaType.video));
      await mediaDao.insertMediaItem(media('gif', type: MediaType.gif));
      await mediaDao.insertMediaItem(media('raw', type: MediaType.rawImage));
      await mediaDao.insertMediaItem(media('pano', width: 8000, height: 2000));
      await mediaDao.insertMediaItem(media('plain', width: 4000, height: 3000));
    }

    test('favorites holds only starred items', () async {
      await seed();
      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartFavorites),
      );
      expect(items.map((i) => i.id).toList(), <String>['fav']);
    });

    test('videos holds only videos', () async {
      await seed();
      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartVideos),
      );
      expect(items.map((i) => i.id).toList(), <String>['vid']);
    });

    test('gifs holds only gifs', () async {
      await seed();
      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartGifs),
      );
      expect(items.map((i) => i.id).toList(), <String>['gif']);
    });

    test('raw holds only raw captures', () async {
      await seed();
      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartRaw),
      );
      expect(items.map((i) => i.id).toList(), <String>['raw']);
    });

    test('panoramas holds only wide stills', () async {
      await seed();
      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartPanoramas),
      );
      expect(items.map((i) => i.id).toList(), <String>['pano']);
    });

    test('recently added drops anything past the window', () async {
      final today = DateTime(2026, 8, 30);
      await mediaDao.insertMediaItem(media('new', added: today));
      await mediaDao.insertMediaItem(media('old', added: DateTime(2020, 1, 1)));

      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartRecentlyAdded),
        now: today,
      );
      expect(items.map((i) => i.id).toList(), <String>['new']);
    });

    test(
      'summaries count every smart album and cover the non-empty ones',
      () async {
        await seed();
        final summaries = await repository.getSmartAlbums(now: now);

        expect(summaries.length, 7);
        final favorites = summaries.firstWhere(
          (s) => s.albumType == AlbumType.smartFavorites,
        );
        expect(favorites.itemCount, 1);
        expect(favorites.coverItem?.id, 'fav');
      },
    );

    test('an empty smart album reports zero and no cover', () async {
      final summaries = await repository.getSmartAlbums(now: now);
      for (final summary in summaries) {
        expect(summary.itemCount, 0);
        expect(summary.coverItem, isNull);
      }
    });

    test('a key resolves to the same items as the album itself', () async {
      await seed();
      final byKey = await repository.getSmartAlbumMediaByKey('videos');
      expect(byKey!.map((i) => i.id).toList(), <String>['vid']);
    });

    test('an unknown key returns null rather than throwing', () async {
      expect(await repository.getSmartAlbumMediaByKey('nonsense'), isNull);
    });

    test(
      'a user filter cannot widen a smart album past its own rule',
      () async {
        await seed();
        final items = await repository.getSmartAlbumMedia(
          SmartAlbumService.forType(AlbumType.smartVideos),
          // The sheet asks for images; the album is Videos, so Videos wins.
          filter: const FilterOptions(mediaTypes: <MediaType>{MediaType.image}),
        );
        expect(items.map((i) => i.id).toList(), <String>['vid']);
      },
    );

    test('a user filter can still narrow a smart album', () async {
      await mediaDao.insertMediaItem(media('small', type: MediaType.video));
      final items = await repository.getSmartAlbumMedia(
        SmartAlbumService.forType(AlbumType.smartVideos),
        filter: const FilterOptions(minSizeBytes: 100000),
      );
      expect(items, isEmpty);
    });

    test(
      'trash smart album retains isTrash when extra filter is applied',
      () async {
        await seed();
        await mediaDao.insertMediaItem(media('trashed', isTrash: true));

        // Query without extra filter
        final withoutFilter = await repository.getSmartAlbumMedia(
          SmartAlbumService.forType(AlbumType.smartTrash),
        );
        expect(withoutFilter.map((i) => i.id).toList(), <String>['trashed']);

        // Query with extra filter (e.g. albumFilterProvider)
        final withFilter = await repository.getSmartAlbumMedia(
          SmartAlbumService.forType(AlbumType.smartTrash),
          filter: const FilterOptions(),
        );
        expect(withFilter.map((i) => i.id).toList(), <String>['trashed']);

        // By key
        final byKey = await repository.getSmartAlbumMediaByKey(
          'trash',
          filter: const FilterOptions(),
        );
        expect(byKey!.map((i) => i.id).toList(), <String>['trashed']);
      },
    );
  });
}
