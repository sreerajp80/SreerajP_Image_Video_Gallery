import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/batch_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/gallery_batch_handler.dart';

/// Does nothing to the files; fails the items it is told to.
class _FakeHandler implements GalleryBatchHandler {
  final Set<String> failIds;
  final List<String> handled = <String>[];

  _FakeHandler({this.failIds = const <String>{}});

  @override
  Future<String?> handle(BatchAction action, MediaItem item) async {
    if (failIds.contains(item.id)) throw StateError('locked');
    handled.add(item.id);
    return null;
  }

  @override
  Future<List<String>> begin(BatchAction action, List<MediaItem> items) async =>
      const <String>[];

  @override
  bool isWholeBatch(BatchAction action) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MediaItem _photo(String id) => MediaItem(
  id: id,
  path: '/storage/DCIM/Camera/$id.jpg',
  displayName: '$id.jpg',
  mediaType: MediaType.image,
  mimeType: 'image/jpeg',
  size: 1000,
  dateAdded: DateTime(2026, 9),
  dateModified: DateTime(2026, 9),
);

void main() {
  late _FakeHandler handler;
  late ProviderContainer container;

  ProviderContainer build(_FakeHandler fake) {
    handler = fake;
    return ProviderContainer(
      overrides: <Override>[
        galleryBatchHandlerProvider.overrideWith((ref, options) => handler),
      ],
    );
  }

  tearDown(() => container.dispose());

  test('runs every item and reports the outcome', () async {
    container = build(_FakeHandler());

    final outcome = await container
        .read(batchControllerProvider.notifier)
        .run(
          action: BatchAction.favourite,
          items: <MediaItem>[_photo('a'), _photo('b')],
        );

    expect(handler.handled, <String>['a', 'b']);
    expect(outcome?.succeededIds, <String>['a', 'b']);
    expect(container.read(batchControllerProvider).value, outcome);
    expect(container.read(batchProgressProvider), isNull);
  });

  test('one failed item does not stop the rest', () async {
    container = build(_FakeHandler(failIds: <String>{'a'}));

    final outcome = await container
        .read(batchControllerProvider.notifier)
        .run(
          action: BatchAction.favourite,
          items: <MediaItem>[_photo('a'), _photo('b')],
        );

    expect(outcome?.failedIds, <String>['a']);
    expect(outcome?.succeededIds, <String>['b']);
  });

  test('moving to the trash refreshes the trash and the albums', () async {
    container = build(_FakeHandler());
    final trash = container.read(trashRevisionProvider);
    final albums = container.read(albumRevisionProvider);
    final tags = container.read(tagRevisionProvider);

    await container
        .read(batchControllerProvider.notifier)
        .run(action: BatchAction.moveToTrash, items: <MediaItem>[_photo('a')]);

    expect(container.read(trashRevisionProvider), trash + 1);
    expect(container.read(albumRevisionProvider), albums + 1);
    expect(container.read(tagRevisionProvider), tags);
  });

  test('adding tags refreshes the tags only', () async {
    container = build(_FakeHandler());
    final tags = container.read(tagRevisionProvider);
    final albums = container.read(albumRevisionProvider);

    await container
        .read(batchControllerProvider.notifier)
        .run(action: BatchAction.addTags, items: <MediaItem>[_photo('a')]);

    expect(container.read(tagRevisionProvider), tags + 1);
    expect(container.read(albumRevisionProvider), albums);
  });

  test('availability is ready when nothing is selected', () async {
    container = build(_FakeHandler());
    container.listen(batchAvailabilityProvider, (_, _) {});

    // Let the selected-media future settle.
    await Future<void>.delayed(Duration.zero);

    final availability = container.read(batchAvailabilityProvider);
    expect(availability.hasValue, isTrue);
  });
}
