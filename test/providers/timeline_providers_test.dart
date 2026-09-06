import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/timeline_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/timeline/timeline_grouping_service.dart';

MediaItem itemAt(String id, DateTime taken) {
  return MediaItem(
    id: id,
    path: '/storage/emulated/0/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: 256,
    dateAdded: taken,
    dateModified: taken,
    dateTaken: taken,
  );
}

/// A fixed "today" so the date-sensitive providers never depend on the clock.
final fixedNow = DateTime(2026, 8, 29, 14, 30);

/// Builds a container whose timeline items and current date are both fixed, so
/// the grouping and flashback providers can be tested without a database, a
/// device, or the wall clock.
ProviderContainer containerWith(List<MediaItem> items) {
  final container = ProviderContainer(
    overrides: [
      timelineItemsProvider.overrideWith((ref) async => items),
      timelineNowProvider.overrideWithValue(() => fixedNow),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('gridColumnCountProvider', () {
    test('starts at the default density', () {
      final container = containerWith(const <MediaItem>[]);

      expect(container.read(gridColumnCountProvider), kDefaultGridColumnCount);
    });

    test('clamps a value below the minimum', () {
      final container = containerWith(const <MediaItem>[]);

      container.read(gridColumnCountProvider.notifier).set(0);
      expect(
        container.read(gridColumnCountProvider),
        TimelineGroupingService.minColumns,
      );
    });

    test('clamps a value above the maximum', () {
      final container = containerWith(const <MediaItem>[]);

      container.read(gridColumnCountProvider.notifier).set(11);
      expect(
        container.read(gridColumnCountProvider),
        TimelineGroupingService.maxColumns,
      );
    });

    test('steps density up and down, stopping at the limits', () {
      final container = containerWith(const <MediaItem>[]);
      final notifier = container.read(gridColumnCountProvider.notifier);

      notifier.set(1);
      expect(notifier.canDecreaseDensity, isFalse);
      notifier.decreaseDensity();
      expect(container.read(gridColumnCountProvider), 1);

      notifier.increaseDensity();
      expect(container.read(gridColumnCountProvider), 2);

      notifier.set(5);
      expect(notifier.canIncreaseDensity, isFalse);
      notifier.increaseDensity();
      expect(container.read(gridColumnCountProvider), 5);
    });
  });

  group('timelineDataProvider', () {
    test('groups the loaded items for the current density', () async {
      final container = containerWith([
        itemAt('a', DateTime(2026, 8, 29, 9)),
        itemAt('b', DateTime(2026, 8, 29, 10)),
        itemAt('c', DateTime(2026, 8, 28, 10)),
      ]);

      final data = await container.read(timelineDataProvider.future);

      expect(data.groups, hasLength(2));
      expect(data.itemCount, 3);
      expect(data.columnCount, kDefaultGridColumnCount);
    });

    test('re-flattens the rows when the density changes', () async {
      final container = containerWith(
        List.generate(6, (i) => itemAt('i$i', DateTime(2026, 8, 29, 20 - i))),
      );

      final atThree = await container.read(timelineDataProvider.future);
      expect(atThree.columnCount, 3);
      // 1 header + ceil(6 / 3) = 2 tile rows.
      expect(atThree.rows, hasLength(3));

      container.read(gridColumnCountProvider.notifier).set(2);
      final atTwo = await container.read(timelineDataProvider.future);

      expect(atTwo.columnCount, 2);
      // 1 header + ceil(6 / 2) = 3 tile rows.
      expect(atTwo.rows, hasLength(4));
      // The same items are still shown, just laid out differently.
      expect(atTwo.itemCount, atThree.itemCount);
    });

    test('returns an empty timeline when nothing is indexed', () async {
      final container = containerWith(const <MediaItem>[]);

      final data = await container.read(timelineDataProvider.future);

      expect(data.isEmpty, isTrue);
    });
  });

  group('flashbackMemoriesProvider', () {
    test('is empty when nothing matches today', () async {
      final container = containerWith([itemAt('a', DateTime(2026, 8, 29, 9))]);

      expect(await container.read(flashbackMemoriesProvider.future), isEmpty);
    });

    test('picks up media from the same day in an earlier year', () async {
      final container = containerWith([
        itemAt('memory', DateTime(2025, 8, 29, 9)),
      ]);

      final memories = await container.read(flashbackMemoriesProvider.future);

      expect(memories, hasLength(1));
      expect(memories.single.yearsAgo, 1);
      expect(memories.single.items.single.id, 'memory');
    });
  });

  group('timelineFilterProvider', () {
    test('defaults to no active filters', () {
      final container = containerWith(const <MediaItem>[]);

      expect(container.read(timelineFilterProvider).hasActiveFilters, isFalse);
    });
  });

  group('TimelineData', () {
    test('an empty timeline reports itself as empty', () {
      const data = TimelineData.empty();

      expect(data.isEmpty, isTrue);
    });
  });
}
