import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/notes_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/common/adaptive_directionality.dart';

/// The note line in the details sheet.
///
/// Shows the first line of the note, or an invitation to write one. Tapping it
/// opens the editor. Only the first line is shown on purpose: the sheet is a
/// summary, and a long note would push the camera details off the screen.
class NotesPreviewTile extends ConsumerWidget {
  /// The item whose note is being shown.
  final String mediaId;

  const NotesPreviewTile({super.key, required this.mediaId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final note = ref.watch(mediaNoteProvider(mediaId));

    return note.when(
      // A note that is still loading, or one that failed to load, both show
      // nothing rather than an error: the sheet's job is the file's details,
      // and a missing note line is not worth a red message.
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (value) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.sticky_note_2_outlined),
          title: Text(
            l10n.notesDetailsLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          // The invitation is a translated label and follows the locale; the
          // note's own first line follows the note.
          subtitle: value.isEmpty
              ? Text(
                  l10n.notesAddFromDetails,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                )
              : AdaptiveDirectionality(
                  text: value.firstLine,
                  child: Text(
                    value.firstLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // The sheet is closed first, so coming back from the editor does
            // not land the user behind a sheet they have to dismiss.
            Navigator.of(context).pop();
            context.push(mediaNotesPath(mediaId));
          },
        );
      },
    );
  }
}
