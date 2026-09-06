import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_manifest.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/sync/transfer_progress.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/p2p_connection.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/sync/transfer_protocol.dart';

/// Where an arriving file should be written, and what to do once it is there.
///
/// An interface so the exchange can be tested against a temporary directory,
/// with no MediaStore, no scanner and no database.
abstract class IncomingFileSink {
  /// Opens a staging file for an offered entry.
  ///
  /// Staged app-private, never straight into the gallery: a file is only
  /// moved into place once its length and digest match what the manifest
  /// promised, so a half-received photo never appears in the timeline.
  Future<File> openStaging(TransferEntry entry);

  /// Moves a fully checked file into the gallery and records its metadata.
  ///
  /// Returns the path it ended up at.
  Future<String> commit(TransferEntry entry, File staged);

  /// Whether this device already has the file with this digest.
  ///
  /// Lets the receiver decline a photo it already has instead of moving the
  /// bytes and then finding out, which on a phone camera roll is most of what
  /// a second transfer would otherwise re-send.
  Future<bool> alreadyHave(String sha256);
}

/// Moves files across an established connection.
///
/// One class for both directions, because they are two halves of the same
/// conversation and splitting them would put the protocol in two places that
/// then have to agree.
///
/// The receiving side treats everything from the peer as untrusted:
///
/// * a file name is sanitised before it is used, so a peer offering
///   `../../secret.jpg` gets a plain name and nothing else;
/// * a size larger than the cap is refused before anything is allocated;
/// * the bytes are checked against the digest the manifest promised, and a
///   file that does not match is dropped rather than saved.
class TransferExchangeService {
  final P2pConnection _connection;
  final IncomingFileSink _sink;

  TransferExchangeService({
    required P2pConnection connection,
    required IncomingFileSink sink,
  }) : _connection = connection,
       _sink = sink;

  // ------------------------------------------------------------------ sender

  /// Offers [manifest] and sends whatever the peer asks for.
  Future<TransferOutcome> send({
    required TransferManifest manifest,
    required Future<File?> Function(TransferEntry entry) fileFor,
    void Function(TransferProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    if (manifest.entries.length > AppConstants.syncMaxManifestEntries) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'That is more files than one transfer can carry',
      );
    }

    await _connection.sendJson(FrameType.manifest, manifest.toJson());

    final reply = await _expect(FrameType.manifestReply);
    final replyBody = await _connection.openJson(reply);
    final wanted = _indicesFrom(replyBody?['wanted'], manifest.entries.length);

    var progress = TransferProgress.starting(
      wanted.length,
      wanted.fold<int>(0, (sum, i) => sum + manifest.entries[i].sizeBytes),
    );
    onProgress?.call(progress);

    var sent = 0;
    var failed = 0;
    var bytes = 0;

    for (final index in wanted) {
      if (isCancelled?.call() ?? false) {
        await _connection.sendJson(FrameType.cancel, <String, dynamic>{});
        return TransferOutcome(
          sentCount: sent,
          failedCount: failed,
          skippedCount: manifest.entries.length - sent - failed,
          bytesTransferred: bytes,
          failure: TransferFailure.cancelled,
        );
      }

      final entry = manifest.entries[index];
      progress = progress.copyWith(currentName: entry.displayName);
      onProgress?.call(progress);

      final file = await fileFor(entry);
      if (file == null || !await file.exists()) {
        // The file went away between building the manifest and sending it.
        // The peer is told, and the rest of the transfer carries on.
        await _connection.sendJson(FrameType.fileStart, <String, dynamic>{
          'index': index,
          'missing': true,
        });
        failed++;
        continue;
      }

      try {
        await _connection.sendJson(FrameType.fileStart, <String, dynamic>{
          'index': index,
        });

        await for (final chunk in file.openRead()) {
          await _connection.sendEncrypted(FrameType.fileChunk, chunk);
          bytes += chunk.length;
          progress = progress.copyWith(bytesDone: bytes);
          onProgress?.call(progress);
        }

        await _connection.sendJson(FrameType.fileEnd, <String, dynamic>{
          'index': index,
        });

        final ack = await _expect(FrameType.fileAck);
        final ackBody = await _connection.openJson(ack);
        if (ackBody?['ok'] == true) {
          sent++;
        } else {
          failed++;
        }
      } catch (error) {
        if (error is TransferSessionException) rethrow;
        failed++;
      }

      progress = progress.copyWith(filesDone: sent + failed);
      onProgress?.call(progress);
    }

    await _connection.sendJson(FrameType.complete, <String, dynamic>{});

    return TransferOutcome(
      sentCount: sent,
      failedCount: failed,
      skippedCount: manifest.entries.length - wanted.length,
      bytesTransferred: bytes,
    );
  }

