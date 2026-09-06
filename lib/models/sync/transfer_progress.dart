import 'package:flutter/foundation.dart';

/// Immutable snapshot of a transfer in flight.
///
/// Carries two levels because one is not enough to be useful: a single bar
/// over "3 of 40 files" freezes for a minute on a large video, and a single
/// bar over bytes hides which file is stuck. The screen shows both.
@immutable
class TransferProgress {
  /// How many files have finished, succeeded or failed.
  final int filesDone;

  /// How many files the transfer started with.
  final int filesTotal;

  /// Bytes moved across every finished file plus the one in flight.
  final int bytesDone;

  /// Bytes the whole transfer will move.
  final int bytesTotal;

  /// Name of the file being moved, for the subtitle.
  final String? currentName;

  const TransferProgress({
    this.filesDone = 0,
    this.filesTotal = 0,
    this.bytesDone = 0,
    this.bytesTotal = 0,
    this.currentName,
  });

  /// Nothing moved yet.
  static const TransferProgress zero = TransferProgress();

  /// A transfer about to start on [manifestFiles] files of [manifestBytes].
  factory TransferProgress.starting(int manifestFiles, int manifestBytes) =>
      TransferProgress(filesTotal: manifestFiles, bytesTotal: manifestBytes);

  /// Fraction of bytes moved, 0 to 1.
  ///
  /// Bytes rather than files, because a hundred thumbnails and one video are
  /// not a hundred and one equal steps.
  double get fraction =>
      bytesTotal <= 0 ? 0 : (bytesDone / bytesTotal).clamp(0.0, 1.0);

  bool get isComplete => filesTotal > 0 && filesDone >= filesTotal;

  TransferProgress copyWith({
    int? filesDone,
    int? filesTotal,
    int? bytesDone,
    int? bytesTotal,
    String? currentName,
    bool clearCurrentName = false,
  }) {
    return TransferProgress(
      filesDone: filesDone ?? this.filesDone,
      filesTotal: filesTotal ?? this.filesTotal,
      bytesDone: bytesDone ?? this.bytesDone,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      currentName: clearCurrentName ? null : (currentName ?? this.currentName),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferProgress &&
          runtimeType == other.runtimeType &&
          filesDone == other.filesDone &&
          filesTotal == other.filesTotal &&
          bytesDone == other.bytesDone &&
          bytesTotal == other.bytesTotal &&
          currentName == other.currentName;

  @override
  int get hashCode =>
      Object.hash(filesDone, filesTotal, bytesDone, bytesTotal, currentName);
}
