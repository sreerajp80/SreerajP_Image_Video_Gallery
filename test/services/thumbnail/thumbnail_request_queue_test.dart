import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_request_queue.dart';

void main() {
  group('ThumbnailRequestQueue', () {
    test('runs no more than maxConcurrent jobs at once', () async {
      final queue = ThumbnailRequestQueue(maxConcurrent: 2);
      final gates = List.generate(5, (_) => Completer<int>());

      final tasks = [
        for (var i = 0; i < 5; i++) queue.enqueue<int>(() => gates[i].future),
      ];

      expect(queue.runningCount, 2);
      expect(queue.waitingCount, 3);

      for (var i = 0; i < 5; i++) {
        if (tasks[i].isStarted) gates[i].complete(i);
      }
      await Future<void>.delayed(Duration.zero);
      expect(queue.runningCount, lessThanOrEqualTo(2));

      for (var i = 0; i < 5; i++) {
        if (!gates[i].isCompleted) gates[i].complete(i);
      }
      final results = await Future.wait(tasks.map((t) => t.future));
      expect(results, [0, 1, 2, 3, 4]);
      expect(queue.runningCount, 0);
      expect(queue.waitingCount, 0);
    });

    test('serves the newest waiting request first', () async {
      final queue = ThumbnailRequestQueue(maxConcurrent: 1);
      final order = <String>[];
      final blocker = Completer<void>();

      final first = queue.enqueue<void>(() async {
        order.add('first');
        await blocker.future;
      });
      final older = queue.enqueue<void>(() async => order.add('older'));
      final newer = queue.enqueue<void>(() async => order.add('newer'));

      blocker.complete();
      await Future.wait([first.future, older.future, newer.future]);

      expect(order, ['first', 'newer', 'older']);
    });

    test('a cancelled waiting request never runs and gives null', () async {
      final queue = ThumbnailRequestQueue(maxConcurrent: 1);
      final blocker = Completer<int>();
      var ranCancelled = false;

      final running = queue.enqueue<int>(() => blocker.future);
      final cancelled = queue.enqueue<int>(() async {
        ranCancelled = true;
        return 7;
      });

      cancelled.cancel();
      expect(queue.waitingCount, 0);
      expect(await cancelled.future, isNull);

      blocker.complete(1);
      expect(await running.future, 1);
      await Future<void>.delayed(Duration.zero);
      expect(ranCancelled, isFalse);
    });

    test('a request cancelled after it started still finishes', () async {
      final queue = ThumbnailRequestQueue(maxConcurrent: 1);
      final gate = Completer<int>();

      final task = queue.enqueue<int>(() => gate.future);
      expect(task.isStarted, isTrue);

      task.cancel();
      gate.complete(5);

      expect(await task.future, 5);
      expect(task.isCancelled, isTrue);
    });

    test('a failing job frees its slot for the next one', () async {
      final queue = ThumbnailRequestQueue(maxConcurrent: 1);

      final failing = queue.enqueue<int>(() async => throw StateError('bad'));
      final next = queue.enqueue<int>(() async => 2);

      await expectLater(failing.future, throwsStateError);
      expect(await next.future, 2);
      expect(queue.runningCount, 0);
    });
  });
}
