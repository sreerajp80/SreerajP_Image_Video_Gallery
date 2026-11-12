/// Why the sending phone opened a Wi-Fi transfer.
///
/// Only the sender needs this. It decides what the picker offers after
/// pairing and what happens on Finish. The receiving phone takes whatever
/// arrives, so it does not need to know.
enum TransferPurpose {
  /// The user selected photos and tapped "Send to device". Only those photos
  /// are offered.
  quickSend,

  /// Settings › Device Sync › "Move to a new phone". Folders and albums are
  /// offered, and the whole app data and settings go on Finish. The vault
  /// goes too, if the user turns it on.
  phoneMove,
}
