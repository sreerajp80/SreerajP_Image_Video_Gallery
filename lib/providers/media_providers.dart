import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/core/device/device_memory_service.dart';
import 'package:in_sreerajp_imgvidgal/models/filter_options.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/database/media_dao.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_permission_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_scanner_service.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_disk_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_memory_cache.dart';
import 'package:in_sreerajp_imgvidgal/services/thumbnail/thumbnail_service.dart';
import 'package:path_provider/path_provider.dart';

/// Platform bridge to the Android MediaStore.
final mediaStoreChannelProvider = Provider<MediaStoreChannel>((ref) {
  return PlatformMediaStoreChannel();
});

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

  MediaScanController({
    required MediaRepository repository,
    required MediaPermissionService permissionService,
    VoidCallback? onPermissionChecked,
  }) : _repository = repository,
       _permissionService = permissionService,
       _onPermissionChecked = onPermissionChecked,
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
        return;
      }

      final result = await _repository.scanDevice(incremental: incremental);
      state = AsyncValue<ScanResult?>.data(result);
    } catch (e, st) {
      state = AsyncValue<ScanResult?>.error(e, st);
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
      );
    });

/// Indexed media items matching a filter.
final mediaItemsProvider =
    FutureProvider.family<List<MediaItem>, FilterOptions>((ref, filter) async {
      // Re-run whenever a scan finishes so new media appears without a restart.
      ref.watch(mediaScanControllerProvider);
      return ref.watch(mediaRepositoryProvider).getMediaItems(filter: filter);
    });

/// One indexed item by id, or null when there is no such row.
///
/// Used by the screens that work on a single item and only need its path,
/// so they do not have to pull the whole timeline in to find one photo.
final mediaItemProvider = FutureProvider.family<MediaItem?, String>((
  ref,
  id,
) async {
  return ref.watch(mediaRepositoryProvider).getMediaItemById(id);
});

/// Total number of indexed items.
final indexedMediaCountProvider = FutureProvider<int>((ref) async {
  ref.watch(mediaScanControllerProvider);
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
