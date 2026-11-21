import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

/// Opens Android's own wallpaper screen for one photo.
///
/// The app never sets the wallpaper itself, so it needs no wallpaper
/// permission. Android's screen, or the app the user picks from the "Set as"
/// list, does that. Kotlin accepts only a MediaStore address.
class WallpaperService {
  final MethodChannel _channel;

  WallpaperService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.intentChannelName);

  /// Hands the photo at [uri] to Android's wallpaper screen.
  ///
  /// [chooserTitle] titles the "Set as" list shown when the phone's wallpaper
  /// screen refuses the photo. Returns whether a screen opened; never throws.
  Future<bool> setAsWallpaper({
    required String uri,
    required String mimeType,
    required String chooserTitle,
  }) async {
    try {
      final opened = await _channel.invokeMethod<bool>(
        'setAsWallpaper',
        <String, Object?>{
          'uri': uri,
          'mimeType': mimeType,
          'chooserTitle': chooserTitle,
        },
      );
      return opened ?? false;
    } on PlatformException catch (error) {
      // The code only (bad_uri, no_app): never the address of the photo.
      AppLogger.warning('Opening the wallpaper screen failed: ${error.code}');
      return false;
    } on MissingPluginException {
      AppLogger.warning('Opening the wallpaper screen failed: no plugin');
      return false;
    }
  }
}
