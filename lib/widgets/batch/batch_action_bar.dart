import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/batch_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/trash_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/delete_choice_sheet.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/batch/batch_action_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_options.dart';
import 'package:in_sreerajp_imgvidgal/widgets/albums/album_edit_dialog.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_progress_dialog.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_result_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/batch/batch_tag_picker_sheet.dart';

/// The bar of actions shown while items are ticked.
///
/// Every action is drawn, and one that cannot run is greyed out with a reason
/// rather than hidden. A button that vanishes teaches nobody why; a greyed
/// one that says "videos cannot be included" teaches them immediately.
///
/// Anything that writes files, moves an original, or trashes something asks
/// once more before it starts, and the question names how many files it is
/// about to touch.
class BatchActionBar extends ConsumerWidget {
  const BatchActionBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availability = ref.watch(batchAvailabilityProvider);
    final theme = Theme.of(context);

    final entries = availability.value;
    if (entries == null || entries.isEmpty) {
      return const SizedBox.shrink();
    }

    // A fixed row, not a scrolling one: whatever scrolls off the edge is as
    // good as hidden, and Trash and Transfer are what people came here for.
    final quick = BatchActionRules.pick(entries, BatchActionRules.quickActions);

    return Material(
      elevation: 3,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 88,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                for (final entry in quick)
                  Expanded(
                    child: _ActionButton(
                      availability: entry,
                      onPressed: () => _start(context, ref, entry),
                    ),
                  ),
                Expanded(
                  child: _MoreButton(
                    onPressed: () => _openMore(context, ref, entries),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows the less common actions in a sheet, grouped.
  ///
  /// The sheet closes before the action starts, so any picker or confirm
  /// dialog the action opens sits on the screen, not on top of the sheet.
  Future<void> _openMore(
    BuildContext context,
    WidgetRef ref,
    List<BatchActionAvailability> entries,
  ) async {
    final groups = [
      for (final group in BatchActionRules.moreActionGroups)
        BatchActionRules.pick(entries, group),
    ].where((group) => group.isNotEmpty).toList(growable: false);

    final chosen = await showModalBottomSheet<BatchActionAvailability>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final l10n = AppLocalizations.of(sheetContext)!;
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < groups.length; i++) ...[
                  if (i > 0) const Divider(height: 16),
                  for (final entry in groups[i])
                    ListTile(
                      leading: Icon(
                        _ActionButton._icon(entry.action),
                        color: entry.isAllowed
                            ? null
                            : theme.colorScheme.onSurface.withValues(
                                alpha: 0.38,
                              ),
                      ),
                      title: Text(
                        _ActionButton._label(l10n, entry.action),
                        style: entry.isAllowed
                            ? null
                            : TextStyle(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.38,
                                ),
                              ),
                      ),
                      // Says why it is greyed out, right where it is greyed.
                      subtitle: entry.isAllowed
                          ? null
                          : Text(_blockedReason(l10n, entry)),
                      onTap: () => Navigator.of(sheetContext).pop(entry),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (chosen == null || !context.mounted) return;
    await _start(context, ref, chosen);
  }

  /// Gathers whatever the action needs, confirms, then runs it.
  Future<void> _start(
    BuildContext context,
    WidgetRef ref,
    BatchActionAvailability availability,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final action = availability.action;

    if (!availability.isAllowed) {
      _tell(context, _blockedReason(l10n, availability));
      return;
    }

    final items = ref.read(selectedMediaProvider).value;
    if (items == null || items.isEmpty) return;

    // Transfer is not a batch at all: it hands the selection to the screen
    // that owns the socket. Doing it here would mean two places could open a
    // listener, which is exactly what the "one screen owns it" rule forbids.
    if (action == BatchAction.transfer) {
      ref.read(transferOutboxProvider.notifier).state = items;
      ref.read(selectionProvider.notifier).clear();
      if (context.mounted) context.push(kRouteSync);
      return;
    }

    // Delete asks first how: to the trash, or for good. Picking "Move to
    // trash" in the sheet is the confirmation, so the usual second question
    // is skipped for it.
    var confirmedBySheet = false;
    if (action == BatchAction.moveToTrash) {
      final choice = await showDeleteChoiceSheet(
        context,
        count: availability.applicableCount,
        secureDelete: ref.read(appSettingsProvider).secureDelete,
      );
      if (choice == null || !context.mounted) return;
      if (choice == DeleteChoice.permanent) {
        await _deletePermanently(context, ref, items);
        return;
      }
      confirmedBySheet = true;
    }

    final options = await _gatherOptions(context, ref, action);
    if (options == null) return;
    if (!context.mounted) return;

    if (!confirmedBySheet &&
        ref.read(batchActionRulesProvider).needsConfirmation(action)) {
      final confirmed = await _confirm(
        context,
        l10n,
        action,
        availability.applicableCount,
      );
      if (confirmed != true || !context.mounted) return;
    }

    // The dialog is not awaited: it closes itself when the batch finishes.
    unawaited(BatchProgressDialog.show(context));

    final outcome = await ref
        .read(batchControllerProvider.notifier)
        .run(action: action, items: items, options: options);

    if (!context.mounted) return;
    Navigator.of(context).pop(); // the progress dialog

    if (outcome == null) return;

    // Anything the batch dealt with is unticked, so the bar does not sit
    // there offering to do it again to the same photos.
    ref.read(selectionProvider.notifier).clear();
    if (!context.mounted) return;

    // A trash that went through cleanly gets a short Undo bar, like the
    // viewer's, instead of the "Finished" sheet. Anything that failed or was
    // skipped still gets the sheet, so a problem is never hidden.
    final cleanTrash =
        action == BatchAction.moveToTrash &&
        outcome.succeededIds.isNotEmpty &&
        outcome.failedIds.isEmpty &&
        outcome.skippedIds.isEmpty &&
        !outcome.wasCancelled;
    if (cleanTrash) {
      _showTrashUndo(context, l10n, outcome.succeededIds);
      return;
    }

    await BatchResultSheet.show(context, outcome);
  }

  /// "N moved to trash · Undo". Undo puts back exactly [ids].
  ///
  /// The bar unmounts once the selection is cleared, so the Undo callback
  /// uses the provider container, not this widget's `ref`.
  void _showTrashUndo(
    BuildContext context,
    AppLocalizations l10n,
    List<String> ids,
  ) {
    final container = ProviderScope.containerOf(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.bodyBatchTrashSuccess(ids.length)),
        // Hides after the usual few seconds instead of waiting for a tap,
        // so it cannot end up over another screen's buttons.
        persist: false,
        action: SnackBarAction(
          label: l10n.actionViewerTrashUndo,
          onPressed: () async {
            await container
                .read(trashControllerProvider.notifier)
                .restoreItems(ids);
            container.invalidate(mediaItemsProvider);
          },
        ),
      ),
    );
  }

  /// Asks for whatever the action needs before it can start.
  ///
  /// Returns null if the user backed out. Everything is gathered up front so
  /// the runner never stops half way to ask a question.
  Future<BatchOptions?> _gatherOptions(
    BuildContext context,
    WidgetRef ref,
    BatchAction action,
  ) async {
    switch (action) {
      case BatchAction.addTags:
      case BatchAction.removeTags:
        final tagIds = await _pickTags(context, ref, action);
        if (tagIds == null || tagIds.isEmpty) return null;
        return BatchOptions(tagIds: tagIds);

      case BatchAction.addToAlbum:
        final albumId = await _pickAlbum(context, ref);
        if (albumId == null) return null;
        return BatchOptions(albumId: albumId);

      default:
        // The rest run on their defaults. Conversion and watermarking use the
        // settings the single-file screens default to, which is what somebody
        // reaching for a bulk action almost always wants.
        return const BatchOptions();
    }
  }

  Future<Set<String>?> _pickTags(
    BuildContext context,
    WidgetRef ref,
    BatchAction action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (action == BatchAction.removeTags) {
      final tags = await ref.read(allTagsProvider.future);
      if (!context.mounted) return null;
      if (tags.isEmpty) {
        _tell(context, l10n.labelFilterNoTags);
        return null;
      }
    }

    if (!context.mounted) return null;
    return BatchTagPickerSheet.show(context, action: action);
  }

  Future<String?> _pickAlbum(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final albums = await ref.read(virtualAlbumsProvider.future);
    if (!context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.labelBatchPickAlbum,
                      style: Theme.of(sheetContext).textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final createdId = await _createAlbum(sheetContext, ref);
                      if (createdId != null && sheetContext.mounted) {
                        Navigator.of(sheetContext).pop(createdId);
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: Text(l10n.actionAlbumPickerCreate),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.emptyAlbumPicker,
                      style: Theme.of(sheetContext).textTheme.bodyMedium,
                    ),
                  ),
                )
              else
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final album in albums)
                        ListTile(
                          leading: const Icon(Icons.photo_album_outlined),
                          title: Text(album.name),
                          subtitle: Text(
                            l10n.descAlbumItemCount(album.itemCount),
                          ),
                          onTap: () => Navigator.of(sheetContext).pop(album.id),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<String?> _createAlbum(BuildContext context, WidgetRef ref) async {
    final existing =
        ref.read(virtualAlbumsProvider).value ?? const <AlbumSummary>[];
    final name = await showDialog<String>(
      context: context,
      builder: (_) =>
          AlbumEditDialog(existingNames: existing.map((a) => a.name).toList()),
    );
    if (name == null || !context.mounted) return null;

    final album = await ref
        .read(albumEditControllerProvider.notifier)
        .create(name);
    return album?.id;
  }

  /// The second look before anything is written.
  Future<bool?> _confirm(
    BuildContext context,
    AppLocalizations l10n,
    BatchAction action,
    int count,
  ) {
    final String body;
    switch (action) {
      case BatchAction.moveToVault:
        body = l10n.bodyBatchConfirmVault(count);
      case BatchAction.moveToTrash:
        body = l10n.bodyBatchConfirmTrash(count);
      default:
        body = l10n.bodyBatchConfirmNewFiles(count);
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.titleBatchConfirm),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.actionBatchConfirmContinue),
          ),
        ],
      ),
    );
  }

  static String _blockedReason(
    AppLocalizations l10n,
    BatchActionAvailability availability,
  ) {
    switch (availability.blockReason) {
      case BatchBlockReason.emptySelection:
        return l10n.emptyBatchBlocked;
      case BatchBlockReason.selectionTooLarge:
        return l10n.bodyBatchBlockedTooLarge;
      case BatchBlockReason.noSupportedItems:
        return l10n.bodyBatchBlockedUnsupported;
      case BatchBlockReason.mixedTypes:
        return l10n.bodyBatchBlockedMixed;
      case null:
        return l10n.bodyBatchBlockedUnsupported;
    }
  }

  /// Deletes the selection from the device for good, in one go.
  ///
  /// Not run through the batch runner: that works one file at a time, and
  /// Android should be asked once for the whole selection, not per photo.
  Future<void> _deletePermanently(
    BuildContext context,
    WidgetRef ref,
    List<MediaItem> items,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          Icons.delete_forever,
          color: Theme.of(dialogContext).colorScheme.error,
        ),
        title: Text(l10n.titleTrashDeletePermanentlyConfirm),
        content: Text(l10n.bodyDeletePermanentlyConfirmCount(items.length)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.actionSettingsCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.titleTrashDeletePermanentlyAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final result = await ref
        .read(trashControllerProvider.notifier)
        .deleteItems(items);
    if (result.anyDeleted) {
      ref.invalidate(mediaItemsProvider);
      ref.read(selectionProvider.notifier).clear();
    }
    if (context.mounted) _tell(context, deleteResultMessage(l10n, result));
  }

  static void _tell(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// The last button in the bar: opens the sheet with every other action.
class _MoreButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MoreButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final label = l10n.labelBatchActionMore;

    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.more_horiz, color: theme.colorScheme.onSurface),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One action in the bar: an icon, a label, and a greyed-out state.
