import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_progress.dart';

/// Everything the transfer screen needs to draw itself.
class TransferSessionState {
  final SyncPhase phase;
  final SyncRole role;

  /// The pairing code to show, when this device is the one listening.
  final PairingPayload? pairing;

  /// The typed fallback code for the same pairing.
  final String? manualCode;

  /// The other device's name, once paired.
  final String peerName;

  final TransferProgress progress;

  /// What the peer is offering, once it has said.
  final TransferManifest? offer;

  final TransferOutcome? outcome;

  /// Why it ended, for the message on screen.
  final TransferFailure? failure;

  /// True when the received files went to the app's own folder rather than
  /// the shared gallery, which happens only on Android 9 and below.
  final bool landedInAppFolder;

  const TransferSessionState({
    this.phase = SyncPhase.idle,
    this.role = SyncRole.send,
    this.pairing,
    this.manualCode,
    this.peerName = '',
    this.progress = TransferProgress.zero,
    this.offer,
    this.outcome,
    this.failure,
    this.landedInAppFolder = false,
  });

  TransferSessionState copyWith({
    SyncPhase? phase,
    SyncRole? role,
    PairingPayload? pairing,
    String? manualCode,
    String? peerName,
    TransferProgress? progress,
    TransferManifest? offer,
    TransferOutcome? outcome,
    TransferFailure? failure,
    bool? landedInAppFolder,
    bool clearFailure = false,
  }) {
    return TransferSessionState(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      pairing: pairing ?? this.pairing,
      manualCode: manualCode ?? this.manualCode,
      peerName: peerName ?? this.peerName,
      progress: progress ?? this.progress,
      offer: offer ?? this.offer,
      outcome: outcome ?? this.outcome,
      failure: clearFailure ? null : (failure ?? this.failure),
      landedInAppFolder: landedInAppFolder ?? this.landedInAppFolder,
    );
  }
}
