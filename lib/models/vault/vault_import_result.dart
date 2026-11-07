import 'package:flutter/foundation.dart';

/// Immutable outcome of one import or export batch.
///
/// A batch is deliberately not all-or-nothing: one unreadable photo out of
/// forty should not undo the other thirty-nine. Each file that failed is
/// counted so the screen can say how many, without naming any of them.
@immutable
class VaultBatchResult {
  /// Ids of the items that made it.
  ///
  /// Vault ids after an import, media ids after an export.
  final List<String> succeededIds;

  /// How many files could not be read, encrypted, or written.
  final int failedCount;

  /// How many originals were actually shredded.
  ///
  /// Zero unless the user chose to shred and confirmed it.
  final int shreddedCount;

  /// How many items were left in the vault on purpose.
  ///
  /// A restore skips an item whose original folder is gone when the user did
  /// not pick another folder. That is not a failure: the item is safe, and
  /// the user can restore it again later.
  final int skippedCount;

  const VaultBatchResult({
    this.succeededIds = const <String>[],
    this.failedCount = 0,
    this.shreddedCount = 0,
    this.skippedCount = 0,
  });

  /// An empty batch.
  static const VaultBatchResult empty = VaultBatchResult();

  /// How many files made it.
  int get succeededCount => succeededIds.length;

  /// Whether every file in the batch failed.
  bool get isTotalFailure => succeededIds.isEmpty && failedCount > 0;

  /// Whether some made it and some did not.
  bool get isPartial => succeededIds.isNotEmpty && failedCount > 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultBatchResult &&
          runtimeType == other.runtimeType &&
          listEquals(succeededIds, other.succeededIds) &&
          failedCount == other.failedCount &&
          shreddedCount == other.shreddedCount &&
          skippedCount == other.skippedCount;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(succeededIds),
    failedCount,
    shreddedCount,
    skippedCount,
  );
}
