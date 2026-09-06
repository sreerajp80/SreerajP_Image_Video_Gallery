import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    final rawFlavor =
        appFlavor ??
        const String.fromEnvironment(
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

    if (kDebugMode) {
      debugPrint(
        'AppFlavor initialized: ${_current.name} (${_current.displayName})',
      );
    }
  }
}
