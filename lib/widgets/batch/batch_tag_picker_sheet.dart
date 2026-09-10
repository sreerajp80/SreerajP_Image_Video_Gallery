import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/batch/batch_action.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/tags/tag_name_rules.dart';

/// Bottom sheet for picking or creating tags during batch operations.
class BatchTagPickerSheet extends ConsumerStatefulWidget {
  final BatchAction action;

  const BatchTagPickerSheet({super.key, required this.action});

  /// Opens the sheet and returns the selected tag IDs, or null if dismissed.
  static Future<Set<String>?> show(
    BuildContext context, {
    required BatchAction action,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => BatchTagPickerSheet(action: action),
    );
  }

  @override
  ConsumerState<BatchTagPickerSheet> createState() =>
      _BatchTagPickerSheetState();
}

class _BatchTagPickerSheetState extends ConsumerState<BatchTagPickerSheet> {
  final TextEditingController _newTagController = TextEditingController();
  final Set<String> _chosen = <String>{};

  @override
  void dispose() {
    _newTagController.dispose();
    super.dispose();
  }

  Future<void> _addTypedTag() async {
    final name = TagNameRules.normalize(_newTagController.text);
    if (name.isEmpty) return;

    final tag = await ref
        .read(tagEditControllerProvider.notifier)
        .findOrCreate(name);
    if (tag == null || !mounted) return;

    _newTagController.clear();
    setState(() {
      _chosen.add(tag.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final allTagsAsync = ref.watch(allTagsProvider);
    final theme = Theme.of(context);
    final isAdd = widget.action == BatchAction.addTags;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isAdd ? l10n.batchPickTags : l10n.batchActionRemoveTags,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            allTagsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.tagErrorFailed),
              ),
              data: (tags) {
                if (tags.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      l10n.filterNoTags,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.35,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tags.length,
                    itemBuilder: (context, index) {
                      final tag = tags[index];
                      final isSelected = _chosen.contains(tag.id);
                      return CheckboxListTile(
                        dense: true,
                        value: isSelected,
                        title: Text(tag.name),
                        secondary: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Color(tag.colorValue),
                            shape: BoxShape.circle,
                          ),
                        ),
                        onChanged: (ticked) => setState(() {
                          if (ticked ?? false) {
                            _chosen.add(tag.id);
                          } else {
                            _chosen.remove(tag.id);
                          }
                        }),
                      );
                    },
                  ),
                );
              },
            ),
            if (isAdd) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTagController,
                      decoration: InputDecoration(
                        hintText: l10n.tagSheetNewHint,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addTypedTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: _addTypedTag,
                    child: Text(l10n.tagSheetAdd),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _chosen.isEmpty
                    ? null
                    : () => Navigator.of(context).pop(_chosen),
                child: Text(l10n.batchConfirmContinue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
