import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/albums/folder_path_rules.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/phone_move_data.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/pairing_payload.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/peer_info.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/sync_role.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_progress.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/local_address_rules.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/sync_selection_rules.dart';
import 'package:in_sreerajp_imgvidgal/repositories/sync_mark_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/device_identity_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/network_interface_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_client_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_server_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/pairing_codec.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/received_media_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_exchange_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_protocol.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_transfer_service.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';

// Moved to models so the UI can use it without importing a service (G46).
export 'package:in_sreerajp_imgvidgal/models/sync/transfer_session_state.dart';

/// Drives one whole pairing, from the code to the last file.
///
/// The screen talks to this and nothing else. It owns the server or the
/// client, and it guarantees the socket is closed: every path out of a
/// session — finished, cancelled, refused, timed out, thrown — runs through
/// [stop]. That guarantee is what lets the app promise the listener lives
/// only as long as the transfer screen is open.
///
/// ### One pairing, several sends
///
/// After pairing, both phones say who they are (install id) and the receiver
/// says how much free space it has. The sender then picks what to send, and
/// may send again and again over the same pairing ("Send the rest"). Every
/// file the receiver now holds is marked as sent to that phone, so the next
/// send — in this pairing or a later one — carries only what is left.
class TransferSessionService {
  final NetworkInterfaceService _network;
  final TransferCryptoService _crypto;
  final ReceivedMediaService _received;
  final DeviceIdentityService _identity;
  final SyncMarkRepository? _marks;

  /// Reads the bytes of a file this device is offering.
  final Future<File?> Function(MediaItem item) _fileFor;

  /// Saves a digest this side worked out, against the media id.
  final Future<void> Function(String mediaId, String sha256)? _saveDigest;

  /// The names of the albums a file is in, to send along with it.
  final Future<List<String>> Function(MediaItem item)? _albumNamesFor;

  /// Phone move: packs this phone's app data and settings to send.
  final Future<Uint8List> Function()? _buildAppData;

  /// Phone move: reads app data and settings that arrived.
  final PhoneMoveData Function(List<int> bytes)? _decodeAppData;

  /// Phone move: the private vault, both to send from and receive into.
  final VaultTransferService? _vault;

  TransferSessionService({
    required NetworkInterfaceService network,
    required TransferCryptoService crypto,
    required ReceivedMediaService received,
    required Future<File?> Function(MediaItem item) fileFor,
    required DeviceIdentityService identity,
    SyncMarkRepository? marks,
    Future<void> Function(String mediaId, String sha256)? saveDigest,
    Future<List<String>> Function(MediaItem item)? albumNamesFor,
    Future<Uint8List> Function()? buildAppData,
    PhoneMoveData Function(List<int> bytes)? decodeAppData,
    VaultTransferService? vault,
  }) : _buildAppData = buildAppData,
       _decodeAppData = decodeAppData,
       _vault = vault,
       _network = network,
       _crypto = crypto,
       _received = received,
       _fileFor = fileFor,
       _identity = identity,
       _marks = marks,
       _saveDigest = saveDigest,
       _albumNamesFor = albumNamesFor;

  P2pServerService? _server;
  P2pClientService? _client;
  P2pConnection? _connection;
  bool _cancelled = false;

  /// True while a send is running, so a second tap cannot start another.
  bool _sending = false;

  /// True after [reset], until the next [host] or [join].
  ///
  /// Closing the socket makes the old session's loops fail a moment later.
  /// Their last words ("connection lost") must not land on top of the clean
  /// state [reset] just put up, so they are dropped.
  bool _quiet = false;

  final StreamController<TransferSessionState> _states =
      StreamController<TransferSessionState>.broadcast();

  TransferSessionState _state = const TransferSessionState();

  /// The current state, for a first build before anything has happened.
  TransferSessionState get state => _state;

  /// State as it changes.
  Stream<TransferSessionState> get states => _states.stream;

