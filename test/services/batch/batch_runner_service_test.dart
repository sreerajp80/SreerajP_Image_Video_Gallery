import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_progress.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_runner_service.dart';

MediaItem _item(String id, {MediaType type = MediaType.image}) => MediaItem(
  id: id,
  path: '/storage/$id.jpg',
  displayName: '$id.jpg',
  mediaType: type,
  mimeType: type == MediaType.video ? 'video/mp4' : 'image/jpeg',
  size: 1000,
  dateAdded: DateTime(2026, 1, 1),
  dateModified: DateTime(2026, 1, 1),
);

List<MediaItem> _items(int count) =>
    List<MediaItem>.generate(count, (i) => _item('m$i'));

/// A handler a test can steer: it records what it was asked to do, and can be
/// told to throw for particular ids.
class _FakeHandler extends BatchItemHandler {
  final Set<String> failOn;
  final List<String> handled = <String>[];
  final List<BatchAction> beginCalls = <BatchAction>[];
  final Set<BatchAction> wholeBatchActions;

  /// Called before each item, so a test can cancel mid-run.
  final void Function(String id)? onEachItem;

  /// Paths [begin] claims to have written.
  final List<String> beginOutputs;

  /// Whether [begin] should throw.
  final bool beginThrows;

  _FakeHandler({
    this.failOn = const <String>{},
    this.wholeBatchActions = const <BatchAction>{},
    this.onEachItem,
    this.beginOutputs = const <String>[],
    this.beginThrows = false,
  });

  @override
  bool isWholeBatch(BatchAction action) => wholeBatchActions.contains(action);

  @override
  Future<List<String>> begin(BatchAction action, List<MediaItem> items) async {
    beginCalls.add(action);
    if (beginThrows) throw StateError('the document could not be built');
    return beginOutputs;
  }

  @override
  Future<String?> handle(BatchAction action, MediaItem item) async {
    onEachItem?.call(item.id);
    handled.add(item.id);
    if (failOn.contains(item.id)) {
      throw StateError('could not read ${item.displayName}');
    }
    return '/out/${item.id}.out';
  }
}

