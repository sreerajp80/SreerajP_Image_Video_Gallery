import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/backup/restore_summary.dart';
import 'package:in_sreerajp_imgvidgal/providers/album_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/providers/tag_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_apply_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_collector_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_crypto_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/backup_service.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/document_picker_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/backup/restore_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Password-derived ciphers, on the Android side.
final backupCryptoChannelProvider = Provider<BackupCryptoChannel>((ref) {
  return BackupCryptoChannel();
});

/// The system file picker.
final documentPickerChannelProvider = Provider<DocumentPickerChannel>((ref) {
  return DocumentPickerChannel();
});

/// Reads the database into a backup payload.
final backupCollectorProvider = Provider<BackupCollectorService>((ref) {
  return BackupCollectorService(
    mediaDao: ref.watch(mediaDaoProvider),
    tagDao: ref.watch(tagDaoProvider),
    albumDao: ref.watch(albumDaoProvider),
  );
});

/// Writes a payload back into the database.
final backupApplyServiceProvider = Provider<BackupApplyService>((ref) {
  return BackupApplyService(
    tagRepository: ref.watch(tagRepositoryProvider),
    albumRepository: ref.watch(albumRepositoryProvider),
    mediaDao: ref.watch(mediaDaoProvider),
  );
});

/// The whole backup write path.
final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    collector: ref.watch(backupCollectorProvider),
    crypto: ref.watch(backupCryptoChannelProvider),
    picker: ref.watch(documentPickerChannelProvider),
  );
});

/// The whole restore read path.
final restoreServiceProvider = Provider<RestoreService>((ref) {
  return RestoreService(
    crypto: ref.watch(backupCryptoChannelProvider),
    picker: ref.watch(documentPickerChannelProvider),
    apply: ref.watch(backupApplyServiceProvider),
    mediaRepository: ref.watch(mediaRepositoryProvider),
    tagRepository: ref.watch(tagRepositoryProvider),
    albumRepository: ref.watch(albumRepositoryProvider),
  );
});

/// The app's own version, for the archive manifest.
final appVersionProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  } catch (_) {
    // The manifest records this for the user's benefit, not the app's. An
    // unknown version is a worse detail line, not a reason to refuse a backup.
    return 'unknown';
  }
});

/// Which stage a running backup has reached, or null when none is running.
final backupStageProvider = StateProvider<BackupStage?>((ref) => null);

/// Makes a backup.
class BackupController extends StateNotifier<AsyncValue<BackupResult?>> {
  final Ref _ref;

  BackupController(this._ref) : super(const AsyncValue.data(null));

  /// Writes an archive, asking the user where it should go.
  ///
  /// The password is passed straight through to the cipher and is never held
  /// in this object, never written to disk, and never logged.
  Future<BackupResult?> createBackup(String password) async {
    state = const AsyncValue.loading();

    try {
      final result = await _ref
          .read(backupServiceProvider)
          .createBackup(
            password: password,
            appVersion: await _ref.read(appVersionProvider.future),
            onStage: (stage) =>
                _ref.read(backupStageProvider.notifier).state = stage,
          );

      state = AsyncValue.data(result);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    } finally {
      _ref.read(backupStageProvider.notifier).state = null;
    }
  }

  /// Clears the last result, so leaving and returning shows a clean screen.
  void reset() => state = const AsyncValue.data(null);
}

final backupControllerProvider =
    StateNotifierProvider<BackupController, AsyncValue<BackupResult?>>((ref) {
      return BackupController(ref);
    });

/// Opens an archive and, once the user agrees, applies it.
///
/// Two steps on purpose: [openArchive] writes nothing, so the user can see
/// the counts and walk away. [applyOpened] is the only call that changes the
/// database.
class RestoreController extends StateNotifier<AsyncValue<OpenedArchive?>> {
  final Ref _ref;

  RestoreController(this._ref) : super(const AsyncValue.data(null));

  /// The result of the last apply, for the summary sheet.
  RestoreSummary? summary;

  /// Picks a file, decrypts it, and works out what a restore would do.
  Future<OpenedArchive?> openArchive(String password) async {
    state = const AsyncValue.loading();
    summary = null;

    try {
      final archive = await _ref
          .read(restoreServiceProvider)
          .openArchive(password: password);

      state = AsyncValue.data(archive);
      return archive;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Writes the opened archive into the database.
  Future<RestoreSummary?> applyOpened() async {
    final archive = state.valueOrNull;
    if (archive == null) return null;

    try {
      final result = await _ref.read(restoreServiceProvider).applyPlan(archive);
      summary = result;

      // A restore can add tags, albums, links and notes all at once, so every
      // dial is turned rather than trying to work out which ones moved.
      _ref.read(tagRevisionProvider.notifier).state++;
      _ref.read(albumRevisionProvider.notifier).state++;
      _ref.invalidate(mediaItemsProvider);

      state = const AsyncValue.data(null);
      return result;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    }
  }

  /// Throws away an opened archive without applying it.
  void discard() {
    summary = null;
    state = const AsyncValue.data(null);
  }
}

final restoreControllerProvider =
    StateNotifierProvider<RestoreController, AsyncValue<OpenedArchive?>>((ref) {
      return RestoreController(ref);
    });
