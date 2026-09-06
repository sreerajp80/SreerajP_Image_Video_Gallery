import 'dart:async';
import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/media_item.dart';
import 'package:in_sreerajp_imgvidgal/repositories/media_repository.dart';

/// Data received from an incoming Android ACTION_VIEW intent.
class MediaIntentData {
  final String uri;
  final String mimeType;
  final String displayName;
  final int size;
  final bool isVideo;

  const MediaIntentData({
    required this.uri,
    required this.mimeType,
    required this.displayName,
    required this.size,
    required this.isVideo,
  });

  factory MediaIntentData.fromMap(Map<dynamic, dynamic> map) {
    final uri = (map['uri'] ?? '').toString();
    final mimeType = (map['mimeType'] ?? 'image/*').toString();
    final displayName = (map['displayName'] ?? '').toString();
    final size = (map['size'] as num?)?.toInt() ?? 0;
    final isVideo =
        map['isVideo'] == true || mimeType.toLowerCase().startsWith('video/');

    return MediaIntentData(
      uri: uri,
      mimeType: mimeType,
      displayName: displayName,
      size: size,
      isVideo: isVideo,
    );
  }
}

/// Listens for and resolves incoming media view intents from other apps.
///
/// When another Android app requests to open an image or video with this app,
/// this service receives the media URI, locates any existing database item, or
/// creates a transient item so the media viewer can display it immediately.
class MediaIntentService {
  final MethodChannel _channel;
  final StreamController<MediaIntentData> _intentStreamController =
      StreamController<MediaIntentData>.broadcast();

  MediaIntentService({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.intentChannelName) {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Stream of media intents arriving while the app is running.
  Stream<MediaIntentData> get incomingIntents => _intentStreamController.stream;

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onMediaIntent') {
      final args = call.arguments;
      if (args is Map) {
        final data = MediaIntentData.fromMap(args);
        if (data.uri.isNotEmpty) {
          _intentStreamController.add(data);
        }
      }
    }
  }

  /// Checks if the app was launched by an external image or video view intent.
  Future<MediaIntentData?> getInitialMediaIntent() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getInitialMediaIntent',
      );
      if (result != null && result.isNotEmpty) {
        final data = MediaIntentData.fromMap(result);
        if (data.uri.isNotEmpty) {
          return data;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Opens the Android system settings screen where users set default apps.
  Future<bool> openDefaultAppsSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openDefaultAppsSettings',
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Resolves an incoming intent to an existing [MediaItem] or a transient item.
  Future<MediaItem> resolveMediaItem(
    MediaIntentData data,
    MediaRepository repository,
  ) async {
    // 1. Try to find the item in SQLite by URI.
    try {
      final itemByUri = await repository.getMediaItemByUri(data.uri);
      if (itemByUri != null) return itemByUri;
    } catch (_) {}

    // 2. If it is a file URI or path, try finding it by path.
    if (data.uri.startsWith('file://')) {
      try {
        final filePath = Uri.parse(data.uri).path;
        final itemByPath = await repository.getMediaItemByPath(filePath);
        if (itemByPath != null) return itemByPath;
      } catch (_) {}
    } else if (data.uri.startsWith('/')) {
      try {
        final itemByPath = await repository.getMediaItemByPath(data.uri);
        if (itemByPath != null) return itemByPath;
      } catch (_) {}
    }

    // 3. Not in database: build a safe transient MediaItem for external display.
    final bool isVideo =
        data.isVideo || data.mimeType.toLowerCase().startsWith('video/');
    final String id = 'ext_${data.uri.hashCode.abs()}';
    final now = DateTime.now();

    String path = data.uri;
    if (data.uri.startsWith('file://')) {
      try {
        path = Uri.parse(data.uri).path;
      } catch (_) {
        path = data.uri;
      }
    }

    return MediaItem(
      id: id,
      path: path,
      uri: data.uri,
      displayName: data.displayName.isNotEmpty ? data.displayName : 'media',
      mediaType: isVideo ? MediaType.video : MediaType.image,
      mimeType: data.mimeType.isNotEmpty
          ? data.mimeType
          : (isVideo ? 'video/mp4' : 'image/jpeg'),
      size: data.size > 0 ? data.size : 0,
      dateAdded: now,
      dateModified: now,
    );
  }

  void dispose() {
    _intentStreamController.close();
  }
}
