import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/services/device/device_memory_service.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_permission_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/media/stale_cleanup_store.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_disk_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_memory_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Platform bridge to the Android MediaStore.
final mediaStoreChannelProvider = Provider<MediaStoreChannel>((ref) {
  return PlatformMediaStoreChannel();
});

/// Whether Android will ask before a permanent delete, and the "Manage
/// media" state. Read it with `ref.refresh(...future)` right before a delete,
/// since the user can change "Manage media" in system settings at any time.
final deleteConfirmInfoProvider = FutureProvider<DeleteConfirmInfo>((ref) {
  return ref.watch(mediaStoreChannelProvider).deleteConfirmInfo();
});

/// Whether the home screen should ask the user to turn on "Manage media".
///
/// True only on Android 12+ (where it exists), while it is off, and with full
/// photos and videos access: with no access the "Permission required" screen
/// comes first, and with "selected photos only" it may have no effect.
bool shouldPromptManageMedia({
  required DeleteConfirmInfo info,
  required MediaPermissionStatus status,
  required bool alreadyShown,
}) {
  return !alreadyShown &&
      info.manageMediaSupported &&
      !info.manageMediaGranted &&
      status == MediaPermissionStatus.granted;
}

/// Asks for "Manage media" at most once per app start, while it is off.
///
/// The state is "already shown during this app start". It lives in memory
/// only, so the next fresh start asks again (the owner's choice).
class ManageMediaPromptController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Returns true when the prompt should be shown now, and marks it shown.
  /// Reads the "Manage media" state fresh; any error means "do not ask".
  Future<bool> takePrompt(MediaPermissionStatus status) async {
    if (state) return false;
    final DeleteConfirmInfo info;
    try {
      info = await ref.refresh(deleteConfirmInfoProvider.future);
    } catch (_) {
      return false;
    }
    if (!ref.mounted) return false;
    final bool show = shouldPromptManageMedia(
      info: info,
      status: status,
      alreadyShown: state,
    );
    if (show) state = true;
    return show;
  }
}

/// See [ManageMediaPromptController].
final manageMediaPromptProvider =
    NotifierProvider<ManageMediaPromptController, bool>(
      ManageMediaPromptController.new,
    );

/// Granular media permission handling.
final mediaPermissionServiceProvider = Provider<MediaPermissionService>((ref) {
  return MediaPermissionService(channel: ref.watch(mediaStoreChannelProvider));
});

/// Current media permission state, refreshed on demand.
final mediaPermissionStatusProvider = FutureProvider<MediaPermissionStatus>((
  ref,
) async {
  return ref.watch(mediaPermissionServiceProvider).check();
});

/// Device RAM detection.
final deviceMemoryServiceProvider = Provider<DeviceMemoryService>((ref) {
  return DeviceMemoryService();
});

/// Cache limits chosen from the device RAM tier.
final thumbnailCacheConfigProvider = Provider<ThumbnailCacheConfig>((ref) {
  return ref.watch(deviceMemoryServiceProvider).resolveCacheConfig();
});

/// Data access object over the media table.
final mediaDaoProvider = Provider<MediaDao>((ref) => MediaDao());

/// MediaStore scanner and indexer.
final mediaScannerServiceProvider = Provider<MediaScannerService>((ref) {
  final scanner = MediaScannerService(
    channel: ref.watch(mediaStoreChannelProvider),
    mediaDao: ref.watch(mediaDaoProvider),
    staleStore: const SharedPreferencesStaleCleanupStore(),
  );
  ref.onDispose(scanner.dispose);
  return scanner;
});

/// Single entry point the UI layer uses for media.
final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return MediaRepository(
    mediaDao: ref.watch(mediaDaoProvider),
    scanner: ref.watch(mediaScannerServiceProvider),
    channel: ref.watch(mediaStoreChannelProvider),
  );
});

/// Thumbnail engine, built once the cache directory is known.
final thumbnailServiceProvider = FutureProvider<ThumbnailService>((ref) async {
  final config = ref.watch(thumbnailCacheConfigProvider);
  final cacheDirectory = await getTemporaryDirectory();

  return ThumbnailService(
    channel: ref.watch(mediaStoreChannelProvider),
    memoryCache: ThumbnailMemoryCache(
      maxItems: config.memoryCacheItems,
      maxBytes: config.memoryCacheBytes,
    ),
    diskCache: ThumbnailDiskCache(
      rootDirectory: ThumbnailDiskCache.defaultRoot(cacheDirectory),
      maxBytes: config.diskCacheBytes,
    ),
    config: config,
  );
});