  // ---------------------------------------------------------------- receiver

  /// Takes an offer and receives whatever is accepted.
  ///
  /// [accept] decides which offered files to take, so the screen can show the
  /// list and let the user choose before any bytes move.
  Future<TransferOutcome> receive({
    required Future<Set<int>> Function(TransferManifest manifest) accept,
    void Function(TransferProgress progress)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final offer = await _expect(FrameType.manifest);
    final offerBody = await _connection.openJson(offer);
    if (offerBody == null) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'The other device sent an offer that could not be read',
      );
    }

    final manifest = TransferManifest.fromJson(offerBody);
    if (manifest.entries.length > AppConstants.syncMaxManifestEntries) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'The other device offered more files than one transfer can carry',
      );
    }

    final chosen = await accept(manifest);

    // Drop anything oversized or already here, before agreeing to it.
    final wanted = <int>[];
    var skipped = 0;
    for (final index in chosen) {
      if (index < 0 || index >= manifest.entries.length) continue;
      final entry = manifest.entries[index];

      if (entry.sizeBytes <= 0 ||
          entry.sizeBytes > AppConstants.syncMaxFileBytes) {
        skipped++;
        continue;
      }
      if (entry.sha256.isNotEmpty && await _sink.alreadyHave(entry.sha256)) {
        skipped++;
        continue;
      }
      wanted.add(index);
    }
    wanted.sort();

    await _connection.sendJson(FrameType.manifestReply, <String, dynamic>{
      'wanted': wanted,
    });

    var progress = TransferProgress.starting(
      wanted.length,
      wanted.fold<int>(0, (sum, i) => sum + manifest.entries[i].sizeBytes),
    );
    onProgress?.call(progress);

    var received = 0;
    var failed = 0;
    var bytes = 0;
    final expected = wanted.toSet();

    while (expected.isNotEmpty) {
      if (isCancelled?.call() ?? false) {
        await _connection.sendJson(FrameType.cancel, <String, dynamic>{});
        return TransferOutcome(
          receivedCount: received,
          failedCount: failed,
          skippedCount: skipped + expected.length,
          bytesTransferred: bytes,
          failure: TransferFailure.cancelled,
        );
      }

      final frame = await _connection.nextFrame();

      if (frame.type == FrameType.complete || frame.type == FrameType.cancel) {
        break;
      }
      if (frame.type != FrameType.fileStart) {
        throw TransferSessionException(
          TransferFailure.unknown,
          'Expected a file and got a ${frame.type.name} frame',
        );
      }

      final startBody = await _connection.openJson(frame);
      final index = (startBody?['index'] as num?)?.toInt() ?? -1;
      if (!expected.remove(index)) {
        // A file that was not asked for, or one offered twice. Not taken.
        failed++;
        continue;
      }
      if (startBody?['missing'] == true) {
        failed++;
        continue;
      }

      final entry = manifest.entries[index];
      progress = progress.copyWith(currentName: _safeName(entry.displayName));
      onProgress?.call(progress);

      final landed = await _receiveOne(
        entry: entry,
        index: index,
        onBytes: (count) {
          bytes += count;
          progress = progress.copyWith(bytesDone: bytes);
          onProgress?.call(progress);
        },
      );

      if (landed) {
        received++;
      } else {
        failed++;
      }

      progress = progress.copyWith(filesDone: received + failed);
      onProgress?.call(progress);
    }

    return TransferOutcome(
      receivedCount: received,
      failedCount: failed,
      skippedCount: skipped,
      bytesTransferred: bytes,
    );
  }

  /// Reads one file's chunks, checks it, and commits it.
  ///
  /// Returns whether it landed. A file that fails its checks is deleted and
  /// reported, never written into the gallery.
  Future<bool> _receiveOne({
    required TransferEntry entry,
    required int index,
    required void Function(int count) onBytes,
  }) async {
    final staged = await _sink.openStaging(entry);
    final sink = staged.openWrite();
    final digest = <int>[];
    var written = 0;
    var ok = true;

    try {
      while (true) {
        final frame = await _connection.nextFrame();

        if (frame.type == FrameType.fileEnd) break;
        if (frame.type != FrameType.fileChunk) {
          ok = false;
          break;
        }

        final chunk = await _connection.openFrame(frame);
        written += chunk.length;

        // A peer that keeps sending past the size it promised is stopped
        // here, rather than being allowed to fill the device.
        if (written > entry.sizeBytes) {
          ok = false;
          break;
        }

        sink.add(chunk);
        digest.addAll(chunk);
        onBytes(chunk.length);
      }
    } catch (error) {
      await _closeQuietly(sink);
      await _deleteQuietly(staged);
      if (error is TransferSessionException) rethrow;
      await _sendAck(index, false);
      return false;
    }

    await _closeQuietly(sink);

    // Both checks, every time. The length alone would let a truncated file
    // through if it happened to stop on a boundary, and the digest alone
    // would mean hashing a file that was obviously the wrong size.
    if (ok && written != entry.sizeBytes) ok = false;
    if (ok &&
        entry.sha256.isNotEmpty &&
        TransferCryptoService.hexDigest(digest) != entry.sha256) {
      ok = false;
    }

    if (!ok) {
      await _deleteQuietly(staged);
      await _sendAck(index, false);
      return false;
    }

    try {
      await _sink.commit(entry, staged);
      await _sendAck(index, true);
      return true;
    } catch (_) {
      await _deleteQuietly(staged);
      await _sendAck(index, false);
      return false;
    }
  }

  Future<void> _sendAck(int index, bool ok) => _connection.sendJson(
    FrameType.fileAck,
    <String, dynamic>{'index': index, 'ok': ok},
  );

  Future<TransferFrame> _expect(FrameType type) async {
    final frame = await _connection.nextFrame();
    if (frame.type == FrameType.error) {
      throw const TransferSessionException(
        TransferFailure.unknown,
        'The other device reported a problem',
      );
    }
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

  /// Reads a list of indices from a peer's reply, refusing anything odd.
  static List<int> _indicesFrom(Object? raw, int count) {
    if (raw is! List) return const <int>[];
    final out = <int>{};
    for (final value in raw) {
      final index = (value as num?)?.toInt();
      if (index == null || index < 0 || index >= count) continue;
      out.add(index);
    }
    final sorted = out.toList()..sort();
    return sorted;
  }

  /// Strips everything from a peer-supplied name but the name.
  ///
  /// A file name arriving over the network is untrusted input. Directory
  /// separators, parent references and control characters all go, so a peer
  /// offering `../../etc/passwd` gets a plain file name and no say in where
  /// it lands.
  static String _safeName(String raw) {
    final base = raw.split(RegExp(r'[/\\]')).last;
    final cleaned = base
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'^\.+'), '')
        .trim();

    if (cleaned.isEmpty) return 'received_file';
    return cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned;
  }

  /// The name an incoming file should be written under.
  ///
  /// Exposed so the sink and the tests use exactly the same rule as the
  /// progress display, rather than two that could drift.
  static String safeFileName(String raw) => _safeName(raw);

  static Future<void> _closeQuietly(IOSink sink) async {
    try {
      await sink.flush();
      await sink.close();
    } catch (_) {
      // Nothing useful to do; the staging file is deleted either way.
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {
      // App-private staging; it goes with the cache.
    }
  }
}
