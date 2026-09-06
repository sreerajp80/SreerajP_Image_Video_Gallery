import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';

/// The bar along the bottom of the comparison screen.
///
/// It carries the plain-words notice that nothing is erased. That notice is
/// not decoration: the button moves copies out of the gallery, and the user
/// has to be able to see, before pressing it, that the files stay on the
/// device and can be brought back.
class KeepBestBar extends StatelessWidget {
  /// How many copies would be moved.
  final int trashCount;

  /// Runs the move. Null while one is already running.
  final VoidCallback? onConfirm;

  const KeepBestBar({super.key, required this.trashCount, this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Material(
      elevation: 3,
      color: theme.colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.compareTrashNotice,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: trashCount > 0 ? onConfirm : null,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: Text(l10n.compareKeepAndTrash(trashCount)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
