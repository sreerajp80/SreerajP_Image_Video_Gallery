import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/flashback_memory.dart';

/// Which date window the Memories tab is showing.
enum MemoriesRange {
  /// Today's exact month and day, in earlier years.
  sameDay,

  /// A few days on each side of today, in earlier years. Used only when
  /// [sameDay] found nothing.
  sameWeek,
}

/// Everything the Memories tab shows: the window used and one memory per
/// earlier year, newest year first.
@immutable
class MemoriesPage {
  /// The window the memories were picked with.
  final MemoriesRange range;

  /// One entry per earlier year that has media, newest year first.
  final List<FlashbackMemory> memories;

  const MemoriesPage({required this.range, required this.memories});

  /// A page with nothing to show.
  const MemoriesPage.empty()
    : range = MemoriesRange.sameDay,
      memories = const <FlashbackMemory>[];

  /// Whether there is nothing to show.
  bool get isEmpty => memories.isEmpty;

  /// Creates a copy of this [MemoriesPage] with updated properties.
  MemoriesPage copyWith({
    MemoriesRange? range,
    List<FlashbackMemory>? memories,
  }) {
    return MemoriesPage(
      range: range ?? this.range,
      memories: memories ?? this.memories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemoriesPage &&
          runtimeType == other.runtimeType &&
          range == other.range &&
          listEquals(memories, other.memories);

  @override
  int get hashCode => Object.hash(range, Object.hashAll(memories));
}
