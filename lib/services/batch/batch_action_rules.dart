import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Why an action cannot run on the current selection.
///
/// A reason, not a message. The screen turns it into localised text, so this
/// layer stays free of `AppLocalizations` and can be tested on its own.
enum BatchBlockReason {
  /// Nothing is selected.
  emptySelection,

  /// More items are selected than one batch may hold.
  selectionTooLarge,

  /// Not one selected item is a type this action can work on.
  noSupportedItems,

  /// Some selected items are the wrong type, and this action needs them all.
  mixedTypes,
}

/// The answer for one action against one selection.
class BatchActionAvailability {
  final BatchAction action;

  /// Whether the action can run at all.
  final bool isAllowed;

  /// Why not, when it cannot.
  final BatchBlockReason? blockReason;

  /// How many selected items the action would actually touch.
  final int applicableCount;

  /// How many it would pass over.
  final int skippedCount;

  const BatchActionAvailability({
    required this.action,
    required this.isAllowed,
    this.blockReason,
    this.applicableCount = 0,
    this.skippedCount = 0,
  });

  /// Whether the action will run but leave some of the selection alone.
  ///
  /// The bar warns about this before starting, because "make a PDF of these
  /// forty things" silently becoming thirty-seven is the kind of surprise
  /// that costs trust.
  bool get willSkipSome => isAllowed && skippedCount > 0;
}

/// Decides which batch actions a selection allows.
///
/// Pure, and the single source of truth for the question. Both the action bar
/// (deciding what to grey out) and the runner (deciding what to refuse) ask
/// this class, so the two cannot drift apart and offer something that then
/// fails.
class BatchActionRules {
  const BatchActionRules();

  /// Works out whether [action] can run over [items].
  BatchActionAvailability evaluate(BatchAction action, List<MediaItem> items) {
    if (items.isEmpty) {
      return BatchActionAvailability(
        action: action,
        isAllowed: false,
        blockReason: BatchBlockReason.emptySelection,
      );
    }

    if (items.length > AppConstants.batchMaxSelectionSize) {
      return BatchActionAvailability(
        action: action,
        isAllowed: false,
        blockReason: BatchBlockReason.selectionTooLarge,
        applicableCount: items.length,
      );
    }

    final applicable = items.where(action.acceptsItem).length;
    final skipped = items.length - applicable;

    if (applicable == 0) {
      return BatchActionAvailability(
        action: action,
        isAllowed: false,
        blockReason: BatchBlockReason.noSupportedItems,
        skippedCount: skipped,
      );
    }

    if (skipped > 0 && action.needsAllAccepted) {
      return BatchActionAvailability(
        action: action,
        isAllowed: false,
        blockReason: BatchBlockReason.mixedTypes,
        applicableCount: applicable,
        skippedCount: skipped,
      );
    }

    return BatchActionAvailability(
      action: action,
      isAllowed: true,
      applicableCount: applicable,
      skippedCount: skipped,
    );
  }

  /// Every action, with its verdict, in enum order.
  ///
  /// The bar shows them all and greys out what will not run, rather than
  /// hiding them: a button that vanishes teaches nobody why.
  List<BatchActionAvailability> evaluateAll(List<MediaItem> items) =>
      BatchAction.values
          .map((action) => evaluate(action, items))
          .toList(growable: false);

  /// The items [action] would actually work on, in the order given.
  List<MediaItem> applicableItems(BatchAction action, List<MediaItem> items) =>
      items.where(action.acceptsItem).toList(growable: false);

  /// Whether the action should ask for a second confirmation.
  ///
  /// True for anything that writes a file, moves an original, or takes media
  /// out of the gallery. Hard rule 4 says nothing destructive happens without
  /// the user saying so plainly, and this is where that is decided once.
  bool needsConfirmation(BatchAction action) =>
      action.touchesFiles || action == BatchAction.moveToTrash;
}
