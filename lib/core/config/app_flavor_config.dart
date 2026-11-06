import 'package:flutter/services.dart';
import 'package:in_sreerajp_imgvidgal/core/logging/app_logger.dart';

enum AppFlavor {
  dev,
  prod;

  bool get isDev => this == AppFlavor.dev;
  bool get isProd => this == AppFlavor.prod;

  String get displayName {
    switch (this) {
      case AppFlavor.dev:
        return 'SreerajP Gallery Dev';
      case AppFlavor.prod:
        return 'SreerajP Image Video Gallery';
    }
  }

  String get applicationId {
    switch (this) {
      case AppFlavor.dev:
        return 'in.sreerajp.imgvidgal.dev';
      case AppFlavor.prod:
        return 'in.sreerajp.imgvidgal';
    }
  }
}

class AppFlavorConfig {
  static AppFlavor _current = AppFlavor.prod;

  static AppFlavor get current => _current;

  static void initialize() {
    const rawFlavor =
        appFlavor ??
        String.fromEnvironment(
          'APP_FLAVOR',
          defaultValue: String.fromEnvironment(
            'FLUTTER_APP_FLAVOR',
            defaultValue: 'prod',
          ),
        );

    switch (rawFlavor.toLowerCase().trim()) {
      case 'dev':
        _current = AppFlavor.dev;
        break;
      case 'prod':
      default:
        _current = AppFlavor.prod;
        break;
    }

    AppLogger.info('App flavor initialized: ${_current.name}');
  }
}
