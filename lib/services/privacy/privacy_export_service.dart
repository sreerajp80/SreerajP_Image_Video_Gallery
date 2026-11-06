import 'dart:io';
import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/gps_fuzz_result.dart';
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_scrub_options.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';
import 'package:in_sreerajp_imgvidgal/services/platform/share_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/exif_scrubber_service.dart';
import 'package:in_sreerajp_imgvidgal/services/privacy/gps_geofence_service.dart';
import 'package:path/path.dart' as p;
import 'package:in_sreerajp_imgvidgal/models/privacy/privacy_export_result.dart';

// Moved to models so the UI can use it without importing a service (G46).
export 'package:in_sreerajp_imgvidgal/models/privacy/privacy_export_result.dart';

/// Reads the untouched bytes of a gallery item, or null when it cannot.
typedef OriginalBytesReader = Future<Uint8List?> Function(MediaItem item);

/// Makes a cleaned copy of a photo and shares it or saves it to the gallery.
///
/// Two kinds of clean copy exist: one with chosen EXIF fields removed, and
/// one with the GPS position moved by a few kilometres. The original file is
/// only ever read. A saved copy is written to a temporary file, handed to
/// MediaStore, and the temporary file is then removed.
class PrivacyExportService {
  final OriginalBytesReader _readOriginal;
  final MediaStoreChannel _channel;
  final ShareService _share;
  final ExifScrubberService _scrubber;
  final GpsGeofenceService _geofence;
  final Future<Directory> Function() _tempDirectory;
  final DateTime Function() _now;

  PrivacyExportService({
    required OriginalBytesReader readOriginal,
    required MediaStoreChannel channel,
    required ShareService share,
    required ExifScrubberService scrubber,
    required GpsGeofenceService geofence,
    required Future<Directory> Function() tempDirectory,
    DateTime Function()? now,
  }) : _readOriginal = readOriginal,
       _channel = channel,
       _share = share,
       _scrubber = scrubber,
       _geofence = geofence,
       _tempDirectory = tempDirectory,
       _now = now ?? DateTime.now;

  /// Shares a copy with the fields in [options] removed.
  Future<PrivacyExportResult> shareScrubbed(
    MediaItem item,
    PrivacyScrubOptions options, {
    required String shareTitle,
  }) {
    return _run('Share scrubbed copy', item, (bytes) async {
      final clean = await _scrubber.scrubBytes(bytes, options: options);
      return _shareBytes(item, clean, 'scrubbed_', shareTitle);
    });
  }

  /// Saves a copy with the fields in [options] removed to the gallery.
  Future<PrivacyExportResult> saveScrubbed(
    MediaItem item,
    PrivacyScrubOptions options,
  ) {
    return _run('Save scrubbed copy', item, (bytes) async {
      final clean = await _scrubber.scrubBytes(bytes, options: options);
      return _publish(item, clean, 'clean_');
    });
  }

  /// Shares a copy whose GPS position is moved by [fuzz].
  Future<PrivacyExportResult> shareFuzzed(
    MediaItem item,
    GpsFuzzResult fuzz, {
    required String shareTitle,
  }) {
    return _run('Share location-shifted copy', item, (bytes) async {
      final moved = _geofence.applyFuzzToImageBytes(
        bytes: bytes,
        fuzzResult: fuzz,
      );
      return _shareBytes(item, moved, 'geofuzzed_', shareTitle);
    });
  }

  /// Saves a copy whose GPS position is moved by [fuzz] to the gallery.
  Future<PrivacyExportResult> saveFuzzed(MediaItem item, GpsFuzzResult fuzz) {
    return _run('Save location-shifted copy', item, (bytes) async {
      final moved = _geofence.applyFuzzToImageBytes(
        bytes: bytes,
        fuzzResult: fuzz,
      );
      return _publish(item, moved, 'fuzzed_');
    });
  }

  /// Reads the original, runs [body], and turns any failure into a result.
  Future<PrivacyExportResult> _run(
    String operation,
    MediaItem item,
    Future<PrivacyExportResult> Function(Uint8List bytes) body,
  ) async {
    try {
      final bytes = await _readOriginal(item);
      if (bytes == null) return PrivacyExportResult.unreadable;
      return await body(bytes);
    } catch (error, stackTrace) {
      AppLogger.error(
        '$operation failed',
        error: error,
        stackTrace: stackTrace,
      );
      return PrivacyExportResult.failed;
    }
  }

  Future<PrivacyExportResult> _shareBytes(
    MediaItem item,
    Uint8List bytes,
    String prefix,
    String title,
  ) async {
    final ok = await _share.shareBytes(
      bytes: bytes,
      filename: '$prefix${item.displayName}',
      mimeType: item.mimeType,
      title: title,
    );
    return ok ? PrivacyExportResult.done : PrivacyExportResult.shareFailed;
  }

  Future<PrivacyExportResult> _publish(
    MediaItem item,
    Uint8List bytes,
    String prefix,
  ) async {
    final directory = await _tempDirectory();
    final name = '$prefix${_now().millisecondsSinceEpoch}_${item.displayName}';
    final tempFile = File(p.join(directory.path, name));
    try {
      await tempFile.writeAsBytes(bytes, flush: true);
      await _channel.publishFile(
        sourcePath: tempFile.path,
        displayName: name,
        mimeType: item.mimeType,
        isVideo: false,
      );
      return PrivacyExportResult.done;
    } finally {
      // MediaStore has its own copy now, or the save failed. Either way the
      // cleaned bytes must not stay behind in the cache.
      try {
        if (await tempFile.exists()) await tempFile.delete();
      } catch (_) {
        // Safe to ignore: Android clears the cache folder in the end.
      }
    }
  }
}
