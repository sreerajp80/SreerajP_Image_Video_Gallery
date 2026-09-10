import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/album_summary.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/batch_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/batch_action_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/batch/gallery_batch_handler.dart';
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

    final entries = availability.valueOrNull;
    if (entries == null || entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 3,
      color: theme.colorScheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (context, index) => _ActionButton(
              availability: entries[index],
              onPressed: () => _start(context, ref, entries[index]),
            ),
          ),
        ),
      ),
    );
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

    final items = ref.read(selectedMediaProvider).valueOrNull;
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

    final options = await _gatherOptions(context, ref, action);
    if (options == null) return;
    if (!context.mounted) return;

    if (ref.read(batchActionRulesProvider).needsConfirmation(action)) {
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

    if (context.mounted) await BatchResultSheet.show(context, outcome);
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
        _tell(context, l10n.filterNoTags);
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
                      l10n.batchPickAlbum,
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
                    label: Text(l10n.albumPickerCreate),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (albums.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      l10n.albumPickerEmpty,
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
                          subtitle: Text(l10n.albumItemCount(album.itemCount)),
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
        ref.read(virtualAlbumsProvider).valueOrNull ?? const <AlbumSummary>[];
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
        body = l10n.batchConfirmVault(count);
      case BatchAction.moveToTrash:
        body = l10n.batchConfirmTrash(count);
      default:
        body = l10n.batchConfirmNewFiles(count);
    }

    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.batchConfirmTitle),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.batchConfirmContinue),
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
        return l10n.batchBlockedEmpty;
      case BatchBlockReason.selectionTooLarge:
        return l10n.batchBlockedTooLarge;
      case BatchBlockReason.noSupportedItems:
        return l10n.batchBlockedUnsupported;
      case BatchBlockReason.mixedTypes:
        return l10n.batchBlockedMixed;
      case null:
        return l10n.batchBlockedUnsupported;
    }
  }

  static void _tell(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
          width: 84,
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
        return l10n.batchActionConvert;
      case BatchAction.watermark:
        return l10n.batchActionWatermark;
      case BatchAction.exportPdf:
        return l10n.batchActionExportPdf;
      case BatchAction.addTags:
        return l10n.batchActionAddTags;
      case BatchAction.removeTags:
        return l10n.batchActionRemoveTags;
      case BatchAction.addToAlbum:
        return l10n.batchActionAddToAlbum;
      case BatchAction.favourite:
        return l10n.batchActionFavourite;
      case BatchAction.unfavourite:
        return l10n.batchActionUnfavourite;
      case BatchAction.moveToVault:
        return l10n.batchActionMoveToVault;
      case BatchAction.transfer:
        return l10n.batchActionTransfer;
      case BatchAction.moveToTrash:
        return l10n.batchActionMoveToTrash;
    }
  }
}
