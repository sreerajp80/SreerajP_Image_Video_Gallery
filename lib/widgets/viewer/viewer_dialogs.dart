import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';

/// Value [showCompareChoiceSheet] returns when the user wants to pick a photo
/// from the gallery rather than a neighbour.
const String compareChoicePick = 'pick';

// The media viewer's dialogs live here so the screen file stays readable
// (G41). Each one only asks; the caller does the work. Moving to the trash
// has no dialog of its own: the delete choice sheet is that step.

/// Asks before the viewer deletes an item for good.
Future<bool> confirmViewerDeletePermanently(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.delete_forever,
        color: Theme.of(dialogContext).colorScheme.error,
      ),
      title: Text(l10n.titleTrashDeletePermanentlyConfirm),
      content: Text(l10n.bodyTrashDeletePermanentlyConfirm),
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
  return confirmed == true;
}

/// Asks before the viewer moves an item into the vault (the original is kept).
Future<bool> confirmViewerMoveToVault(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final agreed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.titleVaultMoveToVault),
      content: Text(l10n.bodyVaultImportKeepOriginal),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionVaultCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.titleVaultMoveToVault),
        ),
      ],
    ),
  );
  return agreed == true;
}

/// Offers the neighbours of the photo in view, or a gallery pick.
///
/// Returns the chosen item's id, [compareChoicePick], or null if dismissed.
Future<String?> showCompareChoiceSheet(
  BuildContext context, {
  MediaItem? prevItem,
  MediaItem? nextItem,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows),
                  const SizedBox(width: 12),
                  Text(
                    l10n.titleComparePhotos,
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (prevItem != null)
              ListTile(
                leading: const Icon(Icons.arrow_back),
                title: Text(l10n.titleCompareWithPrevious),
                subtitle: Text(prevItem.displayName),
                onTap: () => Navigator.of(sheetContext).pop(prevItem.id),
              ),
            if (nextItem != null)
              ListTile(
                leading: const Icon(Icons.arrow_forward),
                title: Text(l10n.titleCompareWithNext),
                subtitle: Text(nextItem.displayName),
                onTap: () => Navigator.of(sheetContext).pop(nextItem.id),
              ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(l10n.titleCompareChooseFromGallery),
              onTap: () => Navigator.of(sheetContext).pop(compareChoicePick),
            ),
          ],
        ),
      );
    },
  );
}
