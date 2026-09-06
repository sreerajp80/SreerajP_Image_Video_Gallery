import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/vault_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/secure_screen.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_auto_lock_scope.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_import_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/vault/vault_item_tile.dart';

/// The unlocked vault.
///
/// Only ever built while the vault is open — the gate screen is what decides
/// that — so nothing here has to check the lock again. It is wrapped in the
/// auto-lock scope, which watches touches and the app lifecycle, and in the
/// secure-screen wrapper, which keeps screenshots and the app switcher blind.
class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  final Set<String> _selectedIds = <String>{};

  bool get _selectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
    });
  }

  void _clearSelection() => setState(_selectedIds.clear);

  List<VaultItem> _selectedItems(List<VaultItem> all) => all
      .where((item) => _selectedIds.contains(item.id))
      .toList(growable: false);

  // --------------------------------------------------------------- actions

  Future<void> _openImportSheet() async {
    final choice = await showModalBottomSheet<VaultImportChoice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const VaultImportSheet(),
    );
    if (choice == null || choice.items.isEmpty || !mounted) return;

    await ref
        .read(vaultBatchControllerProvider.notifier)
        .import(choice.items, shredOriginals: choice.shredOriginals);
    if (mounted) _clearSelection();
  }

  Future<void> _restoreSelected(List<VaultItem> all) async {
    final chosen = _selectedItems(all);
    if (chosen.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final agreed = await _confirm(
      title: l10n.vaultRestoreConfirmTitle(chosen.length),
      body: l10n.vaultRestoreConfirmBody,
      action: l10n.vaultRestoreConfirmAction,
    );
    if (!agreed || !mounted) return;

    await ref.read(vaultBatchControllerProvider.notifier).restore(chosen);
    if (mounted) _clearSelection();
  }

  Future<void> _deleteSelected(List<VaultItem> all) async {
    final chosen = _selectedItems(all);
    if (chosen.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    final agreed = await _confirm(
      title: l10n.vaultDeleteConfirmTitle(chosen.length),
      body: l10n.vaultDeleteConfirmBody,
      action: l10n.vaultDeleteForever,
      destructive: true,
    );
    if (!agreed || !mounted) return;

    await ref.read(vaultBatchControllerProvider.notifier).deleteForever(chosen);
    if (mounted) _clearSelection();
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final agreed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.vaultCancel),
          ),
          FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.error,
                    foregroundColor: theme.colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = ref.watch(vaultItemsProvider);
    final progress = ref.watch(vaultBatchProgressProvider);

    _listenForBatchResult(l10n);

    return SecureScreen(
      child: VaultAutoLockScope(
        child: Scaffold(
          appBar: AppBar(
            leading: _selectionMode
                ? IconButton(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.close),
                    tooltip: l10n.vaultClearSelection,
                  )
                : null,
            title: Text(
              _selectionMode
                  ? l10n.vaultSelectedCount(_selectedIds.length)
                  : l10n.vaultTitle,
            ),
            actions: _buildActions(
              items.valueOrNull ?? const <VaultItem>[],
              l10n,
            ),
            bottom: progress == null
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(4),
                    child: LinearProgressIndicator(value: progress.fraction),
                  ),
          ),
          floatingActionButton: _selectionMode
              ? null
              : FloatingActionButton.extended(
                  onPressed: progress == null ? _openImportSheet : null,
                  icon: const Icon(Icons.add),
                  label: Text(l10n.vaultAddItems),
                ),
          body: items.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.vaultAuthError)),
            data: (list) =>
                list.isEmpty ? _EmptyVault(l10n: l10n) : _buildGrid(list),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(List<VaultItem> all, AppLocalizations l10n) {
    if (_selectionMode) {
      return <Widget>[
        IconButton(
          onPressed: () => _restoreSelected(all),
          icon: const Icon(Icons.drive_file_move_outline),
          tooltip: l10n.vaultRestore,
        ),
        IconButton(
          onPressed: () => _deleteSelected(all),
          icon: const Icon(Icons.delete_forever_outlined),
          tooltip: l10n.vaultDeleteForever,
        ),
      ];
    }

    return <Widget>[
      IconButton(
        onPressed: () => ref.read(vaultLockControllerProvider.notifier).lock(),
        icon: const Icon(Icons.lock_outline),
        tooltip: l10n.vaultLockNow,
      ),
      IconButton(
        onPressed: () => context.push(kRouteVaultSettings),
        icon: const Icon(Icons.tune),
        tooltip: l10n.vaultSettingsAction,
      ),
    ];
  }

  Widget _buildGrid(List<VaultItem> list) {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return VaultItemTile(
          item: item,
          isSelected: _selectedIds.contains(item.id),
          selectionMode: _selectionMode,
          onLongPress: () => _toggleSelection(item.id),
          onTap: _selectionMode
              ? () => _toggleSelection(item.id)
              : () => context.push(vaultViewerPath(item.id)),
        );
      },
    );
  }

  /// Turns a finished batch into one message.
  ///
  /// A partly finished batch says so rather than claiming success: it matters
  /// that four of forty photos could not be read, and quietly rounding that
  /// off would leave the user thinking their vault holds more than it does.
  void _listenForBatchResult(AppLocalizations l10n) {
    ref.listen<AsyncValue<VaultBatchResult?>>(vaultBatchControllerProvider, (
      previous,
      next,
    ) {
      next.whenOrNull(
        data: (result) {
          if (result == null) return;
          final messenger = ScaffoldMessenger.of(context);
          messenger.hideCurrentSnackBar();
          messenger.showSnackBar(
            SnackBar(content: Text(_messageForResult(result, l10n))),
          );
          ref.read(vaultBatchControllerProvider.notifier).clearResult();
        },
        error: (_, _) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.vaultImportFailed)));
          ref.read(vaultBatchControllerProvider.notifier).clearResult();
        },
      );
    });
  }

  String _messageForResult(VaultBatchResult result, AppLocalizations l10n) {
    if (result.isTotalFailure) return l10n.vaultImportFailed;
    if (result.isPartial) {
      return l10n.vaultImportPartial(result.succeededCount, result.failedCount);
    }
    return l10n.vaultImportDone(result.succeededCount);
  }
}

/// What the vault shows before anything is in it.
class _EmptyVault extends StatelessWidget {
  final AppLocalizations l10n;

  const _EmptyVault({required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.lock_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(l10n.vaultEmptyTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.vaultEmptyBody,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
