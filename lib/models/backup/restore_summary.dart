import 'package:flutter/foundation.dart';

/// What a finished restore actually wrote.
///
/// Reported separately from the plan because the two can differ: a tag whose
/// name was taken between the preview and the confirm is reused rather than
/// created, and the summary says what happened, not what was expected.
@immutable
class RestoreSummary {
  final int tagsCreated;
  final int albumsCreated;
  final int tagLinksAdded;
  final int albumLinksAdded;
  final int mediaUpdated;

  /// Archive records that found no file on this device.
  final int unmatchedRecords;

  const RestoreSummary({
    this.tagsCreated = 0,
    this.albumsCreated = 0,
    this.tagLinksAdded = 0,
    this.albumLinksAdded = 0,
    this.mediaUpdated = 0,
    this.unmatchedRecords = 0,
  });

  /// An empty restore.
  static const RestoreSummary empty = RestoreSummary();

  /// Whether anything at all was written.
  bool get changedNothing =>
      tagsCreated == 0 &&
      albumsCreated == 0 &&
      tagLinksAdded == 0 &&
      albumLinksAdded == 0 &&
      mediaUpdated == 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RestoreSummary &&
          runtimeType == other.runtimeType &&
          tagsCreated == other.tagsCreated &&
          albumsCreated == other.albumsCreated &&
          tagLinksAdded == other.tagLinksAdded &&
          albumLinksAdded == other.albumLinksAdded &&
          mediaUpdated == other.mediaUpdated &&
          unmatchedRecords == other.unmatchedRecords;

  @override
  int get hashCode => Object.hash(
    tagsCreated,
    albumsCreated,
    tagLinksAdded,
    albumLinksAdded,
    mediaUpdated,
    unmatchedRecords,
  );
}
