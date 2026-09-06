import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';

/// Everything the scanning device needs to reach the listening one.
///
/// This is the whole of the pairing secret. The session key lives here and
/// nowhere else: it is generated for one transfer, shown as a QR code, and
/// dropped when the session ends. It is never written to disk, never logged,
/// and never sent over the wire — the peer proves it has the key by using it,
/// not by presenting it.
///
/// That is what makes a home Wi-Fi safe enough. Another device on the same
/// router can see the port is open, but without having pointed a camera at
/// the other phone's screen it cannot read a byte of the transfer or push a
/// file into the gallery.
@immutable
class PairingPayload {
  /// Wire protocol version. A peer announcing a different one is refused.
  final int protocolVersion;

  /// IPv4 address of the listening device, on the local network.
  final String host;

  /// Port the listener bound to.
  final int port;

  /// The session key, base64url without padding.
  ///
  /// Random per session, [AppConstants.syncSessionKeyBytes] long.
  final String sessionKey;

  /// Name shown to the other user so they can tell they paired with the right
  /// phone. Free text from the device model; not identity, just a label.
  final String deviceName;

  /// The role the *listening* device has taken.
  ///
  /// The scanner takes the opposite one, so the two cannot both try to send.
  final SyncRole hostRole;

  const PairingPayload({
    required this.protocolVersion,
    required this.host,
    required this.port,
    required this.sessionKey,
    required this.deviceName,
    required this.hostRole,
  });

  /// The role the device that scanned this code should take.
  SyncRole get scannerRole => hostRole.opposite;

  PairingPayload copyWith({
    int? protocolVersion,
    String? host,
    int? port,
    String? sessionKey,
    String? deviceName,
    SyncRole? hostRole,
  }) {
    return PairingPayload(
      protocolVersion: protocolVersion ?? this.protocolVersion,
      host: host ?? this.host,
      port: port ?? this.port,
      sessionKey: sessionKey ?? this.sessionKey,
      deviceName: deviceName ?? this.deviceName,
      hostRole: hostRole ?? this.hostRole,
    );
  }

  /// Deliberately hides the session key.
  ///
  /// `toString` ends up in logs and in crash text, and hard rule "never log
  /// secrets" applies to this key as much as to a vault key.
  @override
  String toString() =>
      'PairingPayload(v$protocolVersion, $host:$port, '
      '$deviceName, ${hostRole.name}, key hidden)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PairingPayload &&
          runtimeType == other.runtimeType &&
          protocolVersion == other.protocolVersion &&
          host == other.host &&
          port == other.port &&
          sessionKey == other.sessionKey &&
          deviceName == other.deviceName &&
          hostRole == other.hostRole;

  @override
  int get hashCode => Object.hash(
    protocolVersion,
    host,
    port,
    sessionKey,
    deviceName,
    hostRole,
  );
}