  void _emit(TransferSessionState next) {
    if (_quiet) return;
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
  }) async {
    await stop();
    _resetSession(role);

    // Old staging files from a session that was killed rather than closed.
    await _received.sweepStaging();

    final address = await _network.preferredAddress();
    if (address == null) {
      _fail(TransferFailure.noLocalNetwork);
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
    } catch (error) {
      AppLogger.warning('Starting the transfer listener failed', error: error);
      _fail(TransferFailure.noLocalNetwork);
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

    await _guard(() async {
      final connection = await server.waitForPeer(
        sessionKey: key,
        deviceName: deviceName,
      );
      _connection = connection;
      await _afterConnect(role);
    });
  }

  /// Connects to a scanned pairing code.
  Future<void> join({
    required PairingPayload pairing,
    required String deviceName,
  }) async {
    await stop();
    final role = pairing.scannerRole;
    _resetSession(role);
    await _received.sweepStaging();

    // The code was already checked when it was decoded. Checked again here,
    // because this is the call that opens a socket and that check must not
    // depend on an earlier one still being in place.
    if (!LocalAddressRules.isConnectable(pairing.host, pairing.port)) {
      _fail(TransferFailure.remoteAddressRefused);
      return;
    }

    final key = _keyFromPairing(pairing);
    if (key == null) {
      _fail(TransferFailure.handshakeRejected);
      return;
    }

    final client = P2pClientService();
    _client = client;

    _emit(
      _state.copyWith(phase: SyncPhase.waiting, role: role, clearFailure: true),
    );

    await _guard(() async {
      final connection = await client.connect(
        payload: pairing,
        sessionKey: key,
        deviceName: deviceName,
      );
      _connection = connection;
      await _afterConnect(role);
    });
  }

  /// Clears what the last session left in the state.
  void _resetSession(SyncRole role) {
    _quiet = false;
    _cancelled = false;
    _sending = false;
    _received.reset();
    _emit(TransferSessionState(role: role));
  }

  /// Runs [body], and ends the session on any error it throws.
  Future<void> _guard(Future<void> Function() body) async {
    try {
      await body();
    } on TransferSessionException catch (error) {
      AppLogger.warning(
        'The transfer ended with a session error',
        error: error,
      );
      _fail(error.failure);
      await stop();
    } catch (error) {
      AppLogger.error('The transfer failed', error: error);
      _fail(TransferFailure.unknown);
      await stop();
    }
  }

  void _fail(TransferFailure failure) {
    _emit(_state.copyWith(phase: SyncPhase.failed, failure: failure));
  }

  /// Says who this phone is, hears who the other one is, then starts the
  /// role's half of the session.
  Future<void> _afterConnect(SyncRole role) async {
    final connection = _connection;
    if (connection == null) return;

    connection.startHeartbeat();

    await connection.sendJson(FrameType.peerInfo, await _ownInfo(role));

    final peerFrame = await _expectFrame(connection, FrameType.peerInfo);
    final peer = PeerInfo.fromJson(await connection.openJson(peerFrame));
    if (peer == null) {
      throw const TransferSessionException(
        TransferFailure.handshakeRejected,
        'The other device did not say who it is',
      );
    }

    _emit(
      _state.copyWith(
        phase: role == SyncRole.send ? SyncPhase.choosing : SyncPhase.paired,
        peerName: connection.peerName,
        peer: peer,
      ),
    );

    if (role == SyncRole.receive) await _receiveLoop(connection);
  }

  /// This phone's info: the install id, plus free space when receiving.
  Future<Map<String, dynamic>> _ownInfo(SyncRole role) async {
    final receiving = role == SyncRole.receive;
    final free = receiving ? await _received.freeSpaceBytes() : null;
    final vaultReady = receiving && (await _vault?.isReady() ?? false);
    return PeerInfo(
      installId: await _identity.installId(),
      freeBytes: free,
      vaultReady: vaultReady,
    ).toJson();
  }

  // ------------------------------------------------------------------ sender

  /// Sends [items] to the paired phone.
  ///
  /// The screen worked out [items] with `SendLimitRules`, so they fit. When
  /// it finishes the phase is [SyncPhase.batchDone] and the screen offers to
  /// send more over the same pairing.
  ///
  /// [finishWhenDone] ends the pairing right after a send that went fully
  /// well, as if the user had tapped Finish. A quick send uses it: nothing
  /// is left to pick after it, so the other phone would only wait.
  Future<void> sendBatch(
    List<MediaItem> items, {
    bool finishWhenDone = false,
  }) async {
    final connection = _connection;
    if (connection == null || _sending || _state.role != SyncRole.send) return;
    if (items.isEmpty) return;
    _sending = true;
    _cancelled = false;

    await _guard(() async {
      try {
        _emit(
          _state.copyWith(
            phase: SyncPhase.preparing,
            progress: TransferProgress.starting(items.length, 0),
            clearOutcome: true,
            triedIds: Set<String>.unmodifiable(<String>{
              ..._state.triedIds,
              for (final item in items) item.id,
            }),
          ),
        );

        final manifest = await buildManifest(
          items,
          onPrepared: (done) => _emit(
            _state.copyWith(
              progress: _state.progress.copyWith(filesDone: done),
            ),
          ),
        );
        if (_cancelled) {
          await connection.sendJson(FrameType.cancel, <String, dynamic>{});
          _fail(TransferFailure.cancelled);
          await stop();
          return;
        }

        final byId = <String, MediaItem>{
          for (final item in items) item.id: item,
        };
        final peerId = _state.peer?.installId;

        _emit(_state.copyWith(phase: SyncPhase.transferring));

        final outcome =
            await TransferExchangeService(
              connection: connection,
              sink: _received,
            ).send(
              manifest: manifest,
              fileFor: (entry) async {
                final item = byId[entry.sourceId];
                return item == null ? null : _fileFor(item);
              },
              onProgress: (progress) =>
                  _emit(_state.copyWith(progress: progress)),
              isCancelled: () => _cancelled,
              onDelivered: (entry) {
                _emit(
                  _state.copyWith(
                    deliveredIds: Set<String>.unmodifiable(<String>{
                      ..._state.deliveredIds,
                      entry.sourceId,
                    }),
                  ),
                );
                return _markSent(peerId, entry);
              },
            );

        if (outcome.failure == TransferFailure.cancelled) {
          _emit(
            _state.copyWith(
              phase: SyncPhase.failed,
              failure: TransferFailure.cancelled,
              outcome: outcome,
              totals: addOutcomes(_state.totals, outcome),
            ),
          );
          await stop();
          return;
        }

        // The receiver says how much room it has left after every send, so
        // the next one is sized against the real number.
        final info = await _expectFrame(connection, FrameType.peerInfo);
        final peer = PeerInfo.fromJson(await connection.openJson(info));

        _emit(
          _state.copyWith(
            phase: SyncPhase.batchDone,
            outcome: outcome,
            totals: addOutcomes(_state.totals, outcome),
            batchCount: _state.batchCount + 1,
            peer: peer ?? _state.peer,
          ),
        );

        if (SyncSelectionRules.shouldAutoFinish(
          finishWhenDone: finishWhenDone,
          outcome: outcome,
        )) {
          await finish();
        }
      } finally {
        _sending = false;
      }
    });
  }

  /// Ends the pairing normally, after the last send.
  ///
  /// For a phone move, [withVault] first sends the private vault (only when
  /// the other phone said it has a vault to take it), and [withAppData] then
  /// sends the whole app data and settings. Both come after the last batch of
  /// files, so the other phone can match the data to every file it now holds.
  Future<void> finish({
    bool withAppData = false,
    bool withVault = false,
  }) async {
    final live = _connection;
    if ((withAppData || withVault) &&
        live != null &&
        !live.isClosed &&
        !_sending &&
        _state.role == SyncRole.send) {
      _sending = true;
      _cancelled = false;
      await _guard(() async {
        try {
          if (withVault && (_state.peer?.vaultReady ?? false)) {
            final finished = await _sendVault(live);
            if (!finished) return;
          }
          if (withAppData) await _sendAppData(live);
          await _sayBye(live);
          _emit(_state.copyWith(phase: SyncPhase.done, outcome: _state.totals));
          await stop();
        } finally {
          _sending = false;
        }
      });
      return;
    }

    final connection = _connection;
    if (connection != null && !connection.isClosed) {
      try {
        await connection.sendJson(FrameType.bye, <String, dynamic>{});
      } catch (_) {
        // Safe to ignore: the other phone has gone already.
      }
    }
    _emit(_state.copyWith(phase: SyncPhase.done, outcome: _state.totals));
    await stop();
  }

  Future<void> _sayBye(P2pConnection connection) async {
    try {
      await connection.sendJson(FrameType.bye, <String, dynamic>{});
    } catch (_) {
      // Safe to ignore: the other phone has gone already.
    }
  }

  /// Sends every vault item not yet sent to this peer.
  ///
  /// Each item is decrypted into a working file just before it goes and
  /// shredded right after, so at most one plaintext copy exists at a time.
  /// Returns false when the user cancelled and the session has been stopped.
  Future<bool> _sendVault(P2pConnection connection) async {
    final vault = _vault;
    if (vault == null) return true;

    final peerId = _state.peer?.installId;
    final marks = _marks;
    final sentIds = peerId == null || marks == null
        ? const <String>{}
        : (await marks.marksForPeer(peerId)).keys.toSet();
    final items = [
      for (final item in await vault.items())
        if (!sentIds.contains(item.id)) item,
    ].take(AppConstants.syncMaxManifestEntries).toList();
    if (items.isEmpty) return true;

    _emit(
      _state.copyWith(
        phase: SyncPhase.preparing,
        progress: TransferProgress.starting(items.length, 0),
        clearOutcome: true,
      ),
    );

    final byId = <String, VaultItem>{for (final item in items) item.id: item};
    final entries = <TransferEntry>[];
    var done = 0;
    for (final item in items) {
      if (_cancelled) break;
      final entry = await _vaultEntryFor(vault, item);
      if (entry != null) entries.add(entry);
      done++;
      _emit(
        _state.copyWith(progress: _state.progress.copyWith(filesDone: done)),
      );
    }
    if (_cancelled) {
      await connection.sendJson(FrameType.cancel, <String, dynamic>{});
      _fail(TransferFailure.cancelled);
      await stop();
      return false;
    }
    if (entries.isEmpty) return true;

    _emit(_state.copyWith(phase: SyncPhase.transferring));

    final outcome =
        await TransferExchangeService(
          connection: connection,
          sink: _received,
        ).send(
          manifest: TransferManifest(entries: entries),
          fileFor: (entry) async {
            final item = byId[entry.sourceId];
            return item == null ? null : vault.openPlain(item);
          },
          afterFile: vault.closePlain,
          onProgress: (progress) => _emit(_state.copyWith(progress: progress)),
          isCancelled: () => _cancelled,
          onDelivered: (entry) => _markSent(peerId, entry),
        );

    if (outcome.failure == TransferFailure.cancelled) {
      _emit(
        _state.copyWith(
          phase: SyncPhase.failed,
          failure: TransferFailure.cancelled,
          outcome: outcome,
          totals: addOutcomes(_state.totals, outcome),
        ),
      );
      await stop();
      return false;
    }

    final info = await _expectFrame(connection, FrameType.peerInfo);
    final peer = PeerInfo.fromJson(await connection.openJson(info));
    _emit(
      _state.copyWith(
        outcome: outcome,
        totals: addOutcomes(_state.totals, outcome),
        batchCount: _state.batchCount + 1,
        peer: peer ?? _state.peer,
      ),
    );
    return true;
  }

  /// The offer line for one vault item, or null when it cannot be read.
  Future<TransferEntry?> _vaultEntryFor(
    VaultTransferService vault,
    VaultItem item,
  ) async {
    File? plain;
    try {
      plain = await vault.openPlain(item);
      final length = await plain.length();
      if (length <= 0 || length > AppConstants.syncMaxFileBytes) return null;
      final digest = await TransferCryptoService.fileDigest(plain);
      return TransferEntry(
        sourceId: item.id,
        displayName: item.originalFilename,
        mimeType: item.mimeType,
        mediaTypeName: item.mediaType.name,
        sizeBytes: length,
        sha256: digest,
        dateTakenMs: item.dateTaken?.millisecondsSinceEpoch,
        tagNames: List<String>.from(item.tags),
        userNotes: item.notes,
        vault: true,
      );
    } catch (error) {
      AppLogger.debug('Reading a vault item for transfer failed');
      return null;
    } finally {
      if (plain != null) await vault.closePlain(plain);
    }
  }

  /// Packs and sends the app data and settings, and waits for the other
  /// phone to say it holds them.
  ///
  /// Any failure here ends the session as [TransferFailure.appDataFailed]:
  /// the files already sent stay, and running the move again sends the data.
  Future<void> _sendAppData(P2pConnection connection) async {
    final build = _buildAppData;
    if (build == null) return;

    _emit(_state.copyWith(phase: SyncPhase.appData));
    try {
      final bytes = await build();
      await connection.sendJson(FrameType.appDataStart, <String, dynamic>{
        'bytes': bytes.length,
        'sha256': TransferCryptoService.hexDigest(bytes),
      });
      const chunk = AppConstants.syncChunkBytes;
      for (var start = 0; start < bytes.length; start += chunk) {
        final end = start + chunk < bytes.length ? start + chunk : bytes.length;
        await connection.sendEncrypted(
          FrameType.appDataChunk,
          Uint8List.sublistView(bytes, start, end),
        );
      }
      final ack = await _expectFrame(connection, FrameType.appDataAck);
      final body = await connection.openJson(ack);
      if (body?['ok'] != true) {
        throw const TransferSessionException(
          TransferFailure.appDataFailed,
          'The other phone could not read the app data',
        );
      }
      _emit(_state.copyWith(appDataSent: true));
    } on TransferSessionException catch (error) {
      if (error.failure == TransferFailure.cancelled ||
          error.failure == TransferFailure.appDataFailed) {
        rethrow;
      }
      throw TransferSessionException(
        TransferFailure.appDataFailed,
        'Sending the app data failed',
        cause: error,
      );
    } catch (error) {
      throw TransferSessionException(
        TransferFailure.appDataFailed,
        'Packing the app data failed',
        cause: error,
      );
    }
  }

  Future<void> _markSent(String? peerId, TransferEntry entry) async {
    final marks = _marks;
    if (marks == null || peerId == null || entry.sha256.isEmpty) return;
    try {
      await marks.markSent(
        peerId: peerId,
        mediaId: entry.sourceId,
        sha256: entry.sha256,
        sizeBytes: entry.sizeBytes,
      );
    } catch (error) {
      AppLogger.debug('Saving a sent mark failed');
      // Safe to ignore: without the mark the file is offered again next
      // time, and the receiver's digest check refuses it then.
    }
  }

  /// Builds the offer for a list of media.
  ///
  /// The digest is what the receiver checks the bytes against, so it is
  /// computed here rather than taken on trust from an index that may be
  /// stale. A file that cannot be read is left out of the offer entirely,
  /// which is better than promising it and failing half way through.
  ///
  /// Never more than [AppConstants.syncMaxManifestEntries] files; the screen
  /// keeps the selection inside that, and says so, before this runs.
  Future<TransferManifest> buildManifest(
    List<MediaItem> items, {
    void Function(int done)? onPrepared,
  }) async {
    final entries = <TransferEntry>[];
    var done = 0;

    for (final item in items.take(AppConstants.syncMaxManifestEntries)) {
      if (_cancelled) break;
      final entry = await _entryFor(item);
      if (entry != null) entries.add(entry);
      onPrepared?.call(++done);
    }

    return TransferManifest(entries: entries);
  }

  Future<TransferEntry?> _entryFor(MediaItem item) async {
    final file = await _fileFor(item);
    if (file == null || !await file.exists()) return null;

    final int length;
    try {
      length = await file.length();
    } catch (error) {
      AppLogger.debug('Reading a file size for transfer failed');
      return null;
    }
    if (length <= 0 || length > AppConstants.syncMaxFileBytes) return null;

    String digest;
    try {
      // Read in pieces. Reading the whole file at once would hold a large
      // video in memory and could crash the app.
      digest = await TransferCryptoService.fileDigest(file);
    } catch (error) {
      AppLogger.debug('Hashing a file for transfer failed');
      return null;
    }

    // Keep the digest. The next send, and the receiver's "already have it"
    // check on a later transfer back, can then skip this work.
    if (digest != item.sha256Hash) {
      try {
        await _saveDigest?.call(item.id, digest);
      } catch (error) {
        AppLogger.debug('Saving a file digest failed');
        // Safe to ignore: the digest is a time saver, not needed to send.
      }
    }

    List<String> albums = const <String>[];
    try {
      albums = await _albumNamesFor?.call(item) ?? const <String>[];
    } catch (error) {
      AppLogger.debug('Reading albums for a sent file failed');
      // Safe to ignore: the file still goes, without its albums.
    }

    final folder = item.path.isEmpty
        ? null
        : FolderPathRules.displayName(
            FolderPathRules.parentDirectory(item.path),
          );

    return TransferEntry(
      sourceId: item.id,
      displayName: item.displayName,
      mimeType: item.mimeType,
      mediaTypeName: item.mediaType.name,
      sizeBytes: length,
      sha256: digest,
      dateTakenMs: item.dateTaken?.millisecondsSinceEpoch,
      tagNames: List<String>.from(item.tags),
      albumNames: albums,
      userNotes: item.userNotes,
      isFavorite: item.isFavorite,
      address: item.address,
      latitude: item.latitude,
      longitude: item.longitude,
      sourceFolder: folder == null || folder.isEmpty ? null : folder,
    );
  }

  // ---------------------------------------------------------------- receiver

  /// Takes sends until the sender says it is finished.
  Future<void> _receiveLoop(P2pConnection connection) async {
    final exchange = TransferExchangeService(
      connection: connection,
      sink: _received,
    );

    while (true) {
      final frame = await connection.nextFrame();

      if (frame.type == FrameType.bye) {
        _emit(_state.copyWith(phase: SyncPhase.done, outcome: _state.totals));
        await stop();
        return;
      }
      if (frame.type == FrameType.cancel) {
        throw const TransferSessionException(
          TransferFailure.cancelled,
          'The other device stopped the transfer',
        );
      }
      if (frame.type == FrameType.peerInfo) continue;
      if (frame.type == FrameType.appDataStart) {
        await _receiveAppData(connection, frame);
        continue;
      }
      if (frame.type != FrameType.manifest) {
        throw TransferSessionException(
          TransferFailure.unknown,
          'Expected a send and got a ${frame.type.name} frame',
        );
      }

      _emit(_state.copyWith(phase: SyncPhase.transferring, clearOutcome: true));

      final outcome = await exchange.receiveOffer(
        frame,
        // Everything offered is taken. The sender already chose; a second
        // list to tick through while the other person waits would be a worse
        // experience, not a safer one.
        accept: (manifest) async {
          _emit(_state.copyWith(offer: manifest));
          return List<int>.generate(manifest.entries.length, (i) => i).toSet();
        },
        onProgress: (progress) => _emit(_state.copyWith(progress: progress)),
        isCancelled: () => _cancelled,
      );

      await _received.indexReceived();

      final totals = addOutcomes(_state.totals, outcome);
      if (outcome.failure == TransferFailure.cancelled) {
        _emit(
          _state.copyWith(
            phase: SyncPhase.failed,
            failure: TransferFailure.cancelled,
            outcome: outcome,
            totals: totals,
            landedInAppFolder: _received.usedFallbackDirectory,
            vaultReceivedCount: _received.vaultReceivedCount,
          ),
        );
        await stop();
        return;
      }

      // Tell the sender how much room is left, for its next send.
      await connection.sendJson(
        FrameType.peerInfo,
        await _ownInfo(SyncRole.receive),
      );

      _emit(
        _state.copyWith(
          phase: SyncPhase.paired,
          outcome: outcome,
          totals: totals,
          batchCount: _state.batchCount + 1,
          landedInAppFolder: _received.usedFallbackDirectory,
          vaultReceivedCount: _received.vaultReceivedCount,
        ),
      );
    }
  }

  /// Takes the app data and settings of a phone move and holds them.
  ///
  /// Untrusted until checked: the announced size must be within the cap,
  /// every slice must fit inside it, and the digest must match. Then it is
  /// decoded and kept in memory for the user to review. Nothing is written
  /// to the user's data here.
  Future<void> _receiveAppData(
    P2pConnection connection,
    TransferFrame start,
  ) async {
    final header = await connection.openJson(start);
    final expected = (header?['bytes'] as num?)?.toInt() ?? -1;
    final digest = header?['sha256'];
    if (expected <= 0 ||
        expected > AppConstants.syncMaxAppDataBytes ||
        digest is! String) {
      throw const TransferSessionException(
        TransferFailure.appDataFailed,
        'The other phone announced app data this phone will not take',
      );
    }

    _emit(_state.copyWith(phase: SyncPhase.appData));

    final buffer = BytesBuilder(copy: false);
    while (buffer.length < expected) {
      final frame = await _expectFrame(connection, FrameType.appDataChunk);
      final plain = await connection.openFrame(frame);
      if (buffer.length + plain.length > expected) {
        throw const TransferSessionException(
          TransferFailure.appDataFailed,
          'The app data was longer than announced',
        );
      }
      buffer.add(plain);
    }

    final bytes = buffer.takeBytes();
    PhoneMoveData? data;
    if (TransferCryptoService.hexDigest(bytes) == digest) {
      try {
        data = _decodeAppData?.call(bytes);
      } catch (error) {
        AppLogger.warning('Reading phone-move app data failed', error: error);
      }
    }

    await connection.sendJson(FrameType.appDataAck, <String, dynamic>{
      'ok': data != null,
    });
    if (data == null) {
      throw const TransferSessionException(
        TransferFailure.appDataFailed,
        'The app data did not check out',
      );
    }
    _emit(_state.copyWith(phase: SyncPhase.paired, receivedAppData: data));
  }

  static Future<TransferFrame> _expectFrame(
    P2pConnection connection,
    FrameType type,
  ) async {
    final frame = await connection.nextFrame();
    if (frame.type == FrameType.cancel) {
      throw const TransferSessionException(
        TransferFailure.cancelled,
        'The other device stopped the transfer',
      );
    }
    if (frame.type != type) {
      throw TransferSessionException(
        TransferFailure.unknown,
        'Expected a ${type.name} frame and got a ${frame.type.name} one',
      );
    }
    return frame;
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

  /// Closes everything, then forgets what the last session showed.
  ///
  /// [stop] alone leaves the state at `done` or `failed`. This service lives
  /// as long as the app, so the next transfer screen would open on that old
  /// result: the scan screen shows its camera only when the phase is `idle`.
  /// The screens call this on the way out, and before a new scan.
  Future<void> reset() async {
    // Anything still running stops at its next check, and stays stopped:
    // the flag is cleared only when a new session starts.
    _cancelled = true;
    await stop();
    _received.reset();
    _quiet = false;
    _emit(TransferSessionState(role: _state.role));
    _quiet = true;
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
      // Safe to ignore: a bad key in the pairing code reads as null and the
      // code is refused.
      return null;
    }
  }
}
