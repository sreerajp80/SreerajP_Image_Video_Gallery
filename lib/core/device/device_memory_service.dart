import 'package:flutter/foundation.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:system_info2/system_info2.dart';

/// Device RAM band used to size the thumbnail caches.
enum DeviceMemoryTier {
  /// Less than 4 GB of RAM.
  low,

  /// 4 GB up to (but not including) 6 GB.
  medium,

  /// 6 GB or more.
  high,
}

/// Cache limits derived from the device memory tier.
@immutable
class ThumbnailCacheConfig {
  final DeviceMemoryTier tier;

  /// Longest edge, in pixels, of a generated thumbnail.
  final int thumbnailSize;

  /// Maximum number of thumbnails held in RAM.
  final int memoryCacheItems;

  /// Maximum bytes of thumbnails held in RAM.
  final int memoryCacheBytes;

  /// Maximum bytes of thumbnails kept on disk.
  final int diskCacheBytes;

  const ThumbnailCacheConfig({
    required this.tier,
    required this.thumbnailSize,
    required this.memoryCacheItems,
    required this.memoryCacheBytes,
    required this.diskCacheBytes,
  });

  /// Conservative settings for low-RAM devices, also used as the safe default
  /// when total RAM cannot be read.
  static const ThumbnailCacheConfig lowTier = ThumbnailCacheConfig(
    tier: DeviceMemoryTier.low,
    thumbnailSize: AppConstants.lowTierThumbnailSize,
    memoryCacheItems: AppConstants.lowTierMemoryCacheItems,
    memoryCacheBytes: AppConstants.lowTierMemoryCacheBytes,
    diskCacheBytes: AppConstants.lowTierDiskCacheBytes,
  );

  static const ThumbnailCacheConfig mediumTier = ThumbnailCacheConfig(
    tier: DeviceMemoryTier.medium,
    thumbnailSize: AppConstants.mediumTierThumbnailSize,
    memoryCacheItems: AppConstants.mediumTierMemoryCacheItems,
    memoryCacheBytes: AppConstants.mediumTierMemoryCacheBytes,
    diskCacheBytes: AppConstants.mediumTierDiskCacheBytes,
  );

  static const ThumbnailCacheConfig highTier = ThumbnailCacheConfig(
    tier: DeviceMemoryTier.high,
    thumbnailSize: AppConstants.highTierThumbnailSize,
    memoryCacheItems: AppConstants.highTierMemoryCacheItems,
    memoryCacheBytes: AppConstants.highTierMemoryCacheBytes,
    diskCacheBytes: AppConstants.highTierDiskCacheBytes,
  );

  /// The configuration matching [tier].
  static ThumbnailCacheConfig forTier(DeviceMemoryTier tier) {
    return switch (tier) {
      DeviceMemoryTier.low => lowTier,
      DeviceMemoryTier.medium => mediumTier,
      DeviceMemoryTier.high => highTier,
    };
  }
}

/// Reads total device RAM and turns it into cache limits.
///
/// Reading RAM can fail on unusual devices and always fails on the test host,
/// so every path falls back to the conservative low tier.
class DeviceMemoryService {
  /// Injectable RAM reader, in bytes. Returns null when RAM is unknown.
  final int? Function() _totalPhysicalMemoryReader;

  DeviceMemoryService({int? Function()? totalPhysicalMemoryReader})
    : _totalPhysicalMemoryReader =
          totalPhysicalMemoryReader ?? _readPhysicalMemory;

  /// Maps a RAM amount in bytes to a tier. Null or non-positive input gives
  /// the safest (low) tier.
  static DeviceMemoryTier tierForBytes(int? totalBytes) {
    if (totalBytes == null || totalBytes <= 0) return DeviceMemoryTier.low;
    if (totalBytes < AppConstants.lowMemoryThresholdBytes) {
      return DeviceMemoryTier.low;
    }
    if (totalBytes < AppConstants.highMemoryThresholdBytes) {
      return DeviceMemoryTier.medium;
    }
    return DeviceMemoryTier.high;
  }

  /// Total physical RAM in bytes, or null when it cannot be read.
  int? totalPhysicalMemoryBytes() {
    try {
      return _totalPhysicalMemoryReader();
    } catch (_) {
      return null;
    }
  }

  /// The memory tier of this device.
  DeviceMemoryTier detectTier() => tierForBytes(totalPhysicalMemoryBytes());

  /// Cache limits for this device.
  ThumbnailCacheConfig resolveCacheConfig() =>
      ThumbnailCacheConfig.forTier(detectTier());

  static int? _readPhysicalMemory() {
    try {
      final total = SysInfo.getTotalPhysicalMemory();
      return total > 0 ? total : null;
    } catch (_) {
      return null;
    }
  }
}
