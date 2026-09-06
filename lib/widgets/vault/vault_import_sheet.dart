import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/timeline_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/media/media_thumbnail.dart';

/// What the user chose in the import sheet.
@immutable
class VaultImportChoice {
  /// The gallery items to encrypt.
  final List<MediaItem> items;

  /// Whether the public originals are to be destroyed.
  final bool shredOriginals;

  const VaultImportChoice({required this.items, required this.shredOriginals});
}

/// Picks gallery items to move into the vault.
///
/// The one screen in the app that can destroy a file the user did not ask to
/// delete, so the shred choice is off by default, is described in plain words,
/// and needs a second confirmation naming how many files go. Keeping the
/// originals is the safe path and the one the sheet starts on.
///
/// Returns a [VaultImportChoice] through `Navigator.pop`, or null when
/// dismissed. It does no encrypting itself: the vault screen runs the batch,
/// so the work is not tied to a sheet that may be swiped away.
class VaultImportSheet extends ConsumerStatefulWidget {
  const VaultImportSheet({super.key});

  @override
  ConsumerState<VaultImportSheet> createState() => _VaultImportSheetState();
}

class _VaultImportSheetState extends ConsumerState<VaultImportSheet> {
  final Set<String> _selectedIds = <String>{};
  bool _shredOriginals = false;
  bool _defaultsApplied = false;

  void _toggle(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  /// Confirms the choice, asking again first when originals will be destroyed.
  Future<void> _confirm(List<MediaItem> available) async {
    final chosen = available
        .where((item) => _selectedIds.contains(item.id))
        .toList(growable: false);
    if (chosen.isEmpty) return;

    if (_shredOriginals) {
      final agreed = await _confirmShred(chosen.length);
      if (!agreed) return;
    }

    if (!mounted) return;
    Navigator.of(
      context,
    ).pop(VaultImportChoice(items: chosen, shredOriginals: _shredOriginals));
  }

  /// The second gate in front of destroying originals.
  Future<bool> _confirmShred(int count) async {
    final l10n = AppLocalizations.of(context)!;
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.vaultShredConfirmTitle(count)),
        content: Text(l10n.vaultShredConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.vaultCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.vaultShredConfirmAction),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final items = ref.watch(timelineItemsProvider);

    // Start on whatever the user set as their default, once.
    ref.watch(vaultSettingsProvider).whenData((settings) {
      if (!_defaultsApplied) {
        _defaultsApplied = true;
        _shredOriginals = settings.shredOnImportByDefault;
      }
    });

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            title: Text(
              l10n.vaultImportTitle,
              style: theme.textTheme.titleLarge,
            ),
            subtitle: Text(l10n.vaultImportBody),
            trailing: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              tooltip: l10n.vaultCancel,
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: items.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(child: Text(l10n.vaultImportFailed)),
              data: (list) => _buildGrid(list, l10n),
            ),
          ),
          const Divider(height: 1),
          _buildOriginalChoice(l10n),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _selectedIds.isEmpty
                    ? null
                    : () => _confirm(items.value ?? const <MediaItem>[]),
                child: Text(
                  _selectedIds.isEmpty
                      ? l10n.vaultImportNothingSelected
                      : l10n.vaultImportConfirm(_selectedIds.length),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(List<MediaItem> list, AppLocalizations l10n) {
    if (list.isEmpty) {
      return Center(child: Text(l10n.vaultEmptyBody));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final selected = _selectedIds.contains(item.id);
        return GestureDetector(
          onTap: () => _toggle(item.id),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              MediaThumbnail(item: item),
              if (selected)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.35),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
              Positioned(
                left: 4,
                top: 4,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.white70,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The keep-or-shred choice, spelled out rather than hidden behind a switch.
  Widget _buildOriginalChoice(AppLocalizations l10n) {
    return RadioGroup<bool>(
      groupValue: _shredOriginals,
      onChanged: (value) => setState(() => _shredOriginals = value ?? false),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RadioListTile<bool>(
            value: false,
            title: Text(l10n.vaultImportKeepOriginal),
            subtitle: Text(l10n.vaultImportKeepOriginalBody),
            dense: true,
          ),
          RadioListTile<bool>(
            value: true,
            title: Text(l10n.vaultImportShredOriginal),
            subtitle: Text(l10n.vaultImportShredOriginalBody),
            dense: true,
          ),
        ],
      ),
    );
  }
}
