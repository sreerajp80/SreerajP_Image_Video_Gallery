import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/local_address_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';

/// Connects to the device whose pairing code was scanned.
///
/// The address is checked before a socket is opened, not after. That ordering
/// is the point: a QR code is untrusted input from an unknown screen, and the
/// app must never make an outbound connection to whatever it happens to name.
/// A code carrying a public address is refused here, and it was already
/// refused when it was decoded — two checks, because this is the one thing
/// that would turn a narrow permission back into a broad one.
class P2pClientService {
  Socket? _socket;
  P2pConnection? _connection;

  bool get isConnected => _connection != null && !_connection!.isClosed;

  /// Connects to [payload]'s device and completes the handshake.
  ///
  /// Throws [TransferSessionException] if the address is not local, nothing
  /// is listening, or the peer cannot prove it holds the session key.
  Future<P2pConnection> connect({
    required PairingPayload payload,
    required Uint8List sessionKey,
    required String deviceName,
  }) async {
    // Before the socket. Always before the socket.
    if (!LocalAddressRules.isConnectable(payload.host, payload.port)) {
      throw const TransferSessionException(
        TransferFailure.remoteAddressRefused,
        'That code points somewhere off the local network',
      );
    }

    try {
      _socket = await Socket.connect(
        payload.host,
        payload.port,
        timeout: const Duration(
          seconds: AppConstants.syncConnectTimeoutSeconds,
        ),
      );
    } catch (_) {
      throw const TransferSessionException(
        TransferFailure.connectionLost,
        'Could not reach the other device',
      );
    }

    // Belt and braces: a redirect or a stale DNS answer cannot land the
    // socket somewhere else, but checking what was actually connected to
    // costs nothing and closes the question.
    final remote = _socket!.remoteAddress.address;
    if (!LocalAddressRules.isBindable(remote)) {
      _socket!.destroy();
      _socket = null;
      throw const TransferSessionException(
        TransferFailure.remoteAddressRefused,
        'The connection went somewhere off the local network',
      );
    }

    _socket!.setOption(SocketOption.tcpNoDelay, true);

    final connection = P2pConnection(
      duplex: SocketDuplex(_socket!),
      sessionKey: sessionKey,
    );
    connection.start();

    try {
      await connection.performClientHandshake(deviceName: deviceName);
      _connection = connection;
      return connection;
    } catch (error) {
      await connection.close();
      _socket = null;
      rethrow;
    }
  }

  /// Closes the connection.
  ///
  /// Safe to call more than once.
  Future<void> disconnect() async {
    await _connection?.close();
    _connection = null;
    try {
      _socket?.destroy();
    } catch (_) {
      // Already gone.
    }
    _socket = null;
  }
}
