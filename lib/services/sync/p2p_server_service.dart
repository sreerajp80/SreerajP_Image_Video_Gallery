import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/local_address_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';

/// Listens for one peer on the local network.
///
/// Three things about this class are the whole reason hard rule 2 can be
/// narrowed rather than broken:
///
/// 1. **It binds to one address, never `0.0.0.0`.** The socket exists on the
///    device's own Wi-Fi interface and nowhere else.
/// 2. **It refuses a peer that is not local.** The remote address is checked
///    the moment a connection arrives, before a single byte is read from it.
/// 3. **It lives only as long as the screen.** [stop] closes everything, the
///    transfer screen calls it on the way out and on backgrounding, and a
///    pairing timeout closes it on its own. There is no background service
///    and no port left open.
///
/// It accepts exactly one peer. A second connection while one is in progress
/// is closed immediately: a transfer is between two phones, and quietly
/// accepting a third would be a surprise nobody asked for.
class P2pServerService {
  ServerSocket? _server;
  StreamSubscription<Socket>? _subscription;
  Timer? _pairingTimer;
  Completer<P2pConnection>? _waiting;
  bool _hasPeer = false;

  /// The address the listener is bound to, or null when it is not running.
  String? get boundAddress => _server?.address.address;

  /// The port the operating system handed out, or null when not running.
  int? get boundPort => _server?.port;

  bool get isListening => _server != null;

  /// Starts listening on [address].
  ///
  /// [address] must be one the transfer feature may bind to; anything else is
  /// refused here rather than trusted to have been checked upstream.
  ///
  /// Returns the port that was bound, which goes into the pairing code.
  Future<int> start({required String address}) async {
    if (_server != null) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'The listener is already running',
      );
    }

    if (LocalAddressRules.isUnspecified(address)) {
      // Binding here would put the listener on every interface the device
      // has, which is exactly what the narrowed rule rules out.
      throw const TransferSessionException(
        TransferFailure.remoteAddressRefused,
        'The listener will not bind to every interface',
      );
    }
    if (!LocalAddressRules.isBindable(address)) {
      throw const TransferSessionException(
        TransferFailure.remoteAddressRefused,
        'That is not a local network address',
      );
    }

    try {
      _server = await ServerSocket.bind(
        address,
        AppConstants.syncEphemeralPort,
        shared: false,
      );
    } catch (error) {
      throw const TransferSessionException(
        TransferFailure.noLocalNetwork,
        'Could not open a port on this network',
      );
    }

    _subscription = _server!.listen(
      _onConnection,
      onError: (Object _) {},
      cancelOnError: false,
    );

    return _server!.port;
  }

  /// Waits for a peer to connect and finish the handshake.
  ///
  /// Gives up after [AppConstants.syncPairingTimeoutSeconds], so a pairing
  /// code left on screen does not hold a port open all day.
  Future<P2pConnection> waitForPeer({
    required Uint8List sessionKey,
    required String deviceName,
  }) async {
    if (_server == null) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'The listener is not running',
      );
    }

    _sessionKey = sessionKey;
    _deviceName = deviceName;

    final completer = Completer<P2pConnection>();
    _waiting = completer;

    _pairingTimer = Timer(
      const Duration(seconds: AppConstants.syncPairingTimeoutSeconds),
      () {
        if (!completer.isCompleted) {
          completer.completeError(
            const TransferSessionException(
              TransferFailure.pairingTimeout,
              'No device connected in time',
            ),
          );
          unawaited(stop());
        }
      },
    );

    try {
      return await completer.future;
    } finally {
      _pairingTimer?.cancel();
      _pairingTimer = null;
      _waiting = null;
    }
  }

  Uint8List? _sessionKey;
  String _deviceName = '';

  Future<void> _onConnection(Socket socket) async {
    final remote = socket.remoteAddress.address;

    // A transfer is between two phones. A second one is not joined.
    if (_hasPeer) {
      socket.destroy();
      return;
    }

    // The check that makes the permission narrow. It happens before the
    // socket is read from, so a connection from off the local network never
    // gets to send this app a single byte.
    if (!LocalAddressRules.isBindable(remote)) {
      socket.destroy();
      return;
    }

    final key = _sessionKey;
    final waiting = _waiting;
    if (key == null || waiting == null || waiting.isCompleted) {
      socket.destroy();
      return;
    }

    _hasPeer = true;
    socket.setOption(SocketOption.tcpNoDelay, true);

    final connection = P2pConnection(
      duplex: SocketDuplex(socket),
      sessionKey: key,
    );
    connection.start();

    try {
      await connection.performServerHandshake(deviceName: _deviceName);
      // The listener has done its job. Closing it now means the port is gone
      // for the whole of the transfer, not just afterwards.
      await _closeListener();
      if (!waiting.isCompleted) waiting.complete(connection);
    } catch (error) {
      await connection.close();
      _hasPeer = false;
      if (!waiting.isCompleted) {
        waiting.completeError(
          error is TransferSessionException
              ? error
              : const TransferSessionException(
                  TransferFailure.handshakeRejected,
                  'The other device could not be paired with',
                ),
        );
      }
      unawaited(stop());
    }
  }

  Future<void> _closeListener() async {
    await _subscription?.cancel();
    _subscription = null;
    try {
      await _server?.close();
    } catch (_) {
      // Already closed.
    }
    _server = null;
  }

  /// Closes the listener and forgets the session key.
  ///
  /// Safe to call more than once. The transfer screen calls it on the way
  /// out, on backgrounding, and on every failure path, so the port is never
  /// left open because an error took an unusual route.
  Future<void> stop() async {
    _pairingTimer?.cancel();
    _pairingTimer = null;

    await _closeListener();

    // The key exists for one session. It is dropped here rather than left in
    // the heap for however long this object happens to live.
    _sessionKey = null;
    _hasPeer = false;

    final waiting = _waiting;
    if (waiting != null && !waiting.isCompleted) {
      waiting.completeError(
        const TransferSessionException(
          TransferFailure.cancelled,
          'The transfer was stopped',
        ),
      );
    }
    _waiting = null;
  }
}
