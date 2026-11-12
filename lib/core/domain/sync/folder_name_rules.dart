import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Decides where a received file goes, from the folder name the sender gave.
///
/// The folder name comes from another device, so it is untrusted input. A
/// sender that offers `../../Android/data` must not choose where a file lands.
/// Only one plain folder level is ever kept, inside the app's own receive
/// folder. The Kotlin side checks the result again before it writes.
class FolderNameRules {
  const FolderNameRules._();

  /// Longest folder name kept. Longer ones are cut.
  static const int maxLength = 80;

  /// A single safe folder name, or null when nothing usable is left.
  ///
  /// Keeps letters in any script (Malayalam and Devanagari names stay as they
  /// are). Drops path separators, control characters, characters Android's
  /// file systems refuse, and leading dots (no hidden folders, no `..`).
  static String? safeFolderName(String? raw) {
    if (raw == null) return null;

    // Only the last part of a path counts. A sender cannot pick a parent.
    final last = raw.split(RegExp(r'[/\\]')).where((p) => p.isNotEmpty);
    if (last.isEmpty) return null;

    final cleaned = last.last
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'[:*?"<>|]'), '')
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();

    if (cleaned.isEmpty) return null;
    if (cleaned.length <= maxLength) return cleaned;
    return cleaned.substring(0, maxLength).trim();
  }

  /// The folder, under the shared Pictures folder, a received file goes to.
  ///
  /// `Drishya Sync/<folder>` when the sender gave a usable folder name, and
  /// plain `Drishya Sync` when it did not.
  static String receiveDirectoryFor(String? sourceFolder) {
    final safe = safeFolderName(sourceFolder);
    const root = AppConstants.syncReceiveDirectoryName;
    return safe == null ? root : '$root/$safe';
  }
}
