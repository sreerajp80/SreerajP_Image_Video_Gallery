/// Which side of a transfer this device is on.
///
/// The role is chosen before pairing and does not change during a session.
/// The device that shows the QR code always listens; the device that scans it
/// always connects. Which of them sends the files is a separate question,
/// answered by this enum, so either phone can start the transfer.
enum SyncRole {
  /// This device offers files to the peer.
  send,

  /// This device takes files from the peer.
  receive;

  /// The role the other device must be in.
  SyncRole get opposite => this == send ? receive : send;
}

/// Where a transfer session has got to.
enum SyncPhase {
  /// Nothing started.
  idle,

  /// Listening, with the pairing code on screen.
  waiting,

  /// A peer connected and the handshake passed.
  ///
  /// On the receiving side this is also the wait between two sends.
  paired,

  /// The sender picks folders and albums for the next send.
  choosing,

  /// The sender is reading and hashing the files before offering them.
  preparing,

  /// Files are moving.
  transferring,

  /// One send finished; the sender can send more or finish.
  batchDone,

  /// Phone move: the app data and settings are being packed and sent, or
  /// received. Comes after the last batch, before [done].
  appData,

  /// Everything finished.
  done,

  /// The session ended early: refused, timed out, cancelled, or broken.
  failed;

  /// Whether a socket is open in this phase.
  ///
  /// Used by the screen to decide whether leaving needs a confirmation, and
  /// by the session to know there is something to close.
  bool get isActive =>
      this == waiting ||
      this == paired ||
      this == choosing ||
      this == preparing ||
      this == transferring ||
      this == batchDone ||
      this == appData;
}
