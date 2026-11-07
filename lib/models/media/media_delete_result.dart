import 'package:flutter/foundation.dart';

/// What happened to one file in a permanent delete.
enum MediaDeleteOutcome {
  /// Written over, then deleted. Undelete tools cannot get it back.
  overwritten,

  /// Deleted, but not written over first.
  deleted,

  /// Still on the device: cancelled, refused, or an error.
  failed;

  /// Reads the native side's word for an outcome. Anything unknown is a
  /// failure, because claiming a file is gone when it may not be is worse.
  static MediaDeleteOutcome fromPlatform(Object? value) {
    return switch (value) {
      'overwritten' => MediaDeleteOutcome.overwritten,
      'deleted' => MediaDeleteOutcome.deleted,
      _ => MediaDeleteOutcome.failed,
    };
  }

  /// Whether the file is gone from the device.
  bool get isGone => this != MediaDeleteOutcome.failed;
}

/// The result of a permanent delete, counted for the user.
@immutable
class MediaDeleteResult {
  /// Files that are gone, written over first or not.
  final int deleted;

  /// Of [deleted], the ones written over first.
  final int overwritten;

  /// Files still on the device.
  final int failed;

  /// Whether this was a secure delete (overwrite asked for).
  final bool secure;

  const MediaDeleteResult({
    required this.deleted,
    required this.overwritten,
    required this.failed,
    required this.secure,
  });

  static const MediaDeleteResult empty = MediaDeleteResult(
    deleted: 0,
    overwritten: 0,
    failed: 0,
    secure: false,
  );

  /// Builds a result from one outcome per file.
  factory MediaDeleteResult.fromOutcomes(
    Iterable<MediaDeleteOutcome> outcomes, {
    required bool secure,
  }) {
    var deleted = 0;
    var overwritten = 0;
    var failed = 0;
    for (final outcome in outcomes) {
      switch (outcome) {
        case MediaDeleteOutcome.overwritten:
          deleted++;
          overwritten++;
        case MediaDeleteOutcome.deleted:
          deleted++;
        case MediaDeleteOutcome.failed:
          failed++;
      }
    }
    return MediaDeleteResult(
      deleted: deleted,
      overwritten: overwritten,
      failed: failed,
      secure: secure,
    );
  }

  /// True when anything was deleted.
  bool get anyDeleted => deleted > 0;

  /// Files a secure delete removed without writing over them first.
  int get notOverwritten => secure ? deleted - overwritten : 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaDeleteResult &&
          other.deleted == deleted &&
          other.overwritten == overwritten &&
          other.failed == failed &&
          other.secure == secure;

  @override
  int get hashCode => Object.hash(deleted, overwritten, failed, secure);

  @override
  String toString() =>
      'MediaDeleteResult(deleted: $deleted, overwritten: $overwritten, '
      'failed: $failed, secure: $secure)';
}
