import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_scan_state.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

MediaItem item(String id, {int size = 100}) {
  final when = DateTime(2026, 1, 1);
  return MediaItem(
    id: id,
    path: '/storage/DCIM/$id.jpg',
    displayName: '$id.jpg',
    mediaType: MediaType.image,
    mimeType: 'image/jpeg',
    size: size,
    dateAdded: when,
    dateModified: when,
  );
}

void main() {
  group('DuplicateGroup', () {
    final group = DuplicateGroup(
      id: 'g1',
      kind: DuplicateGroupKind.exact,
      items: <MediaItem>[
        item('keep', size: 900),
        item('drop1', size: 100),
        item('drop2', size: 250),
      ],
      suggestedKeeperId: 'keep',
    );

    test('reports its size and members', () {
      expect(group.memberCount, 3);
      expect(group.suggestedKeeper.id, 'keep');
      expect(group.others.map((i) => i.id).toList(), <String>[
        'drop1',
        'drop2',
      ]);
    });

    test('reclaimable bytes leave the keeper out', () {
      expect(group.reclaimableBytes, 350);
    });

    test('falls back to the first item when the keeper id is unknown', () {
      // A group whose suggestion has gone stale must still be drawable.
      final broken = group.copyWith(suggestedKeeperId: 'missing');

      expect(broken.suggestedKeeper.id, 'keep');
      // With no keeper matched, nothing is excluded from the total.
      expect(broken.reclaimableBytes, 1250);
    });

    test('copyWith and equality behave', () {
      expect(group.copyWith(), group);
      expect(group.copyWith(id: 'g2'), isNot(group));
      expect(group.hashCode, group.copyWith().hashCode);
    });
  });

  group('DuplicateScanState', () {
    test('starts idle with nothing done', () {
      const state = DuplicateScanState();

      expect(state.stage, DuplicateScanStage.idle);
      expect(state.isRunning, isFalse);
      expect(state.progress, isNull);
      expect(state.groups, isEmpty);
    });

    test('is running only while hashing or grouping', () {
      for (final stage in <DuplicateScanStage>[
        DuplicateScanStage.hashing,
        DuplicateScanStage.grouping,
      ]) {
        expect(DuplicateScanState(stage: stage).isRunning, isTrue);
      }
      for (final stage in <DuplicateScanStage>[
        DuplicateScanStage.idle,
        DuplicateScanStage.done,
        DuplicateScanStage.cancelled,
        DuplicateScanStage.failed,
      ]) {
        expect(DuplicateScanState(stage: stage).isRunning, isFalse);
      }
    });

    test('progress is a fraction, and is clamped', () {
      expect(const DuplicateScanState(processed: 5, total: 10).progress, 0.5);
      // A total that lags behind the count must not produce a bar over 100%.
      expect(const DuplicateScanState(processed: 12, total: 10).progress, 1.0);
      expect(const DuplicateScanState(processed: 5).progress, isNull);
    });

    test('adds up the space every group could free', () {
      final state = DuplicateScanState(
        groups: <DuplicateGroup>[
          DuplicateGroup(
            id: 'a',
            kind: DuplicateGroupKind.exact,
            items: <MediaItem>[item('a1', size: 10), item('a2', size: 40)],
            suggestedKeeperId: 'a1',
          ),
          DuplicateGroup(
            id: 'b',
            kind: DuplicateGroupKind.similar,
            items: <MediaItem>[item('b1', size: 10), item('b2', size: 60)],
            suggestedKeeperId: 'b1',
          ),
        ],
      );

      expect(state.reclaimableBytes, 100);
    });

    test('copyWith and equality behave', () {
      const state = DuplicateScanState(processed: 3, total: 9);

      expect(state.copyWith(), state);
      expect(state.copyWith(processed: 4), isNot(state));
      expect(state.hashCode, state.copyWith().hashCode);
    });
  });
}
