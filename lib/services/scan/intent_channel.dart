import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';
import 'package:in_sreerajp_imgvidgal/models/scan/wifi_credentials.dart';

/// Thrown when handing something to another app did not work.
class IntentException implements Exception {
  final String code;
  final String message;

  const IntentException(this.code, this.message);

  /// Whether no app on the device can open it.
  bool get hasNoApp => code == 'no_app';

  /// Whether the scheme was refused, rather than merely failing.
  ///
  /// This one is a bug, not a device limit: the resolver should never have
  /// offered an action the channel then refuses.
  bool get wasBlocked => code == 'blocked_scheme';

  @override
  String toString() => 'IntentException($code): $message';
}

/// Hands a scanned code to another app.
///
/// The Dart half of the one place that builds an outgoing intent from
/// untrusted text. It checks the scheme before calling, and the Kotlin side
/// checks again; neither gate trusts the other.
class IntentChannel {
  final MethodChannel _channel;

  IntentChannel({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(AppConstants.intentChannelName);

  /// Opens [uri] in whichever app the user has for it.
  ///
  /// Throws [IntentException] with `blocked_scheme` rather than calling the
  /// platform at all when the scheme is not on the permitted list.
  Future<void> openUri(String uri) async {
    final scheme = Uri.tryParse(uri)?.scheme.toLowerCase() ?? '';
    if (!AppConstants.scanLaunchableSchemes.contains(scheme)) {
      throw const IntentException(
        'blocked_scheme',
        'This kind of address is not opened by the app',
      );
    }

    await _invoke<bool>('openUri', <String, Object?>{'uri': uri});
  }

  /// Opens the system Wi-Fi screen.
  Future<void> openWifiSettings() =>
      _invoke<bool>('openWifiSettings', const <String, Object?>{});

  /// Offers [credentials] to Android as a network suggestion.
  ///
  /// Returns whether Android took the suggestion. False is an ordinary answer,
  /// not a failure: on Android 9 and below there is no suggestion API worth
  /// using, and the caller falls back to the settings screen.
  Future<bool> suggestWifiNetwork(WifiCredentials credentials) async {
    final accepted =
        await _invoke<bool>('suggestWifiNetwork', <String, Object?>{
          'ssid': credentials.ssid,
          'password': credentials.password,
          'security': credentials.security.name,
          'hidden': credentials.isHidden,
        });
    return accepted ?? false;
  }

  /// Puts [text] on the clipboard.
  ///
  /// Set [isSensitive] for a password, so Android 13 and above leaves it out
  /// of the clipboard preview shown on screen.
  Future<void> copyToClipboard(
    String text, {
    String label = '',
    bool isSensitive = false,
  }) {
    return _invoke<bool>('copyToClipboard', <String, Object?>{
      'text': text,
      'label': label,
      'isSensitive': isSensitive,
    });
  }

  Future<T?> _invoke<T>(String method, Map<String, Object?> arguments) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw IntentException(error.code, error.message ?? error.code);
    } on MissingPluginException {
      throw const IntentException(
        'unavailable',
        'This is not available on this device',
      );
    }
  }
}
