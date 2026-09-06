import 'package:in_sreerajp_imgvidgal/core/errors/app_exception.dart';
import 'package:in_sreerajp_imgvidgal/services/media/media_store_channel.dart';

/// Thin service wrapping the granular media permission flow.
///
/// The app only ever asks for `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO`
/// (plus the Android 14+ partial-access permission). It never asks for broad
/// legacy storage access on Android 13 and above.
class MediaPermissionService {
  final MediaStoreChannel _channel;

  MediaPermissionService({required MediaStoreChannel channel})
    : _channel = channel;

  /// Reads the current permission state without showing a system dialog.
  Future<MediaPermissionStatus> check() async {
    try {
      return await _channel.checkPermissions();
    } on PermissionDeniedException catch (e) {
      return e.isPermanent
          ? MediaPermissionStatus.permanentlyDenied
          : MediaPermissionStatus.denied;
    } on MediaScanException {
      return MediaPermissionStatus.denied;
    }
  }

  /// Shows the system permission dialog and returns the resulting state.
  Future<MediaPermissionStatus> request() async {
    try {
      return await _channel.requestPermissions();
    } on PermissionDeniedException catch (e) {
      return e.isPermanent
          ? MediaPermissionStatus.permanentlyDenied
          : MediaPermissionStatus.denied;
    } on MediaScanException {
      return MediaPermissionStatus.denied;
    }
  }

  /// Returns the current state, requesting permission only if it is not
  /// already granted and has not been permanently denied.
  Future<MediaPermissionStatus> ensureGranted() async {
    final current = await check();
    if (current.canRead || current == MediaPermissionStatus.permanentlyDenied) {
      return current;
    }
    return request();
  }

  /// Opens the app settings page so a permanently denied permission can be
  /// changed by the user.
  Future<void> openSettings() async {
    try {
      await _channel.openAppSettings();
    } on MediaScanException {
      // Opening settings is a convenience; failing to do so must not crash.
    }
  }
}
