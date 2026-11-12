import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/sync/qr_frame_codec.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/qr_sync_failure.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_collector_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_crypto_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_serializer.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/restore_service.dart';

// The UI reads this type from models, never from a service (G46).
export 'package:in_sreerajp_imgvidgal/models/sync/qr_sync_failure.dart';

/// The frames a sender plays.
class QrSendFrames {
  final List<String> frames;
  const QrSendFrames(this.frames);
}

/// Moves this app's data (not photos) to another phone through QR codes.
///
/// No network at all. The receiving phone shows a key code; the sending
/// phone scans it, then plays its data as a loop of codes, which the
/// receiving phone reads.
///
/// The data is the same as a backup archive (tags, albums, favourites, notes,
/// places, and each photo's identity), compressed and then encrypted with
/// AES-GCM under the one-time key. Somebody who films only the data codes
/// cannot read the notes in them. On the receiving side it goes through the
/// restore preview, so the user sees what will change and says yes first,
/// and nothing already there is removed.
class QrDataSyncService {
  final BackupCollectorService _collector;
  final BackupCryptoChannel _crypto;
  final RestoreService _restore;
  final BackupSerializer _serializer;

  QrDataSyncService({
    required BackupCollectorService collector,
    required BackupCryptoChannel crypto,
    required RestoreService restore,
    BackupSerializer serializer = const BackupSerializer(),
  }) : _collector = collector,
       _crypto = crypto,
       _restore = restore,
       _serializer = serializer;

  // -------------------------------------------------------------- receiver

  /// A fresh one-time key, for the receiving phone to show.
  Future<QrSyncKey> newKey() async {
    final key = await _crypto.randomBytes(AppConstants.syncSessionKeyBytes);
    final id = await _crypto.randomBytes(4);
    final session = id.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return QrSyncKey(sessionId: session, key: key);
  }

  /// Opens the collected frames and works out what applying them would do.
  ///
  /// Writes nothing to the user's data; the screen shows the restore
  /// preview, and only then calls [RestoreService.applyPlan].
  Future<OpenedArchive> open(QrFrameCollector frames, QrSyncKey key) async {
    final blob = frames.assemble();
    if (blob == null || blob.length <= AppConstants.syncIvLengthBytes) {
      throw const QrSyncException(
        QrSyncFailure.unreadable,
        'Not every code has been read',
      );
    }

    final String json;
    try {
      final plain = await _crypto.decryptWithKey(
        key: key.key,
        iv: Uint8List.sublistView(blob, 0, AppConstants.syncIvLengthBytes),
        bytes: Uint8List.sublistView(blob, AppConstants.syncIvLengthBytes),
        aad: _aad(key.sessionId),
      );
      json = utf8.decode(gzip.decode(plain));
    } catch (error) {
      throw QrSyncException(
        QrSyncFailure.unreadable,
        'The codes did not open with this key',
        cause: error,
      );
    }

    try {
      return await _restore.openPayload(_serializer.decode(json));
    } on BackupSerializerException catch (error) {
      throw QrSyncException(
        QrSyncFailure.unreadable,
        'The codes did not hold app data',
        cause: error,
      );
    }
  }

  // ---------------------------------------------------------------- sender

  /// Builds the frames to play for the key the sender scanned.
  ///
  /// Throws [QrSyncException] when there is nothing to send or too much.
  Future<QrSendFrames> buildFrames({
    required QrSyncKey key,
    required String appVersion,
    void Function(int done, int total)? onProgress,
  }) async {
    final payload = await _collector.collectFingerprinted(
      appVersion: appVersion,
      onProgress: onProgress,
    );
    if (payload.isEmpty) {
      throw const QrSyncException(
        QrSyncFailure.nothingToSend,
        'There is no app data to send',
      );
    }

    final packed = gzip.encode(utf8.encode(_serializer.encode(payload)));
    final iv = await _crypto.randomBytes(AppConstants.syncIvLengthBytes);
    final sealed = await _crypto.encryptWithKey(
      key: key.key,
      bytes: Uint8List.fromList(packed),
      iv: iv,
      aad: _aad(key.sessionId),
    );

    final blob = Uint8List.fromList(<int>[...iv, ...sealed]);
    final count = QrFrameCodec.frameCountFor(blob.length);
    if (count > AppConstants.qrSyncMaxFrames) {
      throw QrSyncException(
        QrSyncFailure.tooBig,
        'The data needs more codes than one QR sync can show',
        frameCount: count,
      );
    }
    return QrSendFrames(QrFrameCodec.split(blob, key.sessionId));
  }

  /// Ties the encrypted data to this one session, so data from another QR
  /// sync under a reused key would not open.
  static Uint8List _aad(String sessionId) =>
      Uint8List.fromList(utf8.encode('drishya-qr-sync:$sessionId'));
}
