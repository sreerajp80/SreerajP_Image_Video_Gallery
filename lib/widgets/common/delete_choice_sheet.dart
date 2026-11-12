import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media/delete_confirm_info.dart';
import 'package:in_sreerajp_imgvidgal/models/media/media_delete_result.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';

/// The snackbar text for a finished permanent delete.
///
/// Says plainly when a secure delete removed a file without writing over it
/// first, and when some files are still there. A secure delete that quietly
/// fell back to a plain one would be a broken promise.
String deleteResultMessage(AppLocalizations l10n, MediaDeleteResult result) {
  if (!result.anyDeleted) return l10n.bodyDeleteNothingDeleted;
  final parts = <String>[
    if (result.secure && result.notOverwritten == 0)
      l10n.bodySecureDeletedCount(result.deleted)
    else
      l10n.bodyDeletedPermanentlyCount(result.deleted),
    if (result.notOverwritten > 0)
      l10n.bodySecureDeleteNotOverwritten(result.notOverwritten),
    if (result.failed > 0) l10n.bodyDeleteFailedCount(result.failed),
  ];
  return parts.join(' ');
}

/// How the user chose to delete.
enum DeleteChoice {
  /// Flag it as trashed. The file stays on the device and can be restored.
  trash,

  /// Remove the file from the device for good.
  permanent,
}

/// Asks how to delete [count] items: move to the trash, or delete for good.
///
/// One Delete button opens this, rather than two buttons side by side, so
/// the safe choice is always first and the permanent one is always a
/// deliberate second tap. Returns null when the sheet is dismissed.
///
/// [secureDelete] only changes the wording: when it is on, the permanent row
/// says the files are written over first.
Future<DeleteChoice?> showDeleteChoiceSheet(
  BuildContext context, {
  required int count,
  required bool secureDelete,
}) {
  return showModalBottomSheet<DeleteChoice>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = AppLocalizations.of(sheetContext)!;
      final scheme = Theme.of(sheetContext).colorScheme;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text(
                l10n.titleDeleteChoice(count),
                style: Theme.of(sheetContext).textTheme.titleMedium,
              ),
            ),
            ListTile(
              key: const ValueKey<String>('delete_choice_trash'),
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.titleBatchActionMoveToTrash),
              subtitle: Text(l10n.bodyDeleteChoiceTrash(count)),
              onTap: () => Navigator.of(sheetContext).pop(DeleteChoice.trash),
            ),
            ListTile(
              key: const ValueKey<String>('delete_choice_permanent'),
              leading: Icon(Icons.delete_forever, color: scheme.error),
              title: Text(
                l10n.titleTrashDeletePermanentlyAction,
                style: TextStyle(color: scheme.error),
              ),
              subtitle: Text(
                secureDelete
                    ? l10n.bodyDeleteChoicePermanentSecure
                    : l10n.bodyDeleteChoicePermanent,
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(DeleteChoice.permanent),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

/// Whether the app must show its own "Delete permanently?" dialog after the
/// user picked "Delete permanently" in the choice sheet.
///
/// The user is asked exactly once after the sheet. When Android shows its own
/// prompt (Android 11+, "Manage media" off), that prompt is the one, and the
/// app's dialog would only repeat it. Otherwise (Android 10 and older, or
/// "Manage media" on) the app asks. Read fresh each time, since the user can
/// change "Manage media" in system settings at any moment. When unsure, the
/// app asks: one extra dialog is better than none.
Future<bool> appMustConfirmPermanentDelete(WidgetRef ref) async {
  try {
    final info = await ref.refresh(deleteConfirmInfoProvider.future);
    return info.appMustConfirm;
  } catch (_) {
    return DeleteConfirmInfo.fallback.appMustConfirm;
  }
}
