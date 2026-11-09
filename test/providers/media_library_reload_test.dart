import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_permission_status.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_permission_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';

MediaItem _photo(int i) {
  final date = DateTime(2026, 8, 29).subtract(Duration(minutes: i));
  return MediaItem(
    id: 'p$i',
    path: '/storage/emulated/0/DCIM/p$i.jpg',
    displayName: 'p$i.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 100,
    dateAdded: date,
    dateModified: date,
    dateTaken: date,
  );
}

/// A repository that serves a fixed library and records every list query.
class _FakeMediaRepository extends Fake implements MediaRepository {
  final List<MediaItem> library;

  /// The limit of each list query, null meaning "everything".
  final List<int?> queries = <int?>[];

  /// What the next scan reports.
  ScanResult nextScan = const ScanResult(
    indexed: 1,
    skipped: 0,
    removed: 0,
    permissionStatus: MediaPermissionStatus.granted,
    fullPass: false,
    changed: 0,
  );

  _FakeMediaRepository(this.library);

  @override
  bool get isScanning => false;

  @override
  Future<ScanResult> scanDevice({bool incremental = false}) async => nextScan;

  @override
  Future<List<MediaItem>> getMediaItems({
    FilterOptions filter = const FilterOptions(),
    int? limit,
    int? offset,
  }) async {
    queries.add(limit);
    return limit == null ? library : library.take(limit).toList();
  }

  @override
  Future<int> getTotalCount() async => library.length;
}

class _GrantedPermissionService extends Fake implements MediaPermissionService {
  @override
  Future<MediaPermissionStatus> ensureGranted() async =>
      MediaPermissionStatus.granted;
}

void main() {
  late _FakeMediaRepository repository;
  late ProviderContainer container;

  ProviderContainer build(int librarySize) {
    repository = _FakeMediaRepository([
      for (var i = 0; i < librarySize; i++) _photo(i),
    ]);
    final c = ProviderContainer(
      overrides: [
        mediaRepositoryProvider.overrideWithValue(repository),
        mediaPermissionServiceProvider.overrideWithValue(
          _GrantedPermissionService(),
        ),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Collects every list the timeline sends out.
  List<int> listenToTimeline() {
    final lengths = <int>[];
    container.listen<AsyncValue<List<MediaItem>>>(timelineItemsProvider, (
      _,
      next,
    ) {
      final value = next.value;
      if (next.hasValue && !next.isLoading && value != null) {
        lengths.add(value.length);
      }
    }, fireImmediately: true);
    return lengths;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  group('timelineItemsProvider progressive load', () {
    test('sends the newest page first, then the full list', () async {
      container = build(1000);
      final lengths = listenToTimeline();

      // Only the timeline asks for the list here, as on a cold app start.
      // Reading the full list from the test would start it first.
      for (var i = 0; i < 5; i++) {
        await settle();
      }

      expect(lengths.first, kTimelineFirstPageSize);
      expect(lengths.last, 1000);
      // The first page is asked for before the full list.
      expect(repository.queries, [kTimelineFirstPageSize, null]);
    });

    test('a reload after the list is loaded skips the first page', () async {
      container = build(1000);
      final lengths = listenToTimeline();
      await container.read(mediaItemsProvider(const FilterOptions()).future);
      await settle();
      lengths.clear();
      repository.queries.clear();

      container.invalidate(mediaItemsProvider);
      await container.read(mediaItemsProvider(const FilterOptions()).future);
      await settle();

      expect(repository.queries, [null]);
      expect(lengths, everyElement(1000));
    });

    test('another sort loads the full list in one step', () async {
      container = build(1000);
      container.read(timelineFilterProvider.notifier).state =
          const FilterOptions(sortBy: MediaSortField.size);
      listenToTimeline();

      await container.read(
        mediaItemsProvider(
          const FilterOptions(sortBy: MediaSortField.size),
        ).future,
      );
      await settle();

      expect(repository.queries, [null]);
    });
  });

  group('reload after a scan', () {
    test('a quick scan that found nothing does not reload', () async {
      container = build(10);
      listenToTimeline();
      await container.read(mediaItemsProvider(const FilterOptions()).future);
      await settle();
      repository.queries.clear();

      await container
          .read(mediaScanControllerProvider.notifier)
          .scan(incremental: true);
      await settle();

      expect(repository.queries, isEmpty);
    });

    test('a scan that found new media reloads once', () async {
      container = build(10);
      listenToTimeline();
      await container.read(mediaItemsProvider(const FilterOptions()).future);
      await settle();
      repository.queries.clear();
      repository.nextScan = const ScanResult(
        indexed: 3,
        skipped: 0,
        removed: 0,
        permissionStatus: MediaPermissionStatus.granted,
        fullPass: false,
        changed: 2,
      );

      await container
          .read(mediaScanControllerProvider.notifier)
          .scan(incremental: true);
      await container.read(mediaItemsProvider(const FilterOptions()).future);
      await settle();

      expect(repository.queries, [null]);
    });
  });

  group('ScanResult.libraryChanged', () {
    ScanResult result({
      int indexed = 0,
      int removed = 0,
      bool fullPass = false,
      int? changed,
    }) => ScanResult(
      indexed: indexed,
      skipped: 0,
      removed: removed,
      permissionStatus: MediaPermissionStatus.granted,
      fullPass: fullPass,
      changed: changed,
    );

    test('a quick pass that only re-read the newest row is no change', () {
      expect(result(indexed: 1, changed: 0).libraryChanged, isFalse);
    });

    test('new rows, removed rows or a full pass are a change', () {
      expect(result(indexed: 1, changed: 1).libraryChanged, isTrue);
      expect(result(removed: 1, changed: 0).libraryChanged, isTrue);
      expect(result(fullPass: true, changed: 0).libraryChanged, isTrue);
    });

    test('an unknown change count falls back to the rows read', () {
      expect(result(indexed: 2).libraryChanged, isTrue);
      expect(result().libraryChanged, isFalse);
    });
  });
}
