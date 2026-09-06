import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_protocol.dart';

/// Thrown when a session has to end.
class TransferSessionException implements Exception {
  final TransferFailure failure;
  final String message;

  const TransferSessionException(this.failure, this.message);

  @override
  String toString() => 'TransferSessionException(${failure.name}): $message';
}

/// Somewhere bytes can be written and read.
///
/// A socket, in production. An interface rather than a `Socket` so the whole
/// protocol — handshake, framing, ciphers, file exchange — can be driven over
/// a pair of in-memory pipes in a test, with no network and no ports.
abstract class TransferDuplex {
  /// Bytes arriving from the peer.
  Stream<Uint8List> get incoming;

  /// Sends bytes to the peer.
  void add(List<int> bytes);

  /// Closes the connection.
  Future<void> close();

  /// The peer's address, for the local-network check.
  String get remoteAddress;
}

/// One authenticated, encrypted conversation with a peer.
///
/// Owns the framing, the handshake and the ciphers. It does not know what a
/// photo is: moving files is layered on top by the session service, so this
/// class stays about the wire and can be tested as such.
///
/// ### How each side knows the other scanned the code
///
/// The session key never crosses the wire. Instead:
///
/// * the client opens with a random challenge;
/// * the server answers with an HMAC of it under the session key, plus a
///   challenge of its own — so the client knows it reached the right phone
///   and not something squatting on the port;
/// * every frame after that is AES-GCM encrypted under the same key, so the
///   *client* proves it has the key simply by sending one the server can
///   decrypt. A peer without the key cannot forge a frame that passes the tag
///   check, which makes the proof implicit but no weaker.
///
/// A device on the same Wi-Fi that never saw the QR code gets as far as
/// opening a socket and no further.
class P2pConnection {
  final TransferDuplex _duplex;
  final Uint8List _sessionKey;
  final TransferCryptoService _crypto;

  final FrameReader _reader = FrameReader();

  /// Frames that have arrived and not yet been asked for.
  ///
  /// A queue rather than a stream because the protocol is a conversation:
  /// each step awaits the next frame, one at a time. A single-subscription
  /// stream cannot be awaited twice, and making it a broadcast stream would
  /// drop any frame that landed between two awaits — which on a fast local
  /// network is most of them.
  final List<TransferFrame> _ready = <TransferFrame>[];

  /// Whoever is currently waiting for the next frame.
  Completer<TransferFrame>? _waiting;

  /// The failure that ended the session, if one has.
  TransferSessionException? _failure;

  StreamSubscription<Uint8List>? _subscription;
  Timer? _idleTimer;
  bool _closed = false;

  /// The peer's self-reported name. Never trusted for anything but display.
  String peerName = '';

  P2pConnection({
    required TransferDuplex duplex,
    required Uint8List sessionKey,
    TransferCryptoService? crypto,
  }) : _duplex = duplex,
       _sessionKey = sessionKey,
       _crypto = crypto ?? TransferCryptoService();

  bool get isClosed => _closed;

  /// How many frames have arrived and not yet been read.
  int get bufferedFrames => _ready.length;

  /// Starts reading. Call once, before either handshake.
  void start() {
    _subscription = _duplex.incoming.listen(
      _onBytes,
      onError: (Object error) =>
          _fail(TransferFailure.connectionLost, 'The connection failed'),
      onDone: () {
        if (!_closed) {
          _fail(TransferFailure.connectionLost, 'The peer disconnected');
        }
      },
      cancelOnError: true,
    );
    _touch();
  }

  void _onBytes(Uint8List bytes) {
    _touch();
    try {
      for (final frame in _reader.add(bytes)) {
        _deliver(frame);
      }
    } on TransferProtocolException catch (error) {
      // A bad length or an unknown type is fatal. Trying to resynchronise a
      // byte stream after one is how a parser gets talked into an allocation
      // it cannot afford.
      _fail(TransferFailure.connectionLost, error.message);
    }
  }

  /// Resets the idle clock.
  ///
  /// A socket nothing crosses is closed rather than left open, so the
  /// listener's lifetime really is "while something is happening", not "until
  /// somebody remembers".
  void _touch() {
    _idleTimer?.cancel();
    _idleTimer = Timer(
      const Duration(seconds: AppConstants.syncIdleTimeoutSeconds),
      () => _fail(TransferFailure.idleTimeout, 'Nothing happened for a while'),
    );
  }

