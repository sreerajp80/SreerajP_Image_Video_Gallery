import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';

/// Immutable snapshot of a running batch.
///
/// Rebuilt for every item rather than mutated, so the progress dialog can be
/// driven straight off provider state without a listener of its own.
@immutable
class BatchProgress {
  /// What is being done.
  final BatchAction action;

  /// How many items have been dealt with, finished or failed.
  final int done;

  /// How many items the batch started with.
  final int total;

  /// Display name of the item being worked on, for the dialog's subtitle.
  ///
  /// Null before the first item and after the last one.
  final String? currentName;

  /// Whether the user has asked for the batch to stop.
  ///
  /// The runner checks this between items, so a cancel takes effect after the
  /// file in flight rather than half way through writing it.
  final bool isCancelled;

  const BatchProgress({
    required this.action,
    required this.done,
    required this.total,
    this.currentName,
    this.isCancelled = false,
  });

  /// A batch that has not started yet.
  factory BatchProgress.initial(BatchAction action, int total) =>
      BatchProgress(action: action, done: 0, total: total);

  /// Fraction finished, 0 to 1. Zero when there is nothing to do.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  /// Whether every item has been dealt with.
  bool get isComplete => total > 0 && done >= total;

  BatchProgress copyWith({
    int? done,
    int? total,
    String? currentName,
    bool clearCurrentName = false,
    bool? isCancelled,
  }) {
    return BatchProgress(
      action: action,
      done: done ?? this.done,
      total: total ?? this.total,
      currentName: clearCurrentName ? null : (currentName ?? this.currentName),
      isCancelled: isCancelled ?? this.isCancelled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchProgress &&
          runtimeType == other.runtimeType &&
          action == other.action &&
          done == other.done &&
          total == other.total &&
          currentName == other.currentName &&
          isCancelled == other.isCancelled;

  @override
  int get hashCode =>
      Object.hash(action, done, total, currentName, isCancelled);
}
