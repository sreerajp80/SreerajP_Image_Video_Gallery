import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_plan.dart';
import 'package:intl/intl.dart';

/// Shows what a restore would do, before anything is written.
///
/// This sheet is the reason [RestorePlan] exists as a separate step. The
/// archive has already been opened and understood at this point, and not one
/// row has been changed — walking away here costs nothing.
///
/// It also states the guarantee out loud: a restore only ever adds and fills
/// gaps. Nothing on the device is deleted, and no note or favourite already
/// here is replaced by an older one from the file.
class RestorePreviewSheet extends StatelessWidget {
  final RestorePlan plan;

  const RestorePreviewSheet({super.key, required this.plan});

  /// Shows the sheet. Returns true if the user chose to go ahead.
  static Future<bool?> show(BuildContext context, RestorePlan plan) {
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => RestorePreviewSheet(plan: plan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final date = DateFormat.yMMMd().add_Hm().format(plan.manifest.createdAt);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.restorePreviewTitle, style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                l10n.restoreFromBackupDate(date),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              if (plan.isEmpty)
                Text(l10n.restorePlanNothing, style: theme.textTheme.bodyMedium)
              else ...[
                _Line(
                  icon: Icons.label_outline,
                  text: l10n.restorePlanTags(plan.tagsToCreate.length),
                ),
                _Line(
                  icon: Icons.photo_album_outlined,
                  text: l10n.restorePlanAlbums(plan.albumsToCreate.length),
                ),
                _Line(
                  icon: Icons.link,
                  text: l10n.restorePlanLinks(
                    plan.tagLinkCount + plan.albumLinkCount,
                  ),
                ),
                _Line(
                  icon: Icons.edit_note,
                  text: l10n.restorePlanUpdates(plan.mediaUpdateCount),
                ),
              ],

              if (plan.unmatchedCount > 0) ...[
                const SizedBox(height: 12),
                // Said rather than hidden. A backup from another phone will
                // usually have some of these, and somebody who is not told
                // will assume the restore went wrong.
                _Line(
                  icon: Icons.help_outline,
                  colour: theme.colorScheme.onSurfaceVariant,
                  text: l10n.restorePlanUnmatched(plan.unmatchedCount),
                ),
              ],

              const SizedBox(height: 16),
              Text(
                l10n.backupRestoreBody,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(
                      MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: plan.isEmpty
                        ? null
                        : () => Navigator.of(context).pop(true),
                    child: Text(l10n.restoreApply),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of the plan.
class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? colour;

  const _Line({required this.icon, required this.text, this.colour});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = colour ?? theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
