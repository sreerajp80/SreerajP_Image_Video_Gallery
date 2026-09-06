import 'dart:typed_data';

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_auth_outcome.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_import_result.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_lock_state.dart';
import 'package:in_sreerajp_imgvidgal/models/vault/vault_security_settings.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/vault_item.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/video_tools_providers.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/vault_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/vault_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/device/secure_window_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_auth_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_biometric_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_credential_store.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_crypto_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_export_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_import_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_key_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_lock_policy.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_preview_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_shredder_service.dart';
import 'package:in_sreerajp_imgvidgal/services/vault/vault_storage_service.dart';

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
  return VaultPreviewService(videoTools: ref.watch(videoToolsChannelProvider));
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

  VaultLockController({
    required VaultAuthService authService,
    required VaultRepository repository,
  }) : _authService = authService,
       _repository = repository,
       super(VaultLockState.initial);

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
  }
}

/// Whether the vault is open, and everything that decides it.
final vaultLockControllerProvider =
    StateNotifierProvider<VaultLockController, VaultLockState>((ref) {
      return VaultLockController(
        authService: ref.watch(vaultAuthServiceProvider),
        repository: ref.watch(vaultRepositoryProvider),
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

  /// Restores vault items to public storage.
  Future<void> restore(List<VaultItem> items) async {
    await _run(
      items.length,
      (settings, report) => _repository.exportToGallery(
        items,
        shredPasses: settings.shredPasses,
        onProgress: report,
      ),
    );
  }

  /// Erases vault items and their payloads. There is no undo.
  Future<void> deleteForever(List<VaultItem> items) async {
    await _run(
      items.length,
      (settings, _) =>
          _repository.deleteForever(items, shredPasses: settings.shredPasses),
    );
  }

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

/// Whether this device can hold the vault's master key.
final vaultKeystoreReadyProvider = FutureProvider<bool>((ref) async {
  return ref.watch(vaultAuthServiceProvider).isKeystoreReady();
});

/// Everything in the vault, newest first.
///
/// Empty while the vault is locked. Not "hidden" — actually not read, so a
/// locked vault has nothing in memory to leak.
final vaultItemsProvider = FutureProvider<List<VaultItem>>((ref) async {
  ref.watch(vaultRevisionProvider);
  final lock = ref.watch(vaultLockControllerProvider);
  if (!lock.isUnlocked) return const <VaultItem>[];
  return ref.watch(vaultRepositoryProvider).getItems();
});

/// One vault item by id, or null when the vault is shut or it is gone.
final vaultItemProvider = FutureProvider.family<VaultItem?, String>((
  ref,
  id,
) async {
  ref.watch(vaultRevisionProvider);
  final lock = ref.watch(vaultLockControllerProvider);
  if (!lock.isUnlocked) return null;
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
  final lock = ref.watch(vaultLockControllerProvider);
  if (!lock.isUnlocked) return null;
  final repository = ref.watch(vaultRepositoryProvider);
  final item = await repository.getItem(itemId);
  if (item == null) return null;
  return repository.readThumbnailBytes(item);
});
