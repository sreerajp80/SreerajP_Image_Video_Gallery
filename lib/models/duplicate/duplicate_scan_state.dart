import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';

/// What the duplicate scan is doing right now.
enum DuplicateScanStage {
  /// Nothing has been asked for yet.
  idle,

  /// Reading files and working out their fingerprints.
  hashing,

  /// Fingerprints are in; putting the copies into groups.
  grouping,

  /// Finished on its own.
  done,

  /// Stopped early because the user asked it to.
  cancelled,

  /// Stopped because something went wrong.
  failed,
}

/// A snapshot of a duplicate scan, safe to draw straight onto a screen.
@immutable
class DuplicateScanState {
  /// The stage the scan is in.
  final DuplicateScanStage stage;

  /// How many items have been looked at so far.
  final int processed;

  /// How many items the scan has to look at in total.
  final int total;

  /// Items whose file could not be read or decoded, and were skipped.
  final int failures;

  /// The groups found so far.
  final List<DuplicateGroup> groups;

  /// A message to show when [stage] is `failed`.
  final String? errorMessage;

  const DuplicateScanState({
    this.stage = DuplicateScanStage.idle,
    this.processed = 0,
    this.total = 0,
    this.failures = 0,
    this.groups = const <DuplicateGroup>[],
    this.errorMessage,
  });

  /// True while the scan is still working.
  bool get isRunning =>
      stage == DuplicateScanStage.hashing ||
      stage == DuplicateScanStage.grouping;

  /// Progress from 0 to 1, or null when the total is not known yet.
  double? get progress {
    if (total <= 0) return null;
    return (processed / total).clamp(0.0, 1.0);
  }

  /// Total bytes that could be freed across every group.
  int get reclaimableBytes {
    var total = 0;
    for (final group in groups) {
      total += group.reclaimableBytes;
    }
    return total;
  }

  DuplicateScanState copyWith({
    DuplicateScanStage? stage,
    int? processed,
    int? total,
    int? failures,
    List<DuplicateGroup>? groups,
    String? errorMessage,
  }) {
    return DuplicateScanState(
      stage: stage ?? this.stage,
      processed: processed ?? this.processed,
      total: total ?? this.total,
      failures: failures ?? this.failures,
      groups: groups ?? this.groups,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateScanState &&
          runtimeType == other.runtimeType &&
          stage == other.stage &&
          processed == other.processed &&
          total == other.total &&
          failures == other.failures &&
          listEquals(groups, other.groups) &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
    stage,
    processed,
    total,
    failures,
    Object.hashAll(groups),
    errorMessage,
  );
}
