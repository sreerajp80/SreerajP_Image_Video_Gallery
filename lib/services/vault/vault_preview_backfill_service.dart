import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/video/video_tools_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

/// Makes previews for vault items that never got one.
///
/// Until 2026-11-25 previews were decoded from the original's file path,
/// which Android 10 refuses, so every item imported there has none. This
/// fills them in from the encrypted payload itself, one item at a time, in
/// the background after unlock:
///
/// - **Photo:** decrypted and decoded in memory on the Android side, at a
///   reduced size (`previewFromPayload`). Nothing is written.
/// - **Video:** the playback route — decrypted into the app-private working
///   file, one frame taken, the working file shredded at once.
///
/// Each new preview is encrypted, read back (`verifyWritten`), and only then
/// recorded. A preview that cannot be made leaves the item as it was, with
/// its icon; it is tried again after the next unlock. Nothing here can fail
/// or change the item itself.
class VaultPreviewBackfillService {
  final VaultDao _vaultDao;
  final VaultCryptoService _crypto;
  final VaultStorageService _storage;
  final VaultShredderService _shredder;
  final VideoToolsChannel _videoTools;

  bool _running = false;
  Future<int>? _currentRun;

  VaultPreviewBackfillService({
    required VaultDao vaultDao,
    required VaultCryptoService crypto,
    required VaultStorageService storage,
    required VaultShredderService shredder,
    required VideoToolsChannel videoTools,
  }) : _vaultDao = vaultDao,
       _crypto = crypto,
       _storage = storage,
       _shredder = shredder,
       _videoTools = videoTools;

  /// Whether a run is going on now.
  bool get isRunning => _running;

  /// Completes when no run is going on. A vault batch waits for this, as it
  /// does for the format upgrade.
  Future<void> waitUntilIdle() async {
    final run = _currentRun;
    if (run != null) await run;
  }

  /// Fills in missing previews, returning how many were added.
  ///
  /// [shouldContinue] is asked before each item; the run stops when it says
  /// no (the vault locked, or a batch started). A second call during a run
  /// returns 0 at once.
  Future<int> fillAll({required bool Function() shouldContinue}) {
    if (_running) return Future<int>.value(0);
    final run = _runAll(shouldContinue);
    _currentRun = run;
    return run;
  }

  Future<int> _runAll(bool Function() shouldContinue) async {
    _running = true;
    var added = 0;
    try {
      final ids = await _vaultDao.getIdsWithoutPreview();
      for (final id in ids) {
        if (!shouldContinue()) break;
        try {
          if (await _fillOne(id)) added++;
        } catch (error) {
          AppLogger.debug('Making a missing vault preview failed');
        }
      }
    } catch (error) {
      AppLogger.warning(
        'Listing vault items without a preview failed',
        error: error,
      );
    } finally {
      _running = false;
      _currentRun = null;
    }
    if (added > 0) AppLogger.info('Added $added missing vault previews');
    return added;
  }

  /// Makes and records one preview. Returns whether the row changed.
  Future<bool> _fillOne(String id) async {
    final item = await _vaultDao.getVaultItemById(id);
    if (item == null) return false;
    if (item.encryptedThumbnailFilename != null && item.thumbnailIv != null) {
      return false; // Got one meanwhile.
    }

    final bytes = item.mediaType == MediaType.video
        ? await _videoFrame(item)
        : await _crypto.previewFromPayload(
            fileName: item.encryptedFilename,
            iv: item.iv,
            format: item.payloadFormat,
          );
    if (bytes == null || bytes.isEmpty) return false;

    final preview = await _crypto.encryptThumbnailBytes(bytes);
    try {
      await _crypto.verifyWritten(preview);
      final rows = await _vaultDao.updateEncryption(
        item.copyWith(
          encryptedThumbnailFilename: preview.fileName,
          thumbnailIv: preview.iv,
          thumbnailFormat: preview.format,
        ),
      );
      if (rows == 0) {
        await _delete(preview.fileName); // Deleted meanwhile.
        return false;
      }
    } catch (error) {
      await _delete(preview.fileName);
      rethrow;
    }

    // A preview file left from before schema 2 had no IV and could never be
    // opened. It only ever held ciphertext, so a plain delete is enough.
    final old = item.encryptedThumbnailFilename;
    if (old != null && old.isNotEmpty) await _delete(old);
    return true;
  }

  /// One frame of a vaulted video, through the app-private working file,
  /// which is shredded straight after whatever happens.
  Future<Uint8List?> _videoFrame(VaultItem item) async {
    final workingPath = await _crypto.decryptToWorkingFile(
      fileName: item.encryptedFilename,
      iv: item.iv,
      format: item.payloadFormat,
    );
    try {
      final frame = await _videoTools.grabFrame(
        path: workingPath,
        positionMs: 0,
        maxSide: AppConstants.vaultThumbnailSize,
      );
      return frame.isEmpty ? null : frame;
    } finally {
      await _shredder.shred(workingPath);
    }
  }

  Future<void> _delete(String fileName) async {
    await _shredder.shredAll(<String>[
      await _storage.pathFor(fileName),
    ], passes: 1);
  }
}
