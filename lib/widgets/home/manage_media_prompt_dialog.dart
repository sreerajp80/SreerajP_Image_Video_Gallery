import 'package:material_ui/material_ui.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// Asks the user to turn on "Manage media" (Android 12+).
///
/// Only asks: returns true when the user picked "Open settings". The caller
/// opens Android's page. Returns false for "Not now" or a dismiss.
Future<bool> showManageMediaPromptDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final open = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.perm_media_outlined),
      title: Text(l10n.titleManageMediaPrompt),
      content: Text(l10n.bodyManageMediaPrompt),
      actions: <Widget>[
        TextButton(
          key: const ValueKey<String>('manage_media_prompt_not_now'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.actionNotNow),
        ),
        FilledButton(
          key: const ValueKey<String>('manage_media_prompt_open'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.labelOpenSettings),
        ),
      ],
    ),
  );
  return open == true;
}
