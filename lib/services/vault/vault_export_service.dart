import 'dart:io';

import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/convert/output_naming_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:path/path.dart' as p;
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Writes a decrypted vault file into a folder the user picked.
///
/// Used only when an item's original folder is gone. The real one goes through
/// the Storage Access Framework (see `DocumentPickerChannel.writeToFolder`);
/// tests use a fake. It must never overwrite a file already in the folder.
abstract interface class VaultFolderWriter {
  /// Copies [sourcePath] into [folderUri] as a new file named [displayName].
  Future<void> write({
    required String folderUri,
    required String displayName,
    required String mimeType,
    required String sourcePath,
  });
}

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
  final VaultFolderWriter? _folderWriter;

  VaultExportService({
    required VaultCryptoService crypto,
    required VaultStorageService storage,
    required VaultShredderService shredder,
    required VaultDao vaultDao,
    required MediaDao mediaDao,
    OutputNamingService naming = const OutputNamingService(),
    VaultFolderWriter? folderWriter,
  }) : _crypto = crypto,
       _storage = storage,
       _shredder = shredder,
       _vaultDao = vaultDao,
       _mediaDao = mediaDao,
       _naming = naming,
       _folderWriter = folderWriter;

  /// The items in [items] whose original folder no longer exists.
  ///
  /// Only checks; writes nothing. The screen uses it to ask the user for a
  /// folder before the restore starts.
  List<VaultItem> itemsWithMissingFolder(List<VaultItem> items) =>
      items.where((item) => _restoreSeedPath(item) == null).toList();

  /// Restores [items] to public storage and takes them out of the vault.
  ///
  /// An item whose original folder is gone goes into [fallbackFolderUri], a
  /// folder the user picked. Without one, that item is skipped and stays in
  /// the vault. It is never written anywhere the user did not choose.
  Future<VaultBatchResult> exportItems(
    List<VaultItem> items, {
    int? shredPasses,
    String? fallbackFolderUri,
    void Function(int done, int total)? onProgress,
  }) async {
    if (items.isEmpty) return VaultBatchResult.empty;

    final restored = <String>[];
    var failed = 0;
    var skipped = 0;

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      try {
        final seed = _restoreSeedPath(item);
        if (seed != null) {
          await _exportOne(item, seed, shredPasses: shredPasses);
          restored.add(item.id);
        } else if (fallbackFolderUri != null && fallbackFolderUri.isNotEmpty) {
          await _exportToFolder(
            item,
            fallbackFolderUri,
            shredPasses: shredPasses,
          );
          restored.add(item.id);
        } else {
          skipped++;
        }
      } catch (error) {
        AppLogger.warning('Restoring one vault item failed', error: error);
        failed++;
      }
      onProgress?.call(index + 1, items.length);
    }

    return VaultBatchResult(
      succeededIds: restored,
      failedCount: failed,
      skippedCount: skipped,
    );
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
      } catch (error) {
        AppLogger.warning('Removing one vault item failed', error: error);
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
  Future<File> _exportOne(
    VaultItem item,
    String destinationSeed, {
    int? shredPasses,
  }) async {
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

    await _finishRestore(item, shredPasses: shredPasses);
    return written;
  }

  /// Restores one item into a folder the user picked.
  ///
  /// Photos and videos alike are decrypted into a working file inside the
  /// app-private vault folder, copied out by the folder writer, and the
  /// working file is shredded whatever happened.
  Future<void> _exportToFolder(
    VaultItem item,
    String folderUri, {
    int? shredPasses,
  }) async {
    final writer = _folderWriter;
    if (writer == null) {
      throw const VaultException(
        'No folder writer is available',
        code: 'no_folder_writer',
      );
    }

    final workingPath = await _crypto.decryptToWorkingFile(
      fileName: item.encryptedFilename,
      iv: item.iv,
    );
    try {
      await writer.write(
        folderUri: folderUri,
        displayName: _folderDisplayName(item),
        mimeType: item.mimeType,
        sourcePath: workingPath,
      );
    } finally {
      await _shredder.shred(workingPath, passes: shredPasses);
    }

    await _finishRestore(item, shredPasses: shredPasses);
  }

  /// Tears down the vault side once the file is safely out.
  Future<void> _finishRestore(VaultItem item, {int? shredPasses}) async {
    // Only now is the vault side torn down.
    await _shredPayloads(item, shredPasses: shredPasses);
    await _vaultDao.deleteVaultItem(item.id);

    // Let the gallery show the original row again, if it is still there.
    // The restored file is a new one and the next scan will index it; this
    // just stops the old row from staying hidden forever.
    await _clearVaultedFlag(item);
  }

  /// The name a restored file gets in a picked folder, e.g. `photo_vault.jpg`.
  String _folderDisplayName(VaultItem item) {
    final original = p.basename(item.originalFilename);
    final stem = p.basenameWithoutExtension(original);
    final safeStem = stem.isEmpty ? 'restored' : stem;
    return '$safeStem${AppConstants.vaultExportSuffix}${p.extension(original)}';
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
      // Safe to ignore: the original row may be long gone, which is normal; the
      // restore has already succeeded.
      // The original row may be long gone, which is normal when the original
      // was shredded on import. The restore itself has already succeeded.
    }
  }

  /// Where a restored file should be written, or null if its folder is gone.
  ///
  /// Beside the original when its folder still exists, so a photo comes back
  /// where the user expects it. When the folder is gone, null: the app does
  /// not re-create it (the user may have deleted it on purpose), and it never
  /// writes a bare file name, which would land in whatever the process's
  /// current folder happens to be. The caller asks the user for a folder.
  String? _restoreSeedPath(VaultItem item) {
    final original = item.originalPath;
    if (original.isEmpty || !p.isAbsolute(original)) return null;
    final directory = p.dirname(original);
    if (directory.isEmpty || directory == original) return null;
    return Directory(directory).existsSync() ? original : null;
  }
}

/// The real [VaultFolderWriter], backed by the Storage Access Framework.
class DocumentPickerFolderWriter implements VaultFolderWriter {
  final DocumentPickerChannel _picker;

  const DocumentPickerFolderWriter(this._picker);

  @override
  Future<void> write({
    required String folderUri,
    required String displayName,
    required String mimeType,
    required String sourcePath,
  }) async {
    await _picker.writeToFolder(
      treeUri: folderUri,
      displayName: displayName,
      mimeType: mimeType,
      sourcePath: sourcePath,
    );
  }
}
