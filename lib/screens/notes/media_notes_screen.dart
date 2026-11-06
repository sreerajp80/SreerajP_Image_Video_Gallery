import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/notes_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/intent_exception.dart';
import 'package:in_sreerajp_imgvidgal/widgets/notes/markdown_view.dart';

/// The note editor at `/media-viewer/:id/notes`.
///
/// Two tabs: the markdown as typed, and the same text drawn. Leaving with
/// unsaved changes asks first, because a note is writing the user cannot get
/// back once the screen is gone.
class MediaNotesScreen extends ConsumerStatefulWidget {
  /// The item the note belongs to.
  final String mediaId;

  const MediaNotesScreen({super.key, required this.mediaId});

  @override
  ConsumerState<MediaNotesScreen> createState() => _MediaNotesScreenState();
}

class _MediaNotesScreenState extends ConsumerState<MediaNotesScreen> {
  final TextEditingController _controller = TextEditingController();

  /// What was last written, so unsaved changes can be spotted.
  String _saved = '';

  /// Whether the note has been loaded into the field yet.
  bool _loaded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isDirty => _controller.text.trim() != _saved.trim();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final note = ref.watch(mediaNoteProvider(widget.mediaId));

    // Fill the field once, the first time the note arrives. Doing it on every
    // build would wipe out what the user is in the middle of typing.
    note.whenData((value) {
      if (_loaded) return;
      _loaded = true;
      _saved = value.markdown;
      _controller.text = value.markdown;
    });

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmDiscard() && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(l10n.titleNotes),
            bottom: TabBar(
              tabs: <Widget>[
                Tab(text: l10n.tabNotesWrite),
                Tab(text: l10n.tabNotesPreview),
              ],
            ),
            actions: <Widget>[
              if (_saved.trim().isNotEmpty)
                IconButton(
                  onPressed: _confirmDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: l10n.tooltipNotesDelete,
                ),
              IconButton(
                onPressed: _save,
                icon: const Icon(Icons.check),
                tooltip: l10n.tooltipNotesSave,
              ),
            ],
          ),
          body: SafeArea(
            child: note.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.errorNotesSaveFailed)),
              data: (_) => TabBarView(
                children: <Widget>[
                  _editor(context, l10n),
                  _preview(context, l10n),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editor(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              maxLength: AppConstants.notesMaxLength,
              // The counter is drawn below instead, so the field itself is
              // not cluttered while writing.
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => null,
              decoration: InputDecoration(
                hintText: l10n.helpNotesHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.bodyNotesCharacterCount(
              _controller.text.length,
              AppConstants.notesMaxLength,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: MarkdownView(
        source: _controller.text,
        emptyState: Text(
          l10n.emptyNotes,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        onOpenLink: _openLink,
        onBlockedLink: () => _say(l10n.bodyNotesLinkBlocked),
      ),
    );
  }

  Future<void> _openLink(String target) async {
    final l10n = AppLocalizations.of(context)!;
    final uri = target.contains(':') ? target : 'https://$target';

    try {
      await ref.read(scanActionRunnerProvider).open(uri);
    } on IntentException catch (error) {
      _say(
        error.hasNoApp
            ? l10n.errorCodeScanOpenFailed
            : l10n.bodyNotesLinkBlocked,
      );
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _controller.text;

    if (text.length > AppConstants.notesMaxLength) {
      _say(l10n.bodyNotesTooLong);
      return;
    }

    final saved = await ref
        .read(notesControllerProvider.notifier)
        .save(widget.mediaId, text);

    if (!mounted) return;
    if (saved) {
      setState(() => _saved = text.trim());
      _say(l10n.labelNotesSaved);
    } else {
      _say(l10n.errorNotesSaveFailed);
    }
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context)!;

    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.titleNotesDiscard),
        content: Text(l10n.bodyNotesDiscard),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionNotesDiscardKeep),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionNotesDiscardLeave),
          ),
        ],
      ),
    );

    return leave ?? false;
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.titleNotesDelete),
        content: Text(l10n.bodyNotesDelete),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionNotesCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.tooltipNotesDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final cleared = await ref
        .read(notesControllerProvider.notifier)
        .clear(widget.mediaId);

    if (!mounted) return;
    if (cleared) {
      setState(() {
        _saved = '';
        _controller.clear();
      });
      _say(l10n.labelNotesDeleted);
    } else {
      _say(l10n.errorNotesSaveFailed);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
