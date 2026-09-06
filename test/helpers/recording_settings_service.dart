import 'dart:io';

import 'package:in_sreerajp_imgvidgal/models/settings/app_settings.dart';
import 'package:in_sreerajp_imgvidgal/services/settings/app_settings_service.dart';

/// An in-memory stand-in for [AppSettingsService] that remembers every save.
///
/// A widget test runs in fake time, so a real file write inside one never
/// finishes. This keeps the settings in memory instead, and records what was
/// written so a test can check that a tap on screen actually reached the
/// store. The real file round trip is covered by the service's own test.
class RecordingSettingsService extends AppSettingsService {
  /// Every settings object handed to [save], oldest first.
  final List<AppSettings> saved = <AppSettings>[];

  /// What [load] will return.
  AppSettings stored;

  /// Makes the next [save] report failure, as a full disk would.
  bool failNextSave = false;

  RecordingSettingsService({this.stored = AppSettings.defaults})
    : super(directory: _unusedDirectory);

  /// Never touched: nothing in this class reaches the file system.
  static final Directory _unusedDirectory = Directory('memory-only');

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<bool> save(AppSettings settings) async {
    if (failNextSave) {
      failNextSave = false;
      return false;
    }
    saved.add(settings);
    stored = settings;
    return true;
  }
}
