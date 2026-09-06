import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/storage/atomic_saver.dart';
import 'package:in_sreerajp_imgvidgal/models/search/search_history_entry.dart';
import 'package:path/path.dart' as p;

/// Remembers the searches the user ran, newest first.
///
/// This is a convenience, not data worth protecting, so it lives in one small
/// JSON file rather than the database. Nothing here ever throws at the caller:
/// a missing, unreadable, or corrupt file simply means "no history yet", and a
/// failed write is dropped. A broken recent-search list must never stop
/// somebody searching.
class SearchHistoryService {
  /// Folder the history file is kept in.
  final Directory directory;

  /// Largest number of entries kept.
  final int maxEntries;

  SearchHistoryService({
    required this.directory,
    this.maxEntries = AppConstants.searchHistoryMaxEntries,
  });

  /// Full path of the history file.
  String get filePath =>
      p.join(directory.path, AppConstants.searchHistoryFileName);

  /// Reads the stored history, newest first.
  Future<List<SearchHistoryEntry>> load() async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return const <SearchHistoryEntry>[];

      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return const <SearchHistoryEntry>[];

      final entries = <SearchHistoryEntry>[];
      for (final row in decoded) {
        final entry = SearchHistoryEntry.tryFromJson(row);
        if (entry != null) entries.add(entry);
      }
      return _sortAndCap(entries);
    } catch (_) {
      // A hand-edited or half-written file is not worth an error dialog.
      return const <SearchHistoryEntry>[];
    }
  }

  /// Records [text] as the newest search and returns the updated list.
  ///
  /// Re-running an old search moves it to the top rather than adding a second
  /// copy. Comparison ignores case and surrounding spaces.
  Future<List<SearchHistoryEntry>> record(String text, {DateTime? now}) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return load();

    final existing = await load();
    final key = trimmed.toLowerCase();
    final kept = existing
        .where((entry) => entry.text.trim().toLowerCase() != key)
        .toList();

    final updated = _sortAndCap(<SearchHistoryEntry>[
      SearchHistoryEntry(text: trimmed, lastUsed: now ?? DateTime.now()),
      ...kept,
    ]);

    await _write(updated);
    return updated;
  }

  /// Forgets one search and returns what is left.
  Future<List<SearchHistoryEntry>> remove(String text) async {
    final key = text.trim().toLowerCase();
    final kept = (await load())
        .where((entry) => entry.text.trim().toLowerCase() != key)
        .toList();
    await _write(kept);
    return kept;
  }

  /// Forgets every search.
  Future<void> clear() => _write(const <SearchHistoryEntry>[]);

  /// Newest first, then capped to [maxEntries].
  List<SearchHistoryEntry> _sortAndCap(List<SearchHistoryEntry> entries) {
    final sorted = <SearchHistoryEntry>[...entries]
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    if (sorted.length <= maxEntries) return sorted;
    return sorted.sublist(0, maxEntries);
  }

  Future<void> _write(List<SearchHistoryEntry> entries) async {
    try {
      final json = jsonEncode(entries.map((e) => e.toJson()).toList());
      await AtomicSaver.writeBytes(
        filePath,
        Uint8List.fromList(utf8.encode(json)),
      );
    } catch (_) {
      // Losing the recent list is not worth failing a search over.
    }
  }
}
