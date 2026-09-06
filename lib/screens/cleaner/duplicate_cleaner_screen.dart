import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_sreerajp_imgvidgal/core/routing/app_router.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/duplicate/duplicate_scan_state.dart';
import 'package:in_sreerajp_imgvidgal/providers/duplicate_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/cleaner/duplicate_group_card.dart';
import 'package:in_sreerajp_imgvidgal/widgets/viewer/media_details_sheet.dart';

/// The duplicate cleaner at `/cleaner`.
class DuplicateCleanerScreen extends ConsumerWidget {
  const DuplicateCleanerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(duplicateScanControllerProvider);
    final controller = ref.read(duplicateScanControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.cleanerTitle),
        actions: <Widget>[
          if (state.isRunning)
            TextButton(
              onPressed: controller.cancel,
              child: Text(l10n.cleanerStop),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _StatusPanel(state: state),
            Expanded(child: _Body(state: state)),
          ],
        ),
      ),
      floatingActionButton: state.isRunning
          ? null
          : FloatingActionButton.extended(
              onPressed: controller.start,
              icon: const Icon(Icons.search),
              label: Text(
                state.stage == DuplicateScanStage.idle
                    ? l10n.cleanerStart
                    : l10n.cleanerRescan,
              ),
            ),
    );
  }
}

/// The progress bar and summary line above the group list.
class _StatusPanel extends StatelessWidget {
  final DuplicateScanState state;

  const _StatusPanel({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (state.stage == DuplicateScanStage.idle) {
      return const SizedBox.shrink();
    }

    final lines = <String>[
      switch (state.stage) {
        DuplicateScanStage.hashing => l10n.cleanerScanning(
          state.processed,
          state.total,
        ),
        DuplicateScanStage.grouping => l10n.cleanerGrouping,
        DuplicateScanStage.cancelled => l10n.cleanerCancelled,
        DuplicateScanStage.failed => l10n.cleanerFailed,
        DuplicateScanStage.done ||
        DuplicateScanStage.idle => l10n.cleanerGroupsFound(state.groups.length),
      },
      if (state.groups.isNotEmpty)
        l10n.cleanerReclaimable(formatFileSize(state.reclaimableBytes)),
      if (state.failures > 0) l10n.cleanerFailures(state.failures),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (state.isRunning)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LinearProgressIndicator(value: state.progress),
            ),
          for (final line in lines)
            Text(line, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// The group list, or whatever should stand in for it.
class _Body extends ConsumerWidget {
  final DuplicateScanState state;

  const _Body({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (state.groups.isNotEmpty) {
      return ListView.builder(
        // Room under the last card so the button never covers it.
        padding: const EdgeInsets.only(bottom: 88),
        itemCount: state.groups.length,
        itemBuilder: (context, index) {
          final group = state.groups[index];
          return DuplicateGroupCard(
            group: group,
            onCompare: () => context.push(duplicateComparePath(group.id)),
          );
        },
      );
    }

    return switch (state.stage) {
      DuplicateScanStage.idle => _Message(
        icon: Icons.copy_all_outlined,
        title: l10n.cleanerIdleTitle,
        body: l10n.cleanerIdleBody,
      ),
      DuplicateScanStage.hashing || DuplicateScanStage.grouping => const Center(
        child: CircularProgressIndicator(),
      ),
      DuplicateScanStage.failed => _Message(
        icon: Icons.error_outline,
        title: l10n.cleanerFailed,
        body: state.errorMessage,
      ),
      DuplicateScanStage.cancelled => _Message(
        icon: Icons.pause_circle_outline,
        title: l10n.cleanerCancelled,
      ),
      DuplicateScanStage.done => _Message(
        icon: Icons.check_circle_outline,
        title: l10n.cleanerNoneTitle,
        body: l10n.cleanerNoneBody,
      ),
    };
  }
}

/// A centred icon, title, and optional body.
class _Message extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;

  const _Message({required this.icon, required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (body != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                body!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
