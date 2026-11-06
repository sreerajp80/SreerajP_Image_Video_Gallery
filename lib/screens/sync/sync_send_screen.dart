import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/l10n/generated/app_localizations.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/providers/sync_providers.dart';
import 'package:in_sreerajp_imgvidgal/screens/sync/sync_receive_screen.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/pairing_codec.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/transfer_progress_view.dart';
import 'package:in_sreerajp_imgvidgal/widgets/sync/pairing_qr_scanner.dart';

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
  final TextEditingController _manual = TextEditingController();

  /// True once a code has been accepted, so the camera stops feeding frames.
  bool _handled = false;

  /// True when the user has switched to typing the code.
  bool _typing = false;

  String? _manualError;

  /// Read once in `initState`: Riverpod 3 does not allow `ref` in `dispose`,
  /// and the connection must still be closed there (hard rule 2).
  late final Future<void> Function() _stopSession;

  @override
  void initState() {
    super.initState();
    _stopSession = ref.read(transferSessionProvider).stop;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manual.dispose();
    // The connection goes with the screen, the same rule the receive side
    // follows for its listener.
    _stopSession();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(transferSessionProvider).stop();
    }
  }

  /// Called for every QR code the camera reads. Returns true when the code
  /// is a pairing code and the connection starts; the camera then stops.
  bool _onCode(String raw) {
    if (_handled) return false;

    final pairing = PairingCodec.decode(raw);
    // A QR code that is not ours, or one that points somewhere off the
    // local network. The camera simply keeps looking.
    if (pairing == null) return false;

    _handled = true;
    _connect(pairing);
    return true;
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
      setState(() => _manualError = l10n.bodySyncManualCodeInvalid);
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
    final state = ref.watch(transferStateProvider).value ?? session.state;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.titleSyncScan),
        actions: [
          if (state.phase == SyncPhase.idle)
            TextButton(
              onPressed: () {
                // The camera widget leaves the screen while typing, which
                // releases the camera; it starts again when it comes back.
                setState(() => _typing = !_typing);
              },
              child: Text(
                _typing
                    ? l10n.actionSyncScanCode
                    : l10n.actionSyncTypeCodeInstead,
              ),
            ),
          if (state.phase.isActive)
            TextButton(
              onPressed: () {
                session.cancel();
                session.stop();
              },
              child: Text(l10n.actionSyncStop),
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
                  l10n.bodySyncPairedWith(state.peerName),
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
                Text(l10n.labelSyncDone, style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                if (state.outcome != null) ...[
                  if (state.outcome!.sentCount > 0)
                    Text(l10n.bodySyncResultSent(state.outcome!.sentCount)),
                  if (state.outcome!.receivedCount > 0)
                    Text(
                      l10n.bodySyncResultReceived(state.outcome!.receivedCount),
                    ),
                  if (state.outcome!.skippedCount > 0)
                    Text(
                      l10n.bodySyncResultSkipped(state.outcome!.skippedCount),
                    ),
                  if (state.outcome!.failedCount > 0)
                    Text(
                      l10n.errorSyncResultFailed(state.outcome!.failedCount),
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
                  child: Text(l10n.actionSyncTypeCodeInstead),
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
        PairingQrScanner(
          onCode: _onCode,
          // A camera that will not start is not a dead end: the typed code
          // is offered instead, with the reason said plainly.
          errorBuilder: (context) => Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.no_photography_outlined, size: 48),
                const SizedBox(height: 16),
                Text(
                  l10n.bodySyncCameraPermission,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => setState(() => _typing = true),
                  child: Text(l10n.actionSyncTypeCodeInstead),
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
                l10n.titleSyncPairingHeading,
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
            l10n.titleSyncManualCodeHeading,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _manual,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: l10n.labelSyncManualCode,
              errorText: _manualError,
              hintText: 'XXXX-XXXX-XXXX-XXXX-XXXX-XXXX',
            ),
            onSubmitted: (_) => _submitManual(),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitManual,
            child: Text(l10n.actionSyncScanCode),
          ),
        ],
      ),
    );
  }
}
