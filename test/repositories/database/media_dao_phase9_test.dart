import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Covers the folder, size, and tag-presence filters and the folder grouping
/// query added in Phase 9.
void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late DatabaseHelper dbHelper;
  late MediaDao mediaDao;
  late TagDao tagDao;

  final now = DateTime(2026, 8, 30, 10);

  MediaItem media(
    String id,
    String path, {
    int size = 1000,
    MediaType type = MediaType.image,
    DateTime? taken,
  }) {
    return MediaItem(
      id: id,
      path: path,
      displayName: path.split('/').last,
      mediaType: type,
      mimeType: 'image/jpeg',
      size: size,
      dateAdded: now,
      dateModified: now,
      dateTaken: taken,
    );
  }

  setUp(() async {
    dbHelper = DatabaseHelper(
      customPath: inMemoryDatabasePath,
      customFactory: databaseFactoryFfi,
    );
    mediaDao = MediaDao(dbHelper: dbHelper);
    tagDao = TagDao(dbHelper: dbHelper);
  });

  tearDown(() async {
    await dbHelper.close();
  });

  Future<void> seedFolders() async {
    await mediaDao.insertMediaItem(media('m1', '/DCIM/Camera/a.jpg'));
    await mediaDao.insertMediaItem(media('m2', '/DCIM/Camera/b.jpg'));
    // A sibling folder whose name starts with the same text. A plain prefix
    // match would wrongly pull this into the Camera folder.
    await mediaDao.insertMediaItem(media('m3', '/DCIM/CameraRoll/c.jpg'));
    // A sub-folder. Its file is inside Camera's subtree but not in Camera.
    await mediaDao.insertMediaItem(media('m4', '/DCIM/Camera/2026/d.jpg'));
    await mediaDao.insertMediaItem(media('m5', '/Pictures/Screenshots/e.png'));
  }

  group('folder filter', () {
    test('returns only the files directly in the folder', () async {
      await seedFolders();

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(folderPaths: <String>{'/DCIM/Camera'}),
      );

      expect(items.map((i) => i.id).toSet(), <String>{'m1', 'm2'});
    });

    test('does not leak in a sibling folder with a longer name', () async {
      await seedFolders();

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(folderPaths: <String>{'/DCIM/Camera'}),
      );

      expect(items.map((i) => i.id), isNot(contains('m3')));
    });

    test('does not leak in a sub-folder', () async {
      await seedFolders();

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(folderPaths: <String>{'/DCIM/Camera'}),
      );

      expect(items.map((i) => i.id), isNot(contains('m4')));
    });

    test('accepts several folders at once', () async {
      await seedFolders();

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(
          folderPaths: <String>{'/DCIM/Camera', '/Pictures/Screenshots'},
        ),
      );

      expect(items.map((i) => i.id).toSet(), <String>{'m1', 'm2', 'm5'});
    });

    test('a folder name containing a wildcard matches only itself', () async {
      await mediaDao.insertMediaItem(media('w1', '/DCIM/100%/a.jpg'));
      await mediaDao.insertMediaItem(media('w2', '/DCIM/100X/b.jpg'));

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(folderPaths: <String>{'/DCIM/100%'}),
      );

      expect(items.map((i) => i.id).toList(), <String>['w1']);
    });

    test(
      'a folder name containing an underscore matches only itself',
      () async {
        await mediaDao.insertMediaItem(media('u1', '/DCIM/my_pics/a.jpg'));
        await mediaDao.insertMediaItem(media('u2', '/DCIM/myXpics/b.jpg'));

        final items = await mediaDao.getMediaItems(
          filter: const FilterOptions(folderPaths: <String>{'/DCIM/my_pics'}),
        );

        expect(items.map((i) => i.id).toList(), <String>['u1']);
      },
    );

    test('combines with another filter rather than replacing it', () async {
      await seedFolders();
      await mediaDao.insertMediaItem(
        media('v1', '/DCIM/Camera/v.mp4', type: MediaType.video),
      );

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(
          folderPaths: <String>{'/DCIM/Camera'},
          mediaTypes: <MediaType>{MediaType.video},
        ),
      );

      expect(items.map((i) => i.id).toList(), <String>['v1']);
    });
  });

  group('getFolderSummaries', () {
    test('groups by folder with the right counts', () async {
      await seedFolders();

      final rows = await mediaDao.getFolderSummaries();
      final byDirectory = <String, int>{
        for (final row in rows) row.directory: row.itemCount,
      };

      expect(byDirectory['/DCIM/Camera'], 2);
      expect(byDirectory['/DCIM/CameraRoll'], 1);
      expect(byDirectory['/DCIM/Camera/2026'], 1);
      expect(byDirectory['/Pictures/Screenshots'], 1);
    });

    test('picks the newest item as the cover', () async {
      await mediaDao.insertMediaItem(
        media('old', '/DCIM/Camera/old.jpg', taken: DateTime(2020)),
      );
      await mediaDao.insertMediaItem(
        media('new', '/DCIM/Camera/new.jpg', taken: DateTime(2026, 8)),
      );

      final rows = await mediaDao.getFolderSummaries();
      final camera = rows.firstWhere((r) => r.directory == '/DCIM/Camera');
      expect(camera.coverMediaId, 'new');
    });

    test('leaves out trashed and vaulted items', () async {
      await mediaDao.insertMediaItem(media('m1', '/DCIM/Camera/a.jpg'));
      await mediaDao.insertMediaItem(media('m2', '/DCIM/Camera/b.jpg'));
      await mediaDao.updateTrash('m2', true);

      final rows = await mediaDao.getFolderSummaries();
      final camera = rows.firstWhere((r) => r.directory == '/DCIM/Camera');
      expect(camera.itemCount, 1);
      expect(camera.coverMediaId, 'm1');
    });

    test('returns nothing for an empty library', () async {
      expect(await mediaDao.getFolderSummaries(), isEmpty);
    });

    test('leaves out a path that has no folder at all', () async {
      await mediaDao.insertMediaItem(media('bare', 'loose.jpg'));

      final rows = await mediaDao.getFolderSummaries();
      expect(rows.where((r) => r.directory.isEmpty), isEmpty);
    });

    test('agrees with what the folder filter returns', () async {
      await seedFolders();

      for (final row in await mediaDao.getFolderSummaries()) {
        final items = await mediaDao.getMediaItems(
          filter: FilterOptions(folderPaths: <String>{row.directory}),
        );
        expect(
          items.length,
          row.itemCount,
          reason: 'count disagreed for ${row.directory}',
        );
      }
    });
  });

  group('size range filter', () {
    Future<void> seedSizes() async {
      await mediaDao.insertMediaItem(media('s1', '/a/1.jpg', size: 500));
      await mediaDao.insertMediaItem(media('s2', '/a/2.jpg', size: 1500));
      await mediaDao.insertMediaItem(media('s3', '/a/3.jpg', size: 5000));
    }

    test('applies a lower bound, inclusive', () async {
      await seedSizes();
      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(minSizeBytes: 1500),
      );
      expect(items.map((i) => i.id).toSet(), <String>{'s2', 's3'});
    });

    test('applies an upper bound, inclusive', () async {
      await seedSizes();
      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(maxSizeBytes: 1500),
      );
      expect(items.map((i) => i.id).toSet(), <String>{'s1', 's2'});
    });

    test('applies both ends together', () async {
      await seedSizes();
      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(minSizeBytes: 1000, maxSizeBytes: 2000),
      );
      expect(items.map((i) => i.id).toList(), <String>['s2']);
    });
  });

  group('has tags filter', () {
    test('keeps only items carrying at least one tag', () async {
      await mediaDao.insertMediaItem(media('t1', '/a/1.jpg'));
      await mediaDao.insertMediaItem(media('t2', '/a/2.jpg'));
      await tagDao.insertTag(
        Tag(id: 'tag1', name: 'Nature', colorValue: 1, dateCreated: now),
      );
      await tagDao.addTagToMedia('t1', 'tag1');

      final items = await mediaDao.getMediaItems(
        filter: const FilterOptions(hasTagsOnly: true),
      );
      expect(items.map((i) => i.id).toList(), <String>['t1']);
    });

    test('returns everything when the flag is off', () async {
      await mediaDao.insertMediaItem(media('t1', '/a/1.jpg'));
      await mediaDao.insertMediaItem(media('t2', '/a/2.jpg'));

      final items = await mediaDao.getMediaItems();
      expect(items.length, 2);
    });
  });

  group('getMediaItemsByIds', () {
    test('returns the rows in the order asked for', () async {
      for (final id in <String>['m1', 'm2', 'm3']) {
        await mediaDao.insertMediaItem(media(id, '/a/$id.jpg'));
      }

      final items = await mediaDao.getMediaItemsByIds(<String>[
        'm3',
        'm1',
        'm2',
      ]);
      expect(items.map((i) => i.id).toList(), <String>['m3', 'm1', 'm2']);
    });

    test('quietly skips an id that is no longer indexed', () async {
      await mediaDao.insertMediaItem(media('m1', '/a/1.jpg'));

      final items = await mediaDao.getMediaItemsByIds(<String>['m1', 'gone']);
      expect(items.map((i) => i.id).toList(), <String>['m1']);
    });

    test('returns nothing for an empty list', () async {
      expect(await mediaDao.getMediaItemsByIds(const <String>[]), isEmpty);
    });

    test('leaves out a trashed item', () async {
      await mediaDao.insertMediaItem(media('m1', '/a/1.jpg'));
      await mediaDao.updateTrash('m1', true);

      expect(await mediaDao.getMediaItemsByIds(<String>['m1']), isEmpty);
    });
  });
}
