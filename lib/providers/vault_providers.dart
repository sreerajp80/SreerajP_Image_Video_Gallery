import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_mode.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/backup_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/video_tools_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/device/secure_window_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_auth_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_import_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_key_service.dart';
import 'package:in_sreerajp_imgvidgal/core/domain/vault/vault_lock_policy.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_backfill_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_transfer_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_upgrade_service.dart';
import 'package:flutter_riverpod/legacy.dart';

// ------------------------------------------------------------------ plumbing

/// The single channel to the Android keystore, cipher, and shredder.
final vaultChannelProvider = Provider<VaultChannel>((ref) {
  return PlatformVaultChannel();
});

/// Owns the app-private directory the encrypted payloads live in.
final vaultStorageServiceProvider = Provider<VaultStorageService>((ref) {
  return VaultStorageService();
});

/// Creates and checks the Android Keystore master key.
final vaultKeyServiceProvider = Provider<VaultKeyService>((ref) {
  return VaultKeyService(channel: ref.watch(vaultChannelProvider));
});

/// Encrypts and decrypts vault payloads.
final vaultCryptoServiceProvider = Provider<VaultCryptoService>((ref) {
  return VaultCryptoService(
    channel: ref.watch(vaultChannelProvider),
    storage: ref.watch(vaultStorageServiceProvider),
  );
});

/// Overwrites file bytes before deleting them.
final vaultShredderServiceProvider = Provider<VaultShredderService>((ref) {
  return VaultShredderService(channel: ref.watch(vaultChannelProvider));
});

/// Builds vault previews in memory, never through the disk cache.
final vaultPreviewServiceProvider = Provider<VaultPreviewService>((ref) {
  return VaultPreviewService(
    videoTools: ref.watch(videoToolsChannelProvider),
    // Previews come from MediaStore's thumbnail when the item has a URI;
    // Android 10 does not let this app read shared photos by path.
    mediaStore: ref.watch(mediaStoreChannelProvider),
  );
});

/// Where the PIN salt and hash are kept.
final vaultCredentialStoreProvider = Provider<VaultCredentialStore>((ref) {
  return SecureVaultCredentialStore();
});

/// The biometric prompt.
final vaultBiometricServiceProvider = Provider<VaultBiometricService>((ref) {
  return LocalAuthBiometricService();
});

/// Decides who may open the vault.
final vaultAuthServiceProvider = Provider<VaultAuthService>((ref) {
  return VaultAuthService(
    store: ref.watch(vaultCredentialStoreProvider),
    biometricService: ref.watch(vaultBiometricServiceProvider),
    keyService: ref.watch(vaultKeyServiceProvider),
  );
});

/// Turns the screenshot and screen-recording block on and off.
final secureWindowServiceProvider = Provider<SecureWindowService>((ref) {
  return PlatformSecureWindowService(channel: ref.watch(vaultChannelProvider));
});

/// Data access object over the vault table.
final vaultDaoProvider = Provider<VaultDao>((ref) => VaultDao());

