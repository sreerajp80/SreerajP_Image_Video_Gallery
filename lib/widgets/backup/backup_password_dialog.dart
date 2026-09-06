import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// Asks for the archive password.
///
/// On the create side it asks twice and shows the warning, because a typo in
/// a password that cannot be recovered costs the user the whole backup. On
/// the restore side one field is enough: a wrong password there just fails to
/// open the file, which is recoverable by typing it again.
///
/// The password is returned and never stored. Nothing in this widget writes
/// it anywhere, and the controllers are disposed with the dialog.
class BackupPasswordDialog extends StatefulWidget {
  /// Whether this is for creating a backup rather than restoring one.
  final bool isCreating;

  const BackupPasswordDialog({super.key, required this.isCreating});

  /// Shows the dialog, returning the password or null if it was dismissed.
  static Future<String?> show(
    BuildContext context, {
    required bool isCreating,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => BackupPasswordDialog(isCreating: isCreating),
    );
  }

  @override
  State<BackupPasswordDialog> createState() => _BackupPasswordDialogState();
}

class _BackupPasswordDialogState extends State<BackupPasswordDialog> {
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirm = TextEditingController();

  String? _error;
  bool _obscured = true;

  @override
  void dispose() {
    // The password goes out of memory with the dialog, as far as a Dart
    // String allows. Nothing else here holds a copy.
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final value = _password.text;

    if (value.length < AppConstants.backupPasswordMinLength) {
      setState(() {
        _error = l10n.backupPasswordTooShort(
          AppConstants.backupPasswordMinLength,
        );
      });
      return;
    }
    if (widget.isCreating && value != _confirm.text) {
      setState(() => _error = l10n.backupPasswordMismatch);
      return;
    }

    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text(l10n.backupPasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _password,
            autofocus: true,
            obscureText: _obscured,
            decoration: InputDecoration(
              labelText: l10n.backupPasswordLabel,
              errorText: _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscured ? Icons.visibility_outlined : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              ),
            ),
            onSubmitted: (_) => widget.isCreating ? null : _submit(),
          ),
          if (widget.isCreating) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _confirm,
              obscureText: _obscured,
              decoration: InputDecoration(
                labelText: l10n.backupPasswordConfirmLabel,
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            // Said plainly, because it is true and there is no way round it.
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_outlined,
                  size: 18,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.backupPasswordWarning,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(MaterialLocalizations.of(context).okButtonLabel),
        ),
      ],
    );
  }
}