/// Live scan progress from the scanner service.
final scanProgressProvider = StreamProvider<ScanProgress>((ref) {
  return ref.watch(mediaScannerServiceProvider).progressStream;
});

/// Drives device scans and exposes the resulting state to the UI.
class MediaScanController extends StateNotifier<AsyncValue<ScanResult?>> {
  final MediaRepository _repository;
  final MediaPermissionService _permissionService;
  final VoidCallback? _onPermissionChecked;

  /// Called when the indexed library may have changed, so lists reload.
  ///
  /// Not called for a quick scan that found nothing new, which is what most
  /// app opens and resumes are: reloading 30,000 rows then is pure waste.
  final VoidCallback? _onLibraryChanged;

  MediaScanController({
    required MediaRepository repository,
    required MediaPermissionService permissionService,
    VoidCallback? onPermissionChecked,
    VoidCallback? onLibraryChanged,
  }) : _repository = repository,
       _permissionService = permissionService,
       _onPermissionChecked = onPermissionChecked,
       _onLibraryChanged = onLibraryChanged,
       super(const AsyncValue<ScanResult?>.data(null));

  /// Asks for permission if needed, then scans and indexes the device.
  Future<void> scan({bool incremental = false}) async {
    if (_repository.isScanning) return;

    state = const AsyncValue<ScanResult?>.loading();
    try {
      final permission = await _permissionService.ensureGranted();
      _onPermissionChecked?.call();
      if (!permission.canRead) {
        state = AsyncValue<ScanResult?>.data(
          ScanResult(
            indexed: 0,
            skipped: 0,
            removed: 0,
            permissionStatus: permission,
          ),
        );
        _onLibraryChanged?.call();
        return;
      }

      final result = await _repository.scanDevice(incremental: incremental);
      state = AsyncValue<ScanResult?>.data(result);
      if (result.libraryChanged) _onLibraryChanged?.call();
    } catch (e, st) {
      state = AsyncValue<ScanResult?>.error(e, st);
      // A failed scan may have written part of its work, so reload to be safe.
      _onLibraryChanged?.call();
    }
  }
}

/// Scan controller used by screens.
final mediaScanControllerProvider =
    StateNotifierProvider<MediaScanController, AsyncValue<ScanResult?>>((ref) {
      return MediaScanController(
        repository: ref.watch(mediaRepositoryProvider),
        permissionService: ref.watch(mediaPermissionServiceProvider),
        onPermissionChecked: () =>
            ref.invalidate(mediaPermissionStatusProvider),
        onLibraryChanged: () =>
            ref.read(mediaLibraryVersionProvider.notifier).state++,
      );
    });

/// Goes up by one each time a scan may have changed the indexed library.
///
/// The media lists watch this instead of the scan state itself. The scan
/// state changes twice per scan (running, then done) even when nothing new
/// was found, and each change used to reload the whole library.
final mediaLibraryVersionProvider = StateProvider<int>((ref) => 0);

/// Indexed media items matching a filter.
final mediaItemsProvider =
    FutureProvider.family<List<MediaItem>, FilterOptions>((ref, filter) async {
      // Re-run when a scan changed the library, so new media appears without
      // a restart, but not after a scan that found nothing new.
      ref.watch(mediaLibraryVersionProvider);
      return ref.watch(mediaRepositoryProvider).getMediaItems(filter: filter);
    });

/// One indexed item by id, or null when there is no such row.
///
/// Used by the screens that work on a single item and only need its path,
/// so they do not have to pull the whole timeline in to find one photo.
///
/// An item Android does not currently let the app see (limited or no media
/// access) also gives null, so the screen shows its normal "not found" state
/// instead of a photo the user did not allow.
final mediaItemProvider = FutureProvider.family<MediaItem?, String>((
  ref,
  id,
) async {
  final item = await ref.watch(mediaRepositoryProvider).getMediaItemById(id);
  return (item == null || item.isOutOfReach) ? null : item;
});

/// Total number of indexed items.
final indexedMediaCountProvider = FutureProvider<int>((ref) async {
  ref.watch(mediaLibraryVersionProvider);
  return ref.watch(mediaRepositoryProvider).getTotalCount();
});

/// Thumbnail bytes for one media item, or null when none can be generated.
final thumbnailProvider = FutureProvider.family<Uint8List?, MediaItem>((
  ref,
  item,
) async {
  final service = await ref.watch(thumbnailServiceProvider.future);
  return service.getThumbnail(item);
});
