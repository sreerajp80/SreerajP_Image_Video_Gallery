import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// How sure the app is that the members of a group are the same picture.
enum DuplicateGroupKind {
  /// Byte-for-byte identical files, matched on SHA-256. Not a guess.
  exact,

  /// Files that look the same, matched on the perceptual hashes. A very good
  /// guess, but still a guess.
  similar,
}

/// A set of media items the cleaner believes are copies of one another.
@immutable
class DuplicateGroup {
  /// Stable id for this group, used to address it from a route.
  final String id;

  /// Whether the members are identical or merely alike.
  final DuplicateGroupKind kind;

  /// The members, best-first as chosen by `BestPhotoService`.
  final List<MediaItem> items;

  /// Id of the member the app suggests keeping.
  final String suggestedKeeperId;

  const DuplicateGroup({
    required this.id,
    required this.kind,
    required this.items,
    required this.suggestedKeeperId,
  });

  /// How many copies are in the group.
  int get memberCount => items.length;

  /// Bytes that would be freed if everything but the keeper went away.
  int get reclaimableBytes {
    var total = 0;
    for (final item in items) {
      if (item.id != suggestedKeeperId) total += item.size;
    }
    return total;
  }

  /// The member the app suggests keeping, or the first item when the
  /// suggested id is not in the list.
  MediaItem get suggestedKeeper {
    for (final item in items) {
      if (item.id == suggestedKeeperId) return item;
    }
    return items.first;
  }

  /// Every member except the suggested keeper.
  List<MediaItem> get others =>
      items.where((item) => item.id != suggestedKeeperId).toList();

  DuplicateGroup copyWith({
    String? id,
    DuplicateGroupKind? kind,
    List<MediaItem>? items,
    String? suggestedKeeperId,
  }) {
    return DuplicateGroup(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      items: items ?? this.items,
      suggestedKeeperId: suggestedKeeperId ?? this.suggestedKeeperId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DuplicateGroup &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          listEquals(items, other.items) &&
          suggestedKeeperId == other.suggestedKeeperId;

  @override
  int get hashCode =>
      Object.hash(id, kind, Object.hashAll(items), suggestedKeeperId);
}
