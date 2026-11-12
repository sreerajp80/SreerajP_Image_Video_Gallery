import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// What kind of group a [SyncSource] is.
enum SyncSourceKind {
  /// The photos the user selected before opening Transfer.
  selection,

  /// A device folder.
  folder,

  /// One of the app's own albums.
  album,
}

/// One group of files the sender can tick for a Wi-Fi send.
@immutable
class SyncSource {
  /// Unique across all sources: kind plus folder path or album id.
  final String key;

  final SyncSourceKind kind;

  /// Shown on screen. Empty for [SyncSourceKind.selection]; the screen
  /// names that one itself.
  final String name;

  /// The files in it, oldest first, so "send the rest" keeps an order.
  final List<MediaItem> items;

  /// How many of [items] were already sent to the paired phone.
  final int sentCount;

  const SyncSource({
    required this.key,
    required this.kind,
    required this.name,
    required this.items,
    this.sentCount = 0,
  });

  int get itemCount => items.length;

  /// Total size of [items], in bytes, as the index knows it.
  int get totalBytes => items.fold<int>(0, (sum, item) => sum + item.size);

  bool get allSent => itemCount > 0 && sentCount >= itemCount;
}
