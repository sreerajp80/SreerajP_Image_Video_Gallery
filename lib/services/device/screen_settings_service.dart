import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// Screen brightness, media volume, and keep-awake for the viewer.
///
/// It is an interface first so the viewer can be tested with a fake and so no
/// widget ever talks to a platform channel directly. Every call is best effort:
/// a device that refuses one of these must not break playback.
abstract class ScreenSettingsService {
  /// Current window brightness from 0.0 to 1.0.
  ///
  /// Returns the system brightness the first time, because the window starts
  /// out following the system setting.
  Future<double> getBrightness();

  /// Sets the window brightness for this app only.
  ///
  /// It never changes the device-wide setting, and Android restores it as soon
  /// as the app leaves the foreground.
  Future<void> setBrightness(double value);

  /// Hands brightness control back to the system.
  Future<void> resetBrightness();

  /// Current media volume from 0.0 to 1.0.
  Future<double> getVolume();

  /// Sets the media stream volume.
  Future<void> setVolume(double value);

  /// Keeps the screen on while a video plays, or lets it sleep again.
  Future<void> setKeepScreenOn(bool keepOn);
}

/// Real implementation backed by the `playback` method channel.
class PlatformScreenSettingsService implements ScreenSettingsService {
  final MethodChannel _channel;

  PlatformScreenSettingsService({MethodChannel? channel})
    : _channel =
          channel ?? const MethodChannel(AppConstants.playbackChannelName);

  @override
  Future<double> getBrightness() async {
    final value = await _invoke<double>('getBrightness');
    return _clamp(value ?? 0.5);
  }

  @override
  Future<void> setBrightness(double value) async {
    await _invoke<void>('setBrightness', <String, Object?>{
      'value': _clamp(value),
    });
  }

  @override
  Future<void> resetBrightness() async {
    await _invoke<void>('resetBrightness');
  }

  @override
  Future<double> getVolume() async {
    final value = await _invoke<double>('getVolume');
    return _clamp(value ?? 1.0);
  }

  @override
  Future<void> setVolume(double value) async {
    await _invoke<void>('setVolume', <String, Object?>{'value': _clamp(value)});
  }

  @override
  Future<void> setKeepScreenOn(bool keepOn) async {
    await _invoke<void>('setKeepScreenOn', <String, Object?>{'keepOn': keepOn});
  }

  double _clamp(double value) {
    if (value.isNaN) return 0;
    return value.clamp(0.0, 1.0);
  }

  /// Calls the channel and swallows platform failures.
  ///
  /// These controls are comfort features. If a device or an emulator cannot do
  /// one of them, the video still plays, so a failure is never surfaced.
  Future<T?> _invoke<T>(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
