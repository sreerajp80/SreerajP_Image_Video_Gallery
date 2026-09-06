import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_progress.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/local_address_rules.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/network_interface_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_client_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_server_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/pairing_codec.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/received_media_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_exchange_service.dart';

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

/// Drives one whole transfer, from pairing to the last file.
///
/// The screen talks to this and nothing else. It owns the server or the
/// client, and it guarantees the socket is closed: every path out of a
/// session — finished, cancelled, refused, timed out, thrown — runs through
/// [stop]. That guarantee is what lets the app promise the listener lives
/// only as long as the transfer screen is open.
class TransferSessionService {
  final NetworkInterfaceService _network;
  final TransferCryptoService _crypto;
  final ReceivedMediaService _received;

  /// Reads the bytes of a file this device is offering.
  final Future<File?> Function(MediaItem item) _fileFor;

  TransferSessionService({
    required NetworkInterfaceService network,
    required TransferCryptoService crypto,
    required ReceivedMediaService received,
    required Future<File?> Function(MediaItem item) fileFor,
  }) : _network = network,
       _crypto = crypto,
       _received = received,
       _fileFor = fileFor;

  P2pServerService? _server;
  P2pClientService? _client;
  P2pConnection? _connection;
  bool _cancelled = false;

  final StreamController<TransferSessionState> _states =
      StreamController<TransferSessionState>.broadcast();

  TransferSessionState _state = const TransferSessionState();

  /// The current state, for a first build before anything has happened.
  TransferSessionState get state => _state;

  /// State as it changes.
  Stream<TransferSessionState> get states => _states.stream;

