import 'dart:typed_data';

import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';

/// In-memory [MediaStoreChannel] used by tests instead of a real device.
class FakeMediaStoreChannel implements MediaStoreChannel {
  /// Rows the fake device reports, newest first.
  List<MediaStoreEntry> entries;

  MediaPermissionStatus permissionStatus;

  /// Bytes returned by [loadThumbnail]; null simulates a failed native decode.
  Uint8List? nativeThumbnail;

  /// Bytes returned by [readBytes]; null simulates an unreadable file.
  Uint8List? sourceBytes;

  /// When true, [loadThumbnail] throws instead of returning null.
  bool throwOnThumbnail = false;

  int queryCallCount = 0;
  int thumbnailCallCount = 0;
  int readBytesCallCount = 0;
  int settingsOpenedCount = 0;
  final List<int?> receivedSinceValues = <int?>[];

  FakeMediaStoreChannel({
    List<MediaStoreEntry>? entries,
    this.permissionStatus = MediaPermissionStatus.granted,
    this.nativeThumbnail,
    this.sourceBytes,
  }) : entries = entries ?? <MediaStoreEntry>[];

  @override
  Future<MediaPermissionStatus> checkPermissions() async => permissionStatus;

  @override
  Future<MediaPermissionStatus> requestPermissions() async => permissionStatus;

  @override
  Future<int> getMediaCount() async => entries.length;

  @override
  Future<List<MediaStoreEntry>> queryMedia({
    required int offset,
    required int limit,
    int? sinceDateModifiedMs,
  }) async {
    queryCallCount++;
    receivedSinceValues.add(sinceDateModifiedMs);

    final filtered = sinceDateModifiedMs == null
        ? entries
        : entries
              .where((e) => e.dateModifiedMs >= sinceDateModifiedMs)
              .toList(growable: false);

    if (offset >= filtered.length) return const <MediaStoreEntry>[];
    final end = offset + limit > filtered.length
        ? filtered.length
        : offset + limit;
    return filtered.sublist(offset, end);
  }

  @override
  Future<Uint8List?> loadThumbnail({
    required String uri,
    required int width,
    required int height,
  }) async {
    thumbnailCallCount++;
    if (throwOnThumbnail) {
      throw const MediaScanException('native thumbnail failed');
    }
    return nativeThumbnail;
  }

  @override
  Future<Uint8List?> readBytes(String uri, {int? maxBytes}) async {
    readBytesCallCount++;
    return sourceBytes;
  }

  @override
  Future<void> openAppSettings() async {
    settingsOpenedCount++;
  }

  /// Files this fake was asked to publish, newest last.
  final List<String> publishedNames = <String>[];

  /// Whether [publishFile] should fail.
  bool publishThrows = false;

  @override
  Future<PublishedMedia> publishFile({
    required String sourcePath,
    required String displayName,
    required String mimeType,
    required bool isVideo,
    String relativeDir = AppConstants.syncReceiveDirectoryName,
  }) async {
    if (publishThrows) {
      throw const MediaScanException('publish refused by the fake');
    }
    publishedNames.add(displayName);
    return PublishedMedia(
      uri: 'content://media/external/images/media/${publishedNames.length}',
      path: '/storage/emulated/0/Pictures/$relativeDir/$displayName',
    );
  }

  /// Whether [deleteMedia] should succeed.
  bool deleteSucceeds = true;

  /// URIs passed to [deleteMedia].
  final List<String> deletedUris = <String>[];

  @override
  Future<bool> deleteMedia({
    required List<String> uris,
    required List<String> paths,
  }) async {
    if (!deleteSucceeds) return false;
    deletedUris.addAll(uris);
    entries.removeWhere((e) => uris.contains(e.uri) || paths.contains(e.path));
    return true;
  }
}

/// Builds a MediaStore row with sensible defaults for tests.
MediaStoreEntry buildEntry({
  required String id,
  String? displayName,
  String mimeType = 'image/jpeg',
  int size = 1024,
  int? dateModifiedMs,
  int? dateTakenMs,
  int? durationMs,
  String? path,
}) {
  return MediaStoreEntry(
    id: id,
    path: path ?? '/storage/emulated/0/DCIM/img_$id.jpg',
    uri: 'content://media/external/images/media/$id',
    displayName: displayName ?? 'img_$id.jpg',
    mimeType: mimeType,
    size: size,
    dateAddedMs: dateModifiedMs ?? 1000,
    dateModifiedMs: dateModifiedMs ?? 1000,
    dateTakenMs: dateTakenMs,
    durationMs: durationMs,
    width: 1920,
    height: 1080,
  );
}
