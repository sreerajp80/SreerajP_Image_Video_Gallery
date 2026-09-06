import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_import_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

/// The only way the app reads or changes the vault.
///
/// Screens and widgets talk to this and to nothing below it. They never see a
/// DAO, a cipher, a file path, or an initialisation vector — which is the
/// point: a widget that cannot reach the crypto layer cannot accidentally
/// leave a decrypted file somewhere, and there is exactly one place to look
/// when asking what the vault does.
class VaultRepository {
  final VaultDao _vaultDao;
  final VaultCryptoService _crypto;
  final VaultImportService _importService;
  final VaultExportService _exportService;
  final VaultStorageService _storage;
  final VaultShredderService _shredder;

  VaultRepository({
    required VaultDao vaultDao,
    required VaultCryptoService crypto,
    required VaultImportService importService,
    required VaultExportService exportService,
    required VaultStorageService storage,
    required VaultShredderService shredder,
  }) : _vaultDao = vaultDao,
       _crypto = crypto,
       _importService = importService,
       _exportService = exportService,
       _storage = storage,
       _shredder = shredder;

  // ------------------------------------------------------------------ reads

  /// Every item in the vault, newest first.
  Future<List<VaultItem>> getItems({int? limit, int? offset}) =>
      _vaultDao.getAllVaultItems(limit: limit, offset: offset);

  /// One item, or null when it is not there.
  Future<VaultItem?> getItem(String id) => _vaultDao.getVaultItemById(id);

  /// Several items by id.
  Future<List<VaultItem>> getItemsByIds(List<String> ids) =>
      _vaultDao.getVaultItemsByIds(ids);

  /// How many items the vault holds.
  Future<int> count() => _vaultDao.getVaultItemsCount();

  /// The decrypted preview for a tile, or null when there is none.
  ///
  /// Returns bytes, never a path. A vault preview is only ever held in memory,
  /// so a locked vault leaves nothing readable behind.
  Future<Uint8List?> readThumbnailBytes(VaultItem item) async {
    final name = item.encryptedThumbnailFilename;
    final iv = item.thumbnailIv;
    // Both, or nothing. The preview has its own IV, and reaching for the
    // payload's instead would hand the cipher a key stream that was never
    // used on these bytes.
    if (name == null || name.isEmpty || iv == null || iv.isEmpty) return null;
    try {
      return await _crypto.decryptToMemory(fileName: name, iv: iv);
    } catch (_) {
      // A preview that will not decrypt is a cosmetic loss; the tile falls
      // back to an icon and the item itself is untouched.
      return null;
    }
  }

  /// The decrypted full image for the viewer.
  ///
  /// Only for pictures. Video goes through [openVideoForPlayback], because the
  /// platform player cannot read from memory.
  Future<Uint8List> readImageBytes(VaultItem item) =>
      _crypto.decryptToMemory(fileName: item.encryptedFilename, iv: item.iv);

  /// Decrypts a clip into a working file and returns its path.
  ///
  /// The caller **must** call [closeVideoPlayback] with the returned path when
  /// the player closes. The file sits inside the app-private vault directory —
  /// not the public cache, not the temporary directory — and the sweep in
  /// [prepareForUnlock] shreds any that a crash left behind.
  Future<String> openVideoForPlayback(VaultItem item) => _crypto
      .decryptToWorkingFile(fileName: item.encryptedFilename, iv: item.iv);

  /// Shreds the working file a video playback was reading from.
  Future<void> closeVideoPlayback(String workingPath, {int? shredPasses}) =>
      _shredder.shred(workingPath, passes: shredPasses);

  // ----------------------------------------------------------------- writes

  /// Moves gallery items into the vault.
  ///
  /// [shredOriginals] destroys the public copies for good, and must only be
  /// true after the user has chosen it and confirmed it.
  Future<VaultBatchResult> importFromGallery(
    List<MediaItem> items, {
    bool shredOriginals = false,
    int? shredPasses,
    void Function(int done, int total)? onProgress,
  }) => _importService.importItems(
    items,
    shredOriginals: shredOriginals,
    shredPasses: shredPasses,
    onProgress: onProgress,
  );

  /// Restores items to public storage and takes them out of the vault.
  Future<VaultBatchResult> exportToGallery(
    List<VaultItem> items, {
    int? shredPasses,
    void Function(int done, int total)? onProgress,
  }) => _exportService.exportItems(
    items,
    shredPasses: shredPasses,
    onProgress: onProgress,
  );

  /// Erases items and their payloads for good. There is no undo.
  Future<VaultBatchResult> deleteForever(
    List<VaultItem> items, {
    int? shredPasses,
  }) => _exportService.deleteForever(items, shredPasses: shredPasses);

  /// Changes the name an item is listed under.
  ///
  /// Only the record changes; the payload and its name on disk stay as they
  /// are, because the on-disk name is random by design and says nothing.
  Future<void> rename(VaultItem item, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    await _vaultDao.updateVaultItem(item.copyWith(originalFilename: trimmed));
  }

  /// Replaces an item's private notes.
  Future<void> setNotes(VaultItem item, String? notes) =>
      _vaultDao.updateVaultItem(item.copyWith(notes: notes));

  /// Replaces an item's tags.
  Future<void> setTags(VaultItem item, List<String> tags) =>
      _vaultDao.updateVaultItem(item.copyWith(tags: tags));

  // ----------------------------------------------------------------- hygiene

  /// Sweeps the vault directory before it is shown.
  ///
  /// Two jobs, both cleaning up after a crash rather than after normal use.
  /// Decrypted working files are shredded, because a kill during video
  /// playback can leave one readable on disk. Encrypted payloads that no row
  /// points at are deleted, because an import that wrote its payload and then
  /// failed leaves a file the user can neither see nor reach.
  ///
  /// Never throws. A sweep that fails must not stop someone opening their own
  /// vault.
  Future<void> prepareForUnlock({int? shredPasses}) async {
    try {
      final working = await _storage.findWorkingFiles();
      await _shredder.shredAll(working, passes: shredPasses);
    } catch (_) {
      // Nothing actionable; the next unlock tries again.
    }

    try {
      final known = await _vaultDao.getAllEncryptedFilenames();
      final orphans = await _storage.findOrphanPayloads(known);
      // Plain deletes: these have only ever held ciphertext, and shredding
      // them would spend a lot of writes to hide nothing.
      await _shredder.shredAll(orphans, passes: 1);
    } catch (_) {
      // Same again.
    }
  }
}
