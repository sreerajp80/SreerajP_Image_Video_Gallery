import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_group.dart';
import 'package:in_sreerajp_imgvidgal/providers/duplicate_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/cleaner/comparison_pane.dart';
import 'package:in_sreerajp_imgvidgal/widgets/cleaner/keep_best_bar.dart';

/// Widest a single comparison pane is allowed to get.
///
/// On a tablet or in landscape the panes would otherwise stretch until the
/// pictures were far apart and hard to compare, which is the one thing this
/// screen exists to make easy.
const double kComparePaneMaxWidth = 260;

/// The side-by-side comparison at `/cleaner/compare/:groupId`.
///
/// The panes scroll sideways, so a group of two and a burst of eight are shown
/// the same way with no special case.
class DuplicateCompareScreen extends ConsumerWidget {
  /// Id of the group being compared.
  final String groupId;

  const DuplicateCompareScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final group = ref.watch(duplicateGroupProvider(groupId));
    final cleanup = ref.watch(duplicateCleanupControllerProvider);

    if (group == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.compareTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.compareGroupGone,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      );
    }

    final keeperId = ref
        .watch(duplicateKeeperProvider.notifier)
        .keeperFor(group);
    // Watched so the panes redraw when the choice changes.
    ref.watch(duplicateKeeperProvider);

    final paneWidth = _paneWidth(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.compareTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              group.kind == DuplicateGroupKind.exact
                  ? l10n.cleanerKindExact
                  : l10n.cleanerKindSimilar,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          itemCount: group.items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final item = group.items[index];
            return ComparisonPane(
              item: item,
              width: paneWidth,
              isKeeper: item.id == keeperId,
              isSuggested: item.id == group.suggestedKeeperId,
              onKeep: () => ref
                  .read(duplicateKeeperProvider.notifier)
                  .choose(group.id, item.id),
            );
          },
        ),
      ),
      bottomNavigationBar: KeepBestBar(
        trashCount: group.items.length - 1,
        onConfirm: cleanup.isLoading
            ? null
            : () => _confirm(context, ref, group, keeperId),
      ),
    );
  }

  /// Pane width: two side by side on a phone, capped so they stay comparable.
  double _paneWidth(BuildContext context) {
    final available = MediaQuery.of(context).size.width - 34;
    return (available / 2).clamp(160.0, kComparePaneMaxWidth);
  }

  Future<void> _confirm(
    BuildContext context,
    WidgetRef ref,
    DuplicateGroup group,
    String keeperId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final count = group.items.length - 1;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.compareConfirmTitle(count)),
        content: Text(l10n.compareConfirmBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.compareCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.compareConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final moved = await ref
        .read(duplicateCleanupControllerProvider.notifier)
        .keepOnly(group, keeperId);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          moved == null ? l10n.compareFailed : l10n.compareMoved(moved),
        ),
      ),
    );
    // The group has been dealt with, so there is nothing left to compare.
    if (moved != null) Navigator.of(context).pop();
  }
}
