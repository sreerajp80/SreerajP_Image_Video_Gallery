import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/services/albums/album_name_rules.dart';

/// Makes or renames an album.
///
/// The name rules are checked here as the user types, using the same
/// [AlbumNameRules] the repository checks again before writing, so the inline
/// message and the actual outcome can never disagree.
class AlbumEditDialog extends StatefulWidget {
  /// The album's current name, or null when making a new one.
  final String? currentName;

  /// Names already in use, so a clash is caught before the write.
  final List<String> existingNames;

  const AlbumEditDialog({
    super.key,
    this.currentName,
    this.existingNames = const <String>[],
  });

  @override
  State<AlbumEditDialog> createState() => _AlbumEditDialogState();
}

class _AlbumEditDialogState extends State<AlbumEditDialog> {
  late final TextEditingController _controller;

  /// Set once the user has typed, so the dialog does not open showing an error.
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  AlbumNameCheck get _check => AlbumNameRules.check(
    _controller.text,
    existingNames: widget.existingNames,
    ignoreName: widget.currentName,
  );

  void _submit() {
    final check = _check;
    if (!check.isValid) {
      setState(() => _touched = true);
      return;
    }
    Navigator.of(context).pop(check.normalized);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = _check;
    final isRename = widget.currentName != null;

    return AlertDialog(
      title: Text(isRename ? l10n.albumRenameTitle : l10n.albumCreateTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: AlbumNameRules.maxLength,
        textInputAction: TextInputAction.done,
        onChanged: (_) => setState(() => _touched = true),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: l10n.albumNameLabel,
          hintText: l10n.albumNameHint,
          errorText: _touched ? _errorText(l10n, check) : null,
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.albumCancel),
        ),
        FilledButton(
          onPressed: check.isValid ? _submit : null,
          child: Text(isRename ? l10n.albumRename : l10n.albumSave),
        ),
      ],
    );
  }

  String? _errorText(AppLocalizations l10n, AlbumNameCheck check) {
    return switch (check.error) {
      null => null,
      AlbumNameError.empty => l10n.albumErrorEmpty,
      AlbumNameError.tooLong => l10n.albumErrorTooLong,
      AlbumNameError.duplicate => l10n.albumErrorDuplicate,
    };
  }
}
