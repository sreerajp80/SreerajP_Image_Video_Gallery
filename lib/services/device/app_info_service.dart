import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/constants/app_constants.dart';

/// The installed app's version name and build number.
class AppInfo {
  final String version;
  final String buildNumber;

  const AppInfo({required this.version, required this.buildNumber});

  /// `version+build`, the same shape as the `version:` line in pubspec.
  String get fullVersion => '$version+$buildNumber';
}

/// Reads the app's own version from Android's PackageManager.
///
/// A plain method channel instead of the `package_info_plus` plugin, which
/// brought the `http` package into the dependency tree (CLAUDE.md blocks HTTP
/// clients even as transitive dependencies).
class AppInfoService {
  final MethodChannel _channel;

  const AppInfoService({
    MethodChannel channel = const MethodChannel(
      AppConstants.appInfoChannelName,
    ),
  }) : _channel = channel;

  /// The app's version, or null when the platform cannot say.
  ///
  /// Never throws: callers use this for display and a sanity check only.
  Future<AppInfo?> load() async {
    try {
      final raw = await _channel.invokeMapMethod<String, Object?>('getAppInfo');
      if (raw == null) return null;
      final version = raw['versionName'];
      final build = raw['buildNumber'];
      if (version is! String || build is! String) return null;
      return AppInfo(version: version, buildNumber: build);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
