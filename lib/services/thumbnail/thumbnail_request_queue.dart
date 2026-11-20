import 'dart:async';

/// One piece of work waiting in, or running from, a [ThumbnailRequestQueue].
class ThumbnailQueueTask<T> {
  final Completer<T?> _completer = Completer<T?>();
  final Future<T?> Function() _work;
  final ThumbnailRequestQueue _queue;

  bool _started = false;
  bool _cancelled = false;

  ThumbnailQueueTask._(this._queue, this._work);

  /// Completes with the work's result, or with null when the task was
  /// cancelled before it started.
  Future<T?> get future => _completer.future;

  /// True once the work has been handed to the device.
  bool get isStarted => _started;

  /// True once [cancel] was called.
  bool get isCancelled => _cancelled;

  /// Drops the task if it has not started yet.
  ///
  /// Work that has already started is left to finish: its result is still
  /// useful for the caches, and the device call cannot be stopped anyway.
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    if (!_started && _queue._removeWaiting(this)) {
      _completer.complete(null);
    }
  }

  void _start() {
    _started = true;
    Future<T?>.sync(_work).then(
      (value) {
        // Free the slot before the caller hears back, so the counts are
        // right by the time anyone looks.
        _queue._taskFinished();
        _completer.complete(value);
      },
      onError: (Object error, StackTrace stackTrace) {
        _queue._taskFinished();
        _completer.completeError(error, stackTrace);
      },
    );
  }
}

/// Limits how many slow thumbnail jobs run at once and serves the newest
/// request first.
///
/// When the user flings through a long grid, every tile that passes by asks
/// for a thumbnail. Served in arrival order, the tiles the user finally stops
/// on would wait behind hundreds of tiles already gone. Serving newest first
/// (last in, first out) makes the tiles on screen fill first, and tiles that
/// leave the screen cancel their waiting request so it never runs at all.
class ThumbnailRequestQueue {
  /// Most jobs running at the same time.
  final int maxConcurrent;

  /// Waiting tasks, oldest first. The newest is taken from the end.
  final List<ThumbnailQueueTask<Object?>> _waiting =
      <ThumbnailQueueTask<Object?>>[];

  int _running = 0;

  ThumbnailRequestQueue({required this.maxConcurrent})
    : assert(maxConcurrent > 0, 'maxConcurrent must be at least 1');

  /// Number of jobs running now.
  int get runningCount => _running;

  /// Number of jobs waiting to start.
  int get waitingCount => _waiting.length;

  /// Adds [work] to the queue and returns a handle to its result.
  ThumbnailQueueTask<T> enqueue<T>(Future<T?> Function() work) {
    final task = ThumbnailQueueTask<T>._(this, work);
    _waiting.add(task);
    _pump();
    return task;
  }

  bool _removeWaiting(ThumbnailQueueTask<Object?> task) =>
      _waiting.remove(task);

  void _pump() {
    while (_running < maxConcurrent && _waiting.isNotEmpty) {
      final task = _waiting.removeLast();
      _running++;
      task._start();
    }
  }

  void _taskFinished() {
    _running--;
    _pump();
  }
}