  /// Hands a frame to whoever is waiting, or queues it until someone asks.
  void _deliver(TransferFrame frame) {
    final waiting = _waiting;
    if (waiting != null && !waiting.isCompleted) {
      _waiting = null;
      waiting.complete(frame);
      return;
    }
    _ready.add(frame);
  }

  /// Ends the session and wakes anyone waiting on a frame.
  ///
  /// The failure is remembered, so a later read fails the same way rather
  /// than hanging on a connection that is already gone.
  void _fail(TransferFailure failure, String message) {
    if (_closed) return;
    _failure ??= TransferSessionException(failure, message);

    final waiting = _waiting;
    if (waiting != null && !waiting.isCompleted) {
      _waiting = null;
      waiting.completeError(_failure!);
    }
    unawaited(close());
  }

  // -------------------------------------------------------------- handshake

  /// Opens the conversation from the connecting side.
  ///
  /// Sends a challenge and checks the answer. Throws if the peer cannot
  /// produce one, speaks another protocol version, or says nothing in time.
  Future<void> performClientHandshake({required String deviceName}) async {
    final challenge = await _crypto.newChallenge();

    _sendPlain(FrameType.hello, <String, dynamic>{
      'version': AppConstants.syncProtocolVersion,
      'challenge': base64.encode(challenge),
      'deviceName': deviceName,
    });

    final welcome = await _expect(FrameType.welcome);
    final body = welcome.json;
    if (body == null) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The peer sent a reply that could not be read',
      );
    }

    final version = (body['version'] as num?)?.toInt();
    if (version != AppConstants.syncProtocolVersion) {
      throw const TransferSessionException(
        TransferFailure.protocolMismatch,
        'The other device is running a different version of the app',
      );
    }

    final proof = _decodeBase64(body['proof']);
    if (proof == null ||
        !TransferCryptoService.verifyProof(
          key: _sessionKey,
          challenge: challenge,
          proof: proof,
        )) {
      // Something answered on that port, but it is not the phone whose code
      // was scanned. Nothing more is sent to it.
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The other device could not prove it showed that code',
      );
    }

    peerName = body['deviceName'] as String? ?? '';
  }

  /// Answers the conversation from the listening side.
  ///
  /// Verifies nothing about the client here: the client proves it holds the
  /// key by sending an encrypted frame this connection can open, which is the
  /// first thing it does after this returns.
  Future<void> performServerHandshake({required String deviceName}) async {
    final hello = await _expect(FrameType.hello);
    final body = hello.json;
    if (body == null) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The peer sent an opening that could not be read',
      );
    }

    final version = (body['version'] as num?)?.toInt();
    if (version != AppConstants.syncProtocolVersion) {
      _sendPlain(FrameType.error, <String, dynamic>{'code': 'version'});
      throw const TransferSessionException(
        TransferFailure.protocolMismatch,
        'The other device is running a different version of the app',
      );
    }

    final challenge = _decodeBase64(body['challenge']);
    if (challenge == null || challenge.isEmpty) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The peer sent no challenge',
      );
    }

    peerName = body['deviceName'] as String? ?? '';

    _sendPlain(FrameType.welcome, <String, dynamic>{
      'version': AppConstants.syncProtocolVersion,
      'proof': base64.encode(
        TransferCryptoService.proofFor(key: _sessionKey, challenge: challenge),
      ),
      'deviceName': deviceName,
    });
  }

  // ------------------------------------------------------------------ frames

  /// Sends an encrypted frame carrying JSON.
  Future<void> sendJson(FrameType type, Map<String, dynamic> body) =>
      sendEncrypted(type, utf8.encode(jsonEncode(body)));

  /// Sends an encrypted frame carrying raw bytes.
  ///
  /// The wire body is the IV followed by the ciphertext and its tag. The IV
  /// is not a secret; it only has to be different every time, and it is drawn
  /// fresh for each frame.
  Future<void> sendEncrypted(FrameType type, List<int> plain) async {
    if (_closed) {
      throw const TransferSessionException(
        TransferFailure.connectionLost,
        'The connection is closed',
      );
    }

    final sealed = await _crypto.seal(
      key: _sessionKey,
      plain: Uint8List.fromList(plain),
    );

    _duplex.add(
      TransferProtocol.encode(type, <int>[...sealed.iv, ...sealed.bytes]),
    );
    _touch();
  }

  /// Decrypts a frame body.
  ///
  /// A tag failure means the peer does not hold the session key, or something
  /// altered the frame on the way. Either way the session ends: there is no
  /// version of "carry on" that is safe here.
  Future<Uint8List> openFrame(TransferFrame frame) async {
    const ivLength = AppConstants.syncIvLengthBytes;
    if (frame.body.length <= ivLength) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The peer sent a frame that was too short to be encrypted',
      );
    }

    try {
      return await _crypto.open(
        key: _sessionKey,
        iv: Uint8List.sublistView(frame.body, 0, ivLength),
        bytes: Uint8List.sublistView(frame.body, ivLength),
      );
    } catch (_) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The other device does not hold the pairing key',
      );
    }
  }

  /// Decrypts a frame body and reads it as JSON.
  Future<Map<String, dynamic>?> openJson(TransferFrame frame) async {
    try {
      final decoded = jsonDecode(utf8.decode(await openFrame(frame)));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on TransferSessionException {
      rethrow;
    } catch (_) {
      return null;
    }
  }

  /// Sends an unencrypted frame. Only the handshake uses this.
  void _sendPlain(FrameType type, Map<String, dynamic> body) {
    _duplex.add(TransferProtocol.encodeJson(type, body));
    _touch();
  }

  /// Waits for the next frame, insisting it is of [type].
  Future<TransferFrame> _expect(FrameType type) async {
    final frame = await nextFrame();
    if (frame.type == FrameType.error) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The other device refused the connection',
      );
    }
    if (frame.type != type) {
      throw TransferSessionException(
        TransferFailure.handshakeRejected,
        'Expected a ${type.name} frame and got a ${frame.type.name} one',
      );
    }
    return frame;
  }

  /// The next frame, or a failure if the connection ends first.
  ///
  /// Frames that arrived while nothing was waiting are handed back straight
  /// away. On a fast local network a whole file's worth can land between two
  /// awaits, so anything that dropped them would lose most of a transfer.
  Future<TransferFrame> nextFrame() async {
    if (_ready.isNotEmpty) return _ready.removeAt(0);

    final failure = _failure;
    if (failure != null) throw failure;
    if (_closed) {
      throw const TransferSessionException(
        TransferFailure.connectionLost,
        'The connection closed',
      );
    }
    if (_waiting != null) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'Two reads were waiting on the same connection',
      );
    }

    final completer = Completer<TransferFrame>();
    _waiting = completer;

    try {
      return await completer.future.timeout(
        const Duration(seconds: AppConstants.syncIdleTimeoutSeconds),
      );
    } on TimeoutException {
      _waiting = null;
      throw const TransferSessionException(
        TransferFailure.idleTimeout,
        'The other device stopped responding',
      );
    }
  }

  static Uint8List? _decodeBase64(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return base64.decode(value);
    } catch (_) {
      return null;
    }
  }

  /// Closes everything this connection owns.
  ///
  /// Safe to call more than once, and called from every failure path, so a
  /// socket is never left open because an error took an unusual route out.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;

    _idleTimer?.cancel();
    _idleTimer = null;

    await _subscription?.cancel();
    _subscription = null;

    await _duplex.close();

    final waiting = _waiting;
    if (waiting != null && !waiting.isCompleted) {
      _waiting = null;
      waiting.completeError(
        _failure ??
            const TransferSessionException(
              TransferFailure.connectionLost,
              'The connection closed',
            ),
      );
    }
    _ready.clear();
  }
}

/// A [TransferDuplex] over a real socket.
class SocketDuplex implements TransferDuplex {
  final dynamic _socket;

  /// [socket] is a `dart:io` `Socket`. Typed loosely so this file does not
  /// force `dart:io` on the tests that use the in-memory duplex instead.
  SocketDuplex(this._socket);

  @override
  Stream<Uint8List> get incoming => _socket as Stream<Uint8List>;

  @override
  void add(List<int> bytes) => _socket.add(bytes);

  @override
  Future<void> close() async {
    try {
      await _socket.flush();
    } catch (_) {
      // Nothing to do: the peer has already gone.
    }
    try {
      _socket.destroy();
    } catch (_) {
      // Already destroyed.
    }
  }

  @override
  String get remoteAddress => _socket.remoteAddress.address as String;
}
