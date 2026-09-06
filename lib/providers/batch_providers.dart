import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_progress.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/convert_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_action_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_runner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/gallery_batch_handler.dart';

/// Decides which actions a selection allows.
final batchActionRulesProvider = Provider<BatchActionRules>((ref) {
  return const BatchActionRules();
});

/// What every action the bar could offer would do to the current selection.
///
/// Watched by the action bar so a button is greyed out with a reason rather
/// than offered and then refused.
final batchAvailabilityProvider =
    Provider<AsyncValue<List<BatchActionAvailability>>>((ref) {
      final rules = ref.watch(batchActionRulesProvider);
      return ref
          .watch(selectedMediaProvider)
          .whenData((items) => rules.evaluateAll(items));
    });

/// Progress of the batch that is running, or null when none is.
final batchProgressProvider = StateProvider<BatchProgress?>((ref) => null);

/// Builds the handler for one batch, with the options the user chose.
///
/// A family rather than a singleton because the options are part of the job:
/// "convert to PNG" and "convert to JPEG" are different handlers, and reusing
/// one across batches would mean the second run quietly used the first run's
/// settings.
final galleryBatchHandlerProvider =
    Provider.family<GalleryBatchHandler, BatchOptions>((ref, options) {
      return GalleryBatchHandler(
        mediaRepository: ref.watch(mediaRepositoryProvider),
        tagRepository: ref.watch(tagRepositoryProvider),
        albumRepository: ref.watch(albumRepositoryProvider),
        vaultImport: ref.watch(vaultImportServiceProvider),
        conversion: ref.watch(formatConversionServiceProvider),
        pdfExport: ref.watch(pdfExportServiceProvider),
        options: options,
      );
    });

/// Runs a batch and reports what happened.
///
/// Holds the runner while a batch is in flight so [cancel] has something to
/// call. The runner itself is thrown away afterwards: it carries per-batch
/// state and reusing one would let a cancel leak into the next run.
class BatchController extends StateNotifier<AsyncValue<BatchOutcome?>> {
  final Ref _ref;
  BatchRunnerService? _runner;

  BatchController(this._ref) : super(const AsyncValue.data(null));

  /// Whether a batch is running now.
  bool get isRunning => _runner?.isRunning ?? false;

  /// Runs [action] over [items].
  Future<BatchOutcome?> run({
    required BatchAction action,
    required List<MediaItem> items,
    BatchOptions options = const BatchOptions(),
  }) async {
    if (isRunning) return null;

    final runner = BatchRunnerService(
      handler: _ref.read(galleryBatchHandlerProvider(options)),
      rules: _ref.read(batchActionRulesProvider),
    );
    _runner = runner;
    state = const AsyncValue.loading();

    try {
      final outcome = await runner.run(
        action: action,
        items: items,
        onProgress: (progress) =>
            _ref.read(batchProgressProvider.notifier).state = progress,
      );

      _refreshAffectedViews(action);
      state = AsyncValue.data(outcome);
      return outcome;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    } finally {
      _runner = null;
      _ref.read(batchProgressProvider.notifier).state = null;
    }
  }

  /// Asks the running batch to stop after the file in flight.
  void cancel() => _runner?.cancel();

  /// Turns the revision dials the changed views watch.
  ///
  /// Riverpod cannot see a database write, so anything showing tags, albums
  /// or the vault has to be told. Only the dials an action could actually
  /// have moved are turned, so a batch of favourites does not make every
  /// album on screen rebuild.
  void _refreshAffectedViews(BatchAction action) {
    switch (action) {
      case BatchAction.addTags:
      case BatchAction.removeTags:
        _bump(tagRevisionProvider);

      case BatchAction.addToAlbum:
        _bump(albumRevisionProvider);

      case BatchAction.moveToVault:
        _bump(vaultRevisionProvider);
        _ref.invalidate(mediaItemsProvider);

      case BatchAction.favourite:
      case BatchAction.unfavourite:
      case BatchAction.moveToTrash:
        // The media list has no revision dial of its own; the viewer
        // invalidates it directly after a favourite, and this follows suit
        // rather than adding a second mechanism beside it.
        _ref.invalidate(mediaItemsProvider);

      case BatchAction.convert:
      case BatchAction.watermark:
      case BatchAction.exportPdf:
      case BatchAction.transfer:
        // These write new files rather than changing rows. The next scan
        // picks them up; nothing on screen is stale until then.
        break;
    }
  }

  void _bump(StateProvider<int> provider) {
    _ref.read(provider.notifier).state++;
  }
}

/// The one way a batch is started or cancelled.
final batchControllerProvider =
    StateNotifierProvider<BatchController, AsyncValue<BatchOutcome?>>((ref) {
      return BatchController(ref);
    });
