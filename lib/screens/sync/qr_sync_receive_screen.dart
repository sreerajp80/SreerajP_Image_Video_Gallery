import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/qr_frame_codec.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/widgets/backup/restore_preview_sheet.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/camera_caption.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/pairing_qr_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum _Step { loading, showKey, scanning, opening, applying, done, failed }

/// Receives app data (no photos) from another phone through QR codes.
///
/// 1. Show a one-time key code; the other phone scans it.
/// 2. Read the other phone's moving codes, in any order, until all are in.
/// 3. Open them and show the restore preview. Nothing changes until the
///    user says yes, and even then nothing here is removed or blanked.
class QrSyncReceiveScreen extends ConsumerStatefulWidget {
  const QrSyncReceiveScreen({super.key});

  @override
  ConsumerState<QrSyncReceiveScreen> createState() =>
      _QrSyncReceiveScreenState();
}

class _QrSyncReceiveScreenState extends ConsumerState<QrSyncReceiveScreen> {
  _Step _step = _Step.loading;
  QrSyncKey? _key;
  QrFrameCollector? _collector;
  int _read = 0;
  int _total = 0;
  String? _message;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _makeKey());
  }

  Future<void> _makeKey() async {
    try {
      final key = await ref.read(qrDataSyncServiceProvider).newKey();
      if (!mounted) return;
      setState(() {
        _key = key;
        _collector = QrFrameCollector(sessionId: key.sessionId);
        _step = _Step.showKey;
      });
    } catch (error) {
      AppLogger.warning('Making a QR sync key failed', error: error);
      _failWith(null);
    }
  }

  /// Called for each code the camera reads. Returns true once every frame is
  /// in, which stops the camera.
  bool _onCode(String raw) {
    final collector = _collector;
    if (collector == null || _step != _Step.scanning) return false;
    if (collector.add(raw)) {
      setState(() {
        _read = collector.received;
        _total = collector.total;
      });
    }
    if (!collector.isComplete) return false;
    unawaited(_open());
    return true;
  }

  Future<void> _open() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _step = _Step.opening);
    try {
      final archive = await ref
          .read(qrDataSyncServiceProvider)
          .open(_collector!, _key!);
      if (!mounted) return;

      // Nothing has been written yet. This is the last point at which
      // walking away costs the user nothing.
      final confirmed = await RestorePreviewSheet.show(context, archive.plan);
      if (!mounted) return;
      if (confirmed != true) {
        Navigator.of(context).maybePop();
        return;
      }

      setState(() => _step = _Step.applying);
      await ref.read(restoreServiceProvider).applyPlan(archive);
      if (!mounted) return;
      setState(() {
        _step = _Step.done;
        _message = l10n.labelRestoreDone;
      });
    } catch (error) {
      AppLogger.warning('Opening QR sync data failed', error: error);
      _failWith(l10n.errorQrSyncFailed);
    }
  }

  void _failWith(String? message) {
    if (!mounted) return;
    setState(() {
      _step = _Step.failed;
      _message = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleQrSyncReceive)),
      body: SafeArea(child: _body(context, l10n)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    switch (_step) {
      case _Step.loading:
      case _Step.opening:
      case _Step.applying:
        return const Center(child: CircularProgressIndicator());

      case _Step.showKey:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                l10n.bodyQrSyncShowKey,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // Fixed white, whatever the theme. A scanner needs the
                  // contrast.
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: QrFrameCodec.encodeKey(_key!),
                  size: 240,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.M,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => setState(() => _step = _Step.scanning),
                child: Text(l10n.actionQrSyncNext),
              ),
            ],
          ),
        );

      case _Step.scanning:
        return Stack(
          fit: StackFit.expand,
          children: [
            PairingQrScanner(
              onCode: _onCode,
              errorBuilder: (context) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    l10n.bodySyncCameraPermission,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            CameraCaption(
              text: _total == 0
                  ? l10n.bodyQrSyncScanFrames
                  : l10n.bodyQrSyncFramesProgress(_read, _total),
            ),
          ],
        );

      case _Step.done:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(_message ?? '', textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(l10n.actionSyncFinish),
                ),
              ],
            ),
          ),
        );

      case _Step.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  _message ?? l10n.errorQrSyncFailed,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }
}
