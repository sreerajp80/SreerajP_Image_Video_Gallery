import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/peer_info.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/phone_move_data.dart';
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

  /// What the other device said about itself: its install id and, when it
  /// is the receiver, its free space. Null until it has said.
  final PeerInfo? peer;

  final TransferProgress progress;

  /// What the peer is offering, once it has said.
  final TransferManifest? offer;

  /// What the last send did.
  final TransferOutcome? outcome;

  /// What every send in this pairing did, added up.
  final TransferOutcome totals;

  /// How many sends this pairing has carried.
  final int batchCount;

  /// Why it ended, for the message on screen.
  final TransferFailure? failure;

  /// True when the received files went to the app's own folder rather than
  /// the shared gallery, which happens only on Android 9 and below.
  final bool landedInAppFolder;

  /// Phone move, sending side: the app data and settings reached the other
  /// phone.
  final bool appDataSent;

  /// Phone move, receiving side: the app data and settings that arrived,
  /// waiting for the user to look at them and say yes. Null when none came.
  final PhoneMoveData? receivedAppData;

  /// Receiving side: how many files went into this phone's private vault.
  final int vaultReceivedCount;

  /// Sending side: ids of the files the other phone now holds, in this
  /// pairing. Every file it acknowledged, and every file it said it already
  /// had. A file that failed is not here, so it can be offered again.
  ///
  /// Kept here, not in the picker widget: the picker is rebuilt after every
  /// send and would forget.
  final Set<String> deliveredIds;

  /// Sending side: ids of every file put in a send in this pairing, whether
  /// it arrived or not.
  final Set<String> triedIds;

  const TransferSessionState({
    this.phase = SyncPhase.idle,
    this.role = SyncRole.send,
    this.pairing,
    this.manualCode,
    this.peerName = '',
    this.peer,
    this.progress = TransferProgress.zero,
    this.offer,
    this.outcome,
    this.totals = TransferOutcome.empty,
    this.batchCount = 0,
    this.failure,
    this.landedInAppFolder = false,
    this.appDataSent = false,
    this.receivedAppData,
    this.vaultReceivedCount = 0,
    this.deliveredIds = const <String>{},
    this.triedIds = const <String>{},
  });

  /// The receiver's free space, in bytes, or null when unknown.
  int? get peerFreeBytes => peer?.freeBytes;

  TransferSessionState copyWith({
    SyncPhase? phase,
    SyncRole? role,
    PairingPayload? pairing,
    String? manualCode,
    String? peerName,
    PeerInfo? peer,
    TransferProgress? progress,
    TransferManifest? offer,
    TransferOutcome? outcome,
    TransferOutcome? totals,
    int? batchCount,
    TransferFailure? failure,
    bool? landedInAppFolder,
    bool? appDataSent,
    PhoneMoveData? receivedAppData,
    int? vaultReceivedCount,
    Set<String>? deliveredIds,
    Set<String>? triedIds,
    bool clearFailure = false,
    bool clearOutcome = false,
  }) {
    return TransferSessionState(
      phase: phase ?? this.phase,
      role: role ?? this.role,
      pairing: pairing ?? this.pairing,
      manualCode: manualCode ?? this.manualCode,
      peerName: peerName ?? this.peerName,
      peer: peer ?? this.peer,
      progress: progress ?? this.progress,
      offer: offer ?? this.offer,
      outcome: clearOutcome ? null : (outcome ?? this.outcome),
      totals: totals ?? this.totals,
      batchCount: batchCount ?? this.batchCount,
      failure: clearFailure ? null : (failure ?? this.failure),
      landedInAppFolder: landedInAppFolder ?? this.landedInAppFolder,
      appDataSent: appDataSent ?? this.appDataSent,
      receivedAppData: receivedAppData ?? this.receivedAppData,
      vaultReceivedCount: vaultReceivedCount ?? this.vaultReceivedCount,
      deliveredIds: deliveredIds ?? this.deliveredIds,
      triedIds: triedIds ?? this.triedIds,
    );
  }
}

/// Adds two send results together.
TransferOutcome addOutcomes(TransferOutcome a, TransferOutcome b) {
  return TransferOutcome(
    receivedCount: a.receivedCount + b.receivedCount,
    sentCount: a.sentCount + b.sentCount,
    skippedCount: a.skippedCount + b.skippedCount,
    failedCount: a.failedCount + b.failedCount,
    bytesTransferred: a.bytesTransferred + b.bytesTransferred,
    failure: b.failure ?? a.failure,
  );
}
