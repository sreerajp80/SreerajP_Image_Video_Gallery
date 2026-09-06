import 'package:flutter_test/flutter_test.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/device/device_memory_service.dart';

const int gb = 1024 * 1024 * 1024;

void main() {
  group('DeviceMemoryService tier detection', () {
    test('less than 4 GB is the low tier', () {
      expect(DeviceMemoryService.tierForBytes(2 * gb), DeviceMemoryTier.low);
      expect(
        DeviceMemoryService.tierForBytes(
          AppConstants.lowMemoryThresholdBytes - 1,
        ),
        DeviceMemoryTier.low,
      );
    });

    test('4 GB up to 6 GB is the medium tier', () {
      expect(
        DeviceMemoryService.tierForBytes(AppConstants.lowMemoryThresholdBytes),
        DeviceMemoryTier.medium,
      );
      expect(DeviceMemoryService.tierForBytes(5 * gb), DeviceMemoryTier.medium);
      expect(
        DeviceMemoryService.tierForBytes(
          AppConstants.highMemoryThresholdBytes - 1,
        ),
        DeviceMemoryTier.medium,
      );
    });

    test('6 GB and above is the high tier', () {
      expect(
        DeviceMemoryService.tierForBytes(AppConstants.highMemoryThresholdBytes),
        DeviceMemoryTier.high,
      );
      expect(DeviceMemoryService.tierForBytes(12 * gb), DeviceMemoryTier.high);
    });

    test('unknown or invalid RAM falls back to the low tier', () {
      expect(DeviceMemoryService.tierForBytes(null), DeviceMemoryTier.low);
      expect(DeviceMemoryService.tierForBytes(0), DeviceMemoryTier.low);
      expect(DeviceMemoryService.tierForBytes(-1), DeviceMemoryTier.low);
    });

    test('a reader that throws degrades to the low tier', () {
      final service = DeviceMemoryService(
        totalPhysicalMemoryReader: () => throw StateError('no RAM info'),
      );

      expect(service.totalPhysicalMemoryBytes(), isNull);
      expect(service.detectTier(), DeviceMemoryTier.low);
      expect(
        service.resolveCacheConfig().thumbnailSize,
        AppConstants.lowTierThumbnailSize,
      );
    });
  });

  group('ThumbnailCacheConfig', () {
    test('each tier maps to its own limits', () {
      expect(
        ThumbnailCacheConfig.forTier(DeviceMemoryTier.low).thumbnailSize,
        AppConstants.lowTierThumbnailSize,
      );
      expect(
        ThumbnailCacheConfig.forTier(DeviceMemoryTier.medium).thumbnailSize,
        AppConstants.mediumTierThumbnailSize,
      );
      expect(
        ThumbnailCacheConfig.forTier(DeviceMemoryTier.high).thumbnailSize,
        AppConstants.highTierThumbnailSize,
      );
    });

    test('cache budgets grow with the tier', () {
      final low = ThumbnailCacheConfig.forTier(DeviceMemoryTier.low);
      final medium = ThumbnailCacheConfig.forTier(DeviceMemoryTier.medium);
      final high = ThumbnailCacheConfig.forTier(DeviceMemoryTier.high);

      expect(low.memoryCacheItems, lessThan(medium.memoryCacheItems));
      expect(medium.memoryCacheItems, lessThan(high.memoryCacheItems));
      expect(low.diskCacheBytes, lessThan(high.diskCacheBytes));
    });

    test('a high-RAM reader resolves to the high tier config', () {
      final service = DeviceMemoryService(
        totalPhysicalMemoryReader: () => 8 * gb,
      );

      expect(service.detectTier(), DeviceMemoryTier.high);
      expect(service.resolveCacheConfig().tier, DeviceMemoryTier.high);
    });
  });
}