/// Moves media into the vault.
final vaultImportServiceProvider = Provider<VaultImportService>((ref) {
  return VaultImportService(
    crypto: ref.watch(vaultCryptoServiceProvider),
    storage: ref.watch(vaultStorageServiceProvider),
    shredder: ref.watch(vaultShredderServiceProvider),
    preview: ref.watch(vaultPreviewServiceProvider),
    vaultDao: ref.watch(vaultDaoProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    // Shredding a public original has to go through MediaStore on
    // Android 11+; a plain path write is refused there.
    mediaStore: ref.watch(mediaStoreChannelProvider),
  );
});

/// Takes media back out, and erases it for good.
final vaultExportServiceProvider = Provider<VaultExportService>((ref) {
  return VaultExportService(
    crypto: ref.watch(vaultCryptoServiceProvider),
    storage: ref.watch(vaultStorageServiceProvider),
    shredder: ref.watch(vaultShredderServiceProvider),
    vaultDao: ref.watch(vaultDaoProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    folderWriter: DocumentPickerFolderWriter(
      ref.watch(documentPickerChannelProvider),
    ),
  );
});

/// Copies the vault to another phone during a phone move, and takes vault
/// files from one.
final vaultTransferServiceProvider = Provider<VaultTransferService>((ref) {
  final auth = ref.watch(vaultAuthServiceProvider);
  return VaultTransferService(
    crypto: ref.watch(vaultCryptoServiceProvider),
    storage: ref.watch(vaultStorageServiceProvider),
    shredder: ref.watch(vaultShredderServiceProvider),
    preview: ref.watch(vaultPreviewServiceProvider),
    vaultDao: ref.watch(vaultDaoProvider),
    isReady: () async => await auth.isSetUp() && await auth.isKeystoreReady(),
  );
});

/// Converts old-format items to the fast format after unlock.
///
/// One instance for the app, so "is a run going on" means the same thing to
/// the lock controller and to the batch controller.
final vaultUpgradeServiceProvider = Provider<VaultUpgradeService>((ref) {
  return VaultUpgradeService(
    vaultDao: ref.watch(vaultDaoProvider),
    crypto: ref.watch(vaultCryptoServiceProvider),
    storage: ref.watch(vaultStorageServiceProvider),
    shredder: ref.watch(vaultShredderServiceProvider),
  );
});

/// Makes previews for vault items that have none, after unlock.
final vaultPreviewBackfillServiceProvider =
    Provider<VaultPreviewBackfillService>((ref) {
      return VaultPreviewBackfillService(
        vaultDao: ref.watch(vaultDaoProvider),
        crypto: ref.watch(vaultCryptoServiceProvider),
        storage: ref.watch(vaultStorageServiceProvider),
        shredder: ref.watch(vaultShredderServiceProvider),
        videoTools: ref.watch(videoToolsChannelProvider),
      );
    });

/// The only way the screens reach the vault.
final vaultRepositoryProvider = Provider<VaultRepository>((ref) {
  return VaultRepository(
    vaultDao: ref.watch(vaultDaoProvider),
    crypto: ref.watch(vaultCryptoServiceProvider),
    importService: ref.watch(vaultImportServiceProvider),
    exportService: ref.watch(vaultExportServiceProvider),
    storage: ref.watch(vaultStorageServiceProvider),
    shredder: ref.watch(vaultShredderServiceProvider),
  );
});

// --------------------------------------------------------------- lock state

/// Owns whether the vault is open, and shuts it when it should be.
///
/// The state lives here rather than in a widget so it survives a rebuild and
/// so nothing can hold an "unlocked" flag of its own. Locking is deliberately
/// cheap and total: the status flips, and every screen watching it is thrown
/// back to the gate on the same frame.
class VaultLockController extends StateNotifier<VaultLockState> {
  final VaultAuthService _authService;
  final VaultRepository _repository;
  final VaultUpgradeService? _upgradeService;
  final VaultPreviewBackfillService? _previewBackfill;
  final bool Function() _isBatchRunning;
  final void Function() _onItemsConverted;

  VaultLockController({
    required VaultAuthService authService,
    required VaultRepository repository,
    VaultUpgradeService? upgradeService,
    VaultPreviewBackfillService? previewBackfill,
    bool Function()? isBatchRunning,
    void Function()? onItemsConverted,
  }) : _authService = authService,
       _repository = repository,
       _upgradeService = upgradeService,
       _previewBackfill = previewBackfill,
       _isBatchRunning = isBatchRunning ?? _never,
       _onItemsConverted = onItemsConverted ?? _nothing,
       super(VaultLockState.initial);

  static bool _never() => false;
  static void _nothing() {}

  /// Reads whether the vault has been set up, without opening it.
  Future<void> refreshStatus() async {
    final setUp = await _authService.isSetUp();
    state = state.copyWith(
      status: setUp ? VaultLockStatus.locked : VaultLockStatus.notSetUp,
    );
  }

  /// Creates the vault with [pin] and opens it.
  Future<VaultAuthOutcome> setUp(String pin) async {
    final outcome = await _authService.setUpVault(pin);
    if (outcome.isSuccess) await _open();
    return outcome;
  }

  /// Tries [pin].
  ///
  /// A wrong PIN advances the back-off counter held in the state; enough of
  /// them shut the pad for a cool-down. The counter is in the lock state and
  /// not in storage, so it is cleared by a successful unlock — and not by
  /// restarting the app, which must not be a way around it.
  Future<VaultAuthOutcome> unlockWithPin(String pin) async {
    final now = DateTime.now();
    if (state.isLockedOutAt(now)) {
      return VaultAuthOutcome(
        status: VaultAuthStatus.lockedOut,
        lockoutSeconds: state.remainingLockoutSeconds(now),
      );
    }

    final outcome = await _authService.unlockWithPin(
      pin,
      failedAttempts: state.failedAttempts,
    );

    if (outcome.isSuccess) {
      await _open();
      return outcome;
    }

    if (outcome.status == VaultAuthStatus.wrongPin ||
        outcome.status == VaultAuthStatus.lockedOut) {
      state = VaultLockPolicy.afterFailedAttempt(state, now);
    }
    return outcome;
  }

  /// Creates the vault with the phone's own lock and opens it.
  Future<VaultAuthOutcome> setUpWithPhoneLock(String reason) async {
    final outcome = await _authService.setUpWithPhoneLock(reason: reason);
    if (outcome.isSuccess) await _open();
    return outcome;
  }

  /// Opens a phone-lock vault with Android's prompt.
  ///
  /// Android counts wrong tries and locks out on its own, so the app's PIN
  /// back-off is not involved.
  Future<VaultAuthOutcome> unlockWithPhoneLock(String reason) async {
    final outcome = await _authService.unlockWithPhoneLock(reason: reason);
    if (outcome.isSuccess) await _open();
    return outcome;
  }

  /// Tries the biometric prompt. [reason] is the localised line Android shows.
  Future<VaultAuthOutcome> unlockWithBiometrics(String reason) async {
    if (state.isLockedOutAt(DateTime.now())) {
      return VaultAuthOutcome(
        status: VaultAuthStatus.lockedOut,
        lockoutSeconds: state.remainingLockoutSeconds(DateTime.now()),
      );
    }
    final outcome = await _authService.unlockWithBiometrics(reason: reason);
    if (outcome.isSuccess) await _open();
    return outcome;
  }

  /// Shuts the vault.
  void lock() {
    if (!state.isUnlocked) return;
    state = state.copyWith(
      status: VaultLockStatus.locked,
      clearLastActivity: true,
    );
    // The data keyset leaves memory with the vault. Not awaited: the lock has
    // already happened, and this call never throws.
    _repository.forgetDataKey();
  }

  /// Records that the user did something, restarting the idle countdown.
  void noteActivity() {
    if (!state.isUnlocked) return;
    state = state.copyWith(lastActivityAt: DateTime.now());
  }

  /// Locks if [VaultLockPolicy] says the vault should be shut.
  ///
  /// Called by the auto-lock widget on a lifecycle change and on its timer.
  bool lockIfDue({
    required AppLifecycleState lifecycle,
    required int autoLockSeconds,
  }) {
    final reason = VaultLockPolicy.shouldLock(
      state: state,
      lifecycle: lifecycle,
      autoLockSeconds: autoLockSeconds,
      now: DateTime.now(),
    );
    if (reason == null) return false;
    lock();
    return true;
  }

  /// Opens the vault, sweeping the directory on the way in.
  Future<void> _open() async {
    // Shred anything a crash left decrypted, and drop payloads no row points
    // at, before a single tile is drawn.
    await _repository.prepareForUnlock();
    state = state.copyWith(
      status: VaultLockStatus.unlocked,
      lastActivityAt: DateTime.now(),
      failedAttempts: 0,
      clearLockout: true,
    );
    _startUpgrade();
  }

  /// Converts old-format items in the background. Not awaited: the grid
  /// shows at once, and old items still open while they wait their turn.
  void _startUpgrade() {
    final upgrade = _upgradeService;
    final backfill = _previewBackfill;
    if (upgrade == null && backfill == null) return;
    bool keepGoing() => mounted && state.isUnlocked && !_isBatchRunning();

    Future<void> run() async {
      final converted = upgrade == null
          ? 0
          : await upgrade.upgradeAll(shouldContinue: keepGoing);
      // Previews second: a converted item's preview is then made from its
      // new, fast payload.
      final added = backfill == null || !keepGoing()
          ? 0
          : await backfill.fillAll(shouldContinue: keepGoing);
      if ((converted > 0 || added > 0) && mounted) _onItemsConverted();
    }

    run();
  }
}

/// Whether the vault is open, and everything that decides it.
final vaultLockControllerProvider =
    StateNotifierProvider<VaultLockController, VaultLockState>((ref) {
      return VaultLockController(
        authService: ref.watch(vaultAuthServiceProvider),
        repository: ref.watch(vaultRepositoryProvider),
        upgradeService: ref.watch(vaultUpgradeServiceProvider),
        previewBackfill: ref.watch(vaultPreviewBackfillServiceProvider),
        isBatchRunning: () => ref.read(vaultBatchProgressProvider) != null,
        // Rows now point at new files; every view reloads them.
        onItemsConverted: () =>
            ref.read(vaultRevisionProvider.notifier).state++,
      );
    });

// ----------------------------------------------------------------- contents

/// Bumped whenever the vault changes, so every vault view refreshes together.
final vaultRevisionProvider = StateProvider<int>((ref) => 0);

/// How far along the running import, restore, or delete is.
///
/// Null when nothing is running. A batch can take a while — every file is
/// encrypted or decrypted in turn — so the screen shows real progress rather
/// than a spinner that says nothing.
final vaultBatchProgressProvider = StateProvider<VaultBatchProgress?>(
  (ref) => null,
);

/// Progress through one vault batch.
@immutable
class VaultBatchProgress {
  /// How many items are finished.
  final int done;

  /// How many items the batch holds.
  final int total;

  const VaultBatchProgress({required this.done, required this.total});

  /// Share of the work finished, 0 to 1.
  double get fraction => total <= 0 ? 0 : (done / total).clamp(0.0, 1.0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultBatchProgress &&
          runtimeType == other.runtimeType &&
          done == other.done &&
          total == other.total;

  @override
  int get hashCode => Object.hash(done, total);
}

/// Runs the vault's batch jobs and reports how they went.
///
/// Every write goes through here rather than straight from a screen, so the
/// revision dial is turned exactly once per batch and every vault view
/// refreshes together — and so a screen never holds a repository call of its
/// own that could outlive the widget that started it.
class VaultBatchController
    extends StateNotifier<AsyncValue<VaultBatchResult?>> {
  final VaultRepository _repository;
  final Ref _ref;

  VaultBatchController({required VaultRepository repository, required Ref ref})
    : _repository = repository,
      _ref = ref,
      super(const AsyncValue<VaultBatchResult?>.data(null));

  /// Moves gallery items into the vault.
  ///
  /// [shredOriginals] destroys the public copies for good and must only be
  /// true once the user has chosen it and confirmed it.
  Future<void> import(
    List<MediaItem> items, {
    required bool shredOriginals,
  }) async {
    await _run(
      items.length,
      (settings, report) => _repository.importFromGallery(
        items,
        shredOriginals: shredOriginals,
        shredPasses: settings.shredPasses,
        onProgress: report,
      ),
    );
  }

  /// The items in [items] whose original folder no longer exists.
  ///
  /// The screen asks the user for a folder for these before [restore].
  Future<List<VaultItem>> findItemsWithMissingFolder(List<VaultItem> items) =>
      _repository.itemsWithMissingFolder(items);

  /// Asks the user to pick a folder, or returns null if they backed out.
  ///
  /// A device with no folder picker also gives null, which the restore
  /// treats like Skip: those items stay safely in the vault.
  Future<String?> pickRestoreFolder() async {
    try {
      return await _ref.read(documentPickerChannelProvider).openFolder();
    } on DocumentPickerException catch (error) {
      AppLogger.warning('The folder picker could not be shown', error: error);
      return null;
    }
  }

  /// Restores vault items to public storage.
  ///
  /// Items whose original folder is gone go into [fallbackFolderUri]. Without
  /// one, they stay in the vault and are counted as skipped.
  Future<void> restore(
    List<VaultItem> items, {
    String? fallbackFolderUri,
  }) async {
    await _run(
      items.length,
      (settings, report) async => _repository.exportToGallery(
        await _fresh(items),
        shredPasses: settings.shredPasses,
        fallbackFolderUri: fallbackFolderUri,
        onProgress: report,
      ),
    );
  }

  /// Erases vault items and their payloads. There is no undo.
  Future<void> deleteForever(List<VaultItem> items) async {
    await _run(
      items.length,
      (settings, _) async => _repository.deleteForever(
        await _fresh(items),
        shredPasses: settings.shredPasses,
      ),
    );
  }

  /// The current rows for [items].
  ///
  /// The screen's list can be older than the background format upgrade,
  /// which gives a converted item new file names. Reading the rows again
  /// (after [_run] has waited for the upgrade to pause) means the batch works
  /// on the files that are really there.
  Future<List<VaultItem>> _fresh(List<VaultItem> items) =>
      _repository.getItemsByIds(items.map((i) => i.id).toList());

  /// Clears the last result, so a message is not shown twice.
  void clearResult() {
    state = const AsyncValue<VaultBatchResult?>.data(null);
  }

  Future<void> _run(
    int total,
    Future<VaultBatchResult> Function(
      VaultSecuritySettings settings,
      void Function(int done, int total) report,
    )
    action,
  ) async {
    if (total <= 0) return;
    state = const AsyncValue<VaultBatchResult?>.loading();
    _ref.read(vaultBatchProgressProvider.notifier).state = VaultBatchProgress(
      done: 0,
      total: total,
    );

    try {
      // The progress value above already tells the upgrade to stop; this
      // waits for the item it is converting right now to finish.
      await _ref.read(vaultUpgradeServiceProvider).waitUntilIdle();
      await _ref.read(vaultPreviewBackfillServiceProvider).waitUntilIdle();
      final settings = await _ref.read(vaultAuthServiceProvider).readSettings();
      final result = await action(settings, (done, batchTotal) {
        _ref.read(vaultBatchProgressProvider.notifier).state =
            VaultBatchProgress(done: done, total: batchTotal);
      });
      state = AsyncValue<VaultBatchResult?>.data(result);
    } catch (error, stackTrace) {
      state = AsyncValue<VaultBatchResult?>.error(error, stackTrace);
    } finally {
      _ref.read(vaultBatchProgressProvider.notifier).state = null;
      // One bump per batch, whatever happened: a partly finished import still
      // changed the vault, and every view has to see it.
      _ref.read(vaultRevisionProvider.notifier).state++;
    }
  }
}

/// The only place vault batches are started from.
final vaultBatchControllerProvider =
    StateNotifierProvider<VaultBatchController, AsyncValue<VaultBatchResult?>>((
      ref,
    ) {
      return VaultBatchController(
        repository: ref.watch(vaultRepositoryProvider),
        ref: ref,
      );
    });

/// The stored vault settings.
final vaultSettingsProvider = FutureProvider<VaultSecuritySettings>((
  ref,
) async {
  ref.watch(vaultRevisionProvider);
  return ref.watch(vaultAuthServiceProvider).readSettings();
});

/// Whether a biometric prompt can be offered right now.
final vaultBiometricAvailableProvider = FutureProvider<bool>((ref) async {
  ref.watch(vaultRevisionProvider);
  return ref.watch(vaultAuthServiceProvider).canUseBiometrics();
});

/// How the vault opens, or null when it has not been set up.
final vaultLockModeProvider = FutureProvider<VaultLockMode?>((ref) async {
  ref.watch(vaultRevisionProvider);
  // Only whether it is open matters here, not every touch.
  ref.watch(vaultLockControllerProvider.select((s) => s.status));
  return ref.watch(vaultAuthServiceProvider).lockMode();
});

/// Whether this phone has a secure lock screen, which phone lock needs.
///
/// Read fresh each time the vault screens ask (autoDispose), because the user
/// can turn the screen lock on or off in Android settings at any moment.
final vaultPhoneLockAvailableProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  return ref.watch(vaultAuthServiceProvider).canUsePhoneLock();
});

/// Whether this device can hold the vault's master key.
final vaultKeystoreReadyProvider = FutureProvider<bool>((ref) async {
  return ref.watch(vaultAuthServiceProvider).isKeystoreReady();
});

/// Whether the vault is open, and nothing else.
///
/// The lock state also carries the time of the last touch, which changes on
/// every pointer event for the auto-lock timer. The content providers below
/// watch this instead, so a touch reloads nothing: before, each tap and each
/// scroll step re-read the rows and decrypted every visible preview again,
/// and the grid swapped to a spinner mid-press, which cancelled long-press.
/// Locking still flips this, so a shut vault still holds nothing.
final _vaultOpenProvider = Provider<bool>((ref) {
  return ref.watch(
    vaultLockControllerProvider.select((lock) => lock.isUnlocked),
  );
});

/// Everything in the vault, newest first.
///
/// Empty while the vault is locked. Not "hidden" — actually not read, so a
/// locked vault has nothing in memory to leak.
final vaultItemsProvider = FutureProvider<List<VaultItem>>((ref) async {
  ref.watch(vaultRevisionProvider);
  if (!ref.watch(_vaultOpenProvider)) return const <VaultItem>[];
  return ref.watch(vaultRepositoryProvider).getItems();
});

/// One vault item opened for viewing.
///
/// A picture comes back as decrypted bytes held in memory only. A video comes
/// back as the path of a decrypted working file, which the caller must hand
/// to [VaultViewerActions.discardWorkingFile] when playback ends.
class VaultOpenedItem {
  final VaultItem item;
  final Uint8List? imageBytes;
  final String? videoWorkingPath;

  const VaultOpenedItem.image(this.item, Uint8List bytes)
    : imageBytes = bytes,
      videoWorkingPath = null;

  const VaultOpenedItem.video(this.item, String workingPath)
    : imageBytes = null,
      videoWorkingPath = workingPath;
}

/// What the vault viewer screen does with the repository.
class VaultViewerActions {
  final VaultRepository _repository;

  const VaultViewerActions(this._repository);

  /// Opens one item, or returns null when it no longer exists.
  ///
  /// Throws a `VaultException` when the stored payload fails its integrity
  /// check, so the screen can say the file was tampered with.
  Future<VaultOpenedItem?> open(String id) async {
    final item = await _repository.getItem(id);
    if (item == null) return null;
    if (item.mediaType == MediaType.video) {
      final path = await _repository.openVideoForPlayback(item);
      return VaultOpenedItem.video(item, path);
    }
    return VaultOpenedItem.image(item, await _repository.readImageBytes(item));
  }

  /// Starts shredding a video working file without waiting for it.
  ///
  /// Safe to call from `dispose`. Errors are swallowed on purpose: the sweep
  /// on the next unlock catches a shred that could not run, and there is no
  /// user here to tell.
  void discardWorkingFile(String path) {
    _repository.closeVideoPlayback(path).catchError((_) {});
  }
}

final vaultViewerActionsProvider = Provider<VaultViewerActions>((ref) {
  return VaultViewerActions(ref.watch(vaultRepositoryProvider));
});

/// One vault item by id, or null when the vault is shut or it is gone.
final vaultItemProvider = FutureProvider.family<VaultItem?, String>((
  ref,
  id,
) async {
  ref.watch(vaultRevisionProvider);
  if (!ref.watch(_vaultOpenProvider)) return null;
  return ref.watch(vaultRepositoryProvider).getItem(id);
});

/// The decrypted preview bytes for one tile.
///
/// Kept alive only while something is watching it, so locking the vault drops
/// every decrypted preview along with the widgets that were showing them.
final vaultThumbnailProvider = FutureProvider.family<Uint8List?, String>((
  ref,
  itemId,
) async {
  // A batch or the preview backfill bumps the revision, so a tile that had
  // no preview picks up a new one without reopening the vault.
  ref.watch(vaultRevisionProvider);
  if (!ref.watch(_vaultOpenProvider)) return null;
  final repository = ref.watch(vaultRepositoryProvider);
  final item = await repository.getItem(itemId);
  if (item == null) return null;
  return repository.readThumbnailBytes(item);
});
