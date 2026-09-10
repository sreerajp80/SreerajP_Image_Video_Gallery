import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/forensic_metadata.dart';
import 'package:in_sreerajp_imgvidgal/providers/media_providers.dart';
import 'package:in_sreerajp_imgvidgal/services/platform/share_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/exif_scrubber_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/forensic_inspector_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/gps_geofence_service.dart';

/// Provider for metadata scrubbing operations.
final exifScrubberServiceProvider = Provider<ExifScrubberService>((ref) {
  return const ExifScrubberService();
});

/// Provider for GPS location fuzzing / geofence shifting.
final gpsGeofenceServiceProvider = Provider<GpsGeofenceService>((ref) {
  return GpsGeofenceService();
});

/// Provider for forensic lens and sensor metadata extraction.
final forensicInspectorServiceProvider = Provider<ForensicInspectorService>((
  ref,
) {
  return const ForensicInspectorService();
});

/// Provider for offline Android native file sharing.
final shareServiceProvider = Provider<ShareService>((ref) {
  return const ShareService();
});

/// Deep forensic optical, hardware, and sensor metadata for an item.
final mediaForensicProvider = FutureProvider.autoDispose
    .family<ForensicMetadata, MediaItem>((ref, item) async {
      if (!item.isImage) return const ForensicMetadata();

      final repository = ref.watch(mediaRepositoryProvider);
      final bytes = await repository.readOriginalBytes(item);
      if (bytes == null) return const ForensicMetadata();

      final inspector = ref.watch(forensicInspectorServiceProvider);
      return inspector.inspectBytes(bytes);
    });
