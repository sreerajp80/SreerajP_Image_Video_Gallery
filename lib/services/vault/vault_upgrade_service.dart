import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_crypto_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

/// Converts old-format vault items to the current, fast format.
///
/// Old items (format 1) were encrypted straight under the Keystore key, so
/// every byte has to go through the secure hardware to be read, which is
/// slow. This re-encrypts them under the data keyset (format 2), one item at
/// a time, in the background after the vault unlocks.
///
/// The order of the steps is what keeps it safe:
///
/// 1. Decrypt the old file and write the new one under a **new** name.
/// 2. Point the row at the new file in one update.
/// 3. Only then delete the old file.
///
/// A crash at any point leaves either the old row with the old file or the
/// new row with the new file. The leftover file is ciphertext nobody points
/// at, and the orphan sweep on the next unlock removes it.
///
/// Nothing decrypted touches disk in the clear except a video's working file,
/// which is the same app-private file playback uses and is shredded at once.
class VaultUpgradeService {
  final VaultDao _vaultDao;
  final VaultCryptoService _crypto;
  final VaultStorageService _storage;
  final VaultShredderService _shredder;

  bool _running = false;
  Future<int>? _currentRun;

  VaultUpgradeService({
    required VaultDao vaultDao,
    required VaultCryptoService crypto,
    required VaultStorageService storage,
    required VaultShredderService shredder,
  }) : _vaultDao = vaultDao,
       _crypto = crypto,
       _storage = storage,
       _shredder = shredder;

  /// Whether a run is going on now.
  bool get isRunning => _running;

  /// Completes when no run is going on.
  ///
  /// A vault batch calls this after it has made [upgradeAll]'s
  /// `shouldContinue` return false, so the item being converted right now is
  /// finished before the batch reads its rows.
  Future<void> waitUntilIdle() async {
    final run = _currentRun;
    if (run != null) await run;
  }

  /// Converts every old-format item, returning how many were converted.
  ///
  /// [shouldContinue] is asked before each item. The caller returns false
  /// when the vault locks or a vault batch starts, and the run stops there;
  /// the rest is converted after the next unlock. A second call while a run
  /// is going returns 0 at once.
  ///
  /// One item that fails is logged and skipped, never fatal: it still opens
  /// in the old format and is tried again next time.
  Future<int> upgradeAll({required bool Function() shouldContinue}) {
    if (_running) return Future<int>.value(0);
    final run = _runAll(shouldContinue);
    _currentRun = run;
    return run;
  }

  Future<int> _runAll(bool Function() shouldContinue) async {
    _running = true;
    var converted = 0;
    try {
      final ids = await _vaultDao.getLegacyFormatIds();
      for (final id in ids) {
        if (!shouldContinue()) break;
        try {
          if (await _upgradeOne(id)) converted++;
        } on VaultException catch (error) {
          if (error.code == 'verify_failed') {
            // A file that does not read back the same most likely means
            // something is wrong on this device, not with this one item.
            // Stop, rather than spend slow old-format reads on every other
            // item only to fail the same way. The old files are all still
            // there; the next unlock tries again.
            AppLogger.warning('A converted vault file failed its read-back');
            break;
          }
          AppLogger.warning('Converting one vault item failed', error: error);
        } catch (error) {
          AppLogger.warning('Converting one vault item failed', error: error);
        }
      }
    } catch (error) {
      AppLogger.warning('Listing old-format vault items failed', error: error);
    } finally {
      _running = false;
      _currentRun = null;
    }
    if (converted > 0) {
      AppLogger.info('Converted $converted vault items to the new format');
    }
    return converted;
  }

  /// Converts one item. Returns whether its row changed.
  Future<bool> _upgradeOne(String id) async {
    final item = await _vaultDao.getVaultItemById(id);
    if (item == null) return false;

    final written = <String>[];
    final replaced = <String>[];
    var updated = item;

    try {
      if (item.payloadFormat == AppConstants.vaultPayloadFormatLegacy) {
        final payload = await _reencryptPayload(item);
        written.add(payload.fileName);
        // Read back before the row moves and the old file goes.
        await _crypto.verifyWritten(payload);
        replaced.add(item.encryptedFilename);
        updated = updated.copyWith(
          encryptedFilename: payload.fileName,
          iv: payload.iv,
          sizeBytes: payload.cipherSizeBytes,
          payloadFormat: payload.format,
        );
      }

      final thumbnail = await _reencryptThumbnail(item);
      if (thumbnail != null) {
        written.add(thumbnail.fileName);
        replaced.add(item.encryptedThumbnailFilename!);
        updated = updated.copyWith(
          encryptedThumbnailFilename: thumbnail.fileName,
          thumbnailIv: thumbnail.iv,
          thumbnailFormat: thumbnail.format,
        );
      }

      if (written.isEmpty) return false;

      final rows = await _vaultDao.updateEncryption(updated);
      if (rows == 0) {
        // Deleted while we worked. The new files belong to nobody.
        await _deleteAll(written);
        return false;
      }
    } catch (error) {
      await _deleteAll(written);
      rethrow;
    }

    // The row now points at the new files. The old ones only ever held
    // ciphertext, so a plain delete is enough, as in the orphan sweep.
    await _deleteAll(replaced);
    return true;
  }

  /// Writes the payload again in the new format.
  ///
  /// A photo goes through memory. A video, or anything too large for memory,
  /// goes through the app-private working file, shredded straight after.
  Future<VaultCryptoResult> _reencryptPayload(VaultItem item) async {
    final throughMemory =
        item.mediaType != MediaType.video &&
        item.sizeBytes <= AppConstants.vaultMaxDecryptToMemoryBytes;

    if (throughMemory) {
      final bytes = await _crypto.decryptToMemory(
        fileName: item.encryptedFilename,
        iv: item.iv,
        format: item.payloadFormat,
      );
      return _crypto.encryptBytesToPayload(bytes);
    }

    final workingPath = await _crypto.decryptToWorkingFile(
      fileName: item.encryptedFilename,
      iv: item.iv,
      format: item.payloadFormat,
    );
    try {
      return await _crypto.encryptToPayload(sourcePath: workingPath);
    } finally {
      await _shredder.shred(workingPath);
    }
  }

  /// Writes the preview again in the new format, or returns null when there
  /// is nothing to convert or it will not decrypt.
  ///
  /// A preview that will not decrypt is a cosmetic loss, the same rule the
  /// grid uses; it must not stop the payload from being converted.
  Future<VaultCryptoResult?> _reencryptThumbnail(VaultItem item) async {
    final name = item.encryptedThumbnailFilename;
    final iv = item.thumbnailIv;
    if (name == null || name.isEmpty || iv == null || iv.isEmpty) return null;
    if (item.thumbnailFormat != AppConstants.vaultPayloadFormatLegacy) {
      return null;
    }
    try {
      final bytes = await _crypto.decryptToMemory(
        fileName: name,
        iv: iv,
        format: item.thumbnailFormat,
      );
      final thumbnail = await _crypto.encryptThumbnailBytes(bytes);
      try {
        await _crypto.verifyWritten(thumbnail);
      } catch (error) {
        await _deleteAll(<String>[thumbnail.fileName]);
        rethrow;
      }
      return thumbnail;
    } catch (error) {
      // The old preview stays, still readable, and is tried again next time.
      AppLogger.debug('Converting a vault preview failed');
      return null;
    }
  }

  Future<void> _deleteAll(List<String> fileNames) async {
    final paths = <String>[
      for (final name in fileNames) await _storage.pathFor(name),
    ];
    await _shredder.shredAll(paths, passes: 1);
  }
}
