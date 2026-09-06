import 'package:flutter/foundation.dart';

/// Why a transfer session ended the way it did.
enum TransferFailure {
  /// No peer arrived before the pairing window closed.
  pairingTimeout,

  /// The peer's address was not on the local network.
  ///
  /// The refusal that keeps hard rule 2 honest. It happens before a socket is
  /// opened outward, and before a connected socket is read from.
  remoteAddressRefused,

  /// The peer could not prove it had the session key.
  handshakeRejected,

  /// The peer spoke a protocol version this build does not know.
  protocolMismatch,

  /// The connection dropped or the socket errored.
  connectionLost,

  /// Nothing crossed the socket for longer than the idle timeout.
  idleTimeout,

  /// The user stopped it.
  cancelled,

  /// The device has no usable local network address.
  noLocalNetwork,

  /// Something else went wrong.
  unknown,
}

/// What a finished transfer session did.
///
/// Like a batch, a transfer does not fall over because one file did. A photo
/// whose digest did not match is counted and dropped, and the rest still land.
@immutable
class TransferOutcome {
  /// Files written into the gallery on this device.
  final int receivedCount;

  /// Files handed to the peer and acknowledged.
  final int sentCount;

  /// Files the receiver already had, matched by digest, so they were not
  /// sent again.
  final int skippedCount;

  /// Files that were tried and did not make it, digest mismatches included.
  final int failedCount;

  /// Bytes actually moved.
  final int bytesTransferred;

  /// Why the session stopped early, or null if it finished normally.
  final TransferFailure? failure;

  const TransferOutcome({
    this.receivedCount = 0,
    this.sentCount = 0,
    this.skippedCount = 0,
    this.failedCount = 0,
    this.bytesTransferred = 0,
    this.failure,
  });

  /// A session that did nothing.
  static const TransferOutcome empty = TransferOutcome();

  /// A session that ended on [failure] having moved nothing.
  factory TransferOutcome.failed(TransferFailure failure) =>
      TransferOutcome(failure: failure);

  /// Whether the session ran to the end of its manifest.
  bool get succeeded => failure == null;

  /// Whether anything at all moved.
  bool get movedNothing => receivedCount == 0 && sentCount == 0;

  TransferOutcome copyWith({
    int? receivedCount,
    int? sentCount,
    int? skippedCount,
    int? failedCount,
    int? bytesTransferred,
    TransferFailure? failure,
    bool clearFailure = false,
  }) {
    return TransferOutcome(
      receivedCount: receivedCount ?? this.receivedCount,
      sentCount: sentCount ?? this.sentCount,
      skippedCount: skippedCount ?? this.skippedCount,
      failedCount: failedCount ?? this.failedCount,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferOutcome &&
          runtimeType == other.runtimeType &&
          receivedCount == other.receivedCount &&
          sentCount == other.sentCount &&
          skippedCount == other.skippedCount &&
          failedCount == other.failedCount &&
          bytesTransferred == other.bytesTransferred &&
          failure == other.failure;

  @override
  int get hashCode => Object.hash(
    receivedCount,
    sentCount,
    skippedCount,
    failedCount,
    bytesTransferred,
    failure,
  );
}
