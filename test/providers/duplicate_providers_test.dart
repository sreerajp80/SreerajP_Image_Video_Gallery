import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/duplicate_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';

/// Records which items were moved to the trash, and can be told to fail.
class _FakeRepository implements MediaRepository {
  final List<String> trashed = <String>[];
  bool fail = false;

  @override
  Future<void> setTrash(String id, bool isTrash) async {
    if (fail) throw StateError('locked');
    trashed.add(id);
  }

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

final _group = DuplicateGroup(
  id: 'g1',
  kind: DuplicateGroupKind.exact,
  items: <MediaItem>[_photo('a'), _photo('b'), _photo('c')],
  suggestedKeeperId: 'a',
);

void main() {
  group('DuplicateKeeperNotifier', () {
    late DuplicateKeeperNotifier notifier;

    setUp(() => notifier = DuplicateKeeperNotifier());
    tearDown(() => notifier.dispose());

    test('uses the suggested keeper until the user picks one', () {
      expect(notifier.keeperFor(_group), 'a');

      notifier.choose('g1', 'c');
      expect(notifier.keeperFor(_group), 'c');

      notifier.forget('g1');
      expect(notifier.keeperFor(_group), 'a');
    });
  });

  group('DuplicateCleanupController', () {
    late _FakeRepository repository;
    late ProviderContainer container;

    setUp(() {
      repository = _FakeRepository();
      container = ProviderContainer(
        overrides: <Override>[
          mediaRepositoryProvider.overrideWithValue(repository),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('trashes every copy except the keeper', () async {
      final trashBefore = container.read(trashRevisionProvider);
      final albumsBefore = container.read(albumRevisionProvider);
      container.read(duplicateKeeperProvider.notifier).choose('g1', 'b');

      final moved = await container
          .read(duplicateCleanupControllerProvider.notifier)
          .keepOnly(_group, 'b');

      expect(moved, 2);
      expect(repository.trashed, <String>['a', 'c']);
      expect(container.read(duplicateCleanupControllerProvider).value, 2);
      expect(container.read(trashRevisionProvider), trashBefore + 1);
      expect(container.read(albumRevisionProvider), albumsBefore + 1);
      // The choice is forgotten once the group is done with.
      expect(container.read(duplicateKeeperProvider), isEmpty);
    });

    test('a failure gives an error state and moves nothing more', () async {
      repository.fail = true;

      final moved = await container
          .read(duplicateCleanupControllerProvider.notifier)
          .keepOnly(_group, 'a');

      expect(moved, isNull);
      expect(
        container.read(duplicateCleanupControllerProvider).hasError,
        isTrue,
      );
    });
  });

  test('an unknown group id finds no group', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(duplicateGroupProvider('missing')), isNull);
  });
}
