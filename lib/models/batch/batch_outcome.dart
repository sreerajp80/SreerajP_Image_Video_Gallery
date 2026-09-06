import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';

/// Immutable result of one finished batch.
///
/// A batch is not all-or-nothing, and the same reasoning applies as in the
/// vault import: one unreadable photo out of forty should not undo the other
/// thirty-nine. Failures are counted, not thrown, and the sheet afterwards
/// says how many rather than naming files the user cannot act on anyway.
@immutable
class BatchOutcome {
  /// What was done.
  final BatchAction action;

  /// Media ids the action finished for.
  final List<String> succeededIds;

  /// Media ids the action tried and could not finish.
  final List<String> failedIds;

  /// Media ids the action never tried, because the type was wrong or the
  /// batch was cancelled before reaching them.
  final List<String> skippedIds;

  /// Message from the first failure, for the sheet's detail line.
  ///
  /// Only the first: a hundred identical "file not found" lines tell the user
  /// nothing the count did not already say.
  final String? firstError;

  /// Whether the user cancelled before the batch ran out of items.
  final bool wasCancelled;

  /// Paths of any new files the action wrote.
  ///
  /// Empty for actions that only touch the database. The screen uses it to
  /// offer "open" after a conversion or a PDF export.
  final List<String> outputPaths;

  const BatchOutcome({
    required this.action,
    this.succeededIds = const <String>[],
    this.failedIds = const <String>[],
    this.skippedIds = const <String>[],
    this.firstError,
    this.wasCancelled = false,
    this.outputPaths = const <String>[],
  });

  int get succeededCount => succeededIds.length;
  int get failedCount => failedIds.length;
  int get skippedCount => skippedIds.length;

  /// Whether anything at all was dealt with.
  bool get isEmpty =>
      succeededIds.isEmpty && failedIds.isEmpty && skippedIds.isEmpty;

  /// Whether every item the batch tried failed.
  bool get isTotalFailure => succeededIds.isEmpty && failedIds.isNotEmpty;

  /// Whether some worked and some did not.
  bool get isPartial =>
      succeededIds.isNotEmpty &&
      (failedIds.isNotEmpty || skippedIds.isNotEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BatchOutcome &&
          runtimeType == other.runtimeType &&
          action == other.action &&
          listEquals(succeededIds, other.succeededIds) &&
          listEquals(failedIds, other.failedIds) &&
          listEquals(skippedIds, other.skippedIds) &&
          firstError == other.firstError &&
          wasCancelled == other.wasCancelled &&
          listEquals(outputPaths, other.outputPaths);

  @override
  int get hashCode => Object.hash(
    action,
    Object.hashAll(succeededIds),
    Object.hashAll(failedIds),
    Object.hashAll(skippedIds),
    firstError,
    wasCancelled,
    Object.hashAll(outputPaths),
  );
}
