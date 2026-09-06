import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scan_action.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/scanned_code.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/notes_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/scan_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/scan/intent_channel.dart';
import 'package:in_sreerajp_imgvidgal/widgets/scan/scanned_code_card.dart';

/// Shows the codes found inside one picture, at `/media-viewer/:id/scan`.
///
/// The scan reads a file already on the device: no camera is opened and no
/// camera permission is needed. Every action goes through the provider layer,
/// so this screen never builds an intent of its own.
class ImageScanScreen extends ConsumerStatefulWidget {
  /// The media item being scanned.
  final String mediaId;

  const ImageScanScreen({super.key, required this.mediaId});

  @override
  ConsumerState<ImageScanScreen> createState() => _ImageScanScreenState();
}

class _ImageScanScreenState extends ConsumerState<ImageScanScreen> {
  @override
  void initState() {
    super.initState();
    // Providers cannot be written while the first frame is being built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }

  Future<void> _scan() async {
    if (!mounted) return;

    final item = await ref.read(mediaItemProvider(widget.mediaId).future);
    if (!mounted) return;

    await ref.read(imageScanControllerProvider.notifier).scan(item?.path ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(imageScanControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.codeScanTitle),
        actions: <Widget>[
          IconButton(
            onPressed: _scan,
            icon: const Icon(Icons.refresh),
            tooltip: l10n.codeScanRetry,
          ),
        ],
      ),
      body: state.when(
        loading: () => _busy(l10n.codeScanLooking),
        error: (_, __) => _message(
          context,
          icon: Icons.error_outline,
          text: l10n.codeScanFailed,
          onRetry: _scan,
        ),
        data: (outcome) {
          if (outcome == null) return _busy(l10n.codeScanLooking);

          if (outcome.decoderFailed) {
            return _message(
              context,
              icon: Icons.error_outline,
              text: l10n.codeScanFailed,
              onRetry: _scan,
            );
          }
          if (outcome.foundNothing) {
            return _message(
              context,
              icon: Icons.qr_code_scanner_outlined,
              text: l10n.codeScanNoCodes,
              onRetry: _scan,
            );
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  l10n.codeScanFoundCount(outcome.codes.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              for (final code in outcome.codes)
                ScannedCodeCard(
                  code: code,
                  actions: ref.watch(scanActionsProvider(code)),
                  onAction: (action) => _runAction(code, action),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _busy(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String text,
    VoidCallback? onRetry,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.codeScanRetry),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runAction(ScannedCode code, ScanAction action) async {
    final l10n = AppLocalizations.of(context)!;
    final runner = ref.read(scanActionRunnerProvider);

    try {
      switch (action.type) {
        case ScanActionType.copy:
          await runner.copy(action.target);
          _say(l10n.codeScanCopied);

        case ScanActionType.copyWifiPassword:
          // Marked sensitive, so Android 13 and above keeps it out of the
          // clipboard preview that pops up on screen.
          await runner.copy(action.target, isSensitive: true);
          _say(l10n.codeScanPasswordCopied);

        case ScanActionType.connectWifi:
          final wifi = code.wifi;
          if (wifi == null) return;

          // The password is copied first, so the fallback path is useful
          // even when Android will not take the suggestion.
          if (wifi.security.needsPassword) {
            await runner.copy(wifi.password, isSensitive: true);
          }
          final accepted = await runner.connectWifi(wifi);
          _say(accepted ? l10n.codeScanWifiSuggested : l10n.codeScanWifiManual);

        case ScanActionType.saveToNotes:
          final saved = await ref
              .read(notesControllerProvider.notifier)
              .append(widget.mediaId, action.target);
          _say(saved ? l10n.codeScanSavedToNotes : l10n.notesSaveFailed);

        case ScanActionType.openUrl:
        case ScanActionType.dial:
        case ScanActionType.email:
        case ScanActionType.sms:
        case ScanActionType.showOnMap:
          await runner.open(action.target);
      }
    } on IntentException catch (error) {
      _say(error.hasNoApp ? l10n.codeScanOpenFailed : l10n.codeScanFailed);
    } catch (_) {
      _say(l10n.codeScanFailed);
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