  void _emit(TransferSessionState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  /// Starts listening and produces a pairing code to show.
  ///
  /// [role] is what *this* device will do. The scanning device takes the
  /// opposite one, so the two cannot both try to send.
  Future<void> host({
    required SyncRole role,
    required String deviceName,
    List<MediaItem> toOffer = const <MediaItem>[],
  }) async {
    await stop();
    _cancelled = false;

    // Old staging files from a session that was killed rather than closed.
    await _received.sweepStaging();

    final address = await _network.preferredAddress();
    if (address == null) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.noLocalNetwork,
        ),
      );
      return;
    }

    // The code carries the short secret; the socket uses the long key
    // derived from it. Both phones do the same derivation.
    final secret = await _crypto.newPairingSecret();
    final key = TransferCryptoService.deriveSessionKey(secret);

    final server = P2pServerService();
    _server = server;

    final int port;
    try {
      port = await server.start(address: address.address);
    } catch (_) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.noLocalNetwork,
        ),
      );
      await stop();
      return;
    }

    final pairing = PairingPayload(
      protocolVersion: AppConstants.syncProtocolVersion,
      host: address.address,
      port: port,
      sessionKey: base64Url.encode(secret).replaceAll('=', ''),
      deviceName: deviceName,
      hostRole: role,
    );

    _emit(
      _state.copyWith(
        phase: SyncPhase.waiting,
        role: role,
        pairing: pairing,
        manualCode: PairingCodec.encodeManual(pairing),
        clearFailure: true,
      ),
    );

    try {
      final connection = await server.waitForPeer(
        sessionKey: key,
        deviceName: deviceName,
      );
      _connection = connection;
      _emit(
        _state.copyWith(phase: SyncPhase.paired, peerName: connection.peerName),
      );

      await _runExchange(role: role, toOffer: toOffer);
    } on TransferSessionException catch (error) {
      _emit(_state.copyWith(phase: SyncPhase.failed, failure: error.failure));
      await stop();
    } catch (_) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.unknown,
        ),
      );
      await stop();
    }
  }

  /// Connects to a scanned pairing code.
  Future<void> join({
    required PairingPayload pairing,
    required String deviceName,
    List<MediaItem> toOffer = const <MediaItem>[],
  }) async {
    await stop();
    _cancelled = false;
    await _received.sweepStaging();

    // The code was already checked when it was decoded. Checked again here,
    // because this is the call that opens a socket and that check must not
    // depend on an earlier one still being in place.
    if (!LocalAddressRules.isConnectable(pairing.host, pairing.port)) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.remoteAddressRefused,
        ),
      );
      return;
    }

    final key = _keyFromPairing(pairing);
    if (key == null) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.handshakeRejected,
        ),
      );
      return;
    }

    final role = pairing.scannerRole;
    final client = P2pClientService();
    _client = client;

    _emit(
      _state.copyWith(phase: SyncPhase.waiting, role: role, clearFailure: true),
    );

    try {
      final connection = await client.connect(
        payload: pairing,
        sessionKey: key,
        deviceName: deviceName,
      );
      _connection = connection;
      _emit(
        _state.copyWith(phase: SyncPhase.paired, peerName: connection.peerName),
      );

      await _runExchange(role: role, toOffer: toOffer);
    } on TransferSessionException catch (error) {
      _emit(_state.copyWith(phase: SyncPhase.failed, failure: error.failure));
      await stop();
    } catch (_) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.unknown,
        ),
      );
      await stop();
    }
  }

  /// Runs whichever half of the exchange this device is doing.
  Future<void> _runExchange({
    required SyncRole role,
    required List<MediaItem> toOffer,
  }) async {
    final connection = _connection;
    if (connection == null) return;

    final exchange = TransferExchangeService(
      connection: connection,
      sink: _received,
    );

    _emit(_state.copyWith(phase: SyncPhase.transferring));

    try {
      final TransferOutcome outcome;

      if (role == SyncRole.send) {
        final manifest = await buildManifest(toOffer);
        final byId = <String, MediaItem>{
          for (final item in toOffer) item.id: item,
        };

        outcome = await exchange.send(
          manifest: manifest,
          fileFor: (entry) async {
            final item = byId[entry.sourceId];
            return item == null ? null : _fileFor(item);
          },
          onProgress: (progress) => _emit(_state.copyWith(progress: progress)),
          isCancelled: () => _cancelled,
        );
      } else {
        outcome = await exchange.receive(
          // Everything offered is taken. The screen asked before the session
          // started; a second list to tick through while the other person
          // waits would be a worse experience, not a safer one.
          accept: (manifest) async {
            _emit(_state.copyWith(offer: manifest));
            return List<int>.generate(
              manifest.entries.length,
              (i) => i,
            ).toSet();
          },
          onProgress: (progress) => _emit(_state.copyWith(progress: progress)),
          isCancelled: () => _cancelled,
        );

        await _received.indexReceived();
      }

      _emit(
        _state.copyWith(
          phase: outcome.succeeded ? SyncPhase.done : SyncPhase.failed,
          outcome: outcome,
          failure: outcome.failure,
          landedInAppFolder: _received.usedFallbackDirectory,
        ),
      );
    } on TransferSessionException catch (error) {
      _emit(_state.copyWith(phase: SyncPhase.failed, failure: error.failure));
    } finally {
      await stop();
    }
  }

  /// Builds the offer for a list of media.
  ///
  /// The digest is what the receiver checks the bytes against, so it is
  /// computed here rather than taken on trust from an index that may be
  /// stale. A file that cannot be read is left out of the offer entirely,
  /// which is better than promising it and failing half way through.
  Future<TransferManifest> buildManifest(List<MediaItem> items) async {
    final entries = <TransferEntry>[];

    for (final item in items.take(AppConstants.syncMaxManifestEntries)) {
      final file = await _fileFor(item);
      if (file == null || !await file.exists()) continue;

      final int length;
      try {
        length = await file.length();
      } catch (_) {
        continue;
      }
      if (length <= 0 || length > AppConstants.syncMaxFileBytes) continue;

      String digest;
      try {
        digest = TransferCryptoService.hexDigest(await file.readAsBytes());
      } catch (_) {
        continue;
      }

      entries.add(
        TransferEntry(
          sourceId: item.id,
          displayName: item.displayName,
          mimeType: item.mimeType,
          mediaTypeName: item.mediaType.name,
          sizeBytes: length,
          sha256: digest,
          dateTakenMs: item.dateTaken?.millisecondsSinceEpoch,
          tagNames: List<String>.from(item.tags),
          userNotes: item.userNotes,
          isFavorite: item.isFavorite,
        ),
      );
    }

    return TransferManifest(entries: entries);
  }

  /// Asks the transfer to stop after the file in flight.
  void cancel() => _cancelled = true;

  /// Closes everything and forgets the session key.
  ///
  /// Safe to call more than once. The screen calls it on the way out and on
  /// backgrounding, and every failure path above runs through it, so there is
  /// no route that leaves a port open.
  Future<void> stop() async {
    await _connection?.close();
    _connection = null;

    await _server?.stop();
    _server = null;

    await _client?.disconnect();
    _client = null;

    // The session key is not held here at all. The server and the connection
    // each own their copy and drop it when they close, so closing them is
    // what makes the key go — there is no second copy to forget about.
  }

  /// Closes the session and the state stream.
  Future<void> dispose() async {
    await stop();
    if (!_states.isClosed) await _states.close();
  }

  /// Turns the secret in a pairing code into the key the socket uses.
  ///
  /// Returns null for a secret of the wrong length, which is how a code from
  /// another app or another version stops before a socket is opened.
  static Uint8List? _keyFromPairing(PairingPayload pairing) {
    try {
      final padded = pairing.sessionKey.padRight(
        (pairing.sessionKey.length + 3) & ~3,
        '=',
      );
      final secret = base64Url.decode(padded);
      if (secret.length != AppConstants.syncPairingSecretBytes) return null;
      return TransferCryptoService.deriveSessionKey(secret);
    } catch (_) {
      return null;
    }
  }
}
