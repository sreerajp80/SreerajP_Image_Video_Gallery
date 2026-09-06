import 'package:flutter/foundation.dart';

/// One remembered search, so the user can run it again with a tap.
@immutable
class SearchHistoryEntry {
  /// The text exactly as it was typed.
  final String text;

  /// When this search was last run.
  final DateTime lastUsed;

  const SearchHistoryEntry({required this.text, required this.lastUsed});

  SearchHistoryEntry copyWith({String? text, DateTime? lastUsed}) {
    return SearchHistoryEntry(
      text: text ?? this.text,
      lastUsed: lastUsed ?? this.lastUsed,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'text': text,
    'last_used': lastUsed.millisecondsSinceEpoch,
  };

  /// Builds an entry from stored JSON, or null when the row is unusable.
  ///
  /// The history file is a convenience, never something worth failing over,
  /// so a broken row is dropped rather than thrown.
  static SearchHistoryEntry? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final text = json['text'];
    if (text is! String || text.trim().isEmpty) return null;
    final millis = json['last_used'];
    if (millis is! int) return null;
    return SearchHistoryEntry(
      text: text,
      lastUsed: DateTime.fromMillisecondsSinceEpoch(millis),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchHistoryEntry &&
          runtimeType == other.runtimeType &&
          text == other.text &&
          lastUsed == other.lastUsed;

  @override
  int get hashCode => Object.hash(text, lastUsed);
}
