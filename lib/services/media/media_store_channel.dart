import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';

/// Permission state reported by the Android media permission flow.
enum MediaPermissionStatus {
  /// Full access to images and videos.
  granted,

  /// Android 14+ "selected photos" access — only some items are visible.
  partial,

  /// Denied, but the system will ask again.
  denied,

  /// Denied with "Don't ask again"; only app settings can change it.
  permanentlyDenied;

  /// Whether any media at all can be read.
  bool get canRead =>
      this == MediaPermissionStatus.granted ||
      this == MediaPermissionStatus.partial;

  /// Parses the string sent by the native channel, defaulting to [denied].
  static MediaPermissionStatus fromString(String? value) {
    return MediaPermissionStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => MediaPermissionStatus.denied,
    );
  }
}

/// A single raw row read from the Android MediaStore.
///
/// This is the transport shape only. [MediaScannerService] maps it into the
/// immutable [MediaItem] domain model.
@immutable
class MediaStoreEntry {
  /// MediaStore `_ID` as a string.
  final String id;

  /// Absolute file path reported by MediaStore (may be empty on newer devices).
  final String path;

  /// `content://` URI used for reading bytes and thumbnails.
  final String uri;

  /// File name including extension.
  final String displayName;

  /// MIME type, e.g. `image/jpeg`.
  final String mimeType;

  /// File size in bytes.
  final int size;

  /// Seconds/milliseconds normalised to milliseconds since epoch.
  final int dateAddedMs;
  final int dateModifiedMs;
  final int? dateTakenMs;

  /// Video duration in milliseconds, null for still images.
  final int? durationMs;

  final int? width;
  final int? height;
  final int orientation;

  const MediaStoreEntry({
    required this.id,
    required this.path,
    required this.uri,
    required this.displayName,
    required this.mimeType,
    required this.size,
    required this.dateAddedMs,
    required this.dateModifiedMs,
    this.dateTakenMs,
    this.durationMs,
    this.width,
    this.height,
    this.orientation = 0,
  });

