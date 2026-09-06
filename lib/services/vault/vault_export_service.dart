import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;

/// Takes media back out of the vault, and removes it for good.
///
/// Export runs the import in reverse and in the same careful order: the file
/// is written back into public storage first, and only once it is safely there
/// is the payload shredded and the row dropped. A failure part way through
/// leaves the item still in the vault, which is the recoverable outcome.
///
/// Deleting for good is the other way round on purpose — the payload is shred
/// first, then the row — because there the user has asked for the content to
/// be gone, and a leftover row pointing at nothing is a far smaller problem
/// than a leftover payload nothing points at.
class VaultExportService {
  final VaultCryptoService _crypto;
  final VaultStorageService _storage;
  final VaultShredderService _shredder;
  final VaultDao _vaultDao;
  final MediaDao _mediaDao;
  final OutputNamingService _naming;

  VaultExportService({
    required VaultCryptoService crypto,
    required VaultStorageService storage,
    required VaultShredderService shredder,
    required VaultDao vaultDao,
    required MediaDao mediaDao,
    OutputNamingService naming = const OutputNamingService(),
  }) : _crypto = crypto,
       _storage = storage,
       _shredder = shredder,
       _vaultDao = vaultDao,
       _mediaDao = mediaDao,
       _naming = naming;

  /// Restores [items] to public storage and takes them out of the vault.
  Future<VaultBatchResult> exportItems(
    List<VaultItem> items, {
    int? shredPasses,
    void Function(int done, int total)? onProgress,
  }) async {
    if (items.isEmpty) return VaultBatchResult.empty;

    final restored = <String>[];
    var failed = 0;

    for (var index = 0; index < items.length; index++) {
      try {
        await _exportOne(items[index], shredPasses: shredPasses);
        restored.add(items[index].id);
      } catch (_) {
        failed++;
      }
      onProgress?.call(index + 1, items.length);
    }

    return VaultBatchResult(succeededIds: restored, failedCount: failed);
  }

  /// Erases [items] and their payloads for good.
  ///
  /// There is no undo. The caller must have confirmed this with the user.
  Future<VaultBatchResult> deleteForever(
    List<VaultItem> items, {
    int? shredPasses,
  }) async {
    if (items.isEmpty) return VaultBatchResult.empty;

    final removed = <String>[];
    var failed = 0;
    var shredded = 0;

    for (final item in items) {
      try {
        shredded += await _shredPayloads(item, shredPasses: shredPasses);
        await _vaultDao.deleteVaultItem(item.id);
        removed.add(item.id);
      } catch (_) {
        failed++;
      }
    }

    return VaultBatchResult(
      succeededIds: removed,
      failedCount: failed,
      shreddedCount: shredded,
    );
  }

  /// Restores one item beside where it came from.
  Future<File> _exportOne(VaultItem item, {int? shredPasses}) async {
    final destinationSeed = _restoreSeedPath(item);

    // 1. Decrypt and write it back out. Only after this file exists is
    // anything inside the vault disturbed.
    final File written;
    if (item.sizeBytes <= AppConstants.vaultMaxDecryptToMemoryBytes) {
      // A photo. It goes through memory and is written atomically, so an
      // interrupted restore cannot leave a half-file wearing a real name.
      final bytes = await _crypto.decryptToMemory(
        fileName: item.encryptedFilename,
        iv: item.iv,
      );
      written = await _naming.saveBytes(
        sourcePath: destinationSeed,
        suffix: AppConstants.vaultExportSuffix,
        extension: p.extension(item.originalFilename),
        bytes: bytes,
      );
    } else {
      // A video, too large to hold in memory. It is decrypted into a working
      // file inside the vault directory and then moved out, so the plaintext
      // only ever exists in app-private storage until the move completes.
      final workingPath = await _crypto.decryptToWorkingFile(
        fileName: item.encryptedFilename,
        iv: item.iv,
      );
      final targetPath = _naming.reserveOutputPath(
        sourcePath: destinationSeed,
        suffix: AppConstants.vaultExportSuffix,
        extension: p.extension(item.originalFilename),
      );
      try {
        written = await _copyStreamed(workingPath, targetPath);
      } finally {
        // The working copy goes whatever happened, so a failed restore does
        // not leave a readable video sitting in the vault directory.
        await _shredder.shred(workingPath, passes: shredPasses);
      }
    }

    // 2. Only now is the vault side torn down.
    await _shredPayloads(item, shredPasses: shredPasses);
    await _vaultDao.deleteVaultItem(item.id);

    // 3. Let the gallery show the original row again, if it is still there.
    // The restored file is a new one and the next scan will index it; this
    // just stops the old row from staying hidden forever.
    await _clearVaultedFlag(item);

    return written;
  }

  /// Copies a large file without pulling it into memory.
  ///
  /// `AtomicSaver.copyAtomic` reads the whole source into a byte list, which
  /// is fine for a photo and reckless for a two gigabyte video. This does what
  /// that method does for the part that matters — write to a side name, then
  /// rename into place, so an interrupted copy never leaves a half-file
  /// wearing the real name — while letting the platform stream the bytes.
  Future<File> _copyStreamed(String sourcePath, String targetPath) async {
    final staging = File('$targetPath.part');
    if (await staging.exists()) await staging.delete();

    final parent = staging.parent;
    if (!await parent.exists()) await parent.create(recursive: true);

    await File(sourcePath).copy(staging.path);
    return staging.rename(targetPath);
  }

  /// Shreds an item's payload and preview, returning how many went.
  Future<int> _shredPayloads(VaultItem item, {int? shredPasses}) async {
    final paths = <String>[await _storage.pathFor(item.encryptedFilename)];
    final thumbnail = item.encryptedThumbnailFilename;
    if (thumbnail != null && thumbnail.isNotEmpty) {
      paths.add(await _storage.pathFor(thumbnail));
    }
    return _shredder.shredAll(paths, passes: shredPasses);
  }

  /// Clears `is_vaulted` on the media row this item came from, if it survives.
  Future<void> _clearVaultedFlag(VaultItem item) async {
    if (item.originalPath.isEmpty) return;
    try {
      final media = await _mediaDao.getMediaItemByPath(item.originalPath);
      if (media != null) await _mediaDao.updateVaulted(media.id, false);
    } catch (_) {
      // The original row may be long gone, which is normal when the original
      // was shredded on import. The restore itself has already succeeded.
    }
  }

  /// Where a restored file should be written.
  ///
  /// Beside the original when its folder still exists, so a photo comes back
  /// where the user expects it. Otherwise the original name alone, which lands
  /// it in the app's own directory rather than failing the restore over a
  /// folder that has since been deleted.
  String _restoreSeedPath(VaultItem item) {
    final original = item.originalPath;
    if (original.isNotEmpty) {
      final directory = p.dirname(original);
      if (directory.isNotEmpty && Directory(directory).existsSync()) {
        return original;
      }
    }
    return item.originalFilename;
  }
}
