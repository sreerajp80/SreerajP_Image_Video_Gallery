import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/qr_frame_codec.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/viewer_providers.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/qr_sync_failure.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/camera_caption.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/pairing_qr_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum _Step { scanKey, preparing, playing, failed }

/// Sends this app's data (no photos) to another phone through QR codes.
///
/// 1. Scan the key code the other phone shows.
/// 2. The data is gathered, compressed, encrypted under that key and split.
/// 3. The codes play in a loop until the other phone has read them all.
///
/// No network is used. The screen stays on while the codes play.
class QrSyncSendScreen extends ConsumerStatefulWidget {
  const QrSyncSendScreen({super.key});

  @override
  ConsumerState<QrSyncSendScreen> createState() => _QrSyncSendScreenState();
}

class _QrSyncSendScreenState extends ConsumerState<QrSyncSendScreen> {
  _Step _step = _Step.scanKey;
  List<String> _frames = const <String>[];
  int _shown = 0;
  Timer? _timer;
  String? _error;
  bool _keyTaken = false;

  late final Future<void> Function(bool keepOn) _setKeepScreenOn;

  @override
  void initState() {
    super.initState();
    _setKeepScreenOn = ref.read(screenSettingsServiceProvider).setKeepScreenOn;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _setKeepScreenOn(false);
    super.dispose();
  }

  bool _onCode(String raw) {
    if (_keyTaken) return false;
    final key = QrFrameCodec.decodeKey(raw);
    // Not our key code: the camera keeps looking.
    if (key == null) return false;
    _keyTaken = true;
    unawaited(_prepare(key));
    return true;
  }

  Future<void> _prepare(QrSyncKey key) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _step = _Step.preparing);
    try {
      final version = await ref.read(appVersionProvider.future);
      final built = await ref
          .read(qrDataSyncServiceProvider)
          .buildFrames(key: key, appVersion: version);
      if (!mounted) return;
      _frames = built.frames;
      _shown = 0;
      setState(() => _step = _Step.playing);
      unawaited(_setKeepScreenOn(true));
      _timer = Timer.periodic(
        const Duration(milliseconds: AppConstants.qrSyncFrameMillis),
        (_) {
          if (!mounted) return;
          setState(() => _shown = (_shown + 1) % _frames.length);
        },
      );
    } on QrSyncException catch (error) {
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _error = switch (error.failure) {
          QrSyncFailure.nothingToSend => l10n.bodyQrSyncNothing,
          QrSyncFailure.tooBig => l10n.errorQrSyncTooBig(error.frameCount),
          QrSyncFailure.unreadable => l10n.errorQrSyncFailed,
        };
      });
    } catch (error) {
      AppLogger.warning('Preparing QR sync data failed', error: error);
      if (!mounted) return;
      setState(() {
        _step = _Step.failed;
        _error = l10n.errorQrSyncFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.titleQrSyncSend)),
      body: SafeArea(child: _body(context, l10n)),
    );
  }

  Widget _body(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    switch (_step) {
      case _Step.scanKey:
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
            CameraCaption(text: l10n.bodyQrSyncScanKey),
          ],
        );

      case _Step.preparing:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n.labelQrSyncPreparing),
            ],
          ),
        );

      case _Step.playing:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                l10n.bodyQrSyncShowFrames,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth.clamp(200.0, 360.0);
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      // Fixed white, whatever the theme. A scanner needs the
                      // contrast.
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: QrImageView(
                      data: _frames[_shown],
                      size: size - 24,
                      backgroundColor: Colors.white,
                      // Left at the low error correction default: it keeps a
                      // dense code as small as it can be, and a misread
                      // frame is simply read again on the next loop.
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Text(
                '${_shown + 1} / ${_frames.length}',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.bodyQrSyncFrameCount(_frames.length),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: Text(l10n.actionSyncFinish),
              ),
            ],
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
                  _error ?? l10n.errorQrSyncFailed,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
    }
  }
}