void main() {
  group('BatchRunnerService — the happy path', () {
    test('handles every item once, in the order given', () async {
      final handler = _FakeHandler();
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.addTags,
        items: _items(4),
      );

      expect(handler.handled, <String>['m0', 'm1', 'm2', 'm3']);
      expect(outcome.succeededIds, <String>['m0', 'm1', 'm2', 'm3']);
      expect(outcome.failedIds, isEmpty);
      expect(outcome.skippedIds, isEmpty);
      expect(outcome.wasCancelled, isFalse);
    });

    test('collects the paths of files it wrote', () async {
      final runner = BatchRunnerService(handler: _FakeHandler());
      final outcome = await runner.run(
        action: BatchAction.convert,
        items: _items(2),
      );

      expect(outcome.outputPaths, <String>['/out/m0.out', '/out/m1.out']);
    });

    test('is not running once it finishes', () async {
      final runner = BatchRunnerService(handler: _FakeHandler());
      expect(runner.isRunning, isFalse);

      await runner.run(action: BatchAction.favourite, items: _items(2));
      expect(runner.isRunning, isFalse);
    });
  });

  group('BatchRunnerService — progress', () {
    test('reports a start, then a name and a count for each item', () async {
      final seen = <BatchProgress>[];
      final runner = BatchRunnerService(handler: _FakeHandler());

      await runner.run(
        action: BatchAction.addTags,
        items: _items(2),
        onProgress: seen.add,
      );

      expect(seen.first.done, 0);
      expect(seen.first.total, 2);
      // The name appears before the work, so the dialog says what is
      // happening now rather than what just finished.
      expect(seen[1].currentName, 'm0.jpg');
      expect(seen[1].done, 0);
      expect(seen[2].done, 1);
      expect(seen.last.done, 2);
      expect(seen.last.currentName, isNull);
    });

    test('the count never goes backwards', () async {
      final seen = <int>[];
      final runner = BatchRunnerService(handler: _FakeHandler());

      await runner.run(
        action: BatchAction.addTags,
        items: _items(5),
        onProgress: (p) => seen.add(p.done),
      );

      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
    });

    test('the total counts only the items the action can work on', () async {
      // PDF export takes a mixed selection and passes over the videos, so
      // the bar must not promise progress it will never make.
      final seen = <BatchProgress>[];
      final runner = BatchRunnerService(handler: _FakeHandler());

      await runner.run(
        action: BatchAction.exportPdf,
        items: <MediaItem>[
          _item('a'),
          _item('v', type: MediaType.video),
          _item('b'),
        ],
        onProgress: seen.add,
      );

      expect(seen.first.total, 2);
    });
  });

  group('BatchRunnerService — one failure does not sink the batch', () {
    test('carries on past a file it could not handle', () async {
      final handler = _FakeHandler(failOn: <String>{'m2'});
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.convert,
        items: _items(5),
      );

      expect(handler.handled, hasLength(5), reason: 'every file was tried');
      expect(outcome.succeededIds, <String>['m0', 'm1', 'm3', 'm4']);
      expect(outcome.failedIds, <String>['m2']);
      expect(outcome.isPartial, isTrue);
    });

    test('keeps the first error only', () async {
      final runner = BatchRunnerService(
        handler: _FakeHandler(failOn: <String>{'m1', 'm2'}),
      );

      final outcome = await runner.run(
        action: BatchAction.convert,
        items: _items(4),
      );

      expect(outcome.firstError, contains('m1.jpg'));
      expect(outcome.firstError, isNot(contains('m2.jpg')));
      expect(outcome.failedCount, 2);
    });

    test('reports a total failure when nothing worked', () async {
      final runner = BatchRunnerService(
        handler: _FakeHandler(failOn: <String>{'m0', 'm1'}),
      );

      final outcome = await runner.run(
        action: BatchAction.convert,
        items: _items(2),
      );

      expect(outcome.isTotalFailure, isTrue);
      expect(outcome.succeededIds, isEmpty);
    });

    test('a long error message is trimmed', () async {
      final runner = BatchRunnerService(handler: _ThrowingHandler('x' * 500));

      final outcome = await runner.run(
        action: BatchAction.convert,
        items: _items(1),
      );

      expect(outcome.firstError!.length, lessThanOrEqualTo(160));
      expect(outcome.firstError, endsWith('...'));
    });
  });

  group('BatchRunnerService — cancellation', () {
    test('stops after the file in flight, never during one', () async {
      // A cancel that stopped a half-written encode would leave exactly the
      // mess hard rule 4 exists to prevent.
      late BatchRunnerService runner;
      final handler = _FakeHandler(
        onEachItem: (id) {
          if (id == 'm1') runner.cancel();
        },
      );
      runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.addTags,
        items: _items(5),
      );

      // m1 was allowed to finish; m2 onward were never started.
      expect(handler.handled, <String>['m0', 'm1']);
      expect(outcome.succeededIds, <String>['m0', 'm1']);
      expect(outcome.wasCancelled, isTrue);
    });

    test('counts what it never reached as skipped, not failed', () async {
      late BatchRunnerService runner;
      final handler = _FakeHandler(
        onEachItem: (id) {
          if (id == 'm0') runner.cancel();
        },
      );
      runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.addTags,
        items: _items(4),
      );

      expect(outcome.failedIds, isEmpty);
      expect(outcome.skippedIds, <String>['m1', 'm2', 'm3']);
    });

    test('a cancel does not leak into the next batch', () async {
      final handler = _FakeHandler();
      final runner = BatchRunnerService(handler: handler)..cancel();

      final outcome = await runner.run(
        action: BatchAction.addTags,
        items: _items(3),
      );

      expect(outcome.succeededIds, hasLength(3));
      expect(outcome.wasCancelled, isFalse);
    });
  });

  group('BatchRunnerService — items the action cannot touch', () {
    test('skips the wrong type and works on the rest', () async {
      final handler = _FakeHandler();
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.exportPdf,
        items: <MediaItem>[
          _item('photo'),
          _item('clip', type: MediaType.video),
        ],
      );

      expect(handler.handled, <String>['photo']);
      expect(outcome.skippedIds, <String>['clip']);
    });

    test('attempts nothing when the rules refuse the action', () async {
      // Watermark needs every item to be an image. A selection with a video
      // in it is refused whole rather than quietly done in part.
      final handler = _FakeHandler();
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.watermark,
        items: <MediaItem>[
          _item('photo'),
          _item('clip', type: MediaType.video),
        ],
      );

      expect(handler.handled, isEmpty);
      expect(outcome.succeededIds, isEmpty);
      expect(outcome.skippedIds, <String>['photo', 'clip']);
    });

    test('does nothing at all with an empty selection', () async {
      final handler = _FakeHandler();
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.addTags,
        items: const <MediaItem>[],
      );

      expect(handler.handled, isEmpty);
      expect(outcome.isEmpty, isTrue);
    });
  });

  group('BatchRunnerService — whole-batch actions', () {
    test('calls begin once and never handles items one by one', () async {
      // A PDF is one document from many photos, not one document each.
      final handler = _FakeHandler(
        wholeBatchActions: <BatchAction>{BatchAction.exportPdf},
        beginOutputs: <String>['/out/album.pdf'],
      );
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.exportPdf,
        items: _items(3),
      );

      expect(handler.beginCalls, <BatchAction>[BatchAction.exportPdf]);
      expect(handler.handled, isEmpty);
      expect(outcome.succeededIds, hasLength(3));
      expect(outcome.outputPaths, <String>['/out/album.pdf']);
    });

    test(
      'every item fails together when the document cannot be built',
      () async {
        final handler = _FakeHandler(
          wholeBatchActions: <BatchAction>{BatchAction.exportPdf},
          beginThrows: true,
        );
        final runner = BatchRunnerService(handler: handler);

        final outcome = await runner.run(
          action: BatchAction.exportPdf,
          items: _items(3),
        );

        expect(outcome.succeededIds, isEmpty);
        expect(outcome.failedIds, hasLength(3));
        expect(outcome.firstError, contains('document'));
      },
    );

    test('still reports the skipped items of a mixed selection', () async {
      final handler = _FakeHandler(
        wholeBatchActions: <BatchAction>{BatchAction.exportPdf},
      );
      final runner = BatchRunnerService(handler: handler);

      final outcome = await runner.run(
        action: BatchAction.exportPdf,
        items: <MediaItem>[
          _item('photo'),
          _item('clip', type: MediaType.video),
        ],
      );

      expect(outcome.succeededIds, <String>['photo']);
      expect(outcome.skippedIds, <String>['clip']);
    });
  });
}

/// Throws a message of a chosen length, to check the error is trimmed.
class _ThrowingHandler extends BatchItemHandler {
  final String message;
  _ThrowingHandler(this.message);

  @override
  Future<String?> handle(BatchAction action, MediaItem item) async {
    throw StateError(message);
  }
}
