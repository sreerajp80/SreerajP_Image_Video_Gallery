import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/database_helper.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/tag_dao.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TagFilterNotifier', () {
    late TagFilterNotifier notifier;

    setUp(() => notifier = TagFilterNotifier());
    tearDown(() => notifier.dispose());

    test('starts empty in AND mode', () {
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.mode, TagFilterMode.andMode);
    });

    test('toggle adds and then removes a tag', () {
      notifier.toggle('t1');
      expect(notifier.state.tagIds, <String>{'t1'});
      notifier.toggle('t1');
      expect(notifier.state.isEmpty, isTrue);
    });

    test('selectOnly replaces the selection; clear keeps the mode', () {
      notifier
        ..toggle('t1')
        ..toggle('t2')
        ..setMode(TagFilterMode.orMode)
        ..selectOnly('t3');
      expect(notifier.state.tagIds, <String>{'t3'});

      notifier.clear();
      expect(notifier.state.isEmpty, isTrue);
      expect(notifier.state.mode, TagFilterMode.orMode);
    });
  });

  group('TagEditController', () {
    late MediaDao mediaDao;
    late DatabaseHelper dbHelper;
    late ProviderContainer container;

    setUp(() {
      dbHelper = DatabaseHelper(
        customPath: inMemoryDatabasePath,
        customFactory: databaseFactoryFfi,
      );
      mediaDao = MediaDao(dbHelper: dbHelper);
      container = ProviderContainer(
        overrides: <Override>[
          mediaDaoProvider.overrideWithValue(mediaDao),
          tagDaoProvider.overrideWithValue(TagDao(dbHelper: dbHelper)),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await dbHelper.close();
    });

    TagEditController controller() =>
        container.read(tagEditControllerProvider.notifier);

    test('creating a tag bumps the revision and lists it', () async {
      final before = container.read(tagRevisionProvider);

      expect(await controller().create('Beach'), isNotNull);

      expect(container.read(tagRevisionProvider), before + 1);
      final tags = await container.read(allTagsProvider.future);
      expect(tags.map((t) => t.name), contains('Beach'));
    });

    test('an invalid name gives an error state', () async {
      expect(await controller().create(''), isNull);
      expect(container.read(tagEditControllerProvider).hasError, isTrue);
    });

    test('tags set on a photo are read back for it', () async {
      final photo = MediaItem(
        id: 'g1',
        path: '/storage/DCIM/Camera/G1.jpg',
        displayName: 'G1.jpg',
        mediaType: MediaType.image,
        mimeType: 'image/jpeg',
        size: 1000,
        dateAdded: DateTime(2026, 9),
        dateModified: DateTime(2026, 9),
      );
      await mediaDao.batchUpsertMediaItems(<MediaItem>[photo]);
      final tag = (await controller().findOrCreate('Beach'))!;

      await controller().setTagsForMedia(photo.id, <String>{tag.id});

      final tags = await container.read(tagsForMediaProvider(photo.id).future);
      expect(tags.single.id, tag.id);
    });
  });
}
