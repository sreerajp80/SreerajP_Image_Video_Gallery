import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:in_sreerajp_imgvidgal/core/config/app_config.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';
import 'package:in_sreerajp_imgvidgal/services/device/app_info_service.dart';

class ConfigService {
  static const String assetPath = 'assets/config/app_config.json';

  final Future<String> Function(String path) _loadAsset;

  ConfigService({Future<String> Function(String path)? loadAsset})
    : _loadAsset = loadAsset ?? rootBundle.loadString;

  Future<AppConfig> load() async {
    try {
      final text = await _loadAsset(assetPath);
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) return AppConfig.fallback;
      return AppConfig.fromJson(decoded);
    } catch (error) {
      AppLogger.warning(
        'The app config was unreadable; the fallback is used',
        error: error,
      );
      return AppConfig.fallback;
    }
  }

  /// Loads the config and notes in the debug log when its `version`/`build`
  /// have drifted from the installed app's. Never fails over it.
  Future<AppConfig> loadAndVerify({
    AppInfoService appInfoService = const AppInfoService(),
  }) async {
    final config = await load();
    final info = await appInfoService.load();
    if (info == null) return config; // Unknown (e.g. unit tests) — ignore.
    final mismatch =
        info.version != config.version || info.buildNumber != config.build;
    if (mismatch) {
      AppLogger.debug(
        'ConfigService: version/build in app_config.json '
        '(${config.version}+${config.build}) does not match the build '
        '(${info.fullVersion}).',
      );
    }
    return config;
  }
}
