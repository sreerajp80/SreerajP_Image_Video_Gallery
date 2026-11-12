import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/phone_move_data.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/settings_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/backup/restore_preview_sheet.dart';

/// Phone move, receiving side: lets the user look at the app data that
/// arrived and add it.
///
/// Nothing is written before the user says yes. The app data goes through
/// the same restore preview as a backup file or a QR sync (merge-only: it
/// adds and fills gaps, and deletes nothing). Settings replace this phone's
/// own, so they get their own question afterwards.
///
/// The review opens by itself once, so a user who taps back too quickly does
/// not lose the data without having seen it. The button opens it again.
class AppDataReview extends ConsumerStatefulWidget {
  final PhoneMoveData data;

  const AppDataReview({super.key, required this.data});

  @override
  ConsumerState<AppDataReview> createState() => _AppDataReviewState();
}

enum _ReviewStep { waiting, working, applied, failed }

class _AppDataReviewState extends ConsumerState<AppDataReview> {
  _ReviewStep _step = _ReviewStep.waiting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _review();
    });
  }

  Future<void> _review() async {
    if (_step == _ReviewStep.working || _step == _ReviewStep.applied) return;
    setState(() => _step = _ReviewStep.working);
    try {
      final restore = ref.read(restoreServiceProvider);
      final archive = await restore.openPayload(widget.data.payload);
      if (!mounted) return;

      final confirmed = await RestorePreviewSheet.show(context, archive.plan);
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _step = _ReviewStep.waiting);
        return;
      }

      await restore.applyPlan(archive);
      if (!mounted) return;

      final settings = widget.data.settings;
      if (settings != null) await _offerSettings(settings);
      if (!mounted) return;
      setState(() => _step = _ReviewStep.applied);
    } catch (error) {
      AppLogger.warning('Adding phone-move app data failed', error: error);
      if (mounted) setState(() => _step = _ReviewStep.failed);
    }
  }

  Future<void> _offerSettings(AppSettings settings) async {
    final l10n = AppLocalizations.of(context)!;
    final useTheirs = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.titleSyncUseSettings),
        content: Text(l10n.bodySyncUseSettings),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionSyncKeepMySettings),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionSyncUseTheirSettings),
          ),
        ],
      ),
    );
    if (useTheirs == true) {
      await ref.read(appSettingsProvider.notifier).applyAll(settings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    switch (_step) {
      case _ReviewStep.working:
        return const Padding(
          padding: EdgeInsets.only(top: 16),
          child: CircularProgressIndicator(),
        );
      case _ReviewStep.applied:
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            l10n.bodySyncAppDataApplied,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        );
      case _ReviewStep.waiting:
      case _ReviewStep.failed:
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              if (_step == _ReviewStep.failed)
                Text(
                  l10n.errorSyncAppDataApply,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _review,
                child: Text(l10n.actionSyncReviewAppData),
              ),
            ],
          ),
        );
    }
  }
}