  /// Builds an entry from a platform channel map.
  ///
  /// Throws [MediaScanException] when a required field is missing, so the
  /// scanner can skip that one row and carry on.
  factory MediaStoreEntry.fromPlatformMap(Map<Object?, Object?> map) {
    try {
      final id = map['id']?.toString();
      final uri = map['uri']?.toString();
      final displayName = map['displayName']?.toString();
      if (id == null || id.isEmpty || uri == null || uri.isEmpty) {
        throw const MediaScanException('MediaStore row missing id or uri');
      }
      return MediaStoreEntry(
        id: id,
        path: map['path']?.toString() ?? '',
        uri: uri,
        displayName: (displayName == null || displayName.isEmpty)
            ? 'unknown'
            : displayName,
        mimeType: map['mimeType']?.toString() ?? '',
        size: _asInt(map['size']) ?? 0,
        dateAddedMs: _asInt(map['dateAdded']) ?? 0,
        dateModifiedMs: _asInt(map['dateModified']) ?? 0,
        dateTakenMs: _asInt(map['dateTaken']),
        durationMs: _asInt(map['duration']),
        width: _asInt(map['width']),
        height: _asInt(map['height']),
        orientation: _asInt(map['orientation']) ?? 0,
      );
    } on MediaScanException {
      rethrow;
    } catch (e, st) {
      throw MediaScanException(
        'Could not read a MediaStore row',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static int? _asInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

/// Where a newly published file ended up.
class PublishedMedia {
  /// Content URI of the new entry.
  final String uri;

  /// On-disk path, when the platform would give one.
  final String? path;

  /// Whether it went into the shared gallery through MediaStore.
  ///
  /// False on Android 9 and below, where there is no way to write to shared
  /// storage without the broad legacy permission this app will not ask for.
  /// The file is then in the app's own external directory instead, and the
  /// screen says so rather than pretending it is in the camera roll.
  final bool usedMediaStore;

  const PublishedMedia({
    required this.uri,
    this.path,
    this.usedMediaStore = true,
  });
}

/// Contract for reading media from the device.
///
/// Injected everywhere so tests can supply a fake without touching Android.
abstract class MediaStoreChannel {
  /// Current media permission state without prompting the user.
  Future<MediaPermissionStatus> checkPermissions();

  /// Prompts for media permissions and returns the resulting state.
  Future<MediaPermissionStatus> requestPermissions();

  /// Total number of images and videos visible to the app.
  Future<int> getMediaCount();

  /// Reads one page of MediaStore rows, newest modification first.
  ///
  /// [sinceDateModifiedMs] limits results to rows modified at or after that
  /// moment, which drives incremental rescans.
  Future<List<MediaStoreEntry>> queryMedia({
    required int offset,
    required int limit,
    int? sinceDateModifiedMs,
  });

  /// Returns JPEG thumbnail bytes for [uri], or null when unavailable.
  Future<Uint8List?> loadThumbnail({
    required String uri,
    required int width,
    required int height,
  });

  /// Reads the original bytes of [uri], or null when unreadable.
  Future<Uint8List?> readBytes(String uri, {int? maxBytes});

  /// Opens the app's system settings page so the user can change permissions.
  Future<void> openAppSettings();

  /// Publishes a staged file into the shared gallery.
  ///
  /// Written through MediaStore, so the app can add one file to the user's
  /// pictures without ever holding a permission over the rest of their
  /// storage. Nothing is overwritten: a clashing name is given a new one.
  Future<PublishedMedia> publishFile({
    required String sourcePath,
    required String displayName,
    required String mimeType,
    required bool isVideo,
    String relativeDir,
  });

  /// Permanently deletes media items from Android storage via MediaStore.
  ///
  /// On Android 11+ this presents the system confirmation dialog. Returns true
  /// when the deletion succeeded, false when cancelled or rejected.
  Future<bool> deleteMedia({
    required List<String> uris,
    required List<String> paths,
  });
}

/// Real [MediaStoreChannel] backed by the Android platform channel.
class PlatformMediaStoreChannel implements MediaStoreChannel {
  final MethodChannel _channel;

  PlatformMediaStoreChannel({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.mediaStoreChannelName);

  @override
  Future<MediaPermissionStatus> checkPermissions() async {
    final result = await _invoke<String>('hasPermissions');
    return MediaPermissionStatus.fromString(result);
  }

  @override
  Future<MediaPermissionStatus> requestPermissions() async {
    final result = await _invoke<String>('requestPermissions');
    return MediaPermissionStatus.fromString(result);
  }

  @override
  Future<int> getMediaCount() async {
    final result = await _invoke<int>('getMediaCount');
    return result ?? 0;
  }

  @override
  Future<List<MediaStoreEntry>> queryMedia({
    required int offset,
    required int limit,
    int? sinceDateModifiedMs,
  }) async {
    final result = await _invoke<List<Object?>>('queryMedia', <String, Object?>{
      'offset': offset,
      'limit': limit,
      'sinceDateModified': sinceDateModifiedMs,
    });
    if (result == null) return const <MediaStoreEntry>[];

    final entries = <MediaStoreEntry>[];
    for (final row in result) {
      if (row is! Map) continue;
      try {
        entries.add(
          MediaStoreEntry.fromPlatformMap(row.cast<Object?, Object?>()),
        );
      } on MediaScanException {
        // A single unreadable row must never stop the whole scan.
        continue;
      }
    }
    return entries;
  }

  @override
  Future<Uint8List?> loadThumbnail({
    required String uri,
    required int width,
    required int height,
  }) async {
    try {
      return await _invoke<Uint8List>('loadThumbnail', <String, Object?>{
        'uri': uri,
        'width': width,
        'height': height,
      });
    } on MediaScanException {
      // Missing or corrupt media: the caller falls back to a Dart decode.
      return null;
    }
  }

  @override
  Future<Uint8List?> readBytes(String uri, {int? maxBytes}) async {
    try {
      return await _invoke<Uint8List>('readBytes', <String, Object?>{
        'uri': uri,
        'maxBytes': maxBytes,
      });
    } on MediaScanException {
      return null;
    }
  }

  @override
  Future<void> openAppSettings() async {
    await _invoke<void>('openAppSettings');
  }

  @override
  Future<PublishedMedia> publishFile({
    required String sourcePath,
    required String displayName,
    required String mimeType,
    required bool isVideo,
    String relativeDir = AppConstants.syncReceiveDirectoryName,
  }) async {
    final result =
        await _invoke<Map<Object?, Object?>>('publishFile', <String, Object?>{
          'sourcePath': sourcePath,
          'displayName': displayName,
          'mimeType': mimeType,
          'isVideo': isVideo,
          'relativeDir': relativeDir,
        });

    if (result == null) {
      throw const MediaScanException('The file could not be published');
    }
    return PublishedMedia(
      uri: result['uri'] as String? ?? '',
      path: result['path'] as String?,
      usedMediaStore: result['usedMediaStore'] as bool? ?? false,
    );
  }

  @override
  Future<bool> deleteMedia({
    required List<String> uris,
    required List<String> paths,
  }) async {
    final result = await _invoke<bool>('deleteMedia', <String, Object?>{
      'uris': uris,
      'paths': paths,
    });
    return result ?? false;
  }

  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e, st) {
      if (e.code == _permissionDeniedCode ||
          e.code == _permissionPermanentCode) {
        throw PermissionDeniedException(
          'Media permission is required to read device media',
          isPermanent: e.code == _permissionPermanentCode,
          cause: e,
          stackTrace: st,
        );
      }
      throw MediaScanException(
        'MediaStore call "$method" failed',
        code: e.code,
        cause: e,
        stackTrace: st,
      );
    } on MissingPluginException catch (e, st) {
      throw MediaScanException(
        'MediaStore channel is not available on this platform',
        code: 'missing_plugin',
        cause: e,
        stackTrace: st,
      );
    }
  }

  static const String _permissionDeniedCode = 'permission_denied';
  static const String _permissionPermanentCode =
      'permission_permanently_denied';
}
