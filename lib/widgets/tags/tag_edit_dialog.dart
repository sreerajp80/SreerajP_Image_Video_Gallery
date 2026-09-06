import 'package:flutter/material.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/tag.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_color_palette.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';
import 'package:in_sreerajp_imgvidgal/widgets/tags/tag_color_picker.dart';

/// What the user chose in the tag dialog.
class TagEditResult {
  final String name;
  final int colorValue;

  const TagEditResult({required this.name, required this.colorValue});
}

/// Makes or renames a tag.
///
/// The name rules are checked here as the user types, using the same
/// `TagNameRules` the repository checks again before writing, so the inline
/// message and the actual outcome can never disagree.
class TagEditDialog extends StatefulWidget {
  /// The tag being edited, or null when making a new one.
  final Tag? tag;

  /// Names already in use, so a clash is caught before the write.
  final List<String> existingNames;

  const TagEditDialog({
    super.key,
    this.tag,
    this.existingNames = const <String>[],
  });

  @override
  State<TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<TagEditDialog> {
  late final TextEditingController _controller;
  late int _colorValue;

  /// Set once the user has typed, so a dialog does not open showing an error.
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.tag?.name ?? '');
    _colorValue = widget.tag != null
        ? TagColorPalette.resolve(widget.tag!.colorValue, widget.tag!.name)
        : TagColorPalette.colors.first;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  TagNameCheck get _check => TagNameRules.check(
    _controller.text,
    existingNames: widget.existingNames,
    ignoreName: widget.tag?.name,
  );

  /// The colour a new tag would take if the user does not pick one.
  ///
  /// Following the typed name keeps the preview honest: what is shown in the
  /// dialog is what the tag will look like.
  void _followNameColor(String value) {
    if (widget.tag != null) return;
    setState(() {
      _touched = true;
      _colorValue = TagColorPalette.defaultColorFor(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final check = _check;
    final error = _touched ? _errorText(l10n, check.error) : null;

    return AlertDialog(
      title: Text(widget.tag == null ? l10n.tagNew : l10n.tagEditTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: TagNameRules.maxLength,
            decoration: InputDecoration(
              labelText: l10n.tagNameLabel,
              errorText: error,
            ),
            onChanged: _followNameColor,
            onSubmitted: (_) => _submit(check),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tagColorLabel,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          TagColorPicker(
            selectedColorValue: _colorValue,
            onChanged: (value) => setState(() => _colorValue = value),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.tagCancel),
        ),
        FilledButton(
          onPressed: check.isValid ? () => _submit(check) : null,
          child: Text(l10n.tagSave),
        ),
      ],
    );
  }

  void _submit(TagNameCheck check) {
    if (!check.isValid) {
      setState(() => _touched = true);
      return;
    }
    Navigator.of(
      context,
    ).pop(TagEditResult(name: check.normalized, colorValue: _colorValue));
  }

  String? _errorText(AppLocalizations l10n, TagNameError? error) {
    return switch (error) {
      null => null,
      TagNameError.empty => l10n.tagErrorEmpty,
      TagNameError.tooLong => l10n.tagErrorTooLong,
      TagNameError.duplicate => l10n.tagErrorDuplicate,
    };
  }
}