class _ActionButton extends StatelessWidget {
  final BatchActionAvailability availability;
  final VoidCallback onPressed;

  const _ActionButton({required this.availability, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final enabled = availability.isAllowed;

    final colour = enabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Tooltip(
      message: enabled
          ? _label(l10n, availability.action)
          : BatchActionBar._blockedReason(l10n, availability),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        // Still tappable when blocked, so tapping says why rather than
        // doing nothing at all.
        onTap: onPressed,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_icon(availability.action), color: colour),
              const SizedBox(height: 4),
              Text(
                _label(l10n, availability.action),
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(color: colour),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _icon(BatchAction action) {
    switch (action) {
      case BatchAction.convert:
        return Icons.swap_horiz;
      case BatchAction.watermark:
        return Icons.branding_watermark_outlined;
      case BatchAction.exportPdf:
        return Icons.picture_as_pdf_outlined;
      case BatchAction.addTags:
        return Icons.label_outline;
      case BatchAction.removeTags:
        return Icons.label_off_outlined;
      case BatchAction.addToAlbum:
        return Icons.photo_album_outlined;
      case BatchAction.favourite:
        return Icons.favorite_border;
      case BatchAction.unfavourite:
        return Icons.heart_broken_outlined;
      case BatchAction.moveToVault:
        return Icons.lock_outline;
      case BatchAction.transfer:
        return Icons.send_to_mobile_outlined;
      case BatchAction.moveToTrash:
        return Icons.delete_outline;
    }
  }

  static String _label(AppLocalizations l10n, BatchAction action) {
    switch (action) {
      case BatchAction.convert:
        return l10n.labelBatchActionConvert;
      case BatchAction.watermark:
        return l10n.labelBatchActionWatermark;
      case BatchAction.exportPdf:
        return l10n.labelBatchActionExportPdf;
      case BatchAction.addTags:
        return l10n.labelBatchActionAddTags;
      case BatchAction.removeTags:
        return l10n.labelBatchActionRemoveTags;
      case BatchAction.addToAlbum:
        return l10n.labelBatchActionAddToAlbum;
      case BatchAction.favourite:
        return l10n.labelBatchActionFavourite;
      case BatchAction.unfavourite:
        return l10n.bodyBatchActionUnfavourite;
      case BatchAction.moveToVault:
        return l10n.labelBatchActionMoveToVault;
      case BatchAction.transfer:
        return l10n.bodyBatchActionTransfer;
      case BatchAction.moveToTrash:
        // One Delete button; the choice sheet asks trash or permanent.
        return l10n.titleBatchActionDelete;
    }
  }
}
