import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/sync/sync_receive_screen.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/pairing_codec.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_session_service.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_progress_view.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Reads the other phone's pairing code and connects to it.
///
/// The camera is a convenience. Every path through this screen also works by
/// typing the code, so a device with no camera, a refused permission, or a
/// scanner that will not focus is never stuck.
///
/// A scanned code is not trusted. [PairingCodec] refuses a wrong version, a
/// bad checksum, or an address off the local network before it becomes a
/// payload, and the client checks the address again before opening a socket.
class SyncSendScreen extends ConsumerStatefulWidget {
  const SyncSendScreen({super.key});

  @override
  ConsumerState<SyncSendScreen> createState() => _SyncSendScreenState();
}

class _SyncSendScreenState extends ConsumerState<SyncSendScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _scanner = MobileScannerController(
    // One format, so the scanner does not spend effort looking for barcodes
    // nobody is going to show it.
    formats: const <BarcodeFormat>[BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  final TextEditingController _manual = TextEditingController();

  /// True once a code has been accepted, so the camera stops feeding frames.
  bool _handled = false;

  /// True when the user has switched to typing the code.
  bool _typing = false;

  String? _manualError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanner.dispose();
    _manual.dispose();
    // The connection goes with the screen, the same rule the receive side
    // follows for its listener.
    ref.read(transferSessionProvider).stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(transferSessionProvider).stop();
    }
  }

  /// Called for every frame the scanner decodes.
  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      final pairing = PairingCodec.decode(raw);
      // A QR code that is not ours, or one that points somewhere off the
      // local network. The camera simply keeps looking.
      if (pairing == null) continue;

      _handled = true;
      _scanner.stop();
      _connect(pairing);
      return;
    }
  }

  /// Takes a typed code and connects on it.
  ///
  /// The typed code carries the same pairing secret the QR code does, so the
  /// key it produces is exactly the key the other phone is using. A mistyped
  /// code produces a different key, and the handshake refuses it.
  void _submitManual() {
    final l10n = AppLocalizations.of(context)!;
    final decoded = PairingCodec.decodeManual(_manual.text);

    if (decoded == null) {
      setState(() => _manualError = l10n.syncManualCodeInvalid);
      return;
    }

    setState(() => _manualError = null);
    _handled = true;

    // The typed code has no room for the other phone's name, which is only a
    // label anyway. Everything that matters — the address, the port and the
    // pairing secret — is in it.
    _connect(
      PairingPayload(
        protocolVersion: AppConstants.syncProtocolVersion,
        host: decoded.host,
        port: decoded.port,
        sessionKey: base64Url.encode(decoded.keyPrefix).replaceAll('=', ''),
        deviceName: '',
        hostRole: ref.read(syncRoleProvider).opposite,
      ),
    );
  }

  Future<void> _connect(PairingPayload pairing) async {
    ref.read(scannedPairingProvider.notifier).state = pairing;

    final outbox = ref.read(transferOutboxProvider);
    await ref
        .read(transferSessionProvider)
        .join(
          pairing: pairing,
          deviceName: 'Gallery',
          toOffer: pairing.scannerRole == SyncRole.send ? outbox : const [],
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(transferSessionProvider);
    final state = ref.watch(transferStateProvider).valueOrNull ?? session.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.syncScanTitle),
        actions: [
          if (state.phase == SyncPhase.idle)
            TextButton(
              onPressed: () {
                setState(() => _typing = !_typing);
                if (_typing) {
                  _scanner.stop();
                } else {
                  _scanner.start();
                }
              },
              child: Text(
                _typing ? l10n.syncScanCode : l10n.syncTypeCodeInstead,
              ),
            ),
          if (state.phase.isActive)
            TextButton(
              onPressed: () {
                session.cancel();
                session.stop();
              },
              child: Text(l10n.syncStop),
            ),
        ],
      ),
      body: SafeArea(child: _body(context, l10n, state)),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    TransferSessionState state,
  ) {
    final theme = Theme.of(context);

    switch (state.phase) {
      case SyncPhase.idle:
        return _typing ? _manualEntry(l10n) : _cameraView(l10n);

      case SyncPhase.waiting:
      case SyncPhase.paired:
      case SyncPhase.transferring:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (state.peerName.isNotEmpty)
                Text(
                  l10n.syncPairedWith(state.peerName),
                  style: theme.textTheme.titleMedium,
                ),
              const SizedBox(height: 24),
              TransferProgressView(progress: state.progress),
            ],
          ),
        );

      case SyncPhase.done:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(l10n.syncDone, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (state.outcome != null) ...[
                  if (state.outcome!.sentCount > 0)
                    Text(l10n.syncResultSent(state.outcome!.sentCount)),
                  if (state.outcome!.receivedCount > 0)
                    Text(l10n.syncResultReceived(state.outcome!.receivedCount)),
                  if (state.outcome!.skippedCount > 0)
                    Text(l10n.syncResultSkipped(state.outcome!.skippedCount)),
                  if (state.outcome!.failedCount > 0)
                    Text(
                      l10n.syncResultFailed(state.outcome!.failedCount),
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                ],
              ],
            ),
          ),
        );

      case SyncPhase.failed:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  failureMessage(l10n, state.failure),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                // Always a way back that does not need the camera.
                OutlinedButton(
                  onPressed: () => setState(() {
                    _handled = false;
                    _typing = true;
                  }),
                  child: Text(l10n.syncTypeCodeInstead),
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _cameraView(AppLocalizations l10n) {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scanner,
          onDetect: _onDetect,
          // A camera that will not start is not a dead end: the typed code
          // is offered instead, with the reason said plainly.
          errorBuilder: (context, error, child) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography_outlined, size: 48),
                const SizedBox(height: 16),
                Text(l10n.syncCameraPermission, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => setState(() => _typing = true),
                  child: Text(l10n.syncTypeCodeInstead),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 32,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                l10n.syncPairingHeading,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _manualEntry(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.syncManualCodeHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manual,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.syncManualCodeLabel,
              errorText: _manualError,
              hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
            ),
            onSubmitted: (_) => _submitManual(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitManual,
            child: Text(l10n.syncScanCode),
          ),
        ],
      ),
    );
  }
}
