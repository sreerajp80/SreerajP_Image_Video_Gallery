import 'dart:async';

import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_progress.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_action_rules.dart';

/// What one batch action needs doing to one file.
///
/// The runner owns sequencing, progress, cancellation and error tolerance.
/// It owns none of the actual work: converting a photo, writing a tag row and
/// encrypting into the vault are Phase 6 to 10 jobs, and they stay there.
///
/// Splitting it this way is what makes the runner testable. A test supplies a
/// handler that counts calls or throws on the third file, and every rule about
/// ordering and failure can be checked without touching an image codec.
abstract class BatchItemHandler {
  /// Does the action to one item.
  ///
  /// Returns the path of any file it wrote, or null when it only changed the
  /// database. Throwing means this one item failed; the runner counts it and
  /// carries on.
  Future<String?> handle(BatchAction action, MediaItem item);

  /// Runs once before the first item.
  ///
  /// Where a whole-batch job does its work — a PDF is one document from many
  /// photos, not one document each. Returns paths it wrote.
  Future<List<String>> begin(BatchAction action, List<MediaItem> items) async =>
      const <String>[];

  /// Whether [action] is handled entirely by [begin].
  ///
  /// True for the PDF export. The runner still walks the items so progress
  /// moves, but does not call [handle] for each.
  bool isWholeBatch(BatchAction action) => false;
}

/// Runs one batch action over a selection, one file at a time.
///
/// Three rules, and they are the whole class:
///
/// 1. **Sequential.** One file at a time. Running forty conversions at once
///    would fight the thumbnail engine for memory on exactly the low-end
///    devices this app is meant to work well on.
///
/// 2. **Cancellable between items.** The flag is checked before each file,
///    never during one. A cancel that stopped a half-written encode would
///    leave the very mess hard rule 4 exists to prevent.
///
/// 3. **One failure does not sink the batch.** A file that cannot be read is
///    counted and the rest carry on, the same contract as the vault import.
///    Losing thirty-nine good photos because the ninth was corrupt would be
///    the wrong trade every time.
class BatchRunnerService {
  final BatchItemHandler _handler;
  final BatchActionRules _rules;

  BatchRunnerService({
    required BatchItemHandler handler,
    BatchActionRules rules = const BatchActionRules(),
  }) : _handler = handler,
       _rules = rules;

  /// Whether a cancel has been asked for.
  bool _cancelled = false;

  /// Whether a batch is running now.
  bool _running = false;

  bool get isRunning => _running;

  /// Asks the running batch to stop after the file in flight.
  void cancel() => _cancelled = true;

  /// Runs [action] over [items].
  ///
  /// [onProgress] fires before each file and once more at the end, so a
  /// dialog can show the name of what is happening now rather than what just
  /// finished.
  Future<BatchOutcome> run({
    required BatchAction action,
    required List<MediaItem> items,
    void Function(BatchProgress progress)? onProgress,
  }) async {
    final availability = _rules.evaluate(action, items);
    if (!availability.isAllowed) {
      // The bar asks the same class before offering the button, so reaching
      // here means the selection changed underneath. Nothing is attempted.
      return BatchOutcome(
        action: action,
        skippedIds: items.map((i) => i.id).toList(growable: false),
      );
    }

    _cancelled = false;
    _running = true;

    final applicable = _rules.applicableItems(action, items);
    final skipped = items
        .where((item) => !action.acceptsItem(item))
        .map((item) => item.id)
        .toList();

    final succeeded = <String>[];
    final failed = <String>[];
    final outputs = <String>[];
    String? firstError;

    var progress = BatchProgress.initial(action, applicable.length);
    onProgress?.call(progress);

    try {
      if (_handler.isWholeBatch(action)) {
        return await _runWholeBatch(
          action: action,
          applicable: applicable,
          skipped: skipped,
          onProgress: onProgress,
        );
      }

      for (final item in applicable) {
        if (_cancelled) {
          // Everything not yet reached is skipped, not failed. It was never
          // tried, and saying otherwise would misreport the outcome.
          skipped.addAll(
            applicable.skip(succeeded.length + failed.length).map((i) => i.id),
          );
          break;
        }

        progress = progress.copyWith(currentName: item.displayName);
        onProgress?.call(progress);

        try {
          final output = await _handler.handle(action, item);
          succeeded.add(item.id);
          if (output != null && output.isNotEmpty) outputs.add(output);
        } catch (error) {
          failed.add(item.id);
          firstError ??= _describe(error);
        }

        progress = progress.copyWith(done: succeeded.length + failed.length);
        onProgress?.call(progress);
      }
    } finally {
      _running = false;
    }

    onProgress?.call(progress.copyWith(clearCurrentName: true));

    return BatchOutcome(
      action: action,
      succeededIds: List.unmodifiable(succeeded),
      failedIds: List.unmodifiable(failed),
      skippedIds: List.unmodifiable(skipped),
      firstError: firstError,
      wasCancelled: _cancelled,
      outputPaths: List.unmodifiable(outputs),
    );
  }

  /// Runs an action that makes one thing out of many files.
  ///
  /// The PDF export is the only one. It either produces a document or it does
  /// not, so there is no per-file success to report: every applicable item
  /// succeeds together or fails together.
  Future<BatchOutcome> _runWholeBatch({
    required BatchAction action,
    required List<MediaItem> applicable,
    required List<String> skipped,
    void Function(BatchProgress progress)? onProgress,
  }) async {
    final progress = BatchProgress.initial(action, applicable.length);
    onProgress?.call(
      progress.copyWith(currentName: applicable.first.displayName),
    );

    try {
      final outputs = await _handler.begin(action, applicable);
      onProgress?.call(
        progress.copyWith(done: applicable.length, clearCurrentName: true),
      );

      return BatchOutcome(
        action: action,
        succeededIds: applicable.map((i) => i.id).toList(growable: false),
        skippedIds: List.unmodifiable(skipped),
        outputPaths: List.unmodifiable(outputs),
        wasCancelled: _cancelled,
      );
    } catch (error) {
      onProgress?.call(progress.copyWith(clearCurrentName: true));
      return BatchOutcome(
        action: action,
        failedIds: applicable.map((i) => i.id).toList(growable: false),
        skippedIds: List.unmodifiable(skipped),
        firstError: _describe(error),
        wasCancelled: _cancelled,
      );
    }
  }

  /// Turns an error into one short line.
  ///
  /// Only the message. A stack trace or a full path in a sheet tells the user
  /// nothing and can leak where their photos live.
  static String _describe(Object error) {
    final text = error.toString();
    return text.length > 160 ? '${text.substring(0, 157)}...' : text;
  }
}
