import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/selection_providers.dart';

/// The app bar a grid shows while items are ticked.
///
/// Replaces the screen's own bar rather than sitting beside it, so there is
/// never a moment where the ordinary actions and the selection actions are
/// both on screen offering different things.
class SelectionAppBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Every id on the current screen, for "select all".
  ///
  /// The screen supplies it because only the screen knows what it is
  /// showing: on an album that is the album's items, on the timeline it is
  /// everything indexed.
  final List<String> visibleIds;

  const SelectionAppBar({super.key, required this.visibleIds});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final count = ref.watch(selectionCountProvider);
    final selection = ref.read(selectionProvider.notifier);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.selectionClear,
        onPressed: selection.clear,
      ),
      title: Text(l10n.selectionCount(count)),
      actions: [
        if (count == 2)
          IconButton(
            icon: const Icon(Icons.compare_arrows),
            tooltip: l10n.compareTooltip,
            onPressed: () {
              final selectedIds = ref.read(selectionProvider).toList();
              if (selectedIds.length == 2) {
                context.push(photoComparePath(selectedIds[0], selectedIds[1]));
              }
            },
          ),
        if (visibleIds.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.select_all),
            tooltip: l10n.selectionSelectAll,
            onPressed: () => selection.selectAll(visibleIds),
          ),
      ],
    );
  }
}
