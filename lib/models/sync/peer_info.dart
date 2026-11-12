import 'package:flutter/foundation.dart';

/// What one side of a transfer tells the other about itself.
///
/// Sent inside the encrypted session, never in the clear, because the install
/// id is stable and should not be readable by other devices on the Wi-Fi.
@immutable
class PeerInfo {
  /// Longest install id accepted from a peer.
  static const int maxInstallIdLength = 64;

  /// This install's random id. Not a hardware id, and not secret.
  ///
  /// Lets the sender remember which files it already sent to *this* phone.
  final String installId;

  /// Free space on the receiving side, in bytes, or null when unknown.
  ///
  /// Only the receiver fills it in. The sender uses it to size each send.
  final int? freeBytes;

  /// Whether the receiving side has a vault that can take vault files.
  ///
  /// Only the receiver fills it in. The sender sends no vault files to a
  /// phone that says false.
  final bool vaultReady;

  const PeerInfo({
    required this.installId,
    this.freeBytes,
    this.vaultReady = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'installId': installId,
    if (freeBytes != null) 'freeBytes': freeBytes,
    if (vaultReady) 'vaultReady': true,
  };

  /// Reads a peer's info, or null when it is not usable.
  ///
  /// The install id is untrusted input: it is only kept if it is short and
  /// made of plain letters, digits and dashes, because it is stored in the
  /// database as a key.
  static PeerInfo? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['installId'];
    if (id is! String ||
        id.isEmpty ||
        id.length > maxInstallIdLength ||
        !RegExp(r'^[A-Za-z0-9-]+$').hasMatch(id)) {
      return null;
    }
    final free = json['freeBytes'];
    return PeerInfo(
      installId: id,
      freeBytes: free is num && free >= 0 ? free.toInt() : null,
      vaultReady: json['vaultReady'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerInfo &&
          installId == other.installId &&
          freeBytes == other.freeBytes &&
          vaultReady == other.vaultReady;

  @override
  int get hashCode => Object.hash(installId, freeBytes, vaultReady);
}
